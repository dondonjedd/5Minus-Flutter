-- Match result: drop dead columns, draw is a null winner, enforce the shape.

-- ---------------------------------------------------------------------------
-- Replace Match play helpers that still write dropped columns / the sentinel
-- ---------------------------------------------------------------------------

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
    updated_at = now()
  where game_code = p_code;
end;
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
    set updated_at = now()
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
    perform private.finish_match(p_code, null, 'challenge_tie');
  else
    perform private.finish_match(p_code, v_best, 'challenge');
  end if;
  return true;
end;
$$;

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
  set updated_at = now()
  where game_code = p_code;

  return public.end_turn(p_code);
end;
$$;

-- ---------------------------------------------------------------------------
-- Schema
-- ---------------------------------------------------------------------------

update public.matches
set winner_user_id = null
where winner_user_id = '__DRAW__';

-- Finished rows from before end_reason existed all have a winner.
update public.matches
set end_reason = 'empty_hand'
where status = 'finished'
  and end_reason is null
  and winner_user_id is not null;

revoke update on table public.matches from anon, authenticated;
drop policy if exists "matches_update_host_lobby" on public.matches;

alter table public.matches drop column if exists game_type;
alter table public.matches drop column if exists is_challenge_complete;

alter table public.matches drop constraint if exists matches_winner_user_id_fkey;
alter table public.matches
  add constraint matches_winner_user_id_fkey
  foreign key (winner_user_id) references public.users(id) on delete restrict;

alter table public.matches drop constraint if exists matches_end_reason_check;
alter table public.matches
  add constraint matches_end_reason_check
  check (
    end_reason is null
    or end_reason in (
      'empty_hand',
      'challenge',
      'challenge_tie',
      'penalties',
      'forfeit',
      'disconnect'
    )
  );

alter table public.matches drop constraint if exists matches_result_check;
alter table public.matches
  add constraint matches_result_check
  check (
    (
      status in ('lobby', 'active')
      and winner_user_id is null
      and end_reason is null
      and ended_at is null
    )
    or (
      status = 'finished'
      and end_reason is not null
      and ended_at is not null
      and (
        (end_reason = 'challenge_tie' and winner_user_id is null)
        or (end_reason <> 'challenge_tie' and winner_user_id is not null)
      )
    )
  );
