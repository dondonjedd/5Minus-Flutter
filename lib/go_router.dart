import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/features/authentication/presentation/login/login_controller.dart';
import 'package:five_minus/features/authentication/presentation/register/register_controller.dart';
import 'package:five_minus/features/dashboard/presentation/dashboard_controller.dart';
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
            return null;
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
            ]),
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
        ),
      ],
    );

    return goRoute;
  }

  Widget defaultBuilder(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return LoginController.screen();
    return DashboardController.screen();
  }
}
