import 'package:dotted_border/dotted_border.dart';
import 'package:five_minus/features/gameplay/active_game/presentation/cubit/match_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../resource/asset_path.dart';
import '../../../model/card_model.dart';
import '../../../model/game_model.dart';
import 'front_card_widget.dart';

class DiscardPile extends StatelessWidget {
  const DiscardPile({
    super.key,
    this.highlighted = false,
  });

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchCubit, GameModel?>(
      builder: (context, state) {
        List<CardModel> discardPileCardList = state?.discardDeck?.cardDeck ?? [];
        return DottedBorder(
          color: highlighted ? Colors.black : Colors.white,
          borderType: BorderType.Circle,
          child: (discardPileCardList.isNotEmpty)
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlighted ? Colors.black.withValues(alpha: 0.15) : null,
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
                            child: FrontCard(cardModel: discardPileCardList.last),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: highlighted ? Colors.black.withValues(alpha: 0.15) : null,
                    shape: BoxShape.circle,
                  ),
                ),
        );
      },
    );
  }
}
