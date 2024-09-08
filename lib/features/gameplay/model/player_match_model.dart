import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:five_minus/features/auth_game_services/model/firebase_user_model.dart';
import 'package:five_minus/features/gameplay/model/card_model.dart';

class PlayerMatchModel extends Equatable {
  final DocumentReference<Map<String, dynamic>>? player;
  final FirebaseUserModel? loadedPlayer;
  final bool? isReady;
  final List<CardModel>? playerHand;
  final bool? isChallengedDeclard;

  const PlayerMatchModel({
    this.player,
    this.loadedPlayer,
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
    FirebaseUserModel? loadedPlayer,
    bool? isReady,
    List<CardModel>? playerHand,
    bool? isChallengedDeclard,
  }) {
    return PlayerMatchModel(
      player: player ?? this.player,
      loadedPlayer: loadedPlayer ?? this.loadedPlayer,
      isReady: isReady ?? this.isReady,
      playerHand: playerHand ?? this.playerHand,
      isChallengedDeclard: isChallengedDeclard ?? this.isChallengedDeclard,
    );
  }

  @override
  // TODO: implement props
  List<Object?> get props => [player, isReady, playerHand, isChallengedDeclard];
}
