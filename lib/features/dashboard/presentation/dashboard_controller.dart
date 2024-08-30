import 'package:five_minus/core/utility/loading_overlay_utility.dart';
import 'package:five_minus/features/auth_game_services/data/aug_data_repository.dart';
import 'package:five_minus/features/gameplay/model/lobby_params.dart';
import 'package:five_minus/features/gameplay/lobby/presentation/lobby_controller.dart';
import 'package:five_minus/features/join_game/presentation/join_game_controller.dart';
import 'package:five_minus/features/settings/presentation/settings_controller.dart';
import 'package:five_minus/features/auth_game_services/model/pgs_user_model.dart';
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

  navigateJoinGame(BuildContext context) {
    context.goNamed(JoinGameController.routeName);
  }

  navigateCreateGame(BuildContext context) {
    context.goNamed(LobbyController.routeName, extra: LobbyParams(isCreateGame: true));
  }

  bool _isLeaderboardShowng = false;
  navigateLeaderboard(BuildContext context) async {
    // context.goNamed(LeaderboardController.routeName);

    if (_isLeaderboardShowng == true) return;
    _isLeaderboardShowng = true;
    await GamesServices.showLeaderboards();
    await Future.delayed(const Duration(seconds: 1));
    _isLeaderboardShowng = false;
  }

  navigateSettings(BuildContext context) {
    context.goNamed(SettingsController.routeName);
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
