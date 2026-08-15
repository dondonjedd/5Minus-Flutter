-- Eliminate event + penalty insert-after. Run as postgres.

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
  hand jsonb;
  ev jsonb;
  top jsonb;
  attempted jsonb;
  penalty jsonb;
  prepended jsonb;
  before_len int;
begin
  delete from public.matches where game_code in ('ELIM', 'ELI2', 'ELI3');
  delete from public.users where id in ('elim-a', 'elim-b');

  insert into public.users (id, username) values
    ('elim-a', 'A'),
    ('elim-b', 'B');

  insert into public.matches (game_code, host_id, status)
  values ('ELIM', 'elim-a', 'lobby');
  insert into public.match_players (game_code, user_id, seat, is_ready)
  values
    ('ELIM', 'elim-a', 0, true),
    ('ELIM', 'elim-b', 1, true);

  perform private._test_set_uid('elim-a');
  bundle := public.start_match('ELIM');

  -- Known piles: discard top rank 5, seat 0 hand four cards, index 1 is rank 7.
  update public.matches
  set
    discard_deck = jsonb_build_array(private.make_card(5, 1)),
    draw_deck = jsonb_build_array(
      private.make_card(2, 1),
      private.make_card(3, 1),
      private.make_card(4, 1)
    ),
    drawn_card = null,
    last_eliminate = null
  where game_code = 'ELIM';
  update public.match_players
  set
    player_hand = jsonb_build_array(
      private.make_card(6, 1),
      private.make_card(7, 2),
      private.make_card(8, 3),
      private.make_card(9, 4)
    ),
    penalty_count = 0,
    elimination_locked = false,
    actions_complete = false
  where game_code = 'ELIM' and user_id = 'elim-a';

  attempted := private.make_card(7, 2);
  bundle := public.eliminate_card('ELIM', 1);
  if bundle->>'notice' is null then
    raise exception 'expected fail notice';
  end if;
  ev := bundle->'match'->'last_eliminate';
  if (ev->>'failed') is distinct from 'true' then
    raise exception 'last_eliminate.failed %', ev;
  end if;
  if (ev->>'match_over') is distinct from 'false' then
    raise exception 'last_eliminate.match_over %', ev;
  end if;
  if (ev->>'hand_index')::int is distinct from 1 then
    raise exception 'last_eliminate.hand_index %', ev;
  end if;
  if (ev->>'seat')::int is distinct from 0 then
    raise exception 'last_eliminate.seat %', ev;
  end if;

  hand := bundle->'seats'->0->'player_hand';
  if jsonb_array_length(hand) is distinct from 5 then
    raise exception 'fail hand length %', jsonb_array_length(hand);
  end if;
  if hand->1 is distinct from attempted then
    raise exception 'attempted card moved: %', hand->1;
  end if;
  if (hand->2->>'rank')::int is distinct from 8
     or (hand->3->>'rank')::int is distinct from 9 then
    raise exception 'cards after attempt should stay put: %', hand;
  end if;
  penalty := hand->4;
  if penalty is null or (penalty->>'rank')::int is distinct from 4 then
    raise exception 'penalty should append at the right: %', hand;
  end if;
  if (bundle->'seats'->0->>'elimination_locked') is distinct from 'true' then
    raise exception 'expected elimination locked';
  end if;
  if (bundle->'seats'->0->>'penalty_count')::int is distinct from 1 then
    raise exception 'penalty_count %', bundle->'seats'->0->>'penalty_count';
  end if;

  -- Next play move clears last_eliminate.
  update public.match_players
  set elimination_locked = false, actions_complete = false
  where game_code = 'ELIM' and user_id = 'elim-a';
  update public.matches
  set drawn_card = null
  where game_code = 'ELIM';
  bundle := public.claim_draw('ELIM');
  if bundle->'match'->'last_eliminate' is not null
     and jsonb_typeof(bundle->'match'->'last_eliminate') <> 'null' then
    raise exception 'claim_draw should clear last_eliminate: %', bundle->'match'->'last_eliminate';
  end if;

  -- Successful eliminate: matching rank, card removed, failed=false.
  update public.matches
  set
    discard_deck = jsonb_build_array(private.make_card(8, 1)),
    drawn_card = null,
    last_eliminate = null
  where game_code = 'ELIM';
  update public.match_players
  set
    player_hand = jsonb_build_array(
      private.make_card(6, 1),
      private.make_card(8, 2),
      private.make_card(9, 3)
    ),
    elimination_locked = false,
    actions_complete = false
  where game_code = 'ELIM' and user_id = 'elim-a';

  before_len := 3;
  bundle := public.eliminate_card('ELIM', 1);
  if bundle->>'notice' is not null then
    raise exception 'success should have no notice';
  end if;
  ev := bundle->'match'->'last_eliminate';
  if (ev->>'failed') is distinct from 'false' then
    raise exception 'success last_eliminate.failed %', ev;
  end if;
  if (ev->>'match_over') is distinct from 'false' then
    raise exception 'success last_eliminate.match_over %', ev;
  end if;
  hand := bundle->'seats'->0->'player_hand';
  if jsonb_array_length(hand) is distinct from before_len - 1 then
    raise exception 'success hand length %', jsonb_array_length(hand);
  end if;
  if (hand->0->>'rank')::int is distinct from 6
     or (hand->1->>'rank')::int is distinct from 9 then
    raise exception 'success removed the wrong card: %', hand;
  end if;

  -- Third penalty ends the match (match_over true).
  insert into public.matches (game_code, host_id, status, turn, discard_deck, draw_deck)
  values (
    'ELI2',
    'elim-a',
    'active',
    0,
    jsonb_build_array(private.make_card(1, 1)),
    jsonb_build_array(private.make_card(2, 1), private.make_card(3, 1), private.make_card(4, 1))
  );
  insert into public.match_players (
    game_code, user_id, seat, is_ready, player_hand, penalty_count, elimination_locked
  )
  values
    (
      'ELI2',
      'elim-a',
      0,
      true,
      jsonb_build_array(private.make_card(10, 1), private.make_card(11, 2)),
      2,
      false
    ),
    ('ELI2', 'elim-b', 1, true, jsonb_build_array(private.make_card(12, 1)), 0, false);

  perform private._test_set_uid('elim-a');
  bundle := public.eliminate_card('ELI2', 0);
  ev := bundle->'match'->'last_eliminate';
  if (ev->>'failed') is distinct from 'true'
     or (ev->>'match_over') is distinct from 'true' then
    raise exception 'third penalty last_eliminate %', ev;
  end if;
  if bundle->'match'->>'status' is distinct from 'finished' then
    raise exception 'third penalty status %', bundle->'match'->>'status';
  end if;
  if bundle->'match'->>'end_reason' is distinct from 'penalties' then
    raise exception 'third penalty reason %', bundle->'match'->>'end_reason';
  end if;
  if bundle->'match'->>'winner_user_id' is distinct from 'elim-b' then
    raise exception 'third penalty winner %', bundle->'match'->>'winner_user_id';
  end if;
  hand := bundle->'seats'->0->'player_hand';
  if jsonb_array_length(hand) is distinct from 3 then
    raise exception 'third penalty should still insert: %', hand;
  end if;
  if (hand->0->>'rank')::int is distinct from 10
     or (hand->1->>'rank')::int is distinct from 11 then
    raise exception 'third penalty should append at the right: %', hand;
  end if;

  -- Challenge / shrink still prepends (apply_penalty with null insert-after).
  insert into public.matches (game_code, host_id, status, turn, discard_deck, draw_deck)
  values (
    'ELI3',
    'elim-a',
    'active',
    0,
    jsonb_build_array(private.make_card(5, 1)),
    jsonb_build_array(private.make_card(2, 2))
  );
  insert into public.match_players (
    game_code, user_id, seat, player_hand, penalty_count, is_challenge_declared
  )
  values
    (
      'ELI3',
      'elim-a',
      0,
      jsonb_build_array(private.make_card(6, 1), private.make_card(7, 1)),
      0,
      true
    ),
    ('ELI3', 'elim-b', 1, jsonb_build_array(private.make_card(8, 1)), 0, false);

  top := private.make_card(2, 2);
  perform private.apply_penalty('ELI3', 'elim-a', false);
  select player_hand into hand
  from public.match_players
  where game_code = 'ELI3' and user_id = 'elim-a';
  prepended := hand->0;
  if prepended is distinct from top then
    raise exception 'challenge penalty should prepend draw top: %', hand;
  end if;
  if jsonb_array_length(hand) is distinct from 3 then
    raise exception 'challenge penalty length %', jsonb_array_length(hand);
  end if;
  if (hand->1->>'rank')::int is distinct from 6 then
    raise exception 'challenge penalty should not insert after: %', hand;
  end if;

  delete from public.matches where game_code in ('ELIM', 'ELI2', 'ELI3');
  delete from public.users where id in ('elim-a', 'elim-b');

  raise notice 'eliminate event tests passed';
end;
$$;

drop function if exists private._test_set_uid(text);
