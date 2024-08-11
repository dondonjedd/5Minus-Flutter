import 'dart:io';

import 'package:five_minus/core/component/template/app_template_view.dart';
import 'package:five_minus/features/bg_image.dart';
import 'package:five_minus/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/utility/app_utility.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // FlutterError.onError = (errorDetails) {
  //   FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  // };
  // // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  // PlatformDispatcher.instance.onError = (error, stack) {
  //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //   return true;
  // };

  // await NotificationService.initialise();

  // await KeyValueUtility().initialise();

  // await DeviceInfoUtility().initialise();

  RouterInstance().intialise();
  // AuthCubit authCubit = AuthCubit();
  // await authCubit.initialize();
  // EnvironmentCubit environmentCubit = EnvironmentCubit();
  // await environmentCubit.initialise();
  // LanguageCubit languageCubit = LanguageCubit();
  // await languageCubit.initialise();

  await BgImage().initialise();

  await Future.delayed(const Duration(seconds: 3));

  FlutterNativeSplash.remove();
  runApp(AppTemplateView(
    goRouter: RouterInstance().goRoute,
    name: await AppUtility.name,
  ));
}
