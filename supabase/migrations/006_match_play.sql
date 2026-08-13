-- Match play: named public moves, Match.status, revoke play-column UPDATEs.

-- ---------------------------------------------------------------------------
-- Schema
-- ---------------------------------------------------------------------------

alter table public.matches
  add column if not exists status text not null default 'lobby',
  add column if not exists winner_user_id text,
  add column if not exists end_reason text,
  add column if not exists ended_at timestamptz;

update public.matches
set status = case
  when winner is not null then 'finished'
  when has_started then 'active'
  else 'lobby'
end
where status = 'lobby'
  and (winner is not null or has_started);

update public.matches
set
  winner_user_id = coalesce(winner->>'player_id', winner->>'playerId'),
  end_reason = winner->>'end_reason',
  ended_at = coalesce(ended_at, updated_at, now())
where winner is not null
  and winner_user_id is null;

alter table public.matches drop constraint if exists matches_status_check;
alter table public.matches
  add constraint matches_status_check
  check (status in ('lobby', 'active', 'finished'));

create or replace function private.is_open_lobby(p_code text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.matches m
    where m.game_code = p_code
      and m.status = 'lobby'
  );
$$;

drop policy if exists "matches_select_lobby_or_member" on public.matches;
create policy "matches_select_lobby_or_member" on public.matches
  for select
  to anon, authenticated
  using (
    host_id = private.current_uid()
    or private.is_seated(game_code)
    or status = 'lobby'
  );

alter table public.matches drop column if exists players;
alter table public.matches drop column if exists has_started;
alter table public.matches drop column if exists is_active;
alter table public.matches drop column if exists winner;

-- ---------------------------------------------------------------------------
-- Max two Seats
-- ---------------------------------------------------------------------------

create or replace function private.enforce_max_seats()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (
    select count(*) from public.match_players s
    where s.game_code = new.game_code
  ) >= 2 then
    raise exception 'match is full' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_max_seats on public.match_players;
create trigger enforce_max_seats
  before insert on public.match_players
  for each row
  execute function private.enforce_max_seats();

-- ---------------------------------------------------------------------------
-- Column grants: play columns are function-only
-- ---------------------------------------------------------------------------

revoke all on table public.matches from anon, authenticated;
grant select, insert, delete on table public.matches to anon, authenticated;
grant update (game_type) on table public.matches to anon, authenticated;

revoke all on table public.match_players from anon, authenticated;
grant select, insert, delete on table public.match_players to anon, authenticated;
grant update (is_ready, last_seen) on table public.match_players to anon, authenticated;

drop policy if exists "matches_update_member" on public.matches;
drop policy if exists "matches_update_host_lobby" on public.matches;
create policy "matches_update_host_lobby" on public.matches
  for update
  to anon, authenticated
  using (host_id = private.current_uid() and status = 'lobby')
  with check (host_id = private.current_uid() and status = 'lobby');

drop policy if exists "seats_insert_own" on public.match_players;
create policy "seats_insert_own" on public.match_players
  for insert
  to anon, authenticated
  with check (
    user_id = private.current_uid()
    and private.is_open_lobby(game_code)
  );

drop policy if exists "seats_update_member" on public.match_players;
drop policy if exists "seats_update_own" on public.match_players;
create policy "seats_update_own" on public.match_players
  for update
  to anon, authenticated
  using (user_id = private.current_uid())
  with check (user_id = private.current_uid());

drop policy if exists "matches_insert_as_host" on public.matches;
create policy "matches_insert_as_host" on public.matches
  for insert
  to anon, authenticated
  with check (
    host_id = private.current_uid()
    and status = 'lobby'
  );

-- ---------------------------------------------------------------------------
-- Card / pile helpers
-- ---------------------------------------------------------------------------

create or replace function private.make_card(p_rank int, p_suit int)
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'rank', p_rank,
    'suit', p_suit,
    'power', case
      when p_rank = 11 then 2
      when p_rank = 12 then 1
      when p_rank = 13 and p_suit in (3, 4) then 0
      when p_rank = 13 then 3
      else 0
    end,
    'value', case
      when p_rank in (11, 12) then 10
      when p_rank = 13 and p_suit in (3, 4) then 0
      when p_rank = 13 then 10
      else p_rank
    end
  );
$$;

create or replace function private.card_power(p jsonb)
returns int
language sql
immutable
as $$
  select case
    when p is null then 0
    when (p->>'rank')::int = 11 then 2
    when (p->>'rank')::int = 12 then 1
    when (p->>'rank')::int = 13 and (p->>'suit')::int in (3, 4) then 0
    when (p->>'rank')::int = 13 then 3
    else 0
  end;
$$;

