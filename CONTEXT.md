# 5Minus domain

## Match

One game row: code, host, turn (a stable seat number), Card piles as jsonb, and match-wide flags. Membership is not part of a Match.

## Seat

One `match_players` row: a User in a Match, including hand, ready, presence (`last_seen`), and in-game flags.

## Match Player

In-memory `PlayerMatchModel` assembled from a Seat, plus `loadedPlayer` (never persisted).
