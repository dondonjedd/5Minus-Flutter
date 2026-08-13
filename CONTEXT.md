# 5Minus domain

## User

A person identified by Firebase UID. That string is `users.id`, Seat `user_id`, and `private.current_uid()` (JWT `sub`) once the Firebase ID token is the Supabase access token. `auth.uid()` is uuid-typed and does not work with Firebase IDs. Profile writes are own-row; username/icon may be read by any signed-in User.

## Match

One game row: code, host, turn (a stable seat number), Card piles as jsonb, Match status, and Match result. Membership is not part of a Match.

## Match status

`lobby | active | finished` on Match. Replaces `has_started` / `is_active` / `winner` jsonb. Seat membership is lobby-only. Match play runs while active.

## Match result

`winner_user_id` (nullable User), `end_reason`, and `ended_at` on Match. Lobby and active rows have all three null. Finished rows have `end_reason` and `ended_at`. A draw is `end_reason = challenge_tie` with a null winner; any other reason requires a winner. Replaces `winner` jsonb and the `__DRAW__` sentinel.

## Seat

One `match_players` row: a User in a Match, including hand, ready, presence (`last_seen`), and in-game flags.

## Match Player

In-memory `PlayerMatchModel` assembled from a Seat, plus `loadedPlayer` (never persisted).

## Seat membership

The Postgres module whose interface is named public moves (`create_lobby`, `join_lobby`, `set_ready`, `leave_lobby`, `kick_seat`, `cancel_lobby`). Lobby-only. `create_lobby` inserts Match and host Seat together. `join_lobby` assigns the next free seat. Host `leave_lobby` or `cancel_lobby` deletes the Match. `kick_seat` is host removing a guest. Each move returns `{ match, seats }` (null if the Match is gone). `last_seen` is a Seat write, not this module. Active exit is Match play `forfeit`. Flutter is an adapter.

## Match play

The Postgres module whose interface is named public moves (`start_match`, `claim_draw`, `discard_drawn`, `replace_hand`, `eliminate_card`, `swap_hands`, `clear_pending_power`, `declare_challenge`, `end_turn`, `forfeit`, `win_by_disconnect`). Each move mutates Match piles and Seat hands in one transaction and returns `{ match, seats }`. Seat membership is not this module. Flutter is an adapter.
