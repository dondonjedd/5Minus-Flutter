import 'package:five_minus/core/component/input/password_form_field.dart';
import 'package:five_minus/resource/asset_path.dart';
import 'package:flutter/material.dart';

import '../../../../core/component/button/text_button_component.dart';
import '../../../../core/component/template/screen_template_view.dart';
import 'login_controller.dart';

class LoginScreen extends StatelessWidget {
  final LoginController controller;
  final TextEditingController emailInputController = TextEditingController();
  final TextEditingController passwordInputController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  LoginScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ScreenTemplateView(
      enableOverlapHeader: true,
      layout: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
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
                  child: TextFormField(
                    controller: emailInputController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Email is required';
                      }
                      return null;
                    },
                  ),
                ),

                const Padding(padding: EdgeInsets.only(bottom: 12)),
                //password
                Container(
                    width: 500,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                    ),
                    child: PasswordFormField(
                      passwordController: passwordInputController,
                      textInputAction: TextInputAction.next,
                    )),
                const Padding(padding: EdgeInsets.only(bottom: 12)),
                //sign in
                ElevatedButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    controller.signInEmailPassword(context, emailAddress: emailInputController.text, password: passwordInputController.text);
                  },
                  style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
                  child: const Text('Login'),
                ),
                //sign up
                const Padding(padding: EdgeInsets.only(bottom: 12)),
                ElevatedButton(
                  onPressed: () {
                    controller.navigateRegister(context);
                  },
                  style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
                  child: const Text('Register'),
                ),
                const Padding(padding: EdgeInsets.only(bottom: 12)),
                //sign in or sign up with google
                ElevatedButton(
                  onPressed: () {
                    controller.signInGoogle(context);
                  },
                  style: const ButtonStyle(
                    maximumSize: WidgetStatePropertyAll(
                      Size(300, 45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Image.asset(
                          AssetPath.googleIcon,
                          fit: BoxFit.contain,
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const Expanded(flex: 4, child: Text('Login/Register With Google')),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 200,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
