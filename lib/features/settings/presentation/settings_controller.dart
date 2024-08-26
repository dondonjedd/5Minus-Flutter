import 'package:flutter/material.dart';

import '../../../core/component/template/authentication/data/auth_repository_data.dart';
import 'settings_screen.dart';

class SettingsController {
  static const String routeName = '/SettingsController';
  static Widget screen() {
    return SettingsScreen(controller: SettingsController._());
  }

  SettingsController._();

  AuthRepositoryData repositoryData = AuthRepositoryData();
}
