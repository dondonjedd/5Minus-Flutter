class GameConstants {
  static const int maxPlayers = 2;
  static const int startingHandSize = 4;
  static const int openingPeekCount = 2;
  static const int maxPenalties = 3;
  static const int challengePointLimit = 5; // win if total <= 5
  static const int reconnectTimeoutSeconds = 60;
  static const String drawWinnerId = '__DRAW__';
}

/// Stored on the winner jsonb as `end_reason` (no DB migration).
class EndReason {
  static const String emptyHand = 'empty_hand';
  static const String challenge = 'challenge';
  static const String challengeTie = 'challenge_tie';
  static const String penalties = 'penalties';
  static const String forfeit = 'forfeit';
  static const String disconnect = 'disconnect';
}
