import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const int defaultTimeout = 20;

class NetworkUtility {
  static Future<NetworkModelUtility> get(
      {required final String url,
      final Map<String, Object>? body,
      final void Function(Map)? errorFormHandler,
      final bool includeContentTypeHeader = false,
      final Map<String, String>? extraSettingsHeader,
      required final String authenticationToken,
      final String sessionId = '',
      final int? timeout}) async {
    Map<String, String> header = {
      'Accept': 'application/json',
      if (includeContentTypeHeader) 'Content-Type': 'application/json; charset=utf-8',
      if (extraSettingsHeader != null) ...extraSettingsHeader,
      if (authenticationToken.isNotEmpty) 'Authorization': 'Bearer $authenticationToken',
      if (sessionId.isNotEmpty) 'sessionid': sessionId,
    };
    final dataParameterList = <String>[];
    body?.forEach((key, value) {
      dataParameterList.add('$key=${Uri.encodeComponent(value.toString())}');
    });

    final parameter = dataParameterList.isEmpty ? '' : '?${dataParameterList.join('&')}';

    log('[Request][Get] Network Service: $url$parameter');

    return _handleResponse(
      requestHandler: () => http
          .get(
            Uri.parse('$url$parameter'),
            headers: header,
          )
          .timeout(Duration(seconds: timeout ?? defaultTimeout)),
      logPrefix: '[Response][Get] Network Service: ',
      errorFormHandler: errorFormHandler,
    );
  }

  static Future<NetworkModelUtility> put(
      {required final String url,
      final Map<String, Object>? body,
      final void Function(Map)? errorFormHandler,
      final bool includeContentTypeHeader = false,
      final Map<String, String>? extraSettingsHeader,
      required final String authenticationToken,
      final String sessionId = ''}) async {
    log('[Request][Put] Network Service: $url : $body');
    Map<String, String> header = {
      'Accept': 'application/json',
      if (includeContentTypeHeader) 'Content-Type': 'application/json; charset=utf-8',
      if (extraSettingsHeader != null) ...extraSettingsHeader,
      if (authenticationToken.isNotEmpty) 'Authorization': 'Bearer $authenticationToken',
      if (sessionId.isNotEmpty) 'sessionid': sessionId,
    };

    return _handleResponse(
      requestHandler: () => http
          .put(
            Uri.parse(url),
            headers: header,
            body: body,
          )
          .timeout(const Duration(seconds: defaultTimeout)),
      logPrefix: '[Response][Put] Network Service: ',
      errorFormHandler: errorFormHandler,
    );
  }

  static Future<NetworkModelUtility> post(
      {required final String url,
      final Map<String, String>? header,
      final Object? body,
      final bool enableJsonEncoder = false,
      final void Function(Map)? errorFormHandler,
      final bool includeContentTypeHeader = false,
      final Map<String, String>? extraSettingsHeader,
      required final String authenticationToken,
      final String sessionId = ''}) async {
    log('[Request][Post] Network Service: $url : $body');
    Map<String, String> header = {
      'Accept': 'application/json',
      if (includeContentTypeHeader) 'Content-Type': 'application/json; charset=utf-8',
      if (extraSettingsHeader != null) ...extraSettingsHeader,
      if (authenticationToken.isNotEmpty) 'Authorization': 'Bearer $authenticationToken',
      if (sessionId.isNotEmpty) 'sessionid': sessionId,
    };
    return _handleResponse(
      requestHandler: () => http
          .post(
            Uri.parse(url),
            headers: header,
            body: enableJsonEncoder ? jsonEncode(body) : body,
          )
          .timeout(const Duration(seconds: defaultTimeout)),
      logPrefix: '[Response][Post] Network Service: ',
      errorFormHandler: errorFormHandler,
    );
  }

  static Future<NetworkModelUtility> delete({
    required final String url,
    final Map<String, String>? header,
    final Object? body,
    final void Function(Map)? errorFormHandler,
  }) async {
    log('[Request][Delete] Network Service: $url : $body');

    return _handleResponse(
      requestHandler: () => http
          .delete(
            Uri.parse(url),
            headers: header,
            body: body,
          )
          .timeout(const Duration(seconds: defaultTimeout)),
      logPrefix: '[Response][Delete] Network Service: ',
      errorFormHandler: errorFormHandler,
    );
  }

