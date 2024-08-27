import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GameModel extends Equatable {
  final String hostId;
  final String code;
  final List<DocumentReference<Map<String, dynamic>>>? players;
  final int? gameType;

  const GameModel({required this.hostId, required this.code, this.players, this.gameType});

  factory GameModel.fromMap(Map<String, dynamic> data) => GameModel(
        hostId: (data['host_id'] as String?) ?? '',
        code: (data['game_code'] as String?) ?? '',
        players: (data['players'] as List<dynamic>?)?.map(
          (e) {
            return e as DocumentReference<Map<String, dynamic>>;
          },
        ).toList(),
        gameType: data['game_type'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'host_id': hostId,
        'game_code': code,
        'players': players,
        'game_type': gameType,
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
    List<DocumentReference<Map<String, dynamic>>>? players,
    int? gameType,
  }) {
    return GameModel(
      hostId: hostId,
      code: code,
      players: players ?? this.players,
      gameType: gameType ?? this.gameType,
    );
  }

  @override
  // TODO: implement props
  List<Object?> get props => [code];
}
