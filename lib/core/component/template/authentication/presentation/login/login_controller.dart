import 'package:five_minus/core/utility/dialog_utility.dart';
import 'package:five_minus/core/utility/loading_overlay_utility.dart';
import 'package:five_minus/core/component/template/authentication/data/auth_repository_data.dart';
import 'package:five_minus/core/component/template/authentication/presentation/register/register_controller.dart';
import 'package:five_minus/go_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'login_screen.dart';

class LoginController {
  static const String routeName = '/LoginController';
  static Widget screen() {
    return LoginScreen(controller: LoginController._());
  }

  LoginController._();
  AuthRepositoryData repositoryData = AuthRepositoryData();

  void signInEmailPassword(final BuildContext context, {required String emailAddress, required String password}) async {
    LoadingOverlay().show(context);

    final result = await repositoryData.signInWithEmailAndPassword(emailAddress: emailAddress, password: password);
    await result.fold(
      (failure) {
        DialogUtility().showError(context, title: failure.title, message: failure.errorMessage, type: failure.type);
      },
      (userModel) async {
        if (userModel == null) return;
        await repositoryData.setUserDetails(userModel: userModel);
      },
    );
    LoadingOverlay().hide();
    RouterInstance().goRoute?.refresh();
  }

  void signInGoogle(BuildContext context) async {
    LoadingOverlay().show(context);
    final result = await repositoryData.signInGoogle();

    await result.fold(
      (failure) {
        DialogUtility().showError(context, title: failure.title, message: failure.errorMessage, type: failure.type);
      },
      (userModel) async {
        if (userModel == null) return;
        await repositoryData.setUserDetails(userModel: userModel);
      },
    );
    LoadingOverlay().hide();
    RouterInstance().goRoute?.refresh();
  }

  void navigateRegister(BuildContext context) async {
    context.goNamed(RegisterController.routeName);
  }
}
