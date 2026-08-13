-- Match result shape. Run as postgres (bypasses RLS for setup).

do $$
declare
  n int;
begin
  delete from public.matches where game_code in ('SHRA', 'SHRB', 'SHRC', 'SHRD', 'SHRE', 'SHRF');
  delete from public.users where id in ('shr-a', 'shr-b');

  insert into public.users (id, username) values
    ('shr-a', 'A'),
    ('shr-b', 'B');

  insert into public.matches (game_code, host_id, status)
  values ('SHRA', 'shr-a', 'lobby');
  insert into public.match_players (game_code, user_id, seat, is_ready)
  values
    ('SHRA', 'shr-a', 0, true),
    ('SHRA', 'shr-b', 1, true);

  perform private.finish_match('SHRA', null, 'challenge_tie');
  if not exists (
    select 1 from public.matches
    where game_code = 'SHRA'
      and status = 'finished'
      and winner_user_id is null
      and end_reason = 'challenge_tie'
      and ended_at is not null
  ) then
    raise exception 'tie result shape';
  end if;

  insert into public.matches (game_code, host_id, status)
  values ('SHRB', 'shr-a', 'lobby');
  perform private.finish_match('SHRB', 'shr-a', 'forfeit');
  if not exists (
    select 1 from public.matches
    where game_code = 'SHRB'
      and status = 'finished'
      and winner_user_id = 'shr-a'
      and end_reason = 'forfeit'
  ) then
    raise exception 'win result shape';
  end if;

  begin
    insert into public.matches (
      game_code, host_id, status, winner_user_id, end_reason, ended_at
    ) values (
      'SHRC', 'shr-a', 'finished', '__DRAW__', 'forfeit', now()
    );
    raise exception 'expected __DRAW__ fk failure';
  exception
    when foreign_key_violation then
      null;
    when others then
      if sqlerrm like '%expected __DRAW__ fk failure%' then
        raise;
      end if;
      if sqlstate is distinct from '23503' then
        raise;
      end if;
  end;

  begin
    insert into public.matches (
      game_code, host_id, status, winner_user_id, end_reason, ended_at
    ) values (
      'SHRD', 'shr-a', 'finished', 'shr-a', 'nope', now()
    );
    raise exception 'expected end_reason check failure';
  exception
    when check_violation then
      null;
    when others then
      if sqlerrm like '%expected end_reason check failure%' then
        raise;
      end if;
      if sqlstate is distinct from '23514' then
        raise;
      end if;
  end;

  begin
    insert into public.matches (
      game_code, host_id, status, winner_user_id, end_reason, ended_at
    ) values (
      'SHRE', 'shr-a', 'finished', 'shr-a', 'challenge_tie', now()
    );
    raise exception 'expected tie-with-winner check failure';
  exception
    when check_violation then
      null;
    when others then
      if sqlerrm like '%expected tie-with-winner check failure%' then
        raise;
      end if;
      if sqlstate is distinct from '23514' then
        raise;
      end if;
  end;

  begin
    insert into public.matches (game_code, host_id, status, winner_user_id)
    values ('SHRF', 'shr-a', 'lobby', 'shr-a');
    raise exception 'expected lobby-with-winner check failure';
  exception
    when check_violation then
      null;
    when others then
      if sqlerrm like '%expected lobby-with-winner check failure%' then
        raise;
      end if;
      if sqlstate is distinct from '23514' then
        raise;
      end if;
  end;

  begin
    delete from public.users where id = 'shr-a';
    raise exception 'expected restrict on winner delete';
  exception
    when foreign_key_violation then
      null;
    when others then
      if sqlerrm like '%expected restrict on winner delete%' then
        raise;
      end if;
      if sqlstate is distinct from '23503' then
        raise;
      end if;
  end;

  select count(*) into n from public.users where id = 'shr-a';
  if n is distinct from 1 then
    raise exception 'winner user deleted';
  end if;

  delete from public.matches where game_code in ('SHRA', 'SHRB', 'SHRC', 'SHRD', 'SHRE', 'SHRF');
  delete from public.users where id in ('shr-a', 'shr-b');

  raise notice 'match result tests passed';
end;
$$;
