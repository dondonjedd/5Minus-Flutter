-- Seat membership: lobby-only DELETE, freeze is_ready, host leave cancels Match.
-- Match play still owns piles, hands, and turn. last_seen stays a Seat write.

-- ---------------------------------------------------------------------------
-- Seat DELETE: lobby + (own row or host kick)
-- ---------------------------------------------------------------------------

drop policy if exists "seats_delete_own_or_host" on public.match_players;
drop policy if exists "seats_delete_lobby_own_or_host" on public.match_players;
create policy "seats_delete_lobby_own_or_host" on public.match_players
  for delete
  to anon, authenticated
  using (
    private.is_open_lobby(game_code)
    and (
      user_id = private.current_uid()
      or private.is_match_host(game_code)
    )
  );

-- ---------------------------------------------------------------------------
-- Match DELETE: host + lobby only
-- ---------------------------------------------------------------------------

drop policy if exists "matches_delete_host" on public.matches;
drop policy if exists "matches_delete_host_lobby" on public.matches;
create policy "matches_delete_host_lobby" on public.matches
  for delete
  to anon, authenticated
  using (host_id = private.current_uid() and status = 'lobby');

-- ---------------------------------------------------------------------------
-- is_ready only while lobby. last_seen is unchanged.
-- ---------------------------------------------------------------------------

create or replace function private.freeze_ready_after_lobby()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_ready is distinct from old.is_ready
     and not private.is_open_lobby(new.game_code) then
    raise exception 'ready only in lobby' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists freeze_ready_after_lobby on public.match_players;
create trigger freeze_ready_after_lobby
  before update on public.match_players
  for each row
  execute function private.freeze_ready_after_lobby();

-- ---------------------------------------------------------------------------
-- Host Seat DELETE in lobby cancels the Match (cascades remaining Seats).
-- If the host already DELETE'd the Match, CASCADE removed this row first
-- and the DELETE below matches nothing.
-- ---------------------------------------------------------------------------

create or replace function private.cancel_lobby_if_host_left()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1
    from public.matches
    where game_code = old.game_code
      and host_id = old.user_id
      and status = 'lobby'
  ) then
    delete from public.matches
    where game_code = old.game_code
      and host_id = old.user_id
      and status = 'lobby';
  end if;
  return old;
end;
$$;

drop trigger if exists cancel_lobby_on_host_seat_delete on public.match_players;
create trigger cancel_lobby_on_host_seat_delete
  after delete on public.match_players
  for each row
  execute function private.cancel_lobby_if_host_left();
