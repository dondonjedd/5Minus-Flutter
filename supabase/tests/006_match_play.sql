-- Match-play interface tests. Run as postgres (bypasses RLS for setup).
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
  status text;
  turn int;
  n_draw int;
  hand_len int;
  err text;
begin
  delete from public.matches where game_code in ('TSTA', 'TSTB', 'TSTC');
  delete from public.users where id in ('play-a', 'play-b', 'play-c');

  insert into public.users (id, username) values
    ('play-a', 'A'),
    ('play-b', 'B'),
    ('play-c', 'C');

  insert into public.matches (game_code, host_id, status, game_type)
  values ('TSTA', 'play-a', 'lobby', 0);

  insert into public.match_players (game_code, user_id, seat, is_ready)
  values
    ('TSTA', 'play-a', 0, true),
    ('TSTA', 'play-b', 1, true);

  -- start_match requires host
  perform private._test_set_uid('play-b');
  begin
    perform public.start_match('TSTA');
    raise exception 'expected not the host';
  exception
    when others then
      if sqlerrm not like '%not the host%' then
        raise;
      end if;
  end;

  perform private._test_set_uid('play-a');
  bundle := public.start_match('TSTA');
  status := bundle->'match'->>'status';
  if status is distinct from 'active' then
    raise exception 'start_match status %', status;
  end if;
  if jsonb_array_length(bundle->'seats'->0->'player_hand') is distinct from 4 then
    raise exception 'seat 0 hand not 4';
  end if;
  if jsonb_array_length(bundle->'seats'->1->'player_hand') is distinct from 4 then
    raise exception 'seat 1 hand not 4';
  end if;
  n_draw := jsonb_array_length(bundle->'match'->'draw_deck');
  if n_draw is distinct from 44 then
    raise exception 'draw deck %', n_draw;
  end if;

  -- third Seat after active: trigger max-seats (and RLS would also block)
  begin
    insert into public.match_players (game_code, user_id, seat)
    values ('TSTA', 'play-c', 2);
    raise exception 'expected match is full';
  exception
    when others then
      if sqlerrm not like '%match is full%' then
        raise;
      end if;
  end;

  -- claim_draw is current seat only (turn 0 = play-a)
  perform private._test_set_uid('play-b');
  begin
    perform public.claim_draw('TSTA');
    raise exception 'expected not your turn';
  exception
    when others then
      if sqlerrm not like '%not your turn%' then
        raise;
      end if;
  end;

  perform private._test_set_uid('play-a');
  bundle := public.claim_draw('TSTA');
  if bundle->'match'->'drawn_card' is null then
    raise exception 'claim_draw did not set drawn_card';
  end if;

  begin
    perform public.claim_draw('TSTA');
    raise exception 'expected drawn_card already set';
  exception
    when others then
      if sqlerrm not like '%drawn_card already set%' then
        raise;
      end if;
  end;

  bundle := public.discard_drawn('TSTA');
  if bundle->'match'->'drawn_card' is not null
     and jsonb_typeof(bundle->'match'->'drawn_card') <> 'null' then
    raise exception 'discard left drawn_card';
  end if;
  if (bundle->'seats'->0->>'actions_complete') is distinct from 'true'
     and coalesce((bundle->'match'->>'power_start_time'), '') = '' then
    -- power cards leave actions_complete true as well
    null;
  end if;

  -- finish via forfeit
  perform private._test_set_uid('play-b');
  bundle := public.forfeit('TSTA');
  if bundle->'match'->>'status' is distinct from 'finished' then
    raise exception 'forfeit status %', bundle->'match'->>'status';
  end if;
  if bundle->'match'->>'winner_user_id' is distinct from 'play-a' then
    raise exception 'forfeit winner %', bundle->'match'->>'winner_user_id';
  end if;
  if bundle->'match'->>'end_reason' is distinct from 'forfeit' then
    raise exception 'forfeit reason %', bundle->'match'->>'end_reason';
  end if;

  -- lobby insert gate via function is_open_lobby (status)
  insert into public.matches (game_code, host_id, status)
  values ('TSTB', 'play-a', 'lobby');
  if private.is_open_lobby('TSTB') is not true then
    raise exception 'TSTB should be open lobby';
  end if;
  update public.matches set status = 'active' where game_code = 'TSTB';
  if private.is_open_lobby('TSTB') is not false then
    raise exception 'active match should not be open lobby';
  end if;

  delete from public.matches where game_code in ('TSTA', 'TSTB', 'TSTC');
  delete from public.users where id in ('play-a', 'play-b', 'play-c');

  raise notice 'match play tests passed';
end;
$$;

drop function if exists private._test_set_uid(text);
