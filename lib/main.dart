import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:five_minus/core/component/template/app_template_view.dart';
import 'package:five_minus/core/utility/key_value_utility.dart';
import 'package:five_minus/features/auth_game_services/data/aug_data_repository.dart';
import 'package:five_minus/firebase_options.dart';
import 'package:five_minus/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/utility/app_utility.dart';
import 'features/auth_game_services/model/firebase_user_model.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await KeyValueUtility().initialise();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

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
  AugDataRepository augDataRepository = AugDataRepository();

  final result2 = await augDataRepository.getIsUserSignedInNetwork();
  await result2.fold(
    (failure) async {
      await augDataRepository.setUserInfoLocal(userInfo: '');
    },
    (isSuccess) async {
      if (!isSuccess) {
        await augDataRepository.setUserInfoLocal(userInfo: '');
      } else {
        await augDataRepository.signInFirebaseWithPlayGamesServices();

        final result3 = await augDataRepository.getUserInfoNetwork();
        result3.fold(
          (failure) {},
          (model) async {
            await augDataRepository.setUserInfoLocal(userInfo: model.toJson());
            if (model.username == null || model.id == null) return;
            await augDataRepository
                .createFirebaseUser(FirebaseUserModel(icon: model.icon, points: model.points, username: model.username!, playerId: model.id!));
          },
        );
      }
    },
  );

  final goRoute = RouterInstance().intialise();

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
