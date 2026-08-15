-- Eliminate event: persist last_eliminate for both clients, append fail
-- penalty at the right end of the hand.

alter table public.matches
  add column if not exists last_eliminate jsonb;

-- ---------------------------------------------------------------------------
-- Clear the one-shot event at the start of every play lock. eliminate_card
-- writes a fresh value after it mutates.
-- ---------------------------------------------------------------------------

create or replace function private.lock_match(p_code text)
returns public.matches
language plpgsql
security definer
set search_path = public
as $$
declare
  m public.matches;
begin
  select * into m from public.matches where game_code = p_code for update;
  if not found then
    raise exception 'match not found' using errcode = 'P0001';
  end if;
  perform 1 from public.match_players where game_code = p_code for update;
  if m.last_eliminate is not null then
    update public.matches
    set last_eliminate = null
    where game_code = p_code;
    m.last_eliminate := null;
  end if;
  return m;
end;
$$;

-- ---------------------------------------------------------------------------
-- Optional insert-after index. null prepends (challenge / shrink).
-- ---------------------------------------------------------------------------

drop function if exists private.apply_penalty(text, text, boolean);

create function private.apply_penalty(
  p_code text,
  p_user_id text,
  p_lock_elimination boolean,
  p_insert_after int default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  m public.matches;
  v_draw jsonb;
  v_discard jsonb;
  v_card jsonb;
  v_hand jsonb;
  insert_at int;
  v_left jsonb;
  v_right jsonb;
begin
  select * into m from public.matches where game_code = p_code;
  select e.draw, e.discard into v_draw, v_discard
  from private.ensure_draw(m.draw_deck, m.discard_deck) e;
  v_card := private.last_card(v_draw);
  v_draw := private.drop_last(v_draw);
  select player_hand into v_hand
  from public.match_players
  where game_code = p_code and user_id = p_user_id;
  v_hand := coalesce(v_hand, '[]'::jsonb);
  if v_card is not null then
    if p_insert_after is null then
      v_hand := jsonb_build_array(v_card) || v_hand;
    else
      insert_at := least(greatest(p_insert_after + 1, 0), jsonb_array_length(v_hand));
      select coalesce(jsonb_agg(elem order by ord), '[]'::jsonb)
        into v_left
      from jsonb_array_elements(v_hand) with ordinality as t(elem, ord)
      where ord <= insert_at;
      select coalesce(jsonb_agg(elem order by ord), '[]'::jsonb)
        into v_right
      from jsonb_array_elements(v_hand) with ordinality as t(elem, ord)
      where ord > insert_at;
      v_hand := v_left || jsonb_build_array(v_card) || v_right;
    end if;
  end if;
  update public.match_players
  set
    player_hand = v_hand,
    penalty_count = penalty_count + 1,
    elimination_locked = case
      when p_lock_elimination then true
      else elimination_locked
    end
  where game_code = p_code and user_id = p_user_id;
  update public.matches
  set draw_deck = v_draw, discard_deck = v_discard, updated_at = now()
  where game_code = p_code;
end;
$$;

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
