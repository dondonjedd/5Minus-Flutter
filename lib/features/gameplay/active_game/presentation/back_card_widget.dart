import 'package:flutter/material.dart';

import '../../../../resource/asset_path.dart';

class BackCard extends StatelessWidget {
  const BackCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(child: SizedBox(height: 60, child: Image.asset(AssetPath.backCard)));
  }
}
