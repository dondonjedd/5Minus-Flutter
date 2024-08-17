import 'package:flutter/material.dart';

import '../../../../core/component/template/screen_template_view.dart';
import 'register_controller.dart';

class RegisterScreen extends StatelessWidget {
  final RegisterController controller;
  const RegisterScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return const ScreenTemplateView(
      layout: Center(child: Text('layout')),
    );
  }
}
