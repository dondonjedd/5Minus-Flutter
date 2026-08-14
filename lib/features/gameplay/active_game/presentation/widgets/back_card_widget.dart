import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/data/configuration_data.dart';
import '../../../../../resource/asset_path.dart';
import '../../../model/card_model.dart';
import 'front_card_widget.dart';

class BackCard extends StatelessWidget {
  const BackCard({
    super.key,
    this.cardModel,
  });

  final CardModel? cardModel;

  static bool get _revealHidden => kDebugMode && ConfigurationData.revealHiddenCards;

  @override
  Widget build(BuildContext context) {
    final model = cardModel;
    if (_revealHidden && model != null && model.rank != null && model.suit != null) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
        child: FrontCard(cardModel: model),
      );
    }
    return UnconstrainedBox(child: SizedBox(height: 60, child: Image.asset(AssetPath.backCard)));
  }
}
