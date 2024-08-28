import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerMatchModel {
  DocumentReference<Map<String, dynamic>>? player;
  bool? isReady;

  PlayerMatchModel({this.player, this.isReady = false});

  factory PlayerMatchModel.fromMap(Map<String, dynamic> data) {
    return PlayerMatchModel(
      player: data['player'] as DocumentReference<Map<String, dynamic>>?,
      isReady: data['isReady'] as bool?,
    );
  }

  Map<String, dynamic> toMap() => {
        'player': player,
        'isReady': isReady,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [PlayerMatchModel].
  factory PlayerMatchModel.fromJson(String data) {
    return PlayerMatchModel.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [PlayerMatchModel] to a JSON string.
  String toJson() => json.encode(toMap());

  PlayerMatchModel copyWith({
    DocumentReference<Map<String, dynamic>>? player,
    bool? isReady,
  }) {
    return PlayerMatchModel(
      player: player ?? this.player,
      isReady: isReady ?? this.isReady,
    );
  }
}
