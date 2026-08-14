import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../enums/enum_card_power.dart';
import '../../../model/card_model.dart';
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
    this.cardKeyFor,
    this.hollowIndexes = const {},
    this.hollowIsExtra = false,
    this.hollowCollapsing = false,
  });

  final int playerIndex;
  final bool isOpponent;
  final HandInteractionMode mode;
  final Set<int> revealedIndexes;
  final void Function(int handIndex)? onCardTap;
  final void Function(int handIndex)? onCardDoubleTap;
  final Set<String>? jackSelected; // "playerIndex:handIndex"
  final GlobalKey Function(int handIndex)? cardKeyFor;
  final Set<int> hollowIndexes;
  final bool hollowIsExtra;
  final bool hollowCollapsing;

  static const Duration collapseDuration = Duration(milliseconds: 800);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchCubit, GameModel?>(
      builder: (context, state) {
        final hand = state?.players[playerIndex].playerHand ?? [];
        final extra = hollowIsExtra && hollowIndexes.isNotEmpty;
        final extraIndex = extra ? hollowIndexes.first : null;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: hand.length + (extra ? 1 : 0),
          itemBuilder: (context, visualIndex) {
            if (extra && visualIndex == extraIndex) {
              return _hollowSlot(visualIndex);
            }
            final handIndex = extra && visualIndex > extraIndex! ? visualIndex - 1 : visualIndex;
            final hide = !extra && hollowIndexes.contains(handIndex);
            final showFront = revealedIndexes.contains(handIndex);
            final selected = jackSelected?.contains('$playerIndex:$handIndex') ?? false;
            final singleTappable = onCardTap != null && _isInteractive(mode, isOpponent);
            final doubleTappable = onCardDoubleTap != null && !isOpponent;
            final useFlightKey = cardKeyFor != null && !extra;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.center,
                child: KeyedSubtree(
                  key: useFlightKey ? cardKeyFor!(handIndex) : ValueKey(_cardId(hand[handIndex])),
                  child: SizedBox(
                    width: 40,
                    height: 60,
                    child: hide
                        ? null
                        : GestureDetector(
                            onTap: singleTappable ? () => onCardTap!(handIndex) : null,
                            onDoubleTap: doubleTappable ? () => onCardDoubleTap!(handIndex) : null,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                showFront ? FrontCard(cardModel: hand[handIndex]) : BackCard(cardModel: hand[handIndex]),
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
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _hollowSlot(int index) {
    return Align(
      alignment: Alignment.center,
      child: AnimatedContainer(
        key: cardKeyFor?.call(index),
        duration: collapseDuration,
        curve: Curves.easeInOutCubic,
        width: hollowCollapsing ? 0 : 56,
        height: 60,
      ),
    );
  }

  String _cardId(CardModel card) {
    return '${card.suit?.internalRepresentation}-${card.rank?.internalRepresentation}';
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
