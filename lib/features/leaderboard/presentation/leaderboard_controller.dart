import 'package:five_minus/features/auth_game_services/data/aug_data_repository.dart';
import 'package:flutter/material.dart';

import 'leaderboard_screen.dart';

class LeaderboardController {
  static const String routeName = '/LeaderboardController';
  static Widget screen() {
    return LeaderboardScreen(controller: LeaderboardController._());
  }

  final AugDataRepository _augDataRepository = AugDataRepository();
  LeaderboardController._();

  String getPlayerId() {
    return _augDataRepository.getUserInfoLocal().fold(
      (l) {
        return '';
      },
      (playerId) {
        return playerId;
      },
    );
  }
}
