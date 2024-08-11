import 'package:flutter/material.dart';

import '../../../../core/component/template/screen_template_view.dart';
import 'login_controller.dart';

class LoginScreen extends StatelessWidget {
  final LoginController controller;
  const LoginScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return const ScreenTemplateView(
      enableOverlapHeader: true,
      layout: Center(child: Text('layout')),
    );
  }
}
