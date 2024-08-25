import 'package:five_minus/features/auth_game_services/data/aug_data_repository.dart';
import 'package:five_minus/features/settings/presentation/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dashboard_screen.dart';

class DashboardController {
  static const String routeName = '/DashboardController';
  static Widget screen() {
    return DashboardScreen(controller: DashboardController._());
  }

  DashboardController._();

  final AugDataRepository _augDataRepository = AugDataRepository();

  navigateSettings(BuildContext context) {
    context.goNamed(SettingsController.routeName);
  }

  // UserModel? getUserDetails() {
  //   final res = _augDataRepository.getUserDetails();
  //   UserModel? user = res.fold(
  //     (failure) {
  //       return null;
  //     },
  //     (success) {
  //       return success;
  //     },
  //   );
  //   return user;
  // }
}