  static Future<NetworkModelUtility> postMultipart({
    required final String url,
    final Map<String, String>? header,
    final dynamic body,
    final List<NetworkMultipartFileModel> fileModelList = const [],
    final void Function(Map)? errorFormHandler,
    required final String authenticationToken,
    final String sessionId = '',
  }) {
    log('[Request][Post Multipart] Network Service: $url : $body');

    return _handleResponse(
      requestHandler: () async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(url),
        );

        header?.forEach((key, value) {
          request.headers[key] = value;
        });

        /// Override content type to multipart format
        request.headers['Content-Type'] = 'multipart/form-data';
        if (authenticationToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $authenticationToken';
        }

        if (sessionId.isNotEmpty) {
          request.headers['sessionid'] = sessionId;
        }

        body?.forEach((key, value) {
          request.fields[key] = value;
        });

        for (final model in fileModelList) {
          final fileData = model.fileData;
          if (fileData is Uint8List) {
            print('File Name ${model.fileName}');
            request.files.add(http.MultipartFile.fromBytes(
              model.field,
              fileData,
              filename: model.fileName,
              contentType: MediaType(
                model.contentType.key,
                model.contentType.value,
              ),
            ));
          }
        }

        return http.Response.fromStream(await request.send());
      },
      logPrefix: '[Response][Post Multipart] Network Service: ',
      errorFormHandler: errorFormHandler,
    );
  }

  static Future<NetworkModelUtility> _handleResponse({
    required final Future<http.Response> Function() requestHandler,
    required final String logPrefix,
    final void Function(Map)? errorFormHandler,
  }) async {
    try {
      final response = await requestHandler();

      final statusCode = response.statusCode;

      log('$logPrefix${response.request?.url.toString()} $statusCode ${response.body}');

      if (statusCode >= 200 && statusCode < 300) {
        return NetworkModelUtility(
          statusCode: response.statusCode,
          response: response.body,
          responseData: response.bodyBytes,
        );
      } else {
        if (response.body.contains('https')) {
          return NetworkModelUtility(
            statusCode: response.statusCode,
            responseError: NetworkErrorModelUtility(
              title: 'API Web Error',
              type: '2',
              message: response.body,
            ),
          );
        } else {
          final error = jsonDecode(response.body)?['error'];

          if (error is String) {
            return NetworkModelUtility(
              statusCode: response.statusCode,
              responseError: NetworkErrorModelUtility(
                title: 'Error',
                message: error,
                type: '2',
              ),
            );
          } else if (error is Map<String, dynamic>) {
            return NetworkModelUtility(
              statusCode: response.statusCode,
              responseError: NetworkErrorModelUtility(
                  title: error['title']?.toString() ?? 'Error',
                  message: error['message']?.toString() ?? 'Something unexpected happened. Please try again.',
                  type: jsonDecode(response.body)?['error']?['type'] ?? '2'),
            );
          } else {
            return NetworkModelUtility(
              statusCode: response.statusCode,
              responseError: const NetworkErrorModelUtility(
                title: 'Unknown Error',
                message: 'Something unexpected happened. Please try again.',
                type: '2',
              ),
            );
          }
        }
      }
    } on SocketException {
      const message = 'Could not connect to server. Please check your internet connection.';

      log(message);

      return const NetworkModelUtility(
        statusCode: 999,
        responseError: NetworkErrorModelUtility(
          title: 'Network Error',
          message: message,
          type: '2',
        ),
      );
    } on TimeoutException {
      const message = 'Connection timed out. Please try again later.';

      log(message);

      return const NetworkModelUtility(
        statusCode: 999,
        responseError: NetworkErrorModelUtility(
          title: 'Request Timeout',
          message: message,
          type: '2',
        ),
      );
    } on Exception catch (e) {
      final message = 'Something Unexpected Happened. $e';

      log(message);

      return NetworkModelUtility(
        statusCode: 999,
        responseError: NetworkErrorModelUtility(
          title: 'Unexpected Error',
          message: message,
          type: '2',
        ),
      );
    }
  }

  const NetworkUtility._();
}

class NetworkModelUtility {
  final int statusCode;
  final String response;
  final Uint8List? responseData;
  final NetworkErrorModelUtility responseError;

  const NetworkModelUtility({
    required this.statusCode,
    this.response = '',
    this.responseData,
    this.responseError = const NetworkErrorModelUtility(
      title: 'Unknown Error',
      message: 'Something unexpected happened. Please try again.',
    ),
  });

  Map<String, dynamic> get responseMap {
    return jsonDecode(response);
  }

  bool get isResponseSuccess {
    return statusCode >= 200 && statusCode < 300;
  }

  bool get isResponseFailure {
    return !isResponseSuccess;
  }

  bool get isResponseFailureNotAuthorize {
    return statusCode == 401;
  }
}

class NetworkMultipartFileModel {
  final String field;
  final File? file;
  final String overrideFileName;
  final MapEntry<String, String> contentType;

  const NetworkMultipartFileModel({
    required this.field,
    required this.file,
    required this.overrideFileName,
    required this.contentType,
  });

  const NetworkMultipartFileModel.image({
    required this.field,
    required this.file,
    this.overrideFileName = '',
  }) : contentType = const MapEntry('image', 'png');

  const NetworkMultipartFileModel.video({
    required this.field,
    required this.file,
    this.overrideFileName = '',
  }) : contentType = const MapEntry('video', 'mp4');

  String get fileName {
    if (overrideFileName.isNotEmpty) return overrideFileName;

    if (file == null) return '';

    final filePathList = file?.path.split('/') ?? [];

    if (filePathList.isEmpty) {
      return '${DateTime.now().millisecondsSinceEpoch}.png';
    } else {
      return filePathList.last;
    }
  }

  Uint8List? get fileData {
    if (file == null) return null;

    return file?.readAsBytesSync();
  }
}

class NetworkErrorModelUtility {
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic> formMessage;

  const NetworkErrorModelUtility({
    this.title = '',
    this.message = '',
    this.type = '',
    this.formMessage = const {},
  });

  Map toJson() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'form': formMessage,
    };
  }
}
