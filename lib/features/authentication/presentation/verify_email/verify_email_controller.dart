import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/core/utility/loading_overlay_utility.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utility/dialog_utility.dart';
import '../../../../go_router.dart';
import '../../data/auth_repository_data.dart';
import 'verify_email_screen.dart';

class VerifyEmailController {
  static const String routeName = '/VerifyEmailController';
  static Widget screen() {
    return VerifyEmailScreen(controller: VerifyEmailController._());
  }

  AuthRepositoryData repositoryData = AuthRepositoryData();

  VerifyEmailController._();

  void next(BuildContext context) async {
    LoadingOverlay().show(context);
    await FirebaseAuth.instance.currentUser?.reload();
    LoadingOverlay().hide();
    if (!(FirebaseAuth.instance.currentUser?.emailVerified ?? false)) {
      if (!context.mounted) return;
      DialogUtility().showError(
        context,
        title: 'Email Not Verified',
        message: 'Please check your email for verification\nMake sure to check the spam/junk folder',
      );
    }
    if (!context.mounted) return;
    context.go('/');
  }

  void sendAnotherLink(BuildContext context) async {
    LoadingOverlay().show(context);
    final result = await repositoryData.sendEmailVerification();
    LoadingOverlay().hide();
    result.fold(
      (failure) {
        DialogUtility().showError(context, title: failure.title, message: failure.errorMessage, type: failure.type);
      },
      (success) {
        DialogUtility().showSuccess(
          context,
          title: 'Email verification sent',
          message: 'Please check your email for verification\nMake sure to check the spam/junk folder',
        );
      },
    );
  }

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
}
