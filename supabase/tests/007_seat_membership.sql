-- Seat membership interface tests. Setup as postgres; assertions run as anon with JWT sub.
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
  bundle jsonb;
  code text;
  code_b text;
  n int;
  seat_n int;
begin
  delete from public.matches where host_id in ('mem-a', 'mem-b', 'mem-c');
  delete from public.users where id in ('mem-a', 'mem-b', 'mem-c');

  insert into public.users (id, username) values
    ('mem-a', 'A'),
    ('mem-b', 'B'),
    ('mem-c', 'C');

  -- create_lobby: Match + host Seat 0 ready
  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  bundle := public.create_lobby();
  execute 'reset role';
  code := bundle->'match'->>'game_code';
  if code is null or length(code) is distinct from 4 then
    raise exception 'create_lobby code %', code;
  end if;
  if bundle->'match'->>'host_id' is distinct from 'mem-a' then
    raise exception 'create_lobby host %', bundle->'match'->>'host_id';
  end if;
  if bundle->'match'->>'status' is distinct from 'lobby' then
    raise exception 'create_lobby status %', bundle->'match'->>'status';
  end if;
  if jsonb_array_length(bundle->'seats') is distinct from 1 then
    raise exception 'create_lobby seats %', bundle->'seats';
  end if;
  if bundle->'seats'->0->>'user_id' is distinct from 'mem-a' then
    raise exception 'create_lobby seat user %', bundle->'seats'->0->>'user_id';
  end if;
  if (bundle->'seats'->0->>'seat')::int is distinct from 0 then
    raise exception 'create_lobby seat number %', bundle->'seats'->0->>'seat';
  end if;
  if (bundle->'seats'->0->>'is_ready')::boolean is distinct from true then
    raise exception 'create_lobby host not ready';
  end if;

  -- join_lobby assigns lowest free seat (1)
  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  bundle := public.join_lobby(code);
  execute 'reset role';
  if jsonb_array_length(bundle->'seats') is distinct from 2 then
    raise exception 'join_lobby seats %', bundle->'seats';
  end if;
  select (s->>'seat')::int into seat_n
  from jsonb_array_elements(bundle->'seats') s
  where s->>'user_id' = 'mem-b';
  if seat_n is distinct from 1 then
    raise exception 'join_lobby assigned seat %', seat_n;
  end if;

  -- idempotent re-join
  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  bundle := public.join_lobby(code);
  execute 'reset role';
  if jsonb_array_length(bundle->'seats') is distinct from 2 then
    raise exception 're-join seats %', bundle->'seats';
  end if;

  -- third join fails (full)
  perform private._test_set_uid('mem-c');
  execute 'set local role anon';
  begin
    perform public.join_lobby(code);
    raise exception 'TESTFAIL: third join succeeded';
  exception
    when others then
      if sqlerrm like 'TESTFAIL:%' or sqlerrm not like '%match is full%' then
        raise;
      end if;
  end;
  execute 'reset role';

  -- set_ready lobby ok
  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  bundle := public.set_ready(code, true);
  execute 'reset role';
  if not exists (
    select 1 from jsonb_array_elements(bundle->'seats') s
    where s->>'user_id' = 'mem-b' and (s->>'is_ready')::boolean
  ) then
    raise exception 'set_ready did not ready mem-b';
  end if;

  -- guest leave_lobby keeps Match
  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  bundle := public.leave_lobby(code);
  execute 'reset role';
  if bundle is null then
    raise exception 'guest leave cancelled the Match';
  end if;
  if jsonb_array_length(bundle->'seats') is distinct from 1 then
    raise exception 'guest leave seats %', bundle->'seats';
  end if;
  if not exists (select 1 from public.matches where game_code = code) then
    raise exception 'guest leave deleted the Match';
  end if;

  -- re-join after leave gets lowest free seat (1)
  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  bundle := public.join_lobby(code);
  execute 'reset role';
  select (s->>'seat')::int into seat_n
  from jsonb_array_elements(bundle->'seats') s
  where s->>'user_id' = 'mem-b';
  if seat_n is distinct from 1 then
    raise exception 're-join seat %', seat_n;
  end if;

  -- kick_seat guest ok
  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  bundle := public.kick_seat(code, 'mem-b');
  execute 'reset role';
  if jsonb_array_length(bundle->'seats') is distinct from 1 then
    raise exception 'kick seats %', bundle->'seats';
  end if;
  if exists (
    select 1 from public.match_players where game_code = code and user_id = 'mem-b'
  ) then
    raise exception 'kicked seat still present';
  end if;

  -- kick host rejected
  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  begin
    perform public.kick_seat(code, 'mem-a');
    raise exception 'TESTFAIL: kicked host';
  exception
    when others then
      if sqlerrm like 'TESTFAIL:%' or sqlerrm not like '%cannot kick host%' then
        raise;
      end if;
  end;
  execute 'reset role';

  -- guest cannot kick
  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  bundle := public.join_lobby(code);
  begin
    perform public.kick_seat(code, 'mem-a');
    raise exception 'TESTFAIL: guest kicked host';
  exception
    when others then
      if sqlerrm like 'TESTFAIL:%' or sqlerrm not like '%not the host%' then
        raise;
      end if;
  end;
  execute 'reset role';

  -- host leave_lobby cancels Match
  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  bundle := public.leave_lobby(code);
  execute 'reset role';
  if bundle is not null then
    raise exception 'host leave returned %', bundle;
  end if;
  if exists (select 1 from public.matches where game_code = code) then
    raise exception 'host leave left the Match';
  end if;
  if exists (select 1 from public.match_players where game_code = code) then
    raise exception 'host leave left Seats';
  end if;

  -- cancel_lobby host lobby ok
  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  bundle := public.create_lobby();
  code := bundle->'match'->>'game_code';
  bundle := public.cancel_lobby(code);
  execute 'reset role';
  if bundle is not null then
    raise exception 'cancel_lobby returned %', bundle;
  end if;
  if exists (select 1 from public.matches where game_code = code) then
    raise exception 'cancel_lobby left the Match';
  end if;

  -- join missing match
  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  begin
    perform public.join_lobby('ZZZZ');
    raise exception 'TESTFAIL: joined missing match';
  exception
    when others then
      if sqlerrm like 'TESTFAIL:%' or sqlerrm not like '%match not found%' then
        raise;
      end if;
  end;
  execute 'reset role';

  -- direct INSERT/DELETE denied
  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  begin
    insert into public.matches (game_code, host_id, status)
    values ('DENY', 'mem-a', 'lobby');
    raise exception 'expected matches insert denied';
  exception
    when insufficient_privilege then
      null;
    when others then
      if sqlerrm not like '%permission denied%' then
        raise;
      end if;
  end;
  begin
    insert into public.match_players (game_code, user_id, seat)
    values ('DENY', 'mem-a', 0);
    raise exception 'expected seats insert denied';
  exception
    when insufficient_privilege then
      null;
    when others then
      if sqlerrm not like '%permission denied%' then
        raise;
      end if;
  end;
  execute 'reset role';

  -- Match play still works; set_ready active rejected; last_seen ok; cancel active rejected
  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  bundle := public.create_lobby();
  code_b := bundle->'match'->>'game_code';
  execute 'reset role';

  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  perform public.join_lobby(code_b);
  perform public.set_ready(code_b, true);
  execute 'reset role';

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  bundle := public.start_match(code_b);
  execute 'reset role';
  if bundle->'match'->>'status' is distinct from 'active' then
    raise exception 'start_match status %', bundle->'match'->>'status';
  end if;

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  begin
    perform public.set_ready(code_b, false);
    raise exception 'TESTFAIL: set_ready while active';
  exception
    when others then
      if sqlerrm like 'TESTFAIL:%' or sqlerrm not like '%ready only in lobby%' then
        raise;
      end if;
  end;
  execute 'reset role';

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  begin
    perform public.cancel_lobby(code_b);
    raise exception 'TESTFAIL: cancel while active';
  exception
    when others then
      if sqlerrm like 'TESTFAIL:%' or sqlerrm not like '%not in lobby%' then
        raise;
      end if;
  end;
  execute 'reset role';

  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  begin
    perform public.leave_lobby(code_b);
    raise exception 'TESTFAIL: leave while active';
  exception
    when others then
      if sqlerrm like 'TESTFAIL:%' or sqlerrm not like '%not in lobby%' then
        raise;
      end if;
  end;
  execute 'reset role';

  perform private._test_set_uid('mem-a');
  execute 'set local role anon';
  update public.match_players
  set last_seen = now()
  where game_code = code_b and user_id = 'mem-a';
  get diagnostics n = row_count;
  execute 'reset role';
  if n is distinct from 1 then
    raise exception 'active last_seen update affected % rows', n;
  end if;

  -- direct DELETE denied on active (and generally)
  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  begin
    delete from public.match_players
    where game_code = code_b and user_id = 'mem-b';
    raise exception 'expected seats delete denied';
  exception
    when insufficient_privilege then
      null;
    when others then
      if sqlerrm not like '%permission denied%' then
        raise;
      end if;
  end;
  begin
    delete from public.matches where game_code = code_b;
    raise exception 'expected matches delete denied';
  exception
    when insufficient_privilege then
      null;
    when others then
      if sqlerrm not like '%permission denied%' then
        raise;
      end if;
  end;
  execute 'reset role';

  perform private._test_set_uid('mem-b');
  execute 'set local role anon';
  bundle := public.forfeit(code_b);
  execute 'reset role';
  if bundle->'match'->>'status' is distinct from 'finished' then
    raise exception 'forfeit status %', bundle->'match'->>'status';
  end if;
  if bundle->'match'->>'winner_user_id' is distinct from 'mem-a' then
    raise exception 'forfeit winner %', bundle->'match'->>'winner_user_id';
  end if;

  delete from public.matches where host_id in ('mem-a', 'mem-b', 'mem-c');
  delete from public.users where id in ('mem-a', 'mem-b', 'mem-c');

  raise notice 'seat membership tests passed';
end;
$$;

drop function if exists private._test_set_uid(text);
