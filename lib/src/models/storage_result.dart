/// Result wrapper for storage operations
class StorageResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final Exception? exception;

  const StorageResult._({
    required this.success,
    this.data,
    this.error,
    this.exception,
  });

  /// Create a successful result
  factory StorageResult.success(T data) {
    return StorageResult._(success: true, data: data);
  }

  /// Create a successful result without data
  factory StorageResult.successEmpty() {
    return StorageResult._(success: true);
  }

  /// Create a failed result
  factory StorageResult.failure(String error, [Exception? exception]) {
    return StorageResult._(success: false, error: error, exception: exception);
  }

  /// Check if result has data
  bool get hasData => data != null;

  /// Get data or throw exception
  T get dataOrThrow {
    if (success && data != null) {
      return data!;
    }
    throw exception ?? Exception(error ?? 'Unknown error');
  }

  /// Get data or return default value
  T getDataOrDefault(T defaultValue) {
    return success && data != null ? data! : defaultValue;
  }

  @override
  String toString() {
    if (success) {
      return 'StorageResult.success(data: $data)';
    } else {
      return 'StorageResult.failure(error: $error)';
    }
  }
}

/// Extension for easy result handling
extension StorageResultExtension<T> on StorageResult<T> {
  /// Execute callback if result is successful
  StorageResult<U> map<U>(U Function(T data) mapper) {
    if (success && data != null) {
      try {
        final result = mapper(data!);
        return StorageResult.success(result);
      } catch (e) {
        return StorageResult.failure(
          'Mapping failed: $e',
          e is Exception ? e : Exception(e.toString()),
        );
      }
    }
    return StorageResult.failure(error ?? 'No data to map', exception);
  }

  /// Execute callback if result is successful, ignore result
  void onSuccess(void Function(T data) callback) {
    if (success && data != null) {
      callback(data!);
    }
  }

  /// Execute callback if result failed
  void onFailure(void Function(String error) callback) {
    if (!success && error != null) {
      callback(error!);
    }
  }
}
