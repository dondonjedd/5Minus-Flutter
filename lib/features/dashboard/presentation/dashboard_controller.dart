import 'package:five_minus/features/auth_game_services/data/aug_data_repository.dart';
import 'package:five_minus/features/settings/presentation/settings_controller.dart';
import 'package:five_minus/model/pgs_user_model.dart';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';
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

  navigateLeaderboard(BuildContext context) {
    // context.goNamed(LeaderboardController.routeName);
    GamesServices.showLeaderboards();
  }

  PgsUserModel? getUserDetails() {
    final res = _augDataRepository.getUserInfoLocal();
    PgsUserModel? user = res.fold(
      (failure) {
        return null;
      },
      (success) {
        return PgsUserModel.fromJson(success);
      },
    );
    return user;
  }
}
