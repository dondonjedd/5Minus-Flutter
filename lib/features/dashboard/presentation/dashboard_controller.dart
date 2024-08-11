import 'package:flutter/material.dart';

import '../../../core/service/authentication_service.dart';
import 'dashboard_screen.dart';

class DashboardController {
  static const String routeName = '/DashboardController';
  static Widget screen() {
    return DashboardScreen(controller: DashboardController._());
  }

  DashboardController._();

  void signOut(final BuildContext context) async {
    AuthenticationService.signOut();
  }
}
