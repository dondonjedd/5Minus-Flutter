import 'package:flutter/material.dart';

import '../../../../core/component/template/screen_template_view.dart';
import 'username_controller.dart';

class UsernameScreen extends StatelessWidget {
  final UsernameController controller;
  UsernameScreen({super.key, required this.controller});
  final TextEditingController usernameInputController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ScreenTemplateView(
      layout: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
            child: Form(
          key: formKey,
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.25,
              ),
              Container(
                width: 500,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                ),
                child: TextFormField(
                  controller: usernameInputController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.name,
                  style: const TextStyle(color: Colors.black),
                  onTapOutside: (event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  decoration: const InputDecoration(
                    label: Text(
                      'Username',
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Username is required';
                    }
                    if ((value?.length ?? 0) < 5) {
                      return 'Username must contain at least 5 characters';
                    }

                    if ((value?.length ?? 0) > 10) {
                      return 'Username must contain a maximum of 10 characters';
                    }
                    return null;
                  },
                ),
              ),
              const Padding(padding: EdgeInsets.only(bottom: 12)),
              ElevatedButton(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  controller.submit(context, usernameInputController.text);
                },
                style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(300, 45))),
                child: const Text('Submit'),
              ),
              const Padding(padding: EdgeInsets.only(bottom: 12)),
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
          ),
        )),
      ),
    );
  }
}
