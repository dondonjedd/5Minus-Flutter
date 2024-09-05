import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/features/gameplay/model/game_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../model/card_model.dart';
import '../../../model/deck_model.dart';

class MatchCubit extends Cubit<GameModel?> {
  MatchCubit() : super(null);
  final matchesCollection = FirebaseFirestore.instance.collection('matches');

  initalize(String? gameCode) async {
    if (gameCode == null) return null;

    GameModel? gameModel = GameModel.fromMap((await matchesCollection.doc(gameCode).get()).data() ?? {});

    Deck deck = Deck(generateNewRandomDeck: true);

    while (gameModel.players.any(
      (element) {
        return element.playerHand?.length != 4;
      },
    )) {
      for (var player in gameModel.players) {
        player.playerHand?.add(deck.getCardFromDeck());
      }
    }

    await matchesCollection.doc(gameModel.code).update({
      'draw_deck': deck.toMapList(),
      'discard_deck': [],
      'players': gameModel.players.map(
        (e) {
          return e.toMap();
        },
      ).toList(),
    });

    emit(GameModel.fromMap((await matchesCollection.doc(gameModel.code).get()).data() ?? {}));
  }

  bool isHost({String? uid}) {
    if (state?.hostId == null) return false;
    if (state!.hostId.isEmpty) return false;
    return state!.hostId == (uid ?? FirebaseAuth.instance.currentUser?.uid);
  }

  //DELETE GAME
  deleteGame() async {
    if (state?.code.isEmpty ?? true) return;
    await matchesCollection.doc(state?.code).delete();
  }

  //LEAVE GAME
  Future<void> leaveGame() async {
    if (state?.code == null || state?.players == null) return;
    if (state?.code.length != 4) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    state?.players.removeWhere(
      (element) {
        return element.player?.id == userId;
      },
    );
    if (userId != null) {
      await matchesCollection.doc(state?.code).set({
        'players': state?.players.map(
          (e) {
            return e.toMap();
          },
        ).toList()
      }, SetOptions(merge: true));
    }
  }

  bool updateFromFirestore(DocumentSnapshot<Map<String, dynamic>> event) {
    if (event.data() != null) {
      emit(GameModel.fromMap(event.data()!));
      return true;
    }
    return false;
  }

  //remove hand
  discardHand(int playerIndex, int cardIndex) async {
    GameModel? gameModel = state?.copyWith();
    CardModel? cardDiscarded = gameModel?.players[playerIndex].playerHand?.removeAt(cardIndex);
    if (cardDiscarded != null) gameModel?.discardDeck?.cardDeck?.add(cardDiscarded);

    await matchesCollection.doc(gameModel?.code).update({
      'discard_deck': gameModel?.discardDeck?.toMapList(),
      'players': gameModel?.players.map(
        (e) {
          return e.toMap();
        },
      ).toList(),
    });
  }
}
