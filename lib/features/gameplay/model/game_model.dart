import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:five_minus/features/gameplay/model/deck_model.dart';
import 'package:five_minus/features/gameplay/model/player_match_model.dart';

class GameModel extends Equatable {
  final String hostId;
  final String code;
  final List<PlayerMatchModel> players;
  final int? gameType;
  final bool isActive;
  final Deck? drawDeck;
  final Deck? discardDeck;
  final int? turn;
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
    this.drawDeck,
    this.discardDeck,
    this.turn,
    this.turnStartTime,
    this.powerStartTime,
    this.isChallengeComplete = false,
    this.winner,
  });

  factory GameModel.fromMap(Map<String, dynamic> data) => GameModel(
        hostId: (data['host_id'] as String?) ?? '',
        code: (data['game_code'] as String?) ?? '',
        players: (data['players'] as List<dynamic>?)?.map(
              (e) {
                return PlayerMatchModel.fromMap(e);
              },
            ).toList() ??
            [],
        gameType: data['game_type'] as int?,
        isActive: (data['is_active'] as bool?) ?? false,
        drawDeck: data['draw_deck'] is! List<dynamic> ? null : Deck.fromMapList(data['draw_deck']),
        discardDeck: data['discard_deck'] is! List<dynamic> ? null : Deck.fromMapList(data['discard_deck']),
        turn: data['turn'],
        turnStartTime: DateTime.tryParse(
          data['turn_start_time'] ?? '',
        ),
        powerStartTime: DateTime.tryParse(
          data['power_start_time'] ?? '',
        ),
        isChallengeComplete: (data['is_challenge_complete'] as bool?) ?? false,
        winner: data['winner'],
      );

  Map<String, dynamic> toMap() => {
        'host_id': hostId,
        'game_code': code,
        'players': players.map(
          (e) {
            return e.toMap();
          },
        ).toList(),
        'game_type': gameType,
        'is_active': isActive,
        'draw_deck': drawDeck?.toMapList(),
        'discard_deck': discardDeck?.toMapList(),
        'turn': turn,
        'turn_start_time': turnStartTime,
        'power_start_time': powerStartTime,
        'is_challenge_complete': isChallengeComplete,
        'winner': winner
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [GameModel].
  factory GameModel.fromJson(String data) {
    return GameModel.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [GameModel] to a JSON string.
  String toJson() => json.encode(toMap());

  GameModel copyWith({
    List<PlayerMatchModel>? players,
    int? gameType,
    bool? isActive,
    Deck? drawDeck,
    Deck? discardDeck,
    int? turn,
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
        drawDeck: drawDeck ?? this.drawDeck,
        discardDeck: discardDeck ?? this.discardDeck,
        turn: turn ?? this.turn,
        turnStartTime: turnStartTime ?? this.turnStartTime,
        powerStartTime: powerStartTime ?? this.powerStartTime,
        isChallengeComplete: isChallengeComplete ?? this.isChallengeComplete,
        winner: winner ?? this.winner);
  }

  @override
  // TODO: implement props
  List<Object?> get props => [code];
}
