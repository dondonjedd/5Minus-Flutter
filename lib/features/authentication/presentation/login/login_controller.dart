import 'package:five_minus/core/service/authentication_service.dart';
import 'package:five_minus/core/utility/dialog_utility.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class LoginController {
  static const String routeName = '/LoginController';
  static Widget screen() {
    return LoginScreen(controller: LoginController._());
  }

  LoginController._();

  void signInEmailPassword(final BuildContext context, {required String emailAddress, required String password}) async {
    bool res = await AuthenticationService.signInEmailPassword(emailAddress: emailAddress, password: password);
    if (!res) {
      if (context.mounted) DialogUtility().showError(context, title: 'Login error', message: 'Invalid Credential');
    }
  }

  void signInGoogle(BuildContext context) async {
    bool res = await AuthenticationService.signInGoogle();
    if (!res) {
      if (context.mounted) DialogUtility().showError(context, title: 'Login error', message: 'Invalid Credential');
    }
  }
}
