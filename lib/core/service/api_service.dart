import 'dart:io';

class ApiService {
  String authenticationToken;

  ApiService({
    required this.authenticationToken,
  });

  Map<String, String> _getRequestHeader({
    final bool includeContentType = true,
    final Map<String, String> extraSettings = const {},
  }) {
    return {
      'openkey': 'web',
      'Accept': 'application/json',
      if (includeContentType) 'Content-Type': 'application/json; charset=utf-8',
      ...extraSettings,
      if (authenticationToken.isNotEmpty) 'Authorization': 'Bearer $authenticationToken',
      'x-platform': Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'web',
    };
  }
}
