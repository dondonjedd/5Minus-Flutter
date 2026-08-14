import 'package:flutter/material.dart';

import '../../../model/card_model.dart';

class FrontCard extends StatelessWidget {
  const FrontCard({
    super.key,
    required this.cardModel,
    this.tight = false,
  });

  final CardModel cardModel;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 40,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Center(
        child: Text(
          '${cardModel.suit?.asCharacter}\n${cardModel.rank?.asCharacter}',
          textAlign: TextAlign.center,
          style: TextStyle(color: cardModel.suit?.color, fontWeight: FontWeight.bold),
        ),
      ),
    );
    return tight ? card : UnconstrainedBox(child: card);
  }
}
