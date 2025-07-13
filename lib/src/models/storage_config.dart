/// Configuration for Storage Service
class StorageConfig {
  final String? encryptionKey;
  final bool enableLogging;
  final Duration defaultCacheDuration;
  final int maxCacheSize;
  final bool enableSecureStorage;
  final bool enableDatabase;

  const StorageConfig({
    this.encryptionKey,
    this.enableLogging = false,
    this.defaultCacheDuration = const Duration(hours: 1),
    this.maxCacheSize = 100,
    this.enableSecureStorage = true,
    this.enableDatabase = true,
  });
}
