import 'package:five_minus/core/service/supabase_service.dart';

class MatchRemoteDatasource {
  const MatchRemoteDatasource();

  Future<Map<String, dynamic>?> fetchMatch(String gameCode) => SupabaseService.fetchMatch(gameCode);

  Future<bool> matchExists(String gameCode) => SupabaseService.matchExists(gameCode);

  Future<void> updateMatch(String gameCode, Map<String, dynamic> patch) =>
      SupabaseService.updateMatch(gameCode, patch);

  Stream<Map<String, dynamic>?> watchMatch(String gameCode) => SupabaseService.watchMatch(gameCode);

  Future<List<Map<String, dynamic>>> fetchSeats(String gameCode) => SupabaseService.fetchSeats(gameCode);

  Future<void> updateSeat(String gameCode, String userId, Map<String, dynamic> patch) =>
      SupabaseService.updateSeat(gameCode, userId, patch);

  Stream<Map<String, dynamic>?> watchSeats(String gameCode) => SupabaseService.watchSeats(gameCode);

  Future<Map<String, dynamic>> createLobby() =>
      SupabaseService.rpcMatchPlay('create_lobby', const {});

  Future<Map<String, dynamic>> joinLobby(String gameCode) =>
      SupabaseService.rpcMatchPlay('join_lobby', {'p_code': gameCode});

  Future<Map<String, dynamic>> setReady(String gameCode, bool ready) =>
      SupabaseService.rpcMatchPlay('set_ready', {
        'p_code': gameCode,
        'p_ready': ready,
      });

  Future<Map<String, dynamic>> leaveLobby(String gameCode) =>
      SupabaseService.rpcMatchPlay('leave_lobby', {'p_code': gameCode});

  Future<Map<String, dynamic>> kickSeat(String gameCode, String userId) =>
      SupabaseService.rpcMatchPlay('kick_seat', {
        'p_code': gameCode,
        'p_user_id': userId,
      });

  Future<Map<String, dynamic>> cancelLobby(String gameCode) =>
      SupabaseService.rpcMatchPlay('cancel_lobby', {'p_code': gameCode});

  Future<Map<String, dynamic>> startMatch(String gameCode) =>
      SupabaseService.rpcMatchPlay('start_match', {'p_code': gameCode});

  Future<Map<String, dynamic>> claimDraw(String gameCode) =>
      SupabaseService.rpcMatchPlay('claim_draw', {'p_code': gameCode});

  Future<Map<String, dynamic>> discardDrawn(String gameCode) =>
      SupabaseService.rpcMatchPlay('discard_drawn', {'p_code': gameCode});

  Future<Map<String, dynamic>> replaceHand(String gameCode, int handIndex) =>
      SupabaseService.rpcMatchPlay('replace_hand', {
        'p_code': gameCode,
        'p_hand_index': handIndex,
      });

  Future<Map<String, dynamic>> eliminateCard(String gameCode, int handIndex) =>
      SupabaseService.rpcMatchPlay('eliminate_card', {
        'p_code': gameCode,
        'p_hand_index': handIndex,
      });

  Future<Map<String, dynamic>> swapHands({
    required String gameCode,
    required int seatA,
    required int indexA,
    required int seatB,
    required int indexB,
  }) =>
      SupabaseService.rpcMatchPlay('swap_hands', {
        'p_code': gameCode,
        'p_seat_a': seatA,
        'p_idx_a': indexA,
        'p_seat_b': seatB,
        'p_idx_b': indexB,
      });

  Future<Map<String, dynamic>> clearPendingPower(String gameCode) =>
      SupabaseService.rpcMatchPlay('clear_pending_power', {'p_code': gameCode});

  Future<Map<String, dynamic>> endTurn(String gameCode) =>
      SupabaseService.rpcMatchPlay('end_turn', {'p_code': gameCode});

  Future<Map<String, dynamic>> declareChallenge(String gameCode) =>
      SupabaseService.rpcMatchPlay('declare_challenge', {'p_code': gameCode});

  Future<Map<String, dynamic>> forfeit(String gameCode) =>
      SupabaseService.rpcMatchPlay('forfeit', {'p_code': gameCode});

  Future<Map<String, dynamic>> winByDisconnect(String gameCode) =>
      SupabaseService.rpcMatchPlay('win_by_disconnect', {'p_code': gameCode});
}
