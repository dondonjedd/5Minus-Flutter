import 'package:five_minus/resource/asset_path.dart';
import 'package:flutter/material.dart';

import '../../../core/component/template/screen_template_view.dart';
import 'authenticating_controller.dart';

class AuthenticatingScreen extends StatefulWidget {
  final AuthenticatingController controller;
  const AuthenticatingScreen({super.key, required this.controller});

  @override
  State<AuthenticatingScreen> createState() => _AuthenticatingScreenState();
}

class _AuthenticatingScreenState extends State<AuthenticatingScreen> {
  bool isAuthenticating = true;
  bool isSuccess = false;

  signIn() async {
    setState(() {
      isAuthenticating = true;
    });
    final res = await widget.controller.signInGamesServices(context);
    setState(() {
      isSuccess = res;
      isAuthenticating = false;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        await signIn();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenTemplateView(
      enableOverlapHeader: true,
      layout: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Image.asset(
                alignment: Alignment.center,
                width: 250,
                AssetPath.logoSplashScreen,
              ),
            ),
            Expanded(
              child: Text(
                isAuthenticating
                    ? 'Authenticating...'
                    : isSuccess
                        ? 'Login Successfull'
                        : 'Login Failed',
                textAlign: TextAlign.center,
              ),
            ),
            if (!isAuthenticating && !isSuccess)
              Expanded(
                child: UnconstrainedBox(
                  child: ElevatedButton(
                    onPressed: () async {
                      await signIn();
                    },
                    style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(200, 45))),
                    child: const Text('Try Again'),
                  ),
                ),
              ),
            const Padding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}
