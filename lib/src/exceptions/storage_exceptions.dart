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

  @override
  String toString() => 'StorageInitializationException: $message';
}

/// Thrown when storage operation fails
class StorageOperationException extends StorageException {
  final String? operation;

  const StorageOperationException(String message,
      [dynamic originalError, this.operation])
      : super(message, originalError);

  @override
  String toString() {
    final op = operation != null ? ' (operation: $operation)' : '';
    return 'StorageOperationException: $message$op';
  }
}

/// Thrown when data serialization fails
class StorageSerializationException extends StorageException {
  final Type? dataType;
  final bool? isSerialization;

  const StorageSerializationException(String message,
      [dynamic originalError, this.dataType, this.isSerialization])
      : super(message, originalError);

  @override
  String toString() {
    final typeInfo = dataType != null ? ' (type: $dataType)' : '';
    final operationInfo = isSerialization != null
        ? ' (${isSerialization! ? "serialization" : "deserialization"})'
        : '';
    return 'StorageSerializationException: $message$typeInfo$operationInfo';
  }
}

/// Thrown when encryption/decryption fails
class StorageEncryptionException extends StorageException {
  final bool? isEncryption;

  const StorageEncryptionException(String message,
      [dynamic originalError, this.isEncryption])
      : super(message, originalError);

  @override
  String toString() {
    final operationInfo = isEncryption != null
        ? ' (${isEncryption! ? "encryption" : "decryption"})'
        : '';
    return 'StorageEncryptionException: $message$operationInfo';
  }
}

/// Thrown when file operation fails
class FileStorageException extends StorageException {
  final String? filePath;
  final String? operation;

  const FileStorageException(String message,
      [dynamic originalError, this.filePath, this.operation])
      : super(message, originalError);

  @override
  String toString() {
    final pathInfo = filePath != null ? ' (file: $filePath)' : '';
    final opInfo = operation != null ? ' (operation: $operation)' : '';
    return 'FileStorageException: $message$pathInfo$opInfo';
  }
}
