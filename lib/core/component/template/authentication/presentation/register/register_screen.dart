import 'package:five_minus/core/component/input/password_form_field.dart';
import 'package:flutter/material.dart';

import '../../../screen_template_view.dart';
import 'register_controller.dart';

class RegisterScreen extends StatefulWidget {
  final RegisterController controller;
  const RegisterScreen({super.key, required this.controller});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController pwdController = TextEditingController();
  TextEditingController confirmPwdController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ScreenTemplateView(
      layout: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Padding(padding: EdgeInsets.only(bottom: 100)),
                //Email
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Container(
                        width: 500,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: emailController,
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
                      //Password
                      Container(
                        width: 500,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PasswordFormField(
                          passwordController: pwdController,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      //Confirm Password
                      Container(
                        width: 500,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PasswordFormField(
                          passwordController: confirmPwdController,
                          labelText: 'Confirm Password',
                          extraValidator: (val) {
                            if (val != pwdController.text) {
                              return 'Password does not match';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    widget.controller.registerEmailPassword(context, emailAddress: emailController.text, password: pwdController.text);
                  },
                  style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
                  child: const Text('Submit Registration'),
                ),
                const Padding(padding: EdgeInsets.only(bottom: 200)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
