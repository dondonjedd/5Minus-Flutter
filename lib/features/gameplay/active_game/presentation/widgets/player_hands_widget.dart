import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../model/game_model.dart';
import 'back_card_widget.dart';
import '../cubit/match_cubit.dart';

class PlayerHands extends StatelessWidget {
  const PlayerHands({super.key, required this.playerIndex});

  final int playerIndex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchCubit, GameModel?>(
      builder: (context, state) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: state?.players[playerIndex].playerHand?.length ?? 0,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Draggable(
                feedback: Transform.rotate(
                  angle: 0.5,
                  child: const BackCard(),
                ),
                data: state?.players[playerIndex].playerHand?[index],
                childWhenDragging: const Opacity(
                  opacity: 0.5,
                  child: BackCard(),
                ),
                onDragCompleted: () {
                  // CardModel? cardDiscarded = state?.players[0].playerHand?.removeAt(index);
                  // state?.discardDeck?.cardDeck?.add(cardDiscarded);
                  context.read<MatchCubit>().discardHand(0, index);
                },
                onDragStarted: () {
                  // final audioController = context.read<AudioController>();
                  // audioController.playSfx(SfxType.huhsh);
                },
                onDragEnd: (details) {
                  // final audioController = context.read<AudioController>();
                  // audioController.playSfx(SfxType.wssh);
                },
                child: const BackCard(),
              ),
            );
          },
        );
      },
    );
  }
}
