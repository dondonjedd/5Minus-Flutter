import 'package:flutter/material.dart';

import '../../../../../utility/dialog_utility.dart';
import '../../../../../utility/loading_overlay_utility.dart';
import '../../../../../../go_router.dart';
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
}
