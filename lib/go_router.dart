import 'package:five_minus/features/auth_game_services/data/aug_data_repository.dart';
import 'package:five_minus/features/auth_game_services/presentation/authenticating_controller.dart';
import 'package:five_minus/features/create_game/model/lobby_params.dart';
import 'package:five_minus/features/create_game/presentation/lobby_controller.dart';
import 'package:five_minus/features/dashboard/presentation/dashboard_controller.dart';
import 'package:five_minus/features/join_game/presentation/join_game_controller.dart';
import 'package:five_minus/features/leaderboard/presentation/leaderboard_controller.dart';
import 'package:five_minus/features/settings/presentation/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouterInstance {
  static RouterInstance? _instance;
  GoRouter? goRoute;

  RouterInstance._internal() {
    debugPrint('instance of GoRouter created');
    _instance = this;
  }

  factory RouterInstance() => _instance ?? RouterInstance._internal();
  final AugDataRepository _augDataRepository = AugDataRepository();

  GoRouter? intialise() {
    goRoute = GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: '/',
          builder: (context, state) {
            return defaultBuilder(context);
          },
          redirect: (context, state) {
            final res = _augDataRepository.getUserInfoLocal();
            return res.fold(
              (failure) {
                return null;
              },
              (userModel) {
                if (userModel.isEmpty) {
                  return '/authenticatingController';
                }
                return null;
              },
            );
          },
        ),
        GoRoute(
          path: '/authenticatingController',
          name: AuthenticatingController.routeName,
          builder: (context, state) {
            return AuthenticatingController.screen();
          },
          redirect: (context, state) async {
            final res = _augDataRepository.getUserInfoLocal();
            return res.fold(
              (failure) {
                return null;
              },
              (userModel) {
                if (userModel.isNotEmpty) {
                  return '/';
                }
                return null;
              },
            );
          },
        ),
        GoRoute(
          path: '/dashboardController',
          name: DashboardController.routeName,
          builder: (context, state) {
            return DashboardController.screen();
          },
          redirect: (context, state) {
            final res = _augDataRepository.getUserInfoLocal();
            return res.fold(
              (failure) {
                return null;
              },
              (userModel) {
                if (userModel.isEmpty) {
                  return '/authenticatingController';
                }
                return null;
              },
            );
          },
          routes: [
            GoRoute(
              path: 'leaderboardController',
              name: JoinGameController.routeName,
              builder: (context, state) {
                return JoinGameController.screen();
              },
            ),
            GoRoute(
              path: 'leaderboardController',
              name: LeaderboardController.routeName,
              builder: (context, state) {
                return LeaderboardController.screen();
              },
            ),
            GoRoute(
              path: 'settingsController',
              name: SettingsController.routeName,
              builder: (context, state) {
                return SettingsController.screen();
              },
            ),
          ],
        ),
        GoRoute(
          path: '/createGameController',
          name: LobbyController.routeName,
          builder: (context, state) {
            return LobbyController.screen(params: state.extra as LobbyParams);
          },
          redirect: (context, state) {
            final res = _augDataRepository.getUserInfoLocal();
            return res.fold(
              (failure) {
                return null;
              },
              (userModel) {
                if (userModel.isEmpty) {
                  return '/authenticatingController';
                }
                return null;
              },
            );
          },
        ),
      ],
    );

    return goRoute;
  }

  Widget defaultBuilder(BuildContext context) {
    final res = _augDataRepository.getUserInfoLocal();
    return res.fold(
      (failure) {
        return AuthenticatingController.screen();
      },
      (userModel) {
        if (userModel.isEmpty) {
          return AuthenticatingController.screen();
        }
        return DashboardController.screen();
      },
    );

    // final user = FirebaseAuth.instance.currentUser;
    // if (user == null) return LoginController.screen();
    // if (!(FirebaseAuth.instance.currentUser?.emailVerified ?? false)) {
    //   return VerifyEmailController.screen();
    // }

    // final res = AuthRepositoryData().getUserDetails();
    // return res.fold(
    //   (failure) {
    //     return DashboardController.screen();
    //   },
    //   (model) {
    //     if (model?.username?.isEmpty ?? true) {
    //       return UsernameController.screen();
    //     }
    //     return DashboardController.screen();
    //   },
    // );
  }
}
