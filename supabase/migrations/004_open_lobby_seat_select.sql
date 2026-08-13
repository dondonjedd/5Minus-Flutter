-- Open lobbies: a User who is not yet seated must see existing Seats
-- so join can pick the next free seat (unique on game_code, seat).

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
      and m.has_started = false
  );
$$;

revoke all on function private.is_open_lobby(text) from public;
grant execute on function private.is_open_lobby(text) to anon, authenticated;

drop policy if exists "seats_select_member" on public.match_players;
create policy "seats_select_member" on public.match_players
  for select
  to anon, authenticated
  using (
    private.is_match_host(game_code)
    or private.is_seated(game_code)
    or private.is_open_lobby(game_code)
  );
