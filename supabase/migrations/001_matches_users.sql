-- 5Minus: users + matches (document-shaped jsonb for game state)
-- Run in the new 5Minus Supabase project's SQL editor.

create table if not exists public.users (
  id text primary key,
  player_id text,
  username text not null,
  wins int default 0,
  loss int default 0,
  points int default 0,
  icon text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.matches (
  game_code text primary key,
  host_id text not null references public.users(id),
  players jsonb not null default '[]'::jsonb,
  game_type int not null default 0,
  is_active boolean not null default false,
  has_started boolean not null default false,
  draw_deck jsonb,
  discard_deck jsonb,
  turn int,
  drawn_card jsonb,
  turn_start_time timestamptz,
  power_start_time timestamptz,
  is_challenge_complete boolean default false,
  winner jsonb,
  updated_at timestamptz default now()
);

alter table public.matches replica identity full;

alter table public.users enable row level security;
alter table public.matches enable row level security;

drop policy if exists "Allow all on users" on public.users;
create policy "Allow all on users" on public.users
  for all using (true) with check (true);

drop policy if exists "Allow all on matches" on public.matches;
create policy "Allow all on matches" on public.matches
  for all using (true) with check (true);

grant all on table public.users to anon, authenticated;
grant all on table public.matches to anon, authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'matches'
  ) then
    alter publication supabase_realtime add table public.matches;
  end if;
end $$;
