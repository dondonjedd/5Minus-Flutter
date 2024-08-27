import 'package:flutter/material.dart';

import 'join_game_screen.dart';

class JoinGameController {
  static const String routeName = '/JoinGameController';
  static Widget screen() {
    return JoinGameScreen(controller: JoinGameController._());
  }

  JoinGameController._();
}
