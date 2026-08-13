import 'dart:convert';

import 'package:five_minus/features/gameplay/model/deck_model.dart';
import 'package:five_minus/features/gameplay/model/player_match_model.dart';

import 'card_model.dart';

const Object _unset = Object();

class GameModel {
  final String hostId;
  final String code;
  final List<PlayerMatchModel> players;
  final String status;
  final Deck? drawDeck;
  final Deck? discardDeck;
  final int? turn;
  final CardModel? drawnCard;
  final DateTime? turnStartTime;
  final DateTime? powerStartTime;
  final PlayerMatchModel? winner;
  final String? endReason;

  const GameModel({
    required this.hostId,
    required this.code,
    required this.players,
    this.status = 'lobby',
    this.drawDeck,
    this.discardDeck,
    this.turn,
    this.drawnCard,
    this.turnStartTime,
    this.powerStartTime,
    this.winner,
    this.endReason,
  });

  bool get isActive => status == 'active';
  bool get hasStarted => status != 'lobby';

  /// Timestamps are always normalised to UTC so that values read back from
  /// Postgres (`timestamptz`) compare equal to the ones written locally.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  factory GameModel.fromMap(Map<String, dynamic> data) {
    final players = (data['players'] as List<dynamic>?)
            ?.map((e) => PlayerMatchModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    final winnerId = data['winner_user_id'] as String?;
    PlayerMatchModel? winner;
    if (winnerId != null && winnerId.isNotEmpty) {
      winner = PlayerMatchModel(playerId: winnerId);
      for (final p in players) {
        if (p.playerId == winnerId) {
          winner = p;
          break;
        }
      }
    }
    return GameModel(
      hostId: (data['host_id'] as String?) ?? '',
      code: (data['game_code'] as String?) ?? '',
      players: players,
      status: (data['status'] as String?) ?? 'lobby',
      drawDeck: data['draw_deck'] is! List<dynamic> ? null : Deck.fromMapList(data['draw_deck']),
      discardDeck: data['discard_deck'] is! List<dynamic> ? null : Deck.fromMapList(data['discard_deck']),
      turn: (data['turn'] as num?)?.toInt(),
      drawnCard: data['drawn_card'] == null
          ? null
          : CardModel.fromMap(Map<String, dynamic>.from(data['drawn_card'] as Map)),
      turnStartTime: _parseDateTime(data['turn_start_time']),
      powerStartTime: _parseDateTime(data['power_start_time']),
      winner: winner,
      endReason: data['end_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'host_id': hostId,
        'game_code': code,
        'status': status,
      };

  factory GameModel.fromJson(String data) {
    return GameModel.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  GameModel copyWith({
    List<PlayerMatchModel>? players,
    String? status,
    Object? drawDeck = _unset,
    Object? discardDeck = _unset,
    int? turn,
    Object? drawnCard = _unset,
    Object? turnStartTime = _unset,
    Object? powerStartTime = _unset,
    Object? winner = _unset,
    Object? endReason = _unset,
  }) {
    return GameModel(
      hostId: hostId,
      code: code,
      players: players ?? this.players,
      status: status ?? this.status,
      drawDeck: identical(drawDeck, _unset) ? this.drawDeck : drawDeck as Deck?,
      discardDeck: identical(discardDeck, _unset) ? this.discardDeck : discardDeck as Deck?,
      turn: turn ?? this.turn,
      drawnCard: identical(drawnCard, _unset) ? this.drawnCard : drawnCard as CardModel?,
      turnStartTime: identical(turnStartTime, _unset) ? this.turnStartTime : turnStartTime as DateTime?,
      powerStartTime: identical(powerStartTime, _unset) ? this.powerStartTime : powerStartTime as DateTime?,
      winner: identical(winner, _unset) ? this.winner : winner as PlayerMatchModel?,
      endReason: identical(endReason, _unset) ? this.endReason : endReason as String?,
    );
  }
}
