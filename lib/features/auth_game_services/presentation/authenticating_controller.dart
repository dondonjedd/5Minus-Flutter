import 'package:five_minus/features/auth_game_services/data/aug_data_repository.dart';
import 'package:five_minus/go_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'authenticating_screen.dart';

class AuthenticatingController {
  static const String routeName = '/AuthenticatingController';
  static Widget screen() {
    return AuthenticatingScreen(controller: AuthenticatingController._());
  }

  AuthenticatingController._();
  final AugDataRepository _augDataRepository = AugDataRepository();

  Future<bool> signInGamesServices(BuildContext context) async {
    final result = await _augDataRepository.signInPlayGamesServices();

    bool res = await result.fold(
      (failure) {
        return false;
      },
      (_) async {
        final result2 = await _augDataRepository.getIsUserSignedIn();
        return await result2.fold(
          (failure) {
            return false;
          },
          (isSuccess) {
            _augDataRepository.setIsSignedIn(bol: isSuccess);

            if (isSuccess) return true;

            return false;
          },
        );
      },
    );

    RouterInstance().goRoute?.refresh();

    return res;
  }
}
