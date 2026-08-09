import 'package:five_minus/core/service/supabase_service.dart';
import 'package:five_minus/core/utility/dialog_utility.dart';
import 'package:five_minus/core/utility/loading_overlay_utility.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../gameplay/model/lobby_params.dart';
import '../../gameplay/lobby/presentation/lobby_controller.dart';
import 'join_game_screen.dart';

class JoinGameController {
  static const String routeName = '/JoinGameController';
  static Widget screen() {
    return JoinGameScreen(controller: JoinGameController._());
  }

  joinGame(BuildContext context, String gameCode) async {
    LoadingOverlay().show(context);
    if (!(await isGameExist(gameCode))) {
      LoadingOverlay().hide();
      if (!context.mounted) return;
      DialogUtility().showError(context, title: 'Game does not exist', message: 'Please try another code');
      return;
    }
    LoadingOverlay().hide();
    if (!context.mounted) return;
    context.goNamed(LobbyController.routeName, extra: LobbyParams(isCreateGame: false, gameCode: gameCode));
  }

  //VERIFY IF GAME EXISTS
  Future<bool> isGameExist(String gameCode) async {
    final res = await SupabaseService.client.from('matches').select('game_code').eq('game_code', gameCode).maybeSingle();
    return res != null;
  }

  JoinGameController._();
}