create or replace function private.card_value(p jsonb)
returns int
language sql
immutable
as $$
  select case
    when p is null then 0
    when (p->>'rank')::int in (11, 12) then 10
    when (p->>'rank')::int = 13 and (p->>'suit')::int in (3, 4) then 0
    when (p->>'rank')::int = 13 then 10
    else coalesce((p->>'rank')::int, 0)
  end;
$$;

create or replace function private.hand_points(p_hand jsonb)
returns int
language sql
immutable
as $$
  select coalesce(sum(private.card_value(c)), 0)::int
  from jsonb_array_elements(coalesce(p_hand, '[]'::jsonb)) c;
$$;

create or replace function private.shuffled_deck()
returns jsonb
language sql
volatile
as $$
  select coalesce(jsonb_agg(private.make_card(r, s) order by random()), '[]'::jsonb)
  from generate_series(1, 13) r
  cross join (values (1), (2), (3), (4)) as suits(s);
$$;

create or replace function private.last_card(p jsonb)
returns jsonb
language sql
immutable
as $$
  select case
    when p is null or jsonb_typeof(p) <> 'array' or jsonb_array_length(p) = 0 then null
    else p -> (jsonb_array_length(p) - 1)
  end;
$$;

create or replace function private.drop_last(p jsonb)
returns jsonb
language sql
immutable
as $$
  select case
    when p is null or jsonb_typeof(p) <> 'array' or jsonb_array_length(p) = 0 then '[]'::jsonb
    else p - (jsonb_array_length(p) - 1)
  end;
$$;

create or replace function private.ensure_draw(p_draw jsonb, p_discard jsonb)
returns table(draw jsonb, discard jsonb)
language plpgsql
volatile
as $$
declare
  n int;
  top jsonb;
  rest jsonb;
  shuffled jsonb;
begin
  p_draw := coalesce(p_draw, '[]'::jsonb);
  p_discard := coalesce(p_discard, '[]'::jsonb);
  if jsonb_array_length(p_draw) > 0 then
    draw := p_draw;
    discard := p_discard;
    return next;
    return;
  end if;
  n := jsonb_array_length(p_discard);
  if n <= 1 then
    draw := p_draw;
    discard := p_discard;
    return next;
    return;
  end if;
  top := p_discard -> (n - 1);
  rest := p_discard - (n - 1);
  select coalesce(jsonb_agg(elem order by random()), '[]'::jsonb)
    into shuffled
  from jsonb_array_elements(rest) elem;
  draw := shuffled;
  discard := jsonb_build_array(top);
  return next;
end;
$$;

create or replace function private.match_bundle(p_code text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'match', to_jsonb(m),
    'seats', coalesce((
      select jsonb_agg(to_jsonb(s) order by s.seat)
      from public.match_players s
      where s.game_code = p_code
    ), '[]'::jsonb)
  )
  from public.matches m
  where m.game_code = p_code;
$$;

create or replace function private.require_uid()
returns text
language plpgsql
stable
as $$
declare
  uid text;
begin
  uid := private.current_uid();
  if uid is null or uid = '' then
    raise exception 'not signed in' using errcode = 'P0001';
  end if;
  return uid;
end;
$$;

create or replace function private.lock_match(p_code text)
returns public.matches
language plpgsql
security definer
set search_path = public
as $$
declare
  m public.matches;
begin
  select * into m from public.matches where game_code = p_code for update;
  if not found then
    raise exception 'match not found' using errcode = 'P0001';
  end if;
  perform 1 from public.match_players where game_code = p_code for update;
  return m;
end;
$$;

create or replace function private.pending_power(p_match public.matches)
returns boolean
language sql
immutable
as $$
  select p_match.power_start_time is not null
    and private.card_power(private.last_card(p_match.discard_deck)) in (1, 2);
$$;

