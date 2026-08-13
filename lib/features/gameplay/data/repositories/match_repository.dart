import 'package:five_minus/features/gameplay/data/data_sources/match_remote_datasource.dart';
import 'package:five_minus/features/gameplay/model/game_model.dart';

class MatchRepository {
  MatchRepository({MatchRemoteDatasource? datasource}) : _datasource = datasource ?? const MatchRemoteDatasource();

  final MatchRemoteDatasource _datasource;

  Future<GameModel?> fetchMatch(String gameCode) async {
    final row = await _datasource.fetchMatch(gameCode);
    if (row == null) return null;
    return GameModel.fromMap(row);
  }

  Future<bool> matchExists(String gameCode) => _datasource.matchExists(gameCode);

  Future<void> insertMatch(GameModel game) => _datasource.insertMatch(game.toMap());

  Future<void> insertMatchRow(Map<String, dynamic> row) => _datasource.insertMatch(row);

  Future<void> updateMatch(String gameCode, Map<String, dynamic> patch) =>
      _datasource.updateMatch(gameCode, patch);

  Future<GameModel?> updateMatchIfDrawnCardNull(String gameCode, Map<String, dynamic> patch) async {
    final row = await _datasource.updateMatchIfDrawnCardNull(gameCode, patch);
    if (row == null) return null;
    return GameModel.fromMap(row);
  }

  Future<void> deleteMatch(String gameCode) => _datasource.deleteMatch(gameCode);

  /// Emits the latest match, or `null` when the row is deleted.
  Stream<GameModel?> watchMatch(String gameCode) {
    return _datasource.watchMatch(gameCode).map((row) {
      if (row == null) return null;
      return GameModel.fromMap(row);
    });
  }
}
