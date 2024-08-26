import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../utility/dialog_utility.dart';
import '../../../../../utility/loading_overlay_utility.dart';
import '../../../../../../go_router.dart';
import '../../data/auth_repository_data.dart';
import '../../model/user_model.dart';
import 'username_screen.dart';

class UsernameController {
  static const String routeName = '/UsernameController';
  static Widget screen() {
    return UsernameScreen(controller: UsernameController._());
  }

  AuthRepositoryData repositoryData = AuthRepositoryData();

  UsernameController._();
  void signOut(final BuildContext context) async {
    LoadingOverlay().show(context);
    final result = await repositoryData.signOut();
    LoadingOverlay().hide();
    await result.fold(
      (failure) {
        DialogUtility().showError(context, title: failure.title, message: failure.errorMessage, type: failure.type);
      },
      (success) async {
        await repositoryData.clearAuth();
      },
    );
    LoadingOverlay().hide();
    RouterInstance().goRoute?.refresh();
  }

  submit(BuildContext context, String username) async {
    if (username.isEmpty) return;
    LoadingOverlay().show(context);
    final userRes = repositoryData.getUserDetails();

    await userRes.fold(
      (failure) {
        DialogUtility().showError(context, title: failure.title, message: failure.errorMessage);
      },
      (userModel) async {
        UserModel? newUserModel = userModel?.copyWith(username: username);
        final result = await repositoryData.updateUserNetwork(newUserModel);

        await result.fold(
          (failure) {
            DialogUtility().showError(context, title: failure.title, message: failure.errorMessage, type: failure.type);
          },
          (success) async {
            await repositoryData.setUserDetails(userModel: newUserModel);
          },
        );
      },
    );

    await FirebaseAuth.instance.currentUser?.reload();
    LoadingOverlay().hide();
    if (!context.mounted) return;
    context.go('/');
  }
}
