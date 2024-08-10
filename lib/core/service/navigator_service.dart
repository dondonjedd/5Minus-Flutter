import 'package:flutter/material.dart';

class NavigatorService {
  static const dialog = _DialogNavigator._();

  static const link = _LinkNavigator._();

  static const screen = _ScreenNavigator._();

  const NavigatorService._();
}

class _DialogNavigator {
  /// Show popup dialog
  Future<dynamic> showPopup(
    final BuildContext context, {
    required final Widget widget,
    final bool dismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) {
        if (!dismissible) {
          return PopScope(
            child: widget,
            onPopInvoked: (didPop) async {
              return;
            },
          );
        } else {
          return widget;
        }
      },
    );
  }

  const _DialogNavigator._();
}

class _LinkNavigator {
  /// Start new screen
  Future<dynamic> next(
    final BuildContext context, {
    required final String name,
    final Map<String, Object?>? dataArgumentObject,
    final Map<String, dynamic>? dataParameterMap,
  }) async {
    return Navigator.pushNamed(
      context,
      _linkRoute(
        name: name,
        parameter: dataParameterMap,
      ),
      arguments: dataArgumentObject,
    );
  }

  /// Replace current screen with new screen
  Future<dynamic> nextReplacement(
    final BuildContext context, {
    required final String name,
    final Map<String, Object?>? dataArgumentObject,
    final Map<String, dynamic>? parameter,
  }) async {
    return Navigator.pushReplacementNamed(
      context,
      _linkRoute(
        name: name,
        parameter: parameter,
      ),
      arguments: dataArgumentObject,
    );
  }

  /// Clear all existing screen and start new screen
  Future<dynamic> nextSession(
    final BuildContext context, {
    required final String name,
    final Map<String, Object?>? dataArgumentObject,
    final Map<String, dynamic>? parameter,
  }) async {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      _linkRoute(
        name: name,
        parameter: parameter,
      ),
      _predicateRoute,
      arguments: dataArgumentObject,
    );
  }

  String _linkRoute({
    required final String name,
    final Map<String, dynamic>? parameter,
  }) {
    return Uri(
      path: name,
      // Convert all value to string otherwise it will encounter an error
      queryParameters: parameter?.map((key, value) {
        return MapEntry(key, value.toString());
      }),
    ).toString();
  }

  bool _predicateRoute(final Route route) {
    return false;
  }

  const _LinkNavigator._();
}

class _ScreenNavigator {
  /// Start new screen
  Future<dynamic> next(final BuildContext context, {required final Widget screen, String? name}) {
    return Navigator.push(
      context,
      _pageRoute(screen, name: name),
    );
  }

  /// Replace current screen with new screen
  Future<dynamic> nextReplacement(
    final BuildContext context, {
    required final Widget screen,
  }) {
    return Navigator.pushReplacement(
      context,
      _pageRoute(screen),
    );
  }

  /// Clear all existing screen and start new screen
  Future<dynamic> nextSession(
    final BuildContext context, {
    required final Widget screen,
  }) async {
    return Navigator.pushAndRemoveUntil(
      context,
      _pageRoute(screen),
      _predicateRoute,
    );
  }

  /// Build animation screen route
  Route _pageRoute(final Widget screen, {String? name}) {
    return MaterialPageRoute(
      settings: RouteSettings(name: name),
      builder: (context) {
        return screen;
      },
    );
  }

  bool _predicateRoute(final Route route) {
    return false;
  }

  const _ScreenNavigator._();
}
