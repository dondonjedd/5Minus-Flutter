import 'package:flutter/material.dart';

import '../../../screen_template_view.dart';
import 'verify_email_controller.dart';

class VerifyEmailScreen extends StatelessWidget {
  final VerifyEmailController controller;

  const VerifyEmailScreen({super.key, required this.controller});
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
            const Text(
              'Email Verification Sent!\nPlease check your email for verification and then click ‘Next’',
              textAlign: TextAlign.center,
            ),
            const Padding(padding: EdgeInsets.only(bottom: 24)),
            ElevatedButton(
              onPressed: () {
                controller.next(context);
              },
              style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
              child: const Text('Next'),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 12)),
            ElevatedButton(
              onPressed: () {
                controller.sendAnotherLink(context);
              },
              style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
              child: const Text('Send another link'),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 12)),
            ElevatedButton(
              onPressed: () {
                controller.signOut(context);
              },
              style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
              child: const Text('Logout'),
            ),
          ],
        )),
      ),
    );
  }
}
