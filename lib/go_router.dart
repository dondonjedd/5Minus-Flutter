import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/features/authentication/data/auth_repository_data.dart';
import 'package:five_minus/features/authentication/presentation/login/login_controller.dart';
import 'package:five_minus/features/authentication/presentation/register/register_controller.dart';
import 'package:five_minus/features/authentication/presentation/username/username_controller.dart';
import 'package:five_minus/features/authentication/presentation/verify_email/verify_email_controller.dart';
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
          redirect: (context, state) async {
            final user = FirebaseAuth.instance.currentUser;

            if (user == null) {
              return '/loginController';
            }

            if (!(FirebaseAuth.instance.currentUser?.emailVerified ?? false)) {
              return '/verifyEmailController';
            }
            final res = AuthRepositoryData().getUserDetails();
            return res.fold(
              (failure) {
                return null;
              },
              (model) {
                if (model?.username?.isEmpty ?? true) {
                  return '/usernameController';
                }
                return null;
              },
            );
          },
        ),
        GoRoute(
          path: '/loginController',
          name: LoginController.routeName,
          builder: (context, state) {
            return LoginController.screen();
          },
          redirect: (context, state) async {
            final user = FirebaseAuth.instance.currentUser;

            if (user == null) {
              return null;
            }
            return '/';
          },
          routes: [
            GoRoute(
              path: 'registerController',
              name: RegisterController.routeName,
              builder: (context, state) {
                return RegisterController.screen();
              },
            ),
          ],
        ),
        GoRoute(
          path: '/verifyEmailController',
          name: VerifyEmailController.routeName,
          builder: (context, state) {
            return VerifyEmailController.screen();
          },
          redirect: (context, state) async {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              return null;
            }
            return '/';
          },
        ),
        GoRoute(
          path: '/usernameController',
          name: UsernameController.routeName,
          builder: (context, state) {
            return UsernameController.screen();
          },
          redirect: (context, state) async {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              return null;
            }
            return '/';
          },
        ),
        GoRoute(
          path: '/dashboardController',
          name: DashboardController.routeName,
          builder: (context, state) {
            return DashboardController.screen();
          },
          redirect: (context, state) async {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              return null;
            }
            return '/';
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return LoginController.screen();
    if (!(FirebaseAuth.instance.currentUser?.emailVerified ?? false)) {
      return VerifyEmailController.screen();
    }

    final res = AuthRepositoryData().getUserDetails();
    return res.fold(
      (failure) {
        return DashboardController.screen();
      },
      (model) {
        if (model?.username?.isEmpty ?? true) {
          return UsernameController.screen();
        }
        return DashboardController.screen();
      },
    );
  }
}
