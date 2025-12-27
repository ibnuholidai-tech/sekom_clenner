import 'package:dartz/dartz.dart';

/// Base class untuk semua failures/errors
abstract class Failure {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({required this.message, this.code, this.details});

  @override
  String toString() =>
      'Failure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Server/Network failures
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code, super.details});
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code, super.details});
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code, super.details});
}

/// File system failures
class FileSystemFailure extends Failure {
  const FileSystemFailure({required super.message, super.code, super.details});
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code, super.details});
}

/// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.code, super.details});
}

/// Type alias untuk Result pattern
typedef Result<T> = Either<Failure, T>;

/// Extension untuk Result
extension ResultExtension<T> on Result<T> {
  /// Get value atau throw exception
  T getOrThrow() {
    return fold(
      (failure) => throw Exception(failure.message),
      (value) => value,
    );
  }

  /// Get value atau return default
  T getOrElse(T defaultValue) {
    return fold((_) => defaultValue, (value) => value);
  }

  /// Get value atau compute default
  T getOrElseCompute(T Function() defaultValue) {
    return fold((_) => defaultValue(), (value) => value);
  }

  /// Check if success
  bool get isSuccess => isRight();

  /// Check if failure
  bool get isFailure => isLeft();

  /// Get failure jika ada
  Failure? get failure => fold((failure) => failure, (_) => null);

  /// Get value jika ada
  T? get value => fold((_) => null, (value) => value);
}

/// Helper untuk membuat Result
class ResultHelper {
  /// Success result
  static Result<T> success<T>(T value) => Right(value);

  /// Failure result
  static Result<T> failure<T>(Failure failure) => Left(failure);

  /// Try-catch wrapper yang return Result
  static Future<Result<T>> tryCatch<T>({
    required Future<T> Function() action,
    Failure Function(dynamic error)? onError,
  }) async {
    try {
      final result = await action();
      return success(result);
    } catch (e, stackTrace) {
      if (onError != null) {
        return failure(onError(e));
      }
      return failure(
        UnknownFailure(message: e.toString(), details: stackTrace),
      );
    }
  }

  /// Synchronous try-catch wrapper
  static Result<T> tryCatchSync<T>({
    required T Function() action,
    Failure Function(dynamic error)? onError,
  }) {
    try {
      final result = action();
      return success(result);
    } catch (e, stackTrace) {
      if (onError != null) {
        return failure(onError(e));
      }
      return failure(
        UnknownFailure(message: e.toString(), details: stackTrace),
      );
    }
  }
}

/// Example usage:
/// 
/// Future<Result<String>> fetchData() async {
///   return ResultHelper.tryCatch(
///     action: () async {
///       // Your async operation
///       return 'data';
///     },
///     onError: (error) => ServerFailure(message: error.toString()),
///   );
/// }
/// 
/// void handleResult() async {
///   final result = await fetchData();
///   
///   result.fold(
///     (failure) => print('Error: ${failure.message}'),
///     (data) => print('Success: $data'),
///   );
///   
///   // Or use extensions
///   if (result.isSuccess) {
///     print('Data: ${result.value}');
///   } else {
///     print('Error: ${result.failure?.message}');
///   }
/// }
