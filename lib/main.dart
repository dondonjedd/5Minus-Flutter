import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:five_minus/core/component/template/app_template_view.dart';
import 'package:five_minus/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/utility/app_utility.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();

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

  final goRoute = RouterInstance().intialise();

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      log('User is currently signed out!');
      goRoute?.refresh();
    } else {
      log('User is signed in!');
      goRoute?.refresh();
    }
  });

  // AuthCubit authCubit = AuthCubit();
  // await authCubit.initialize();
  // EnvironmentCubit environmentCubit = EnvironmentCubit();
  // await environmentCubit.initialise();
  // LanguageCubit languageCubit = LanguageCubit();
  // await languageCubit.initialise();

  FlutterNativeSplash.remove();
  runApp(AppTemplateView(
    goRouter: goRoute,
    name: await AppUtility.name,
  ));
}
