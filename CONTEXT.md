# 5Minus domain

## User

A person identified by Firebase UID. That string is `users.id`, Seat `user_id`, and `private.current_uid()` (JWT `sub`) once the Firebase ID token is the Supabase access token. `auth.uid()` is uuid-typed and does not work with Firebase IDs. Profile writes are own-row; username/icon may be read by any signed-in User.

## Match

One game row: code, host, turn (a stable seat number), Card piles as jsonb, and match-wide flags. Membership is not part of a Match.

## Seat

One `match_players` row: a User in a Match, including hand, ready, presence (`last_seen`), and in-game flags.

## Match Player

In-memory `PlayerMatchModel` assembled from a Seat, plus `loadedPlayer` (never persisted).
