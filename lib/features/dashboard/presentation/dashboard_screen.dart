import 'package:flutter/material.dart';
import '../../../core/component/template/screen_template_view.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardController controller;
  const DashboardScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return ScreenTemplateView(
      layout: Center(
          child: ElevatedButton(
              onPressed: () {
                controller.signOut(context);
              },
              child: const Text('Logout'))),
    );
  }
}
