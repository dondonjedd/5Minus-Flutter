import 'package:dotted_border/dotted_border.dart';
import 'package:five_minus/features/gameplay/active_game/presentation/cubit/match_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../resource/asset_path.dart';
import '../../model/card_model.dart';
import '../../model/game_model.dart';

class DiscardPile extends StatelessWidget {
  const DiscardPile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<CardModel>(
        onAcceptWithDetails: (details) {},
        builder: (ctx, candidateData, rejectedData) {
          return BlocBuilder<MatchCubit, GameModel?>(
            builder: (context, state) {
              List<CardModel> discardPileCardList = state?.discardDeck?.cardDeck ?? [];
              return DottedBorder(
                color: candidateData.isNotEmpty ? Colors.black : Colors.white,
                borderType: BorderType.Circle,
                child: (discardPileCardList.isNotEmpty)
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: candidateData.isNotEmpty ? Colors.black.withOpacity(0.15) : null,
                        ),
                        height: double.infinity,
                        width: double.infinity,
                        child: UnconstrainedBox(
                          child: SizedBox(
                            height: 70,
                            child: Stack(
                              children: [
                                Image.asset(
                                  AssetPath.discardPile4Plus,
                                  fit: BoxFit.contain,
                                ),
                                Positioned(
                                  right: 0,
                                  left: 0,
                                  bottom: 0,
                                  top: 0,
                                  child: UnconstrainedBox(
                                    child: Container(
                                      width: 40,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: Colors.grey, width: 0.5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${discardPileCardList.last.suit?.asCharacter}\n${discardPileCardList.last.rank?.asCharacter}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: discardPileCardList.last.suit?.color, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: candidateData.isNotEmpty ? Colors.black.withOpacity(0.15) : null,
                          shape: BoxShape.circle,
                        ),
                      ),
              );
            },
          );
        });
  }
}
