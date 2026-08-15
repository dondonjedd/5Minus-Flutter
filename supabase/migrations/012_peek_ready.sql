-- Opening peek: both seats ready (or 30s from start_match) before play unlocks.

alter table public.match_players
  add column if not exists peek_ready boolean not null default false;

alter table public.matches
  add column if not exists peek_deadline timestamptz;

-- ---------------------------------------------------------------------------
-- Play is unlocked when turn_start_time is set (null during peek).
-- ---------------------------------------------------------------------------

create or replace function private.assert_play_unlocked(p_match public.matches)
returns void
language plpgsql
immutable
as $$
begin
  if p_match.turn_start_time is null then
    raise exception 'peek still open' using errcode = 'P0001';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- start_match: deal hands, set peek_deadline, leave turn_start_time null.
-- ---------------------------------------------------------------------------

create or replace function public.start_match(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  n int;
  ready_n int;
  deck jsonb;
  r record;
  hand jsonb;
  i int;
  card jsonb;
begin
  m := private.lock_match(p_code);
  if m.host_id is distinct from uid then
    raise exception 'not the host' using errcode = 'P0001';
  end if;
  if m.status is distinct from 'lobby' then
    raise exception 'match is not in lobby' using errcode = 'P0001';
  end if;

  select count(*), count(*) filter (where is_ready)
    into n, ready_n
  from public.match_players
  where game_code = p_code;

  if n <> 2 or ready_n <> 2 then
    raise exception 'need two ready seats' using errcode = 'P0001';
  end if;

  deck := private.shuffled_deck();
  for r in
    select user_id from public.match_players
    where game_code = p_code
    order by seat
  loop
    hand := '[]'::jsonb;
    for i in 1..4 loop
      card := private.last_card(deck);
      deck := private.drop_last(deck);
      if card is not null then
        hand := hand || jsonb_build_array(card);
      end if;
    end loop;
    update public.match_players
    set
      player_hand = hand,
      penalty_count = 0,
      elimination_locked = false,
      actions_complete = false,
      is_challenge_declared = false,
      peek_ready = false
    where game_code = p_code and user_id = r.user_id;
  end loop;

  update public.matches
  set
    status = 'active',
    draw_deck = deck,
    discard_deck = '[]'::jsonb,
    turn = 0,
    drawn_card = null,
    power_start_time = null,
    winner_user_id = null,
    end_reason = null,
    ended_at = null,
    turn_start_time = null,
    peek_deadline = now() + interval '30 seconds',
    updated_at = now()
  where game_code = p_code;

  return private.match_bundle(p_code);
end;
$$;

-- ---------------------------------------------------------------------------
-- Caller marks self ready, or either client expires all seats at deadline.
-- ---------------------------------------------------------------------------

create or replace function public.ready_peek(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_seat int;
  ready_n int;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;

  select seat into v_seat
  from public.match_players
  where game_code = p_code and user_id = uid;
  if v_seat is null then
    raise exception 'not seated' using errcode = 'P0001';
  end if;

  if m.peek_deadline is not null and now() >= m.peek_deadline then
    update public.match_players
    set peek_ready = true
    where game_code = p_code;
  else
    update public.match_players
    set peek_ready = true
    where game_code = p_code and user_id = uid;
  end if;

  select count(*) filter (where peek_ready)
    into ready_n
  from public.match_players
  where game_code = p_code;

  if ready_n >= 2 then
    update public.matches
    set
      turn_start_time = now(),
      updated_at = now()
    where game_code = p_code
      and turn_start_time is null;
  end if;

  return private.match_bundle(p_code);
end;
$$;

revoke all on function public.ready_peek(text) from public;
grant execute on function public.ready_peek(text) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Play RPCs: reject while peek is still open. Forfeit / disconnect stay open.
-- ---------------------------------------------------------------------------

create or replace function public.claim_draw(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_seat int;
  v_complete boolean;
  v_draw jsonb;
  v_discard jsonb;
  v_card jsonb;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  perform private.assert_play_unlocked(m);
  if private.pending_power(m) then
    raise exception 'power pending' using errcode = 'P0001';
  end if;
  if m.drawn_card is not null then
    raise exception 'drawn_card already set' using errcode = 'P0001';
  end if;

  select seat, actions_complete into v_seat, v_complete
  from public.match_players
  where game_code = p_code and user_id = uid;
  if v_seat is null then
    raise exception 'not seated' using errcode = 'P0001';
  end if;
  if v_seat is distinct from m.turn then
    raise exception 'not your turn' using errcode = 'P0001';
  end if;
  if v_complete then
    raise exception 'actions already complete' using errcode = 'P0001';
  end if;

  select e.draw, e.discard into v_draw, v_discard
  from private.ensure_draw(m.draw_deck, m.discard_deck) e;
  v_card := private.last_card(v_draw);
  if v_card is null then
    raise exception 'draw pile empty' using errcode = 'P0001';
  end if;
  v_draw := private.drop_last(v_draw);

  update public.matches
  set
    drawn_card = v_card,
    draw_deck = v_draw,
    discard_deck = v_discard,
    updated_at = now()
  where game_code = p_code
    and drawn_card is null;

  if not found then
    raise exception 'drawn_card already set' using errcode = 'P0001';
  end if;

  return private.match_bundle(p_code);
end;
$$;

create or replace function public.discard_drawn(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_seat int;
  v_complete boolean;
  v_discard jsonb;
  v_drawn jsonb;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  perform private.assert_play_unlocked(m);
  if private.pending_power(m) then
    raise exception 'power pending' using errcode = 'P0001';
  end if;
  v_drawn := m.drawn_card;
  if v_drawn is null then
    raise exception 'no drawn card' using errcode = 'P0001';
  end if;

  select seat, actions_complete into v_seat, v_complete
  from public.match_players
  where game_code = p_code and user_id = uid;
  if v_seat is null then
    raise exception 'not seated' using errcode = 'P0001';
  end if;
  if v_seat is distinct from m.turn then
    raise exception 'not your turn' using errcode = 'P0001';
  end if;
  if v_complete then
    raise exception 'actions already complete' using errcode = 'P0001';
  end if;

  v_discard := coalesce(m.discard_deck, '[]'::jsonb) || jsonb_build_array(v_drawn);
  update public.matches
  set discard_deck = v_discard, drawn_card = null, updated_at = now()
  where game_code = p_code;

  perform private.after_discard(p_code, uid, v_drawn);
  return private.match_bundle(p_code);
end;
$$;

create or replace function public.replace_hand(p_code text, p_hand_index int)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_seat int;
  v_complete boolean;
  v_hand jsonb;
  v_removed jsonb;
  v_drawn jsonb;
  v_discard jsonb;
  n int;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  perform private.assert_play_unlocked(m);
  if private.pending_power(m) then
    raise exception 'power pending' using errcode = 'P0001';
  end if;
  v_drawn := m.drawn_card;
  if v_drawn is null then
    raise exception 'no drawn card' using errcode = 'P0001';
  end if;

  select seat, actions_complete, player_hand
    into v_seat, v_complete, v_hand
  from public.match_players
  where game_code = p_code and user_id = uid;
  if v_seat is null then
    raise exception 'not seated' using errcode = 'P0001';
  end if;
  if v_seat is distinct from m.turn then
    raise exception 'not your turn' using errcode = 'P0001';
  end if;
  if v_complete then
    raise exception 'actions already complete' using errcode = 'P0001';
  end if;

  v_hand := coalesce(v_hand, '[]'::jsonb);
  n := jsonb_array_length(v_hand);
  if p_hand_index < 0 or p_hand_index >= n then
    raise exception 'invalid hand index' using errcode = 'P0001';
  end if;

  v_removed := v_hand -> p_hand_index;
  v_hand := jsonb_set(v_hand, array[p_hand_index::text], v_drawn);
  v_discard := coalesce(m.discard_deck, '[]'::jsonb) || jsonb_build_array(v_removed);

  update public.match_players
  set player_hand = v_hand
  where game_code = p_code and user_id = uid;
  update public.matches
  set discard_deck = v_discard, drawn_card = null, updated_at = now()
  where game_code = p_code;

  perform private.after_discard(p_code, uid, v_removed);
  return private.match_bundle(p_code);
end;
$$;

create or replace function public.eliminate_card(p_code text, p_hand_index int)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_seat int;
  v_locked boolean;
  v_hand jsonb;
  v_card jsonb;
  v_top jsonb;
  v_opp text;
  n int;
  notice text;
  v_match_over boolean := false;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  perform private.assert_play_unlocked(m);
  if private.pending_power(m) then
    raise exception 'power pending' using errcode = 'P0001';
  end if;
  v_top := private.last_card(m.discard_deck);
  if v_top is null then
    raise exception 'no discard card' using errcode = 'P0001';
  end if;

  select seat, elimination_locked, player_hand
    into v_seat, v_locked, v_hand
  from public.match_players
  where game_code = p_code and user_id = uid;
  if v_seat is null then
    raise exception 'not seated' using errcode = 'P0001';
  end if;
  if v_seat is distinct from m.turn then
    raise exception 'not your turn' using errcode = 'P0001';
  end if;
  if v_locked then
    raise exception 'elimination locked' using errcode = 'P0001';
  end if;

  v_hand := coalesce(v_hand, '[]'::jsonb);
  n := jsonb_array_length(v_hand);
  if p_hand_index < 0 or p_hand_index >= n then
    raise exception 'invalid hand index' using errcode = 'P0001';
  end if;

  v_card := v_hand -> p_hand_index;
  if (v_card->>'rank') is distinct from (v_top->>'rank') then
    perform private.apply_penalty(p_code, uid, true, n - 1);
    if (
      select penalty_count from public.match_players
      where game_code = p_code and user_id = uid
    ) >= 3 then
      v_opp := private.opponent_user_id(p_code, uid);
      if v_opp is not null then
        perform private.finish_match(p_code, v_opp, 'penalties');
        v_match_over := true;
      end if;
    end if;
    update public.matches
    set last_eliminate = jsonb_build_object(
      'seat', v_seat,
      'hand_index', p_hand_index,
      'failed', true,
      'match_over', v_match_over
    )
    where game_code = p_code;
    notice := 'Wrong rank - elimination locked until your next turn';
    return private.match_bundle(p_code) || jsonb_build_object('notice', notice);
  end if;

  v_hand := v_hand - p_hand_index;
  update public.match_players
  set player_hand = v_hand
  where game_code = p_code and user_id = uid;

  if jsonb_array_length(v_hand) = 0 then
    perform private.finish_match(p_code, uid, 'empty_hand');
    v_match_over := true;
  end if;

  update public.matches
  set last_eliminate = jsonb_build_object(
    'seat', v_seat,
    'hand_index', p_hand_index,
    'failed', false,
    'match_over', v_match_over
  )
  where game_code = p_code;

  return private.match_bundle(p_code);
end;
$$;

create or replace function public.swap_hands(
  p_code text,
  p_seat_a int,
  p_idx_a int,
  p_seat_b int,
  p_idx_b int
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_seat int;
  hand_a jsonb;
  hand_b jsonb;
  user_a text;
  user_b text;
  tmp jsonb;
  n int;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  perform private.assert_play_unlocked(m);
  if m.power_start_time is null
     or private.card_power(private.last_card(m.discard_deck)) is distinct from 2 then
    raise exception 'no swap pending' using errcode = 'P0001';
  end if;

  select seat into v_seat
  from public.match_players
  where game_code = p_code and user_id = uid;
  if v_seat is distinct from m.turn then
    raise exception 'not your turn' using errcode = 'P0001';
  end if;

  select user_id, player_hand into user_a, hand_a
  from public.match_players
  where game_code = p_code and seat = p_seat_a;
  select user_id, player_hand into user_b, hand_b
  from public.match_players
  where game_code = p_code and seat = p_seat_b;
  if user_a is null or user_b is null then
    raise exception 'invalid seat' using errcode = 'P0001';
  end if;

  hand_a := coalesce(hand_a, '[]'::jsonb);
  hand_b := coalesce(hand_b, '[]'::jsonb);
  n := jsonb_array_length(hand_a);
  if p_idx_a < 0 or p_idx_a >= n then
    raise exception 'invalid hand index' using errcode = 'P0001';
  end if;
  n := jsonb_array_length(hand_b);
  if p_idx_b < 0 or p_idx_b >= n then
    raise exception 'invalid hand index' using errcode = 'P0001';
  end if;

  if user_a = user_b then
    tmp := hand_a -> p_idx_a;
    hand_a := jsonb_set(hand_a, array[p_idx_a::text], hand_a -> p_idx_b);
    hand_a := jsonb_set(hand_a, array[p_idx_b::text], tmp);
    update public.match_players
    set player_hand = hand_a
    where game_code = p_code and user_id = user_a;
  else
    tmp := hand_a -> p_idx_a;
    hand_a := jsonb_set(hand_a, array[p_idx_a::text], hand_b -> p_idx_b);
    hand_b := jsonb_set(hand_b, array[p_idx_b::text], tmp);
    update public.match_players
    set player_hand = hand_a
    where game_code = p_code and user_id = user_a;
    update public.match_players
    set player_hand = hand_b
    where game_code = p_code and user_id = user_b;
  end if;

  update public.matches
  set power_start_time = null, updated_at = now()
  where game_code = p_code;

  return private.match_bundle(p_code);
end;
$$;

create or replace function public.clear_pending_power(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_seat int;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  perform private.assert_play_unlocked(m);
  if m.power_start_time is null
     or private.card_power(private.last_card(m.discard_deck)) is distinct from 1 then
    raise exception 'no look pending' using errcode = 'P0001';
  end if;
  select seat into v_seat
  from public.match_players
  where game_code = p_code and user_id = uid;
  if v_seat is distinct from m.turn then
    raise exception 'not your turn' using errcode = 'P0001';
  end if;

  update public.matches
  set power_start_time = null, updated_at = now()
  where game_code = p_code;

  return private.match_bundle(p_code);
end;
$$;

create or replace function public.end_turn(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_seat int;
  v_complete boolean;
  others boolean;
  finished boolean;
begin
  m := private.lock_match(p_code);
  if m.status = 'finished' then
    return private.match_bundle(p_code);
  end if;
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  perform private.assert_play_unlocked(m);
  if private.pending_power(m) then
    raise exception 'power pending' using errcode = 'P0001';
  end if;

  select seat, actions_complete into v_seat, v_complete
  from public.match_players
  where game_code = p_code and user_id = uid;
  if v_seat is null then
    raise exception 'not seated' using errcode = 'P0001';
  end if;
  if v_seat is distinct from m.turn then
    raise exception 'not your turn' using errcode = 'P0001';
  end if;
  if not v_complete then
    raise exception 'actions not complete' using errcode = 'P0001';
  end if;

  select exists (
    select 1 from public.match_players
    where game_code = p_code
      and seat is distinct from v_seat
      and is_challenge_declared
  ) into others;

  if others then
    finished := private.resolve_challenges(p_code);
    if finished then
      return private.match_bundle(p_code);
    end if;
  end if;

  perform private.advance_turn(p_code);
  return private.match_bundle(p_code);
end;
$$;

create or replace function public.declare_challenge(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_seat int;
  v_complete boolean;
  v_declared boolean;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  perform private.assert_play_unlocked(m);
  if private.pending_power(m) then
    raise exception 'power pending' using errcode = 'P0001';
  end if;

  select seat, actions_complete, is_challenge_declared
    into v_seat, v_complete, v_declared
  from public.match_players
  where game_code = p_code and user_id = uid;
  if v_seat is null then
    raise exception 'not seated' using errcode = 'P0001';
  end if;
  if v_seat is distinct from m.turn then
    raise exception 'not your turn' using errcode = 'P0001';
  end if;
  if not v_complete then
    raise exception 'actions not complete' using errcode = 'P0001';
  end if;
  if v_declared then
    raise exception 'already challenged' using errcode = 'P0001';
  end if;

  update public.match_players
  set is_challenge_declared = true
  where game_code = p_code and user_id = uid;
  update public.matches
  set updated_at = now()
  where game_code = p_code;

  return public.end_turn(p_code);
end;
$$;
