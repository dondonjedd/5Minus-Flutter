-- Opening peek ready gate. Run as postgres.

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
  deadline timestamptz;
  unlocked_at timestamptz;
begin
  delete from public.matches where game_code in ('PEKA', 'PEKB');
  delete from public.users where id in ('peek-a', 'peek-b');

  insert into public.users (id, username) values
    ('peek-a', 'A'),
    ('peek-b', 'B');

  insert into public.matches (game_code, host_id, status)
  values ('PEKA', 'peek-a', 'lobby');
  insert into public.match_players (game_code, user_id, seat, is_ready)
  values
    ('PEKA', 'peek-a', 0, true),
    ('PEKA', 'peek-b', 1, true);

  perform private._test_set_uid('peek-a');
  bundle := public.start_match('PEKA');
  if bundle->'match'->>'status' is distinct from 'active' then
    raise exception 'start_match status %', bundle->'match'->>'status';
  end if;
  if bundle->'match'->>'turn_start_time' is not null then
    raise exception 'turn_start_time should be null after start: %', bundle->'match'->>'turn_start_time';
  end if;
  deadline := (bundle->'match'->>'peek_deadline')::timestamptz;
  if deadline is null or deadline <= now() or deadline > now() + interval '31 seconds' then
    raise exception 'peek_deadline %', deadline;
  end if;
  if (bundle->'seats'->0->>'peek_ready') is distinct from 'false'
     or (bundle->'seats'->1->>'peek_ready') is distinct from 'false' then
    raise exception 'peek_ready after start %', bundle->'seats';
  end if;

  begin
    perform public.claim_draw('PEKA');
    raise exception 'expected peek still open on claim_draw';
  exception
    when others then
      if sqlerrm not like '%peek still open%' then
        raise;
      end if;
  end;

  update public.matches
  set discard_deck = jsonb_build_array(private.make_card(5, 1))
  where game_code = 'PEKA';
  begin
    perform public.eliminate_card('PEKA', 0);
    raise exception 'expected peek still open on eliminate_card';
  exception
    when others then
      if sqlerrm not like '%peek still open%' then
        raise;
      end if;
  end;

  bundle := public.ready_peek('PEKA');
  if (bundle->'seats'->0->>'peek_ready') is distinct from 'true' then
    raise exception 'caller peek_ready %', bundle->'seats'->0->>'peek_ready';
  end if;
  if (bundle->'seats'->1->>'peek_ready') is distinct from 'false' then
    raise exception 'other seat should still be waiting: %', bundle->'seats'->1->>'peek_ready';
  end if;
  if bundle->'match'->>'turn_start_time' is not null then
    raise exception 'still locked after one ready: %', bundle->'match'->>'turn_start_time';
  end if;

  begin
    perform public.claim_draw('PEKA');
    raise exception 'expected peek still open after one ready';
  exception
    when others then
      if sqlerrm not like '%peek still open%' then
        raise;
      end if;
  end;

  perform private._test_set_uid('peek-b');
  bundle := public.ready_peek('PEKA');
  if (bundle->'seats'->0->>'peek_ready') is distinct from 'true'
     or (bundle->'seats'->1->>'peek_ready') is distinct from 'true' then
    raise exception 'both should be ready: %', bundle->'seats';
  end if;
  if bundle->'match'->>'turn_start_time' is null then
    raise exception 'turn_start_time should be set after both ready';
  end if;
  unlocked_at := (bundle->'match'->>'turn_start_time')::timestamptz;

  perform private._test_set_uid('peek-a');
  bundle := public.claim_draw('PEKA');
  if bundle->'match'->'drawn_card' is null
     or jsonb_typeof(bundle->'match'->'drawn_card') = 'null' then
    raise exception 'claim_draw after unlock did not set drawn_card';
  end if;

  bundle := public.ready_peek('PEKA');
  if (bundle->'match'->>'turn_start_time')::timestamptz is distinct from unlocked_at then
    raise exception 'ready_peek after unlock should be idempotent';
  end if;
  if (bundle->'seats'->0->>'peek_ready') is distinct from 'true'
     or (bundle->'seats'->1->>'peek_ready') is distinct from 'true' then
    raise exception 'idempotent ready_peek cleared peek_ready';
  end if;

  -- Deadline expire: waiting client unlocks the laggard.
  insert into public.matches (game_code, host_id, status)
  values ('PEKB', 'peek-a', 'lobby');
  insert into public.match_players (game_code, user_id, seat, is_ready)
  values
    ('PEKB', 'peek-a', 0, true),
    ('PEKB', 'peek-b', 1, true);

  perform private._test_set_uid('peek-a');
  bundle := public.start_match('PEKB');
  bundle := public.ready_peek('PEKB');
  if bundle->'match'->>'turn_start_time' is not null then
    raise exception 'PEKB should still be locked after one ready';
  end if;

  update public.matches
  set peek_deadline = now() - interval '1 second'
  where game_code = 'PEKB';

  bundle := public.ready_peek('PEKB');
  if (bundle->'seats'->0->>'peek_ready') is distinct from 'true'
     or (bundle->'seats'->1->>'peek_ready') is distinct from 'true' then
    raise exception 'deadline should ready the laggard: %', bundle->'seats';
  end if;
  if bundle->'match'->>'turn_start_time' is null then
    raise exception 'deadline ready_peek should unlock play';
  end if;

  delete from public.matches where game_code in ('PEKA', 'PEKB');
  delete from public.users where id in ('peek-a', 'peek-b');

  raise notice 'peek ready tests passed';
end;
$$;

drop function if exists private._test_set_uid(text);
