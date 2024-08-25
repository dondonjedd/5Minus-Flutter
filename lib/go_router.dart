import 'package:five_minus/features/auth_game_services/data/aug_data_repository.dart';
import 'package:five_minus/features/auth_game_services/presentation/authenticating_controller.dart';
import 'package:five_minus/features/authentication/presentation/register/register_controller.dart';
import 'package:five_minus/features/dashboard/presentation/dashboard_controller.dart';
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
            final res = _augDataRepository.getIsSignedInLocal();
            return res.fold(
              (failure) {
                return null;
              },
              (isSuccess) {
                if (!isSuccess) {
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
            final res = _augDataRepository.getIsSignedInLocal();
            return res.fold(
              (failure) {
                return null;
              },
              (isSuccess) {
                if (isSuccess) {
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
            final res = _augDataRepository.getIsSignedInLocal();
            return res.fold(
              (failure) {
                return null;
              },
              (isSuccess) {
                if (!isSuccess) {
                  return '/authenticatingController';
                }
                return null;
              },
            );
          },
          routes: [
            GoRoute(
              path: 'settingsController',
              name: SettingsController.routeName,
              builder: (context, state) {
                return SettingsController.screen();
              },
            ),
          ],
        ),
      ],
    );

    return goRoute;
  }

  Widget defaultBuilder(BuildContext context) {
    final res = _augDataRepository.getIsSignedInLocal();
    return res.fold(
      (failure) {
        return AuthenticatingController.screen();
      },
      (isSuccess) {
        if (!isSuccess) {
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
