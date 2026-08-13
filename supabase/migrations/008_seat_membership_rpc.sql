-- Seat membership: named public moves. Table INSERT/DELETE revoked.
-- last_seen stays a Seat column write. Match play is unchanged.

-- ---------------------------------------------------------------------------
-- Drop membership triggers now owned by the moves
-- ---------------------------------------------------------------------------

drop trigger if exists freeze_ready_after_lobby on public.match_players;
drop function if exists private.freeze_ready_after_lobby();

drop trigger if exists cancel_lobby_on_host_seat_delete on public.match_players;
drop function if exists private.cancel_lobby_if_host_left();

drop trigger if exists touch_match_on_seat_change on public.match_players;
drop function if exists private.touch_match_from_seat();

-- ---------------------------------------------------------------------------
-- Column grants: membership writes are function-only
-- ---------------------------------------------------------------------------

revoke all on table public.matches from anon, authenticated;
grant select on table public.matches to anon, authenticated;
grant update (game_type) on table public.matches to anon, authenticated;

revoke all on table public.match_players from anon, authenticated;
grant select on table public.match_players to anon, authenticated;
grant update (last_seen) on table public.match_players to anon, authenticated;

drop policy if exists "seats_insert_own" on public.match_players;
drop policy if exists "seats_delete_own_or_host" on public.match_players;
drop policy if exists "seats_delete_lobby_own_or_host" on public.match_players;
drop policy if exists "matches_insert_as_host" on public.matches;
drop policy if exists "matches_delete_host" on public.matches;
drop policy if exists "matches_delete_host_lobby" on public.matches;

-- ---------------------------------------------------------------------------
-- Code helper
-- ---------------------------------------------------------------------------

create or replace function private.random_game_code()
returns text
language sql
volatile
as $$
  select string_agg(
    substr('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', (floor(random() * 36) + 1)::int, 1),
    ''
  )
  from generate_series(1, 4);
$$;

revoke all on function private.random_game_code() from public;

-- ---------------------------------------------------------------------------
-- Public Seat-membership interface
-- ---------------------------------------------------------------------------

create or replace function public.create_lobby()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  v_code text;
  attempt int;
begin
  for attempt in 1..32 loop
    v_code := private.random_game_code();
    begin
      insert into public.matches (game_code, host_id, status)
      values (v_code, uid, 'lobby');
      insert into public.match_players (game_code, user_id, seat, is_ready)
      values (v_code, uid, 0, true);
      return private.match_bundle(v_code);
    exception
      when unique_violation then
        null;
    end;
  end loop;
  raise exception 'could not allocate game code' using errcode = 'P0001';
end;
$$;

create or replace function public.join_lobby(p_code text)
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
  if m.status is distinct from 'lobby' then
    raise exception 'match is not in lobby' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.match_players
    where game_code = p_code and user_id = uid
  ) then
    return private.match_bundle(p_code);
  end if;

  select s into v_seat
  from generate_series(0, 1) s
  where not exists (
    select 1 from public.match_players
    where game_code = p_code and seat = s
  )
  order by s
  limit 1;
  if v_seat is null then
    raise exception 'match is full' using errcode = 'P0001';
  end if;

  insert into public.match_players (game_code, user_id, seat, is_ready)
  values (p_code, uid, v_seat, false);

  return private.match_bundle(p_code);
end;
$$;

create or replace function public.set_ready(p_code text, p_ready boolean)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'lobby' then
    raise exception 'ready only in lobby' using errcode = 'P0001';
  end if;

  update public.match_players
  set is_ready = p_ready
  where game_code = p_code and user_id = uid;
  if not found then
    raise exception 'not seated' using errcode = 'P0001';
  end if;

  return private.match_bundle(p_code);
end;
$$;

create or replace function public.leave_lobby(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'lobby' then
    raise exception 'match is not in lobby' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.match_players
    where game_code = p_code and user_id = uid
  ) then
    raise exception 'not seated' using errcode = 'P0001';
  end if;

  if m.host_id = uid then
    delete from public.matches
    where game_code = p_code and host_id = uid and status = 'lobby';
    return null;
  end if;

  delete from public.match_players
  where game_code = p_code and user_id = uid;
  return private.match_bundle(p_code);
end;
$$;

create or replace function public.kick_seat(p_code text, p_user_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
begin
  m := private.lock_match(p_code);
  if m.host_id is distinct from uid then
    raise exception 'not the host' using errcode = 'P0001';
  end if;
  if m.status is distinct from 'lobby' then
    raise exception 'match is not in lobby' using errcode = 'P0001';
  end if;
  if p_user_id is not distinct from m.host_id then
    raise exception 'cannot kick host' using errcode = 'P0001';
  end if;

  delete from public.match_players
  where game_code = p_code and user_id = p_user_id;
  if not found then
    raise exception 'not seated' using errcode = 'P0001';
  end if;

  return private.match_bundle(p_code);
end;
$$;

create or replace function public.cancel_lobby(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
begin
  m := private.lock_match(p_code);
  if m.host_id is distinct from uid then
    raise exception 'not the host' using errcode = 'P0001';
  end if;
  if m.status is distinct from 'lobby' then
    raise exception 'match is not in lobby' using errcode = 'P0001';
  end if;

  delete from public.matches
  where game_code = p_code and host_id = uid and status = 'lobby';
  return null;
end;
$$;

revoke all on function public.create_lobby() from public;
revoke all on function public.join_lobby(text) from public;
revoke all on function public.set_ready(text, boolean) from public;
revoke all on function public.leave_lobby(text) from public;
revoke all on function public.kick_seat(text, text) from public;
revoke all on function public.cancel_lobby(text) from public;

grant execute on function public.create_lobby() to anon, authenticated;
grant execute on function public.join_lobby(text) to anon, authenticated;
grant execute on function public.set_ready(text, boolean) to anon, authenticated;
grant execute on function public.leave_lobby(text) to anon, authenticated;
grant execute on function public.kick_seat(text, text) to anon, authenticated;
grant execute on function public.cancel_lobby(text) to anon, authenticated;
