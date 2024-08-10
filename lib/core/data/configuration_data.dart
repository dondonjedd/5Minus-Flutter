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

  const ConfigurationData._();
}
