import 'package:flutter/material.dart';

import '../../../core/component/template/screen_template_view.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController controller;
  const SettingsScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return ScreenTemplateView(
      layout: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
            child: Column(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.25,
            ),
            ElevatedButton(
              onPressed: () {
                controller.signOut(context);
              },
              style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
              child: const Text('Logout'),
            ),
            const SizedBox(
              height: 200,
            ),
          ],
        )),
      ),
    );
  }
}
