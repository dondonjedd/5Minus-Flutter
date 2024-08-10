import 'package:equatable/equatable.dart';

import 'exceptions.dart';

abstract class Failure extends Equatable {
  Failure({required this.title, required this.message, required this.statusCode})
      : assert(
          statusCode is String || statusCode is int,
          'StatusCode cannot be a ${statusCode.runtimeType}',
        );

  final String title;
  final String message;
  final dynamic statusCode;

  String get errorMessage => '$statusCode${statusCode is String ? '' : ' Error'}: $message';

  @override
  List<dynamic> get props => [message, statusCode];
}

class CacheFailure extends Failure {
  CacheFailure({required super.title, required super.message, required super.statusCode});
}

class ServerFailure extends Failure {
  final dynamic type;
  ServerFailure({required super.title, required super.message, required super.statusCode, required this.type});

  ServerFailure.fromException(ServerException exception)
      : this(title: exception.title, message: exception.message, statusCode: exception.statusCode, type: exception.type);
}
