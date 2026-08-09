import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:five_minus/features/auth_game_services/model/firebase_user_model.dart';
import 'package:five_minus/features/gameplay/model/card_model.dart';

class PlayerMatchModel extends Equatable {
  final String? playerId;
  final FirebaseUserModel? loadedPlayer;
  final bool? isReady;
  final List<CardModel>? playerHand;
  final bool? isChallengedDeclard;

  const PlayerMatchModel({
    this.playerId,
    this.loadedPlayer,
    this.isReady = false,
    this.playerHand,
    this.isChallengedDeclard = false,
  });

  factory PlayerMatchModel.fromMap(Map<String, dynamic> data) {
    return PlayerMatchModel(
      playerId: (data['player_id'] as String?) ?? (data['playerId'] as String?),
      isReady: data['isReady'] as bool?,
      playerHand: (data['player_hand'] as List<dynamic>?)
          ?.map((e) => CardModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isChallengedDeclard: data['is_challenge_declared'] as bool?,
    );
  }

  Map<String, dynamic> toMap() => {
        'player_id': playerId,
        'isReady': isReady,
        'player_hand': playerHand?.map((x) => x.toMap()).toList() ?? [],
        'is_challenge_declared': isChallengedDeclard,
      };

  factory PlayerMatchModel.fromJson(String data) {
    return PlayerMatchModel.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  PlayerMatchModel copyWith({
    String? playerId,
    FirebaseUserModel? loadedPlayer,
    bool? isReady,
    List<CardModel>? playerHand,
    bool? isChallengedDeclard,
  }) {
    return PlayerMatchModel(
      playerId: playerId ?? this.playerId,
      loadedPlayer: loadedPlayer ?? this.loadedPlayer,
      isReady: isReady ?? this.isReady,
      playerHand: playerHand ?? this.playerHand,
      isChallengedDeclard: isChallengedDeclard ?? this.isChallengedDeclard,
    );
  }

  @override
  List<Object?> get props => [playerId, isReady, playerHand, isChallengedDeclard];
}
