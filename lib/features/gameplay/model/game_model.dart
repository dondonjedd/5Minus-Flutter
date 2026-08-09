import 'dart:convert';

import 'package:five_minus/features/gameplay/model/deck_model.dart';
import 'package:five_minus/features/gameplay/model/player_match_model.dart';

import 'card_model.dart';

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
  });

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory GameModel.fromMap(Map<String, dynamic> data) => GameModel(
        hostId: (data['host_id'] as String?) ?? '',
        code: (data['game_code'] as String?) ?? '',
        players: (data['players'] as List<dynamic>?)?.map(
              (e) {
                return PlayerMatchModel.fromMap(Map<String, dynamic>.from(e as Map));
              },
            ).toList() ??
            [],
        gameType: data['game_type'] as int?,
        isActive: (data['is_active'] as bool?) ?? false,
        hasStarted: (data['has_started'] as bool?) ?? false,
        drawDeck: data['draw_deck'] is! List<dynamic> ? null : Deck.fromMapList(data['draw_deck']),
        discardDeck: data['discard_deck'] is! List<dynamic> ? null : Deck.fromMapList(data['discard_deck']),
        turn: data['turn'] as int?,
        drawnCard: data['drawn_card'] == null
            ? null
            : CardModel.fromMap(Map<String, dynamic>.from(data['drawn_card'] as Map)),
        turnStartTime: _parseDateTime(data['turn_start_time']),
        powerStartTime: _parseDateTime(data['power_start_time']),
        isChallengeComplete: (data['is_challenge_complete'] as bool?) ?? false,
        winner: data['winner'] == null
            ? null
            : PlayerMatchModel.fromMap(Map<String, dynamic>.from(data['winner'] as Map)),
      );

  Map<String, dynamic> toMap() => {
        'host_id': hostId,
        'game_code': code,
        'players': players.map((e) => e.toMap()).toList(),
        'game_type': gameType,
        'is_active': isActive,
        'has_started': hasStarted,
        'draw_deck': drawDeck?.toMapList(),
        'discard_deck': discardDeck?.toMapList(),
        'turn': turn,
        'drawn_card': drawnCard?.toMap(),
        'turn_start_time': turnStartTime?.toIso8601String(),
        'power_start_time': powerStartTime?.toIso8601String(),
        'is_challenge_complete': isChallengeComplete,
        'winner': winner?.toMap(),
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
    Deck? drawDeck,
    Deck? discardDeck,
    int? turn,
    CardModel? drawnCard,
    DateTime? turnStartTime,
    DateTime? powerStartTime,
    bool? isChallengeComplete,
    PlayerMatchModel? winner,
  }) {
    return GameModel(
        hostId: hostId,
        code: code,
        players: players ?? this.players,
        gameType: gameType ?? this.gameType,
        isActive: isActive ?? this.isActive,
        hasStarted: hasStarted ?? this.hasStarted,
        drawDeck: drawDeck ?? this.drawDeck,
        discardDeck: discardDeck ?? this.discardDeck,
        turn: turn ?? this.turn,
        drawnCard: drawnCard ?? this.drawnCard,
        turnStartTime: turnStartTime ?? this.turnStartTime,
        powerStartTime: powerStartTime ?? this.powerStartTime,
        isChallengeComplete: isChallengeComplete ?? this.isChallengeComplete,
        winner: winner ?? this.winner);
  }
}
