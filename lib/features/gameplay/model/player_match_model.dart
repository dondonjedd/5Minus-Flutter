import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:five_minus/features/auth_game_services/model/firebase_user_model.dart';
import 'package:five_minus/features/gameplay/model/card_model.dart';

const Object _unset = Object();

class PlayerMatchModel extends Equatable {
  final int seat;
  final String? playerId;
  final FirebaseUserModel? loadedPlayer;
  final bool? isReady;
  final List<CardModel>? playerHand;
  final bool? isChallengedDeclard;
  final int penaltyCount;
  final bool eliminationLocked;
  final bool actionsComplete;
  final String? lastSeen;

  const PlayerMatchModel({
    this.seat = 0,
    this.playerId,
    this.loadedPlayer,
    this.isReady = false,
    this.playerHand,
    this.isChallengedDeclard = false,
    this.penaltyCount = 0,
    this.eliminationLocked = false,
    this.actionsComplete = false,
    this.lastSeen,
  });

  static String? _lastSeenFrom(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is String) return value;
    return null;
  }

  factory PlayerMatchModel.fromMap(Map<String, dynamic> data) {
    return PlayerMatchModel(
      seat: (data['seat'] as num?)?.toInt() ?? 0,
      playerId: (data['player_id'] as String?) ?? (data['playerId'] as String?) ?? (data['user_id'] as String?),
      isReady: (data['is_ready'] as bool?) ?? (data['isReady'] as bool?),
      playerHand: (data['player_hand'] as List<dynamic>?)
          ?.map((e) => CardModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isChallengedDeclard: data['is_challenge_declared'] as bool?,
      penaltyCount: (data['penalty_count'] as int?) ?? 0,
      eliminationLocked: (data['elimination_locked'] as bool?) ?? false,
      actionsComplete: (data['actions_complete'] as bool?) ?? false,
      lastSeen: _lastSeenFrom(data['last_seen']),
    );
  }

  /// Seat row from `match_players` (snake_case columns).
  factory PlayerMatchModel.fromSeatRow(Map<String, dynamic> data) {
    return PlayerMatchModel(
      seat: (data['seat'] as num?)?.toInt() ?? 0,
      playerId: data['user_id'] as String?,
      isReady: data['is_ready'] as bool?,
      playerHand: (data['player_hand'] as List<dynamic>?)
          ?.map((e) => CardModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isChallengedDeclard: data['is_challenge_declared'] as bool?,
      penaltyCount: (data['penalty_count'] as int?) ?? 0,
      eliminationLocked: (data['elimination_locked'] as bool?) ?? false,
      actionsComplete: (data['actions_complete'] as bool?) ?? false,
      lastSeen: _lastSeenFrom(data['last_seen']),
    );
  }

  Map<String, dynamic> toMap() => {
        'seat': seat,
        'player_id': playerId,
        'isReady': isReady,
        'player_hand': playerHand?.map((x) => x.toMap()).toList() ?? [],
        'is_challenge_declared': isChallengedDeclard,
        'penalty_count': penaltyCount,
        'elimination_locked': eliminationLocked,
        'actions_complete': actionsComplete,
        'last_seen': lastSeen,
      };

  Map<String, dynamic> toSeatRow({required String gameCode}) => {
        'game_code': gameCode,
        'user_id': playerId,
        'seat': seat,
        'is_ready': isReady ?? false,
        'player_hand': playerHand?.map((x) => x.toMap()).toList() ?? [],
        'is_challenge_declared': isChallengedDeclard ?? false,
        'penalty_count': penaltyCount,
        'elimination_locked': eliminationLocked,
        'actions_complete': actionsComplete,
      };

  /// Column patch for an existing Seat. Never includes `last_seen`.
  Map<String, dynamic> toSeatPatch() => {
        'is_ready': isReady ?? false,
        'player_hand': playerHand?.map((x) => x.toMap()).toList() ?? [],
        'is_challenge_declared': isChallengedDeclard ?? false,
        'penalty_count': penaltyCount,
        'elimination_locked': eliminationLocked,
        'actions_complete': actionsComplete,
      };

  factory PlayerMatchModel.fromJson(String data) {
    return PlayerMatchModel.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  int handPoints() {
    if (playerHand == null) return 0;
    return playerHand!.fold<int>(0, (sum, c) => sum + (c.cardValue ?? 0));
  }

  PlayerMatchModel copyWith({
    Object? seat = _unset,
    Object? playerId = _unset,
    Object? loadedPlayer = _unset,
    Object? isReady = _unset,
    Object? playerHand = _unset,
    Object? isChallengedDeclard = _unset,
    Object? penaltyCount = _unset,
    Object? eliminationLocked = _unset,
    Object? actionsComplete = _unset,
    Object? lastSeen = _unset,
  }) {
    return PlayerMatchModel(
      seat: identical(seat, _unset) ? this.seat : seat as int,
      playerId: identical(playerId, _unset) ? this.playerId : playerId as String?,
      loadedPlayer: identical(loadedPlayer, _unset) ? this.loadedPlayer : loadedPlayer as FirebaseUserModel?,
      isReady: identical(isReady, _unset) ? this.isReady : isReady as bool?,
      playerHand: identical(playerHand, _unset) ? this.playerHand : playerHand as List<CardModel>?,
      isChallengedDeclard:
          identical(isChallengedDeclard, _unset) ? this.isChallengedDeclard : isChallengedDeclard as bool?,
      penaltyCount: identical(penaltyCount, _unset) ? this.penaltyCount : penaltyCount as int,
      eliminationLocked:
          identical(eliminationLocked, _unset) ? this.eliminationLocked : eliminationLocked as bool,
      actionsComplete: identical(actionsComplete, _unset) ? this.actionsComplete : actionsComplete as bool,
      lastSeen: identical(lastSeen, _unset) ? this.lastSeen : lastSeen as String?,
    );
  }

  @override
  List<Object?> get props => [
        seat,
        playerId,
        isReady,
        playerHand,
        isChallengedDeclard,
        penaltyCount,
        eliminationLocked,
        actionsComplete,
        lastSeen,
      ];
}
