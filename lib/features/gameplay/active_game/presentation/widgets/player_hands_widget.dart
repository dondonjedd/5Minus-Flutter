import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../enums/enum_card_power.dart';
import '../../../model/game_model.dart';
import 'back_card_widget.dart';
import 'front_card_widget.dart';
import '../cubit/match_cubit.dart';

enum HandInteractionMode {
  none,
  replace,
  eliminate,
  queenLook,
  jackPick,
}

class PlayerHands extends StatelessWidget {
  const PlayerHands({
    super.key,
    required this.playerIndex,
    this.isOpponent = false,
    this.mode = HandInteractionMode.none,
    this.revealedIndexes = const {},
    this.onCardTap,
    this.onCardDoubleTap,
    this.jackSelected,
  });

  final int playerIndex;
  final bool isOpponent;
  final HandInteractionMode mode;
  final Set<int> revealedIndexes;
  final void Function(int handIndex)? onCardTap;
  final void Function(int handIndex)? onCardDoubleTap;
  final Set<String>? jackSelected; // "playerIndex:handIndex"

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchCubit, GameModel?>(
      builder: (context, state) {
        final hand = state?.players[playerIndex].playerHand ?? [];
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: hand.length,
          itemBuilder: (context, index) {
            final showFront = revealedIndexes.contains(index);
            final selected = jackSelected?.contains('$playerIndex:$index') ?? false;
            final singleTappable = onCardTap != null && _isInteractive(mode, isOpponent);
            final doubleTappable = onCardDoubleTap != null && !isOpponent;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: singleTappable ? () => onCardTap!(index) : null,
                onDoubleTap: doubleTappable ? () => onCardDoubleTap!(index) : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    showFront ? FrontCard(cardModel: hand[index]) : BackCard(cardModel: hand[index]),
                    if (selected)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isInteractive(HandInteractionMode mode, bool opponent) {
    switch (mode) {
      case HandInteractionMode.replace:
      case HandInteractionMode.eliminate:
        return !opponent;
      case HandInteractionMode.queenLook:
        return true;
      case HandInteractionMode.jackPick:
        return true;
      case HandInteractionMode.none:
        return false;
    }
  }
}

String powerHint(CardPower power) {
  switch (power) {
    case CardPower.look:
      return 'Queen: tap any card to look';
    case CardPower.swap:
      return 'Jack: tap two cards to swap';
    case CardPower.sabotage:
      return 'Black King: dealt a card to opponent';
    case CardPower.none:
      return '';
  }
}
