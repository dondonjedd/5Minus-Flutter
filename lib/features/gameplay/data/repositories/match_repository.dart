import 'dart:async';

import 'package:five_minus/features/gameplay/data/data_sources/match_remote_datasource.dart';
import 'package:five_minus/features/gameplay/model/game_constants.dart';
import 'package:five_minus/features/gameplay/model/game_model.dart';
import 'package:five_minus/features/gameplay/model/player_match_model.dart';

class MatchRepository {
  MatchRepository({MatchRemoteDatasource? datasource}) : _datasource = datasource ?? const MatchRemoteDatasource();

  final MatchRemoteDatasource _datasource;

  GameModel _assemble(Map<String, dynamic> row, List<Map<String, dynamic>> seats) {
    final players = seats.map(PlayerMatchModel.fromSeatRow).toList()
      ..sort((a, b) => a.seat.compareTo(b.seat));
    var game = GameModel.fromMap(row).copyWith(players: players);
    final winnerId = game.winner?.playerId;
    if (winnerId != null && winnerId != GameConstants.drawWinnerId) {
      for (final p in players) {
        if (p.playerId == winnerId) {
          game = game.copyWith(winner: p);
          break;
        }
      }
    }
    return game;
  }

  GameModel assembleBundle(Map<String, dynamic> bundle) {
    final match = Map<String, dynamic>.from(bundle['match'] as Map);
    final seats = ((bundle['seats'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return _assemble(match, seats);
  }

  Future<GameModel?> _assembleFromMatchRow(Map<String, dynamic>? row, String gameCode) async {
    if (row == null) return null;
    final seats = await _datasource.fetchSeats(gameCode);
    return _assemble(row, seats);
  }

  Future<GameModel?> fetchMatch(String gameCode) async {
    final row = await _datasource.fetchMatch(gameCode);
    return _assembleFromMatchRow(row, gameCode);
  }

  Future<bool> matchExists(String gameCode) => _datasource.matchExists(gameCode);

  Future<void> insertMatch(GameModel game) async {
    await _datasource.insertMatch(game.toMap());
    PlayerMatchModel? host;
    for (final p in game.players) {
      if (p.playerId == game.hostId) {
        host = p;
        break;
      }
    }
    host ??= game.players.isNotEmpty ? game.players.first : null;
    if (host?.playerId != null) {
      await _datasource.insertSeat(host!.toSeatRow(gameCode: game.code));
    }
  }

  Future<void> updateMatch(String gameCode, Map<String, dynamic> patch) {
    final matchPatch = Map<String, dynamic>.from(patch)..remove('players');
    return _datasource.updateMatch(gameCode, matchPatch);
  }

  Future<void> deleteMatch(String gameCode) => _datasource.deleteMatch(gameCode);

  Future<void> insertSeat(PlayerMatchModel player, {required String gameCode}) {
    return _datasource.insertSeat(player.toSeatRow(gameCode: gameCode));
  }

  Future<void> updateSeat(String gameCode, String userId, Map<String, dynamic> patch) {
    final seatPatch = Map<String, dynamic>.from(patch)..remove('last_seen');
    return _datasource.updateSeat(gameCode, userId, seatPatch);
  }

  Future<void> heartbeatSeat(String gameCode, String userId, DateTime lastSeen) {
    return _datasource.updateSeat(gameCode, userId, {
      'last_seen': lastSeen.toUtc().toIso8601String(),
    });
  }

  Future<void> deleteSeat(String gameCode, String userId) => _datasource.deleteSeat(gameCode, userId);

  Future<GameModel> startMatch(String gameCode) async {
    return assembleBundle(await _datasource.startMatch(gameCode));
  }

  Future<GameModel> claimDraw(String gameCode) async {
    return assembleBundle(await _datasource.claimDraw(gameCode));
  }

  Future<GameModel> discardDrawn(String gameCode) async {
    return assembleBundle(await _datasource.discardDrawn(gameCode));
  }

  Future<GameModel> replaceHand(String gameCode, int handIndex) async {
    return assembleBundle(await _datasource.replaceHand(gameCode, handIndex));
  }

  Future<({GameModel game, String? notice})> eliminateCard(String gameCode, int handIndex) async {
    final bundle = await _datasource.eliminateCard(gameCode, handIndex);
    return (game: assembleBundle(bundle), notice: bundle['notice'] as String?);
  }

  Future<GameModel> swapHands({
    required String gameCode,
    required int seatA,
    required int indexA,
    required int seatB,
    required int indexB,
  }) async {
    return assembleBundle(await _datasource.swapHands(
      gameCode: gameCode,
      seatA: seatA,
      indexA: indexA,
      seatB: seatB,
      indexB: indexB,
    ));
  }

  Future<GameModel> clearPendingPower(String gameCode) async {
    return assembleBundle(await _datasource.clearPendingPower(gameCode));
  }

  Future<GameModel> endTurn(String gameCode) async {
    return assembleBundle(await _datasource.endTurn(gameCode));
  }

  Future<GameModel> declareChallenge(String gameCode) async {
    return assembleBundle(await _datasource.declareChallenge(gameCode));
  }

  Future<GameModel> forfeit(String gameCode) async {
    return assembleBundle(await _datasource.forfeit(gameCode));
  }

  Future<GameModel> winByDisconnect(String gameCode) async {
    return assembleBundle(await _datasource.winByDisconnect(gameCode));
  }

  /// Emits the latest assembled Match, or `null` when the Match row is deleted.
  Stream<GameModel?> watchMatch(String gameCode) {
    late final StreamController<GameModel?> controller;
    StreamSubscription<Map<String, dynamic>?>? matchSub;
    StreamSubscription<Map<String, dynamic>?>? seatSub;
    Timer? poll;
    var fetching = false;
    var pending = false;
    var seen = false;

    void emitGone() {
      poll?.cancel();
      poll = null;
      if (!controller.isClosed) controller.add(null);
    }

    Future<void> refresh({required bool deleted}) async {
      if (deleted) {
        emitGone();
        return;
      }
      if (fetching) {
        pending = true;
        return;
      }
      fetching = true;
      try {
        do {
          pending = false;
          final game = await fetchMatch(gameCode);
          if (game == null) {
            if (seen) emitGone();
            continue;
          }
          seen = true;
          if (!controller.isClosed) controller.add(game);
        } while (pending);
      } catch (_) {
      } finally {
        fetching = false;
      }
    }

    controller = StreamController<GameModel?>(
      onListen: () {
        matchSub = _datasource.watchMatch(gameCode).listen(
          (row) => refresh(deleted: row == null),
          onError: (_) {},
        );
        seatSub = _datasource.watchSeats(gameCode).listen(
          (_) => refresh(deleted: false),
          onError: (_) {},
        );
        unawaited(refresh(deleted: false));
        poll = Timer.periodic(const Duration(seconds: 2), (_) {
          unawaited(refresh(deleted: false));
        });
      },
      onCancel: () async {
        poll?.cancel();
        poll = null;
        await matchSub?.cancel();
        await seatSub?.cancel();
      },
    );

    return controller.stream;
  }
}
