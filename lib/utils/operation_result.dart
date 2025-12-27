/// Type-safe result wrapper for operations that can succeed or fail.
/// 
/// This class provides a clean way to handle operation results without
/// throwing exceptions, making error handling more explicit and predictable.
/// 
/// Example usage:
/// ```dart
/// Future<OperationResult<String>> loadData() async {
///   try {
///     final data = await someAsyncOperation();
///     return OperationResult.success(data);
///   } catch (e, st) {
///     return OperationResult.failure('Failed to load data: ${e.toString()}', e, st);
///   }
/// }
/// 
/// // Using the result
/// final result = await loadData();
/// if (result.success) {
///   print('Data loaded: ${result.data}');
/// } else {
///   print('Error: ${result.errorMessage}');
/// }
/// ```
class OperationResult<T> {
  /// Whether the operation succeeded
  final bool success;
  
  /// The data returned by the operation (null if failed)
  final T? data;
  
  /// Human-readable error message (null if successful)
  final String? errorMessage;
  
  /// The exception that caused the failure (null if successful or no exception)
  final dynamic exception;
  
  /// Stack trace for debugging (null if successful or not available)
  final StackTrace? stackTrace;

  /// Creates a successful result with data
  OperationResult.success(this.data)
      : success = true,
        errorMessage = null,
        exception = null,
        stackTrace = null;

  /// Creates a failed result with an error message
  OperationResult.failure(this.errorMessage, [this.exception, this.stackTrace])
      : success = false,
        data = null;

  /// Creates a failed result with just an exception (message extracted from exception)
  OperationResult.fromException(dynamic e, [StackTrace? st])
      : success = false,
        data = null,
        errorMessage = e.toString(),
        exception = e,
        stackTrace = st;

  /// Returns the data if successful, otherwise throws the exception or an error
  T getOrThrow() {
    if (success && data != null) {
      return data as T;
    }
    if (exception != null) {
      throw exception;
    }
    throw StateError(errorMessage ?? 'Operation failed');
  }

  /// Returns the data if successful, otherwise returns the provided default value
  T getOrDefault(T defaultValue) {
    return success ? (data ?? defaultValue) : defaultValue;
  }

  /// Returns the data if successful, otherwise returns null
  T? getOrNull() {
    return success ? data : null;
  }

  @override
  String toString() {
    if (success) {
      return 'OperationResult.success(data: $data)';
    } else {
      return 'OperationResult.failure(error: $errorMessage)';
    }
  }
}

/// Specialized result for operations that don't return data (void operations)
class VoidResult extends OperationResult<void> {
  VoidResult.success() : super.success(null);
  
  VoidResult.failure(String errorMessage, [dynamic exception, StackTrace? stackTrace])
      : super.failure(errorMessage, exception, stackTrace);
      
  VoidResult.fromException(dynamic e, [StackTrace? st])
      : super.fromException(e, st);
}

/// Specialized result for batch operations that return multiple item results
class BatchOperationResult<T> {
  final List<T> successfulItems;
  final List<String> failedItems;
  final int totalItems;
  
  BatchOperationResult({
    required this.successfulItems,
    required this.failedItems,
    required this.totalItems,
  });
  
  bool get hasFailures => failedItems.isNotEmpty;
  bool get allSucceeded => failedItems.isEmpty;
  bool get allFailed => successfulItems.isEmpty;
  int get successCount => successfulItems.length;
  int get failureCount => failedItems.length;
  
  /// Returns a summary message for the batch operation
  String getSummary({String itemName = 'item'}) {
    if (allSucceeded) {
      return 'Berhasil memproses semua $totalItems $itemName';
    } else if (allFailed) {
      return 'Gagal memproses semua $totalItems $itemName';
    } else {
      return 'Berhasil: $successCount, Gagal: $failureCount dari $totalItems $itemName';
    }
  }
  
  @override
  String toString() {
    return 'BatchOperationResult(total: $totalItems, success: $successCount, failed: $failureCount)';
  }
}
