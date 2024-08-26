import 'package:five_minus/features/auth_game_services/data/aug_data_repository.dart';
import 'package:five_minus/go_router.dart';
import 'package:flutter/material.dart';
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
        final result2 = await _augDataRepository.getIsUserSignedInNetwork();
        return await result2.fold(
          (failure) {
            _augDataRepository.setUserInfoLocal(userInfo: '');

            return false;
          },
          (isSuccess) async {
            if (!isSuccess) {
              _augDataRepository.setUserInfoLocal(userInfo: '');
              return false;
            } else {
              final result3 = await _augDataRepository.getUserInfoNetwork();
              return result3.fold(
                (failure) {
                  return false;
                },
                (model) async {
                  final result4 = await _augDataRepository.setUserInfoLocal(userInfo: model.toJson());
                  return result4.fold(
                    (l) {
                      return false;
                    },
                    (r) {
                      return true;
                    },
                  );
                },
              );
            }
          },
        );
      },
    );

    RouterInstance().goRoute?.refresh();

    return res;
  }
}
