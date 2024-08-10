import 'package:flutter/material.dart';

import '../component/template/dialog_template_view.dart';

class LoadingOverlay {
  OverlayEntry? _overlay;

  static LoadingOverlay? _instance;

  LoadingOverlay._internal() {
    debugPrint('instance of Loading Overlay created');
    _instance = this;
  }

  factory LoadingOverlay() => _instance ?? LoadingOverlay._internal();

  void show(BuildContext context, {bool isDismissable = false}) {
    if (_overlay == null) {
      _overlay = OverlayEntry(
        builder: (context) => GestureDetector(
          onTap: () {
            if (isDismissable) hide();
          },
          child: ColoredBox(
            color: const Color(0x80000000),
            child: GestureDetector(
              onTap: () {},
              child: const DialogTemplateView(
                title: 'Loading...',
                layout: LinearProgressIndicator(),
                layoutPadding: EdgeInsets.only(
                  top: 12,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_overlay!);
    }
  }

  void hide() {
    if (_overlay != null) {
      _overlay?.remove();
      _overlay = null;
    }
  }
}
