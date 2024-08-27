import 'package:five_minus/features/auth_game_services/data/aug_data_repository.dart';
import 'package:five_minus/features/auth_game_services/model/firebase_user_model.dart';
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
              await _augDataRepository.signInFirebaseWithPlayGamesServices();

              final result3 = await _augDataRepository.getUserInfoNetwork();
              return result3.fold(
                (failure) {
                  return false;
                },
                (model) async {
                  bool res = false;
                  final result4 = await _augDataRepository.setUserInfoLocal(userInfo: model.toJson());
                  result4.fold(
                    (l) {
                      res = false;
                    },
                    (r) {
                      res = true;
                    },
                  );

                  if (model.username == null || model.id == null) return false;

                  final result5 = await _augDataRepository.createFirebaseUser(FirebaseUserModel(
                    playerId: model.id!,
                    username: model.username!,
                    icon: model.icon,
                    points: model.points,
                  ));
                  result5.fold(
                    (l) {
                      res = false;
                    },
                    (r) {
                      res = true;
                    },
                  );

                  return res;
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
