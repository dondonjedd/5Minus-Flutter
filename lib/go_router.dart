import 'package:five_minus/core/component/template/screen_template_view.dart';
import 'package:five_minus/features/authentication/presentation/login/login_controller.dart';
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

  intialise() {
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
            return null;

            // final status = context.read<AuthCubit>().state;

            // if (status.token?.isNotEmpty ?? false) {
            //   if (status.resetFlag == 'C') {
            //     return '/changePassword';
            //   }
            //   switch (status.runtimeType) {
            //     case Distribution:
            //       if ((status as Distribution).confirmParking?.process == ScanType.getTypeString(scanType: ScanType.yardIn) ||
            //           (status).confirmParking?.process == ScanType.getTypeString(scanType: ScanType.stagingIn)) {
            //         if (status.confirmParking?.confirmFlag == 'Y' && status.confirmParking?.parkingFlag == 'N') {
            //           return '/processSummary';
            //         }
            //       }

            //       return '/distributionDashboard?isAfterUpdate=${state.uri.queryParameters['isAfterUpdate']}';
            //     case Transporter || TransporterAdmin:
            //       return '/transporterDashboard';
            //     case Outlet:
            //       return '/outletDashboard';
            //     default:
            //       return '/login';
            //   }
            // } else {
            //   return '/login';
            // }
          },
        ),
        GoRoute(
          path: '/loginController',
          name: LoginController.routeName,
          builder: (context, state) {
            return LoginController.screen();
          },
          redirect: (context, state) async {
            return null;

            // final status = context.read<AuthCubit>().state;
            // if (status.token?.isEmpty ?? true) {
            //   return null;
            // }
            // return '/';
          },
          // routes: [
          //   GoRoute(
          //     path: 'forgotPassword',
          //     name: ForgotPasswordController.routeName,
          //     builder: (context, state) {
          //       return ForgotPasswordController.screen();
          //     },
          //   ),
          // ]
        ),
      ],
    );
  }

  Widget defaultBuilder(BuildContext context) {
    return LoginController.screen();
    return const ScreenTemplateView(
      layout: Center(
        child: Text('ERROR'),
      ),
    );
    // final status = context.read<AuthCubit>().state;

    // if (status.token?.isNotEmpty ?? false) {
    //   if (status.resetFlag == 'C') {
    //     return ChangePasswordController.screen();
    //   }
    //   switch (status.runtimeType) {
    //     case Distribution:
    //       return DistributionDashboardController.screen();
    //     case Transporter || TransporterAdmin:
    //       return TransporterDashboardController.screen();
    //     case Outlet:
    //       return OutletDashboardController.screen();
    //     default:
    //       return AuthenticationLoginControllerRoute.screen();
    //   }
    // } else {
    //   return AuthenticationLoginControllerRoute.screen();
    // }
  }
}
