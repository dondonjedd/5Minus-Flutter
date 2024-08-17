import 'package:flutter/material.dart';

enum ColorVariableData {
  dark(
    primary: Color(0xFF145999),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF145999),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFFF36F21),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF22B0E5),
    onSecondaryContainer: Color(0xFF1D192B),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1C1B1F),
    background: Color(0xFFFFFFFF),
    onBackground: Color(0xFF1C1B1F),
    system: Color(0xFFFFFFFF),
    onSystem: Color(0xFF1C1B1F),
    scaffoldBackgroundColor: Color(0xFFFFFFFF),
  ),
  light(
    primary: Color(0xFF145999),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFF145999),
    secondary: Color(0xFFF36F21),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF22B0E5),
    onSecondaryContainer: Color(0xFF1D192B),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1C1B1F),
    background: Color(0xFFFFFFFF),
    onBackground: Color(0xFF1C1B1F),
    system: Color(0xFFFFFFFF),
    onSystem: Color(0xFF1C1B1F),
    scaffoldBackgroundColor: Color(0xFFFFFFFF),
  );

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color surface;
  final Color onSurface;
  final Color background;
  final Color onBackground;
  final Color system;
  final Color onSystem;
  final Color scaffoldBackgroundColor;

  const ColorVariableData(
      {required this.primary,
      required this.onPrimary,
      required this.primaryContainer,
      required this.onPrimaryContainer,
      required this.secondary,
      required this.onSecondary,
      required this.secondaryContainer,
      required this.onSecondaryContainer,
      required this.error,
      required this.onError,
      required this.errorContainer,
      required this.onErrorContainer,
      required this.surface,
      required this.onSurface,
      required this.background,
      required this.onBackground,
      required this.system,
      required this.onSystem,
      required this.scaffoldBackgroundColor});
}
