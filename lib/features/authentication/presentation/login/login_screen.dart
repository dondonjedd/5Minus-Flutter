import 'package:five_minus/resource/asset_path.dart';
import 'package:flutter/material.dart';

import '../../../../core/component/button/text_button_component.dart';
import '../../../../core/component/input/text_input_component.dart';
import '../../../../core/component/template/screen_template_view.dart';
import 'login_controller.dart';

class LoginScreen extends StatelessWidget {
  final LoginController controller;
  final TextEditingController emailInputController = TextEditingController();
  final TextEditingController passwordInputController = TextEditingController();
  LoginScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return ScreenTemplateView(
      enableOverlapHeader: true,
      layout: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.25,
              ),
              //email
              Container(
                width: 500,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                ),
                child: TextInputComponent.email(
                  controller: emailInputController,
                  label: 'Email',
                  prefixIcon: SizedBox.square(
                    dimension: 24,
                    child: Center(
                      child: Image.asset(
                        AssetPath.avatar,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  style: TextInputStyle.fill,
                ),
              ),
              //password
              Container(
                width: 500,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                ),
                child: SecureTextInputComponent(
                    controller: passwordInputController,
                    backgroundColor: Theme.of(context).colorScheme.onPrimary,
                    style: TextInputStyle.fill,
                    prefixIcon: SizedBox.square(
                      dimension: 24,
                      child: Center(
                        child: Image.asset(
                          AssetPath.lock,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    label: 'Password'),
              ),

              //sign in
              TextButtonComponent(
                margin: const EdgeInsets.symmetric(
                  horizontal: 32,
                ),
                minimumWidth: 300,
                title: 'Login',
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                style: TextButtonStyle.elevated,
                onPressed: () {
                  controller.signInEmailPassword(context, emailAddress: emailInputController.text, password: passwordInputController.text);
                },
              ),
              //sign up
              TextButtonComponent(
                margin: const EdgeInsets.symmetric(
                  horizontal: 32,
                ),
                minimumWidth: 300,
                title: 'Register',
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                style: TextButtonStyle.elevated,
                onPressed: () {
                  controller.registerEmailPassword(context, emailAddress: emailInputController.text, password: passwordInputController.text);
                },
              ),
              //sign in or sign up with google
              TextButtonComponent(
                margin: const EdgeInsets.symmetric(
                  horizontal: 32,
                ),
                minimumWidth: 300,
                title: 'Login/Register With Google',
                prefixIcon: Image.asset(
                  AssetPath.googleIcon,
                  fit: BoxFit.contain,
                  width: 24,
                  height: 24,
                ),
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                style: TextButtonStyle.elevated,
                onPressed: () {
                  controller.signInGoogle(context);
                },
              ),
              const SizedBox(
                height: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
