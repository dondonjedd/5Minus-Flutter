-- Extract Match Player seats from matches.players jsonb.

create table if not exists public.match_players (
  game_code text not null references public.matches(game_code) on delete cascade,
  user_id text not null references public.users(id),
  seat int not null,
  is_ready boolean not null default false,
  last_seen timestamptz,
  player_hand jsonb not null default '[]'::jsonb,
  is_challenge_declared boolean not null default false,
  penalty_count int not null default 0,
  elimination_locked boolean not null default false,
  actions_complete boolean not null default false,
  primary key (game_code, user_id),
  unique (game_code, seat)
);

insert into public.match_players (
  game_code,
  user_id,
  seat,
  is_ready,
  last_seen,
  player_hand,
  is_challenge_declared,
  penalty_count,
  elimination_locked,
  actions_complete
)
select
  m.game_code,
  p.elem->>'player_id',
  (p.ord - 1)::int,
  coalesce((p.elem->>'isReady')::boolean, false),
  case
    when (p.elem->>'last_seen') ~ '^\d{4}-' then (p.elem->>'last_seen')::timestamptz
    else null
  end,
  coalesce(p.elem->'player_hand', '[]'::jsonb),
  coalesce((p.elem->>'is_challenge_declared')::boolean, false),
  coalesce((p.elem->>'penalty_count')::int, 0),
  coalesce((p.elem->>'elimination_locked')::boolean, false),
  coalesce((p.elem->>'actions_complete')::boolean, false)
from public.matches m
cross join lateral jsonb_array_elements(coalesce(m.players, '[]'::jsonb)) with ordinality as p(elem, ord)
where exists (
  select 1 from public.users u where u.id = p.elem->>'player_id'
)
on conflict do nothing;

alter table public.matches drop column if exists players;

alter table public.match_players replica identity full;
alter table public.match_players enable row level security;

drop policy if exists "Allow all on match_players" on public.match_players;
create policy "Allow all on match_players" on public.match_players
  for all using (true) with check (true);

grant all on table public.match_players to anon, authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'match_players'
  ) then
    alter publication supabase_realtime add table public.match_players;
  end if;
end $$;
