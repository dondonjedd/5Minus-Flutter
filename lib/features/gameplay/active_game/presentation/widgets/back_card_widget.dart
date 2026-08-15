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
    this.tight = false,
  });

  final CardModel? cardModel;
  final bool tight;

  static bool get _revealHidden => kDebugMode && ConfigurationData.revealHiddenCards;

  @override
  Widget build(BuildContext context) {
    final model = cardModel;
    if (_revealHidden && model != null && model.rank != null && model.suit != null) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
        child: FrontCard(cardModel: model, tight: tight),
      );
    }
    final image = Image.asset(
      AssetPath.backCard,
      width: 40,
      height: 60,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    return tight ? image : UnconstrainedBox(child: image);
  }
}
