-- Seat membership RLS tests. Setup as postgres; assertions run as anon with JWT sub.
-- Identity is private.current_uid() via request.jwt.claims.

create or replace function private._test_set_uid(p_uid text)
returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', p_uid)::text, true);
  perform set_config('request.jwt.claim.sub', p_uid, true);
end;
$$;

do $$
declare
  n int;
  err text;
begin
  delete from public.matches where game_code in ('MEMA', 'MEMB', 'MEMC', 'MEMD', 'MEME');
  delete from public.users where id in ('mem-a', 'mem-b', 'mem-c');

  insert into public.users (id, username) values
    ('mem-a', 'A'),
    ('mem-b', 'B'),
    ('mem-c', 'C');

  -- Guest deletes own Seat in lobby
  insert into public.matches (game_code, host_id, status)
  values ('MEMA', 'mem-a', 'lobby');
  insert into public.match_players (game_code, user_id, seat, is_ready)
  values
    ('MEMA', 'mem-a', 0, true),
    ('MEMA', 'mem-b', 1, false);

  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  delete from public.match_players
  where game_code = 'MEMA' and user_id = 'mem-b';
  get diagnostics n = row_count;
  execute 'reset role';
  if n is distinct from 1 then
    raise exception 'guest lobby leave deleted % rows', n;
  end if;
  if exists (
    select 1 from public.match_players
    where game_code = 'MEMA' and user_id = 'mem-b'
  ) then
    raise exception 'guest seat still present after leave';
  end if;
  if not exists (select 1 from public.matches where game_code = 'MEMA') then
    raise exception 'guest leave cancelled the Match';
  end if;

  -- Host kicks guest in lobby
  insert into public.matches (game_code, host_id, status)
  values ('MEMB', 'mem-a', 'lobby');
  insert into public.match_players (game_code, user_id, seat, is_ready)
  values
    ('MEMB', 'mem-a', 0, true),
    ('MEMB', 'mem-b', 1, false);

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  delete from public.match_players
  where game_code = 'MEMB' and user_id = 'mem-b';
  get diagnostics n = row_count;
  execute 'reset role';
  if n is distinct from 1 then
    raise exception 'host kick deleted % rows', n;
  end if;
  if exists (
    select 1 from public.match_players
    where game_code = 'MEMB' and user_id = 'mem-b'
  ) then
    raise exception 'kicked seat still present';
  end if;
  if not exists (select 1 from public.matches where game_code = 'MEMB') then
    raise exception 'host kick cancelled the Match';
  end if;

  -- Host deletes own Seat in lobby — Match row gone
  insert into public.matches (game_code, host_id, status)
  values ('MEMC', 'mem-a', 'lobby');
  insert into public.match_players (game_code, user_id, seat, is_ready)
  values
    ('MEMC', 'mem-a', 0, true),
    ('MEMC', 'mem-b', 1, true);

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  delete from public.match_players
  where game_code = 'MEMC' and user_id = 'mem-a';
  get diagnostics n = row_count;
  execute 'reset role';
  if n is distinct from 1 then
    raise exception 'host seat leave deleted % rows', n;
  end if;
  if exists (select 1 from public.matches where game_code = 'MEMC') then
    raise exception 'host seat leave left the Match';
  end if;
  if exists (select 1 from public.match_players where game_code = 'MEMC') then
    raise exception 'host seat leave left Seats';
  end if;

  -- Host DELETE Match in lobby
  insert into public.matches (game_code, host_id, status)
  values ('MEMD', 'mem-a', 'lobby');
  insert into public.match_players (game_code, user_id, seat, is_ready)
  values ('MEMD', 'mem-a', 0, true);

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  delete from public.matches where game_code = 'MEMD';
  get diagnostics n = row_count;
  execute 'reset role';
  if n is distinct from 1 then
    raise exception 'host match delete deleted % rows', n;
  end if;
  if exists (select 1 from public.matches where game_code = 'MEMD') then
    raise exception 'host match delete left the Match';
  end if;

  -- Active: no Seat/Match DELETE; is_ready rejected; last_seen ok
  insert into public.matches (game_code, host_id, status)
  values ('MEME', 'mem-a', 'lobby');
  insert into public.match_players (game_code, user_id, seat, is_ready)
  values
    ('MEME', 'mem-a', 0, true),
    ('MEME', 'mem-b', 1, true);

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  update public.match_players
  set is_ready = false
  where game_code = 'MEME' and user_id = 'mem-a';
  get diagnostics n = row_count;
  execute 'reset role';
  if n is distinct from 1 then
    raise exception 'lobby ready update deleted % rows', n;
  end if;

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  update public.match_players
  set is_ready = true
  where game_code = 'MEME' and user_id = 'mem-a';
  perform public.start_match('MEME');
  execute 'reset role';

  if (select status from public.matches where game_code = 'MEME') is distinct from 'active' then
    raise exception 'MEME not active';
  end if;

  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  delete from public.match_players
  where game_code = 'MEME' and user_id = 'mem-b';
  get diagnostics n = row_count;
  execute 'reset role';
  if n is distinct from 0 then
    raise exception 'active seat delete affected % rows', n;
  end if;
  if not exists (
    select 1 from public.match_players
    where game_code = 'MEME' and user_id = 'mem-b'
  ) then
    raise exception 'active guest seat was deleted';
  end if;

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  delete from public.matches where game_code = 'MEME';
  get diagnostics n = row_count;
  execute 'reset role';
  if n is distinct from 0 then
    raise exception 'active match delete affected % rows', n;
  end if;
  if not exists (select 1 from public.matches where game_code = 'MEME') then
    raise exception 'active Match was deleted';
  end if;

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  begin
    update public.match_players
    set is_ready = false
    where game_code = 'MEME' and user_id = 'mem-a';
    raise exception 'expected ready only in lobby';
  exception
    when others then
      if sqlerrm not like '%ready only in lobby%' then
        raise;
      end if;
  end;
  execute 'reset role';

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  update public.match_players
  set last_seen = now()
  where game_code = 'MEME' and user_id = 'mem-a';
  get diagnostics n = row_count;
  execute 'reset role';
  if n is distinct from 1 then
    raise exception 'active last_seen update affected % rows', n;
  end if;

  delete from public.matches where game_code in ('MEMA', 'MEMB', 'MEMC', 'MEMD', 'MEME');
  delete from public.users where id in ('mem-a', 'mem-b', 'mem-c');

  raise notice 'seat membership tests passed';
end;
$$;

drop function if exists private._test_set_uid(text);
