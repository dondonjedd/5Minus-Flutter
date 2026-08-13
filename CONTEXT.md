# 5Minus domain

## User

A person identified by Firebase UID. That string is `users.id`, Seat `user_id`, and `private.current_uid()` (JWT `sub`) once the Firebase ID token is the Supabase access token. `auth.uid()` is uuid-typed and does not work with Firebase IDs. Profile writes are own-row; username/icon may be read by any signed-in User.

## Match

One game row: code, host, turn (a stable seat number), Card piles as jsonb, Match status, and match-wide flags. Membership is not part of a Match.

## Match status

`lobby | active | finished` on Match. Replaces `has_started` / `is_active` / `winner` jsonb. Seat insert is lobby-only. Match play runs while active.

## Seat

One `match_players` row: a User in a Match, including hand, ready, presence (`last_seen`), and in-game flags.

## Match Player

In-memory `PlayerMatchModel` assembled from a Seat, plus `loadedPlayer` (never persisted).

## Match play

The Postgres module whose interface is named public moves (`start_match`, `claim_draw`, `discard_drawn`, `replace_hand`, `eliminate_card`, `swap_hands`, `clear_pending_power`, `declare_challenge`, `end_turn`, `forfeit`, `win_by_disconnect`). Each move mutates Match piles and Seat hands in one transaction and returns `{ match, seats }`. Membership RLS is not this module. Flutter is an adapter.
