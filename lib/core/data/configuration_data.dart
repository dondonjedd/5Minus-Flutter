import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localization.dart';

class ConfigurationData {
  static const localizationDelegateList = AppLocalizations.localizationsDelegates;

  static const supportedLocaleList = AppLocalizations.supportedLocales;

  static const defaultThemeMode = ThemeMode.light;

  static final defaultLocalizationDelegate = localizationDelegateList.first;

  static final defaultLocale = supportedLocaleList.first;

  static const bool isTestMode = true;

  static const bool screenshotMode = false;

  static const int pageSize = 20;

  static const String clientId = '74700725365-h4f88e2mv14d5agpliaf6o5rfp3h5224.apps.googleusercontent.com';

  static const String androidLeaderboardId = 'CgkI9biKpJYCEAIQAQ';

  const ConfigurationData._();
}
