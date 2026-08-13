import 'package:five_minus/core/service/supabase_service.dart';

class MatchRemoteDatasource {
  const MatchRemoteDatasource();

  Future<Map<String, dynamic>?> fetchMatch(String gameCode) => SupabaseService.fetchMatch(gameCode);

  Future<bool> matchExists(String gameCode) => SupabaseService.matchExists(gameCode);

  Future<void> insertMatch(Map<String, dynamic> row) => SupabaseService.insertMatch(row);

  Future<void> updateMatch(String gameCode, Map<String, dynamic> patch) =>
      SupabaseService.updateMatch(gameCode, patch);

  Future<Map<String, dynamic>?> updateMatchIfDrawnCardNull(
    String gameCode,
    Map<String, dynamic> patch,
  ) =>
      SupabaseService.updateMatchIfDrawnCardNull(gameCode, patch);

  Future<void> deleteMatch(String gameCode) => SupabaseService.deleteMatch(gameCode);

  Stream<Map<String, dynamic>?> watchMatch(String gameCode) => SupabaseService.watchMatch(gameCode);
}
