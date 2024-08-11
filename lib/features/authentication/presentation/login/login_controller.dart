import 'package:flutter/material.dart';

import 'login_screen.dart';

class LoginController {
  static const String routeName = '/LoginController';
  static Widget screen() {
    return LoginScreen(controller: LoginController._());
  }

  LoginController._();
}
