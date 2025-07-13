/// Base exception for storage operations
abstract class StorageException implements Exception {
  final String message;
  final dynamic originalError;

  const StorageException(this.message, [this.originalError]);

  @override
  String toString() => 'StorageException: $message';
}

/// Thrown when storage initialization fails
class StorageInitializationException extends StorageException {
  const StorageInitializationException(String message, [dynamic originalError])
      : super(message, originalError);
}

/// Thrown when storage operation fails
class StorageOperationException extends StorageException {
  const StorageOperationException(String message, [dynamic originalError])
      : super(message, originalError);
}

/// Thrown when data serialization fails
class StorageSerializationException extends StorageException {
  const StorageSerializationException(String message, [dynamic originalError])
      : super(message, originalError);
}

/// Thrown when encryption/decryption fails
class StorageEncryptionException extends StorageException {
  const StorageEncryptionException(String message, [dynamic originalError])
      : super(message, originalError);
}

/// Thrown when file operation fails
class FileStorageException extends StorageException {
  const FileStorageException(String message, [dynamic originalError])
      : super(message, originalError);
}
