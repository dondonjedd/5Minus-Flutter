import 'package:dartz/dartz.dart';

import '../errors/failures.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef Result<T> = Either<Failure, T>;
typedef ResultVoid = ResultFuture<void>;
typedef DataMap = Map<String, dynamic>;

//**************SERVER */

typedef ResultFutureServer<T> = Future<Either<ServerFailure, T>>;

typedef ResultServer<T> = Either<ServerFailure, T>;

//**************SERVER */

//**************CACHE */

typedef ResultFutureCache<T> = Future<Either<CacheFailure, T>>;

typedef ResultCache<T> = Either<CacheFailure, T>;

//**************CACHE */
