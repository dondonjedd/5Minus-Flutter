-- Identity seam: membership RLS keyed off the Firebase UID in the JWT `sub`.
-- `auth.uid()` is uuid-typed and cannot compare to users.id (text Firebase UIDs).
-- Helpers live in `private` so they are not PostgREST RPCs.
-- Dashboard (not applied by this file):
--   Authentication → Third-party → add Firebase, project ID minus-9c259
--   https://supabase.com/dashboard/project/gfbyydeemhxvrhthsvll/auth/third-party
--   Realtime postgres_changes uses these table policies once the Firebase JWT is sent.
-- Policies target both anon and authenticated: Firebase JWTs omit role unless
-- a custom claim is set, so PostgREST may run them as the anon role.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to postgres, anon, authenticated, service_role;

create or replace function private.current_uid()
returns text
language sql
stable
set search_path = public
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
  );
$$;

create or replace function private.is_match_host(p_code text)
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
      and m.host_id = private.current_uid()
  );
$$;

create or replace function private.is_seated(p_code text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.match_players s
    where s.game_code = p_code
      and s.user_id = private.current_uid()
  );
$$;

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

revoke all on function private.current_uid() from public;
revoke all on function private.is_match_host(text) from public;
revoke all on function private.is_seated(text) from public;
revoke all on function private.is_open_lobby(text) from public;
grant execute on function private.current_uid() to anon, authenticated;
grant execute on function private.is_match_host(text) to anon, authenticated;
grant execute on function private.is_seated(text) to anon, authenticated;
grant execute on function private.is_open_lobby(text) to anon, authenticated;

-- users: any signed-in User may read profiles; writes are own-row.
drop policy if exists "Allow all on users" on public.users;
drop policy if exists "users_select_signed_in" on public.users;
drop policy if exists "users_insert_own" on public.users;
drop policy if exists "users_update_own" on public.users;
drop policy if exists "users_delete_own" on public.users;

create policy "users_select_signed_in" on public.users
  for select
  to anon, authenticated
  using (private.current_uid() is not null);

create policy "users_insert_own" on public.users
  for insert
  to anon, authenticated
  with check (id = private.current_uid());

create policy "users_update_own" on public.users
  for update
  to anon, authenticated
  using (id = private.current_uid())
  with check (id = private.current_uid());

create policy "users_delete_own" on public.users
  for delete
  to anon, authenticated
  using (id = private.current_uid());

-- matches: open lobbies readable by code; started rows are host/seated only.
drop policy if exists "Allow all on matches" on public.matches;
drop policy if exists "matches_select_lobby_or_member" on public.matches;
drop policy if exists "matches_insert_as_host" on public.matches;
drop policy if exists "matches_update_member" on public.matches;
drop policy if exists "matches_delete_host" on public.matches;

create policy "matches_select_lobby_or_member" on public.matches
  for select
  to anon, authenticated
  using (
    host_id = private.current_uid()
    or private.is_seated(game_code)
    or has_started = false
  );

create policy "matches_insert_as_host" on public.matches
  for insert
  to anon, authenticated
  with check (host_id = private.current_uid());

create policy "matches_update_member" on public.matches
  for update
  to anon, authenticated
  using (host_id = private.current_uid() or private.is_seated(game_code))
  with check (host_id = private.current_uid() or private.is_seated(game_code));

create policy "matches_delete_host" on public.matches
  for delete
  to anon, authenticated
  using (host_id = private.current_uid());

-- match_players: host or seated may read/update any Seat; insert own Seat.
drop policy if exists "Allow all on match_players" on public.match_players;
drop policy if exists "seats_select_member" on public.match_players;
drop policy if exists "seats_insert_own" on public.match_players;
drop policy if exists "seats_update_member" on public.match_players;
drop policy if exists "seats_delete_own_or_host" on public.match_players;

create policy "seats_select_member" on public.match_players
  for select
  to anon, authenticated
  using (
    private.is_match_host(game_code)
    or private.is_seated(game_code)
    or private.is_open_lobby(game_code)
  );

create policy "seats_insert_own" on public.match_players
  for insert
  to anon, authenticated
  with check (user_id = private.current_uid());

create policy "seats_update_member" on public.match_players
  for update
  to anon, authenticated
  using (private.is_match_host(game_code) or private.is_seated(game_code))
  with check (private.is_match_host(game_code) or private.is_seated(game_code));

create policy "seats_delete_own_or_host" on public.match_players
  for delete
  to anon, authenticated
  using (user_id = private.current_uid() or private.is_match_host(game_code));
