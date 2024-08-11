import 'package:five_minus/core/service/authentication_service.dart';
import 'package:five_minus/core/utility/dialog_utility.dart';
import 'package:five_minus/core/utility/loading_overlay_utility.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class LoginController {
  static const String routeName = '/LoginController';
  static Widget screen() {
    return LoginScreen(controller: LoginController._());
  }

  LoginController._();

  void signInEmailPassword(final BuildContext context, {required String emailAddress, required String password}) async {
    LoadingOverlay().show(context);
    await AuthenticationService.signInEmailPassword(context, emailAddress: emailAddress, password: password);
    LoadingOverlay().hide();
  }

  void signInGoogle(BuildContext context) async {
    LoadingOverlay().show(context);
    bool res = await AuthenticationService.signInGoogle();
    LoadingOverlay().hide();
    if (!res) {
      if (context.mounted) DialogUtility().showError(context, title: 'Login error', message: 'Invalid Credential');
    }
  }
}
