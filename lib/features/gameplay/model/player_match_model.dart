import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:five_minus/features/gameplay/model/card_model.dart';

class PlayerMatchModel {
  DocumentReference<Map<String, dynamic>>? player;
  bool? isReady;
  List<CardModel>? playerHand;
  bool? isChallengedDeclard;

  PlayerMatchModel({
    this.player,
    this.isReady = false,
    this.playerHand,
    this.isChallengedDeclard = false,
  });

  factory PlayerMatchModel.fromMap(Map<String, dynamic> data) {
    return PlayerMatchModel(
        player: data['player'] as DocumentReference<Map<String, dynamic>>?,
        isReady: data['isReady'] as bool?,
        playerHand: (data['player_hand'] as List<dynamic>?)?.map((e) => CardModel.fromMap(e)).toList(),
        isChallengedDeclard: data['is_challenge_declared'] as bool?);
  }

  Map<String, dynamic> toMap() => {
        'player': player,
        'isReady': isReady,
        'player_hand': playerHand?.map((x) => x.toMap()).toList() ?? [],
        'is_challenge_declared': isChallengedDeclard,
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
    List<CardModel>? playerHand,
    bool? isChallengedDeclard,
  }) {
    return PlayerMatchModel(
      player: player ?? this.player,
      isReady: isReady ?? this.isReady,
      playerHand: playerHand ?? this.playerHand,
      isChallengedDeclard: isChallengedDeclard ?? this.isChallengedDeclard,
    );
  }
}
