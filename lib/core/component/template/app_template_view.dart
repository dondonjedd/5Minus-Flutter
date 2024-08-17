import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/configuration_data.dart';
import '../../data/variable/color_variable_data.dart';

class AppTemplateView extends StatefulWidget {
  final String name;
  final GoRouter? goRouter;

  const AppTemplateView({super.key, required this.name, required this.goRouter});

  @override
  State<AppTemplateView> createState() => _AppTemplateViewState();
}

class _AppTemplateViewState extends State<AppTemplateView> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    precacheImage(const AssetImage('asset/image/background.jpg'), context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: ConfigurationData.screenshotMode ? false : true,
      title: widget.name,
      themeMode: ConfigurationData.defaultThemeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: ColorVariableData.light.primary,
        scaffoldBackgroundColor: ColorVariableData.light.scaffoldBackgroundColor,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 46,
          ),
          headlineMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(
            fontSize: 12,
            color: Color(0xFF9F9F9F),
            fontWeight: FontWeight.w500,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
          ),
          bodySmall: TextStyle(
            fontSize: 14,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
          ),
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
            fillColor: ColorVariableData.light.primaryContainer,
            filled: true,
            errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red))),
        elevatedButtonTheme: const ElevatedButtonThemeData(style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(Colors.black))),
        colorScheme: ColorScheme.light(
          brightness: Brightness.light,
          primary: ColorVariableData.light.primary,
          onPrimary: ColorVariableData.light.onPrimary,
          primaryContainer: ColorVariableData.light.primaryContainer,
          onPrimaryContainer: ColorVariableData.light.onPrimaryContainer,
          secondary: ColorVariableData.light.secondary,
          onSecondary: ColorVariableData.light.onSecondary,
          secondaryContainer: ColorVariableData.light.secondaryContainer,
          onSecondaryContainer: ColorVariableData.light.onSecondaryContainer,
          error: ColorVariableData.light.error,
          onError: ColorVariableData.light.onError,
          errorContainer: ColorVariableData.light.errorContainer,
          onErrorContainer: ColorVariableData.light.onErrorContainer,
          surface: ColorVariableData.light.surface,
          onSurface: ColorVariableData.light.onSurface,
        ),
        dialogTheme: const DialogTheme(titleTextStyle: TextStyle(color: Colors.black)),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(ColorVariableData.light.primary),
        ),
        checkboxTheme: CheckboxThemeData(
          checkColor: WidgetStateProperty.all(ColorVariableData.light.primary),
        ),
      ),
      // locale: selectedLocale,
      supportedLocales: ConfigurationData.supportedLocaleList,
      localizationsDelegates: ConfigurationData.localizationDelegateList,
      routerConfig: widget.goRouter,
    );
  }
}
