import 'dart:convert';

import 'package:five_minus/features/gameplay/model/deck_model.dart';
import 'package:five_minus/features/gameplay/model/player_match_model.dart';

import 'card_model.dart';

const Object _unset = Object();

class GameModel {
  final String hostId;
  final String code;
  final List<PlayerMatchModel> players;
  final int? gameType;
  final bool isActive;
  final bool hasStarted;
  final Deck? drawDeck;
  final Deck? discardDeck;
  final int? turn;
  final CardModel? drawnCard;
  final DateTime? turnStartTime;
  final DateTime? powerStartTime;
  final bool? isChallengeComplete;
  final PlayerMatchModel? winner;
  /// Why the match ended; persisted inside winner jsonb as `end_reason`.
  final String? endReason;

  const GameModel({
    required this.hostId,
    required this.code,
    required this.players,
    required this.gameType,
    required this.isActive,
    required this.hasStarted,
    this.drawDeck,
    this.discardDeck,
    this.turn,
    this.drawnCard,
    this.turnStartTime,
    this.powerStartTime,
    this.isChallengeComplete = false,
    this.winner,
    this.endReason,
  });

  /// Timestamps are always normalised to UTC so that values read back from
  /// Postgres (`timestamptz`) compare equal to the ones written locally.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  factory GameModel.fromMap(Map<String, dynamic> data) => GameModel(
        hostId: (data['host_id'] as String?) ?? '',
        code: (data['game_code'] as String?) ?? '',
        players: (data['players'] as List<dynamic>?)
                ?.map((e) => PlayerMatchModel.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        gameType: (data['game_type'] as num?)?.toInt(),
        isActive: (data['is_active'] as bool?) ?? false,
        hasStarted: (data['has_started'] as bool?) ?? false,
        drawDeck: data['draw_deck'] is! List<dynamic> ? null : Deck.fromMapList(data['draw_deck']),
        discardDeck: data['discard_deck'] is! List<dynamic> ? null : Deck.fromMapList(data['discard_deck']),
        turn: (data['turn'] as num?)?.toInt(),
        drawnCard: data['drawn_card'] == null
            ? null
            : CardModel.fromMap(Map<String, dynamic>.from(data['drawn_card'] as Map)),
        turnStartTime: _parseDateTime(data['turn_start_time']),
        powerStartTime: _parseDateTime(data['power_start_time']),
        isChallengeComplete: (data['is_challenge_complete'] as bool?) ?? false,
        winner: data['winner'] == null
            ? null
            : PlayerMatchModel.fromMap(Map<String, dynamic>.from(data['winner'] as Map)),
        endReason: data['winner'] is Map
            ? (data['winner'] as Map)['end_reason'] as String?
            : data['end_reason'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'host_id': hostId,
        'game_code': code,
        'game_type': gameType,
        'is_active': isActive,
        'has_started': hasStarted,
        'draw_deck': drawDeck?.toMapList(),
        'discard_deck': discardDeck?.toMapList(),
        'turn': turn,
        'drawn_card': drawnCard?.toMap(),
        'turn_start_time': turnStartTime?.toUtc().toIso8601String(),
        'power_start_time': powerStartTime?.toUtc().toIso8601String(),
        'is_challenge_complete': isChallengeComplete,
        'winner': winner == null
            ? null
            : {
                ...winner!.toMap(),
                if (endReason != null) 'end_reason': endReason,
              },
      };

  factory GameModel.fromJson(String data) {
    return GameModel.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  GameModel copyWith({
    List<PlayerMatchModel>? players,
    int? gameType,
    bool? isActive,
    bool? hasStarted,
    Object? drawDeck = _unset,
    Object? discardDeck = _unset,
    int? turn,
    Object? drawnCard = _unset,
    Object? turnStartTime = _unset,
    Object? powerStartTime = _unset,
    bool? isChallengeComplete,
    Object? winner = _unset,
    Object? endReason = _unset,
  }) {
    return GameModel(
      hostId: hostId,
      code: code,
      players: players ?? this.players,
      gameType: gameType ?? this.gameType,
      isActive: isActive ?? this.isActive,
      hasStarted: hasStarted ?? this.hasStarted,
      drawDeck: identical(drawDeck, _unset) ? this.drawDeck : drawDeck as Deck?,
      discardDeck: identical(discardDeck, _unset) ? this.discardDeck : discardDeck as Deck?,
      turn: turn ?? this.turn,
      drawnCard: identical(drawnCard, _unset) ? this.drawnCard : drawnCard as CardModel?,
      turnStartTime: identical(turnStartTime, _unset) ? this.turnStartTime : turnStartTime as DateTime?,
      powerStartTime: identical(powerStartTime, _unset) ? this.powerStartTime : powerStartTime as DateTime?,
      isChallengeComplete: isChallengeComplete ?? this.isChallengeComplete,
      winner: identical(winner, _unset) ? this.winner : winner as PlayerMatchModel?,
      endReason: identical(endReason, _unset) ? this.endReason : endReason as String?,
    );
  }
}
