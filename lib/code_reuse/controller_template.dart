import 'package:flutter/material.dart';

import '../core/component/template/screen_template_view.dart';

class Controller {
  static const String routeName = '/Controller';
  static Widget screen() {
    return Screen(controller: Controller._());
  }

  Controller._();
}

class Screen extends StatelessWidget {
  final Controller controller;
  const Screen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return const ScreenTemplateView(
      infoTitle: 'title',
      layout: Center(child: Text('layout')),
    );
  }
}
