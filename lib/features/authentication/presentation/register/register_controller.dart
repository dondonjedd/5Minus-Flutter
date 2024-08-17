import 'package:flutter/material.dart';

import '../../../../core/utility/dialog_utility.dart';
import '../../../../core/utility/loading_overlay_utility.dart';
import '../../data/auth_repository_data.dart';
import 'register_screen.dart';

class RegisterController {
  static const String routeName = '/RegisterController';
  static Widget screen() {
    return RegisterScreen(controller: RegisterController._());
  }

  RegisterController._();
  AuthRepositoryData repositoryData = AuthRepositoryData();

  void registerEmailPassword(final BuildContext context, {required String emailAddress, required String password}) async {
    LoadingOverlay().show(context);

    final result = await repositoryData.registerEmailPassword(emailAddress: emailAddress, password: password);
    LoadingOverlay().hide();
    result.fold(
      (failure) {
        DialogUtility().showError(context, title: failure.title, message: failure.errorMessage, type: failure.type);
      },
      (success) {},
    );
  }
}
