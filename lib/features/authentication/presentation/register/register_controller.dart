import 'package:flutter/material.dart';

import 'register_screen.dart';

class RegisterController {
  static const String routeName = '/RegisterController';
  static Widget screen() {
    return RegisterScreen(controller: RegisterController._());
  }

  RegisterController._();
}