create or replace function private.finish_match(
  p_code text,
  p_winner_user_id text,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.matches
  set
    status = 'finished',
    winner_user_id = p_winner_user_id,
    end_reason = p_reason,
    ended_at = now(),
    is_challenge_complete = true,
    updated_at = now()
  where game_code = p_code;
end;
$$;

create or replace function private.apply_penalty(
  p_code text,
  p_user_id text,
  p_lock_elimination boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  m public.matches;
  v_draw jsonb;
  v_discard jsonb;
  v_card jsonb;
  v_hand jsonb;
begin
  select * into m from public.matches where game_code = p_code;
  select e.draw, e.discard into v_draw, v_discard
  from private.ensure_draw(m.draw_deck, m.discard_deck) e;
  v_card := private.last_card(v_draw);
  v_draw := private.drop_last(v_draw);
  select player_hand into v_hand
  from public.match_players
  where game_code = p_code and user_id = p_user_id;
  v_hand := coalesce(v_hand, '[]'::jsonb);
  if v_card is not null then
    v_hand := jsonb_build_array(v_card) || v_hand;
  end if;
  update public.match_players
  set
    player_hand = v_hand,
    penalty_count = penalty_count + 1,
    elimination_locked = case
      when p_lock_elimination then true
      else elimination_locked
    end
  where game_code = p_code and user_id = p_user_id;
  update public.matches
  set draw_deck = v_draw, discard_deck = v_discard, updated_at = now()
  where game_code = p_code;
end;
$$;

create or replace function private.opponent_user_id(p_code text, p_user_id text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select s.user_id
  from public.match_players s
  where s.game_code = p_code
    and s.user_id is distinct from p_user_id
  order by s.seat
  limit 1;
$$;

create or replace function private.resolve_challenges(p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
  v_user text;
  v_points int;
  v_best text;
  v_best_points int;
  v_tie boolean := false;
  r record;
  v_opp text;
begin
  select count(*) into n
  from public.match_players
  where game_code = p_code and is_challenge_declared;

  if n = 0 then
    return false;
  end if;

  if n = 1 then
    select user_id, private.hand_points(player_hand)
      into v_user, v_points
    from public.match_players
    where game_code = p_code and is_challenge_declared;

    if v_points <= 5 then
      perform private.finish_match(p_code, v_user, 'challenge');
      return true;
    end if;

    perform private.apply_penalty(p_code, v_user, false);
    update public.match_players
    set is_challenge_declared = false
    where game_code = p_code;
    update public.matches
    set is_challenge_complete = true, updated_at = now()
    where game_code = p_code;

    if (
      select penalty_count from public.match_players
      where game_code = p_code and user_id = v_user
    ) >= 3 then
      v_opp := private.opponent_user_id(p_code, v_user);
      if v_opp is not null then
        perform private.finish_match(p_code, v_opp, 'penalties');
        return true;
      end if;
    end if;
    return false;
  end if;

  v_best_points := 999;
  for r in
    select user_id, private.hand_points(player_hand) as pts
    from public.match_players
    where game_code = p_code and is_challenge_declared
  loop
    if r.pts < v_best_points then
      v_best_points := r.pts;
      v_best := r.user_id;
      v_tie := false;
    elsif r.pts = v_best_points then
      v_tie := true;
    end if;
  end loop;

  if v_tie then
    perform private.finish_match(p_code, '__DRAW__', 'challenge_tie');
  else
    perform private.finish_match(p_code, v_best, 'challenge');
  end if;
  return true;
end;
$$;

create or replace function private.after_discard(
  p_code text,
  p_user_id text,
  p_discarded jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  power int;
  m public.matches;
  v_draw jsonb;
  v_discard jsonb;
  v_card jsonb;
  v_opp text;
  v_hand jsonb;
begin
  power := private.card_power(p_discarded);

  if power = 3 then
    v_opp := private.opponent_user_id(p_code, p_user_id);
    select * into m from public.matches where game_code = p_code;
    select e.draw, e.discard into v_draw, v_discard
    from private.ensure_draw(m.draw_deck, m.discard_deck) e;
    v_card := private.last_card(v_draw);
    v_draw := private.drop_last(v_draw);
    if v_opp is not null and v_card is not null then
      select player_hand into v_hand
      from public.match_players
      where game_code = p_code and user_id = v_opp;
      v_hand := jsonb_build_array(v_card) || coalesce(v_hand, '[]'::jsonb);
      update public.match_players
      set player_hand = v_hand
      where game_code = p_code and user_id = v_opp;
    end if;
    update public.matches
    set
      draw_deck = v_draw,
      discard_deck = v_discard,
      drawn_card = null,
      power_start_time = null,
      updated_at = now()
    where game_code = p_code;
    update public.match_players
    set actions_complete = true
    where game_code = p_code and user_id = p_user_id;
    if (
      select jsonb_array_length(coalesce(player_hand, '[]'::jsonb))
      from public.match_players
      where game_code = p_code and user_id = p_user_id
    ) = 0 then
      perform private.finish_match(p_code, p_user_id, 'empty_hand');
    end if;
    return;
  end if;

  if power in (1, 2) then
    update public.matches
    set
      drawn_card = null,
      power_start_time = now(),
      updated_at = now()
    where game_code = p_code;
    update public.match_players
    set actions_complete = true
    where game_code = p_code and user_id = p_user_id;
    return;
  end if;

  update public.matches
  set
    drawn_card = null,
    power_start_time = null,
    updated_at = now()
  where game_code = p_code;
  update public.match_players
  set actions_complete = true
  where game_code = p_code and user_id = p_user_id;
  if (
    select jsonb_array_length(coalesce(player_hand, '[]'::jsonb))
    from public.match_players
    where game_code = p_code and user_id = p_user_id
  ) = 0 then
    perform private.finish_match(p_code, p_user_id, 'empty_hand');
  end if;
end;
$$;

create or replace function private.advance_turn(p_code text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  m public.matches;
  v_current int;
  v_next int;
begin
  select * into m from public.matches where game_code = p_code;
  if m.status = 'finished' then
    return;
  end if;
  v_current := coalesce(m.turn, 0);
  v_next := case when v_current = 1 then 0 else 1 end;

  update public.match_players
  set actions_complete = false
  where game_code = p_code and seat = v_current;

  update public.match_players
  set actions_complete = false, elimination_locked = false
  where game_code = p_code and seat = v_next;

  update public.matches
  set
    turn = v_next,
    turn_start_time = now(),
    drawn_card = null,
    power_start_time = null,
    updated_at = now()
  where game_code = p_code;
end;
$$;

-- ---------------------------------------------------------------------------
-- Public Match-play interface
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
      is_challenge_declared = false
    where game_code = p_code and user_id = r.user_id;
  end loop;

  update public.matches
  set
    status = 'active',
    draw_deck = deck,
    discard_deck = '[]'::jsonb,
    turn = 0,
    drawn_card = null,
    is_challenge_complete = false,
    power_start_time = null,
    winner_user_id = null,
    end_reason = null,
    ended_at = null,
    turn_start_time = now(),
    updated_at = now()
  where game_code = p_code;

  return private.match_bundle(p_code);
end;
$$;

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
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
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
    perform private.apply_penalty(p_code, uid, true);
    if (
      select penalty_count from public.match_players
      where game_code = p_code and user_id = uid
    ) >= 3 then
      v_opp := private.opponent_user_id(p_code, uid);
      if v_opp is not null then
        perform private.finish_match(p_code, v_opp, 'penalties');
      end if;
    end if;
    notice := 'Wrong rank - elimination locked until your next turn';
    return private.match_bundle(p_code) || jsonb_build_object('notice', notice);
  end if;

  v_hand := v_hand - p_hand_index;
  update public.match_players
  set player_hand = v_hand
  where game_code = p_code and user_id = uid;

  if jsonb_array_length(v_hand) = 0 then
    perform private.finish_match(p_code, uid, 'empty_hand');
  end if;

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
  set is_challenge_complete = false, updated_at = now()
  where game_code = p_code;

  return public.end_turn(p_code);
end;
$$;

create or replace function public.forfeit(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_opp text;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.match_players
    where game_code = p_code and user_id = uid
  ) then
    raise exception 'not seated' using errcode = 'P0001';
  end if;
  v_opp := private.opponent_user_id(p_code, uid);
  if v_opp is null then
    raise exception 'no opponent' using errcode = 'P0001';
  end if;
  perform private.finish_match(p_code, v_opp, 'forfeit');
  return private.match_bundle(p_code);
end;
$$;

create or replace function public.win_by_disconnect(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_opp text;
  v_seen timestamptz;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.match_players
    where game_code = p_code and user_id = uid
  ) then
    raise exception 'not seated' using errcode = 'P0001';
  end if;
  v_opp := private.opponent_user_id(p_code, uid);
  if v_opp is null then
    raise exception 'no opponent' using errcode = 'P0001';
  end if;
  select last_seen into v_seen
  from public.match_players
  where game_code = p_code and user_id = v_opp;
  if v_seen is null or extract(epoch from (now() - v_seen)) < 60 then
    raise exception 'opponent has not timed out' using errcode = 'P0001';
  end if;
  perform private.finish_match(p_code, uid, 'disconnect');
  return private.match_bundle(p_code);
end;
$$;

revoke all on function public.start_match(text) from public;
revoke all on function public.claim_draw(text) from public;
revoke all on function public.discard_drawn(text) from public;
revoke all on function public.replace_hand(text, int) from public;
revoke all on function public.eliminate_card(text, int) from public;
revoke all on function public.swap_hands(text, int, int, int, int) from public;
revoke all on function public.clear_pending_power(text) from public;
revoke all on function public.end_turn(text) from public;
revoke all on function public.declare_challenge(text) from public;
revoke all on function public.forfeit(text) from public;
revoke all on function public.win_by_disconnect(text) from public;

grant execute on function public.start_match(text) to anon, authenticated;
grant execute on function public.claim_draw(text) to anon, authenticated;
grant execute on function public.discard_drawn(text) to anon, authenticated;
grant execute on function public.replace_hand(text, int) to anon, authenticated;
grant execute on function public.eliminate_card(text, int) to anon, authenticated;
grant execute on function public.swap_hands(text, int, int, int, int) to anon, authenticated;
grant execute on function public.clear_pending_power(text) to anon, authenticated;
grant execute on function public.end_turn(text) to anon, authenticated;
grant execute on function public.declare_challenge(text) to anon, authenticated;
grant execute on function public.forfeit(text) to anon, authenticated;
grant execute on function public.win_by_disconnect(text) to anon, authenticated;
