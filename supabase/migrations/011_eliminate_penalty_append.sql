-- Failed eliminate: append the penalty at the right end of the hand.

create or replace function public.eliminate_card(p_code text, p_hand_index int)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid text := private.require_uid();
  m public.matches;
  v_seat int;
  v_locked boolean;
  v_hand jsonb;
  v_card jsonb;
  v_top jsonb;
  v_opp text;
  n int;
  notice text;
  v_match_over boolean := false;
begin
  m := private.lock_match(p_code);
  if m.status is distinct from 'active' then
    raise exception 'match is not active' using errcode = 'P0001';
  end if;
  if private.pending_power(m) then
    raise exception 'power pending' using errcode = 'P0001';
  end if;
  v_top := private.last_card(m.discard_deck);
  if v_top is null then
    raise exception 'no discard card' using errcode = 'P0001';
  end if;

  select seat, elimination_locked, player_hand
    into v_seat, v_locked, v_hand
  from public.match_players
  where game_code = p_code and user_id = uid;
  if v_seat is null then
    raise exception 'not seated' using errcode = 'P0001';
  end if;
  if v_seat is distinct from m.turn then
    raise exception 'not your turn' using errcode = 'P0001';
  end if;
  if v_locked then
    raise exception 'elimination locked' using errcode = 'P0001';
  end if;

  v_hand := coalesce(v_hand, '[]'::jsonb);
  n := jsonb_array_length(v_hand);
  if p_hand_index < 0 or p_hand_index >= n then
    raise exception 'invalid hand index' using errcode = 'P0001';
  end if;

  v_card := v_hand -> p_hand_index;
  if (v_card->>'rank') is distinct from (v_top->>'rank') then
    perform private.apply_penalty(p_code, uid, true, n - 1);
    if (
      select penalty_count from public.match_players
      where game_code = p_code and user_id = uid
    ) >= 3 then
      v_opp := private.opponent_user_id(p_code, uid);
      if v_opp is not null then
        perform private.finish_match(p_code, v_opp, 'penalties');
        v_match_over := true;
      end if;
    end if;
    update public.matches
    set last_eliminate = jsonb_build_object(
      'seat', v_seat,
      'hand_index', p_hand_index,
      'failed', true,
      'match_over', v_match_over
    )
    where game_code = p_code;
    notice := 'Wrong rank - elimination locked until your next turn';
    return private.match_bundle(p_code) || jsonb_build_object('notice', notice);
  end if;

  v_hand := v_hand - p_hand_index;
  update public.match_players
  set player_hand = v_hand
  where game_code = p_code and user_id = uid;

  if jsonb_array_length(v_hand) = 0 then
    perform private.finish_match(p_code, uid, 'empty_hand');
    v_match_over := true;
  end if;

  update public.matches
  set last_eliminate = jsonb_build_object(
    'seat', v_seat,
    'hand_index', p_hand_index,
    'failed', false,
    'match_over', v_match_over
  )
  where game_code = p_code;

  return private.match_bundle(p_code);
end;
$$;
