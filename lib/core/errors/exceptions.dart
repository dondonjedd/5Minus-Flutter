import 'package:equatable/equatable.dart';

class ServerException extends Equatable implements Exception {
  const ServerException({this.title = 'Server Error', this.type = '2', required this.message, required this.statusCode});
  final String title;
  final String message;
  final String statusCode;
  final String type;

  @override
  List<dynamic> get props => [message, statusCode];
}

class CacheException extends Equatable implements Exception {
  const CacheException({this.title = 'Cache Error', required this.message, this.statusCode = 500});
  final String title;
  final String message;
  final int statusCode;

  @override
  List<dynamic> get props => [message, statusCode];
}
