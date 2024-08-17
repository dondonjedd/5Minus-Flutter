import 'package:flutter/material.dart';

import '../../../core/utility/dialog_utility.dart';
import '../../../core/utility/loading_overlay_utility.dart';
import '../../authentication/data/auth_repository_data.dart';
import 'dashboard_screen.dart';

class DashboardController {
  static const String routeName = '/DashboardController';
  static Widget screen() {
    return DashboardScreen(controller: DashboardController._());
  }

  DashboardController._();

  AuthRepositoryData repositoryData = AuthRepositoryData();

  void signOut(final BuildContext context) async {
    LoadingOverlay().show(context);

    final result = await repositoryData.signOut();
    LoadingOverlay().hide();

    result.fold(
      (failure) {
        DialogUtility().showError(context, title: failure.title, message: failure.errorMessage, type: failure.type);
      },
      (success) {},
    );
  }
}
