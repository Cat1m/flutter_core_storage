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

  /// Create a development configuration
  factory StorageConfig.development() {
    return const StorageConfig(
      enableLogging: true,
      defaultCacheDuration: Duration(minutes: 30),
      maxCacheSize: 50,
      enableSecureStorage: true,
      enableDatabase: true,
    );
  }

  /// Create a production configuration
  factory StorageConfig.production() {
    return const StorageConfig(
      enableLogging: false,
      defaultCacheDuration: Duration(hours: 2),
      maxCacheSize: 200,
      enableSecureStorage: true,
      enableDatabase: true,
    );
  }

  /// Create a minimal configuration (no database, no secure storage)
  factory StorageConfig.minimal() {
    return const StorageConfig(
      enableLogging: false,
      defaultCacheDuration: Duration(minutes: 15),
      maxCacheSize: 25,
      enableSecureStorage: false,
      enableDatabase: false,
    );
  }

  /// Create a secure configuration with encryption
  factory StorageConfig.secure({required String encryptionKey}) {
    return StorageConfig(
      encryptionKey: encryptionKey,
      enableLogging: false, // Don't log in secure mode
      defaultCacheDuration: const Duration(minutes: 30),
      maxCacheSize: 100,
      enableSecureStorage: true,
      enableDatabase: true,
    );
  }

  /// Create configuration optimized for low memory devices
  factory StorageConfig.lowMemory() {
    return const StorageConfig(
      enableLogging: false,
      defaultCacheDuration: Duration(minutes: 10),
      maxCacheSize: 20,
      enableSecureStorage: true,
      enableDatabase: true,
    );
  }

  /// Copy configuration with modified values
  StorageConfig copyWith({
    String? encryptionKey,
    bool? enableLogging,
    Duration? defaultCacheDuration,
    int? maxCacheSize,
    bool? enableSecureStorage,
    bool? enableDatabase,
  }) {
    return StorageConfig(
      encryptionKey: encryptionKey ?? this.encryptionKey,
      enableLogging: enableLogging ?? this.enableLogging,
      defaultCacheDuration: defaultCacheDuration ?? this.defaultCacheDuration,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      enableSecureStorage: enableSecureStorage ?? this.enableSecureStorage,
      enableDatabase: enableDatabase ?? this.enableDatabase,
    );
  }

  /// Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'encryptionKey': encryptionKey,
      'enableLogging': enableLogging,
      'defaultCacheDuration': defaultCacheDuration.inMilliseconds,
      'maxCacheSize': maxCacheSize,
      'enableSecureStorage': enableSecureStorage,
      'enableDatabase': enableDatabase,
    };
  }

  /// Create from Map
  factory StorageConfig.fromMap(Map<String, dynamic> map) {
    return StorageConfig(
      encryptionKey: map['encryptionKey'] as String?,
      enableLogging: map['enableLogging'] as bool? ?? false,
      defaultCacheDuration: Duration(
        milliseconds: map['defaultCacheDuration'] as int? ?? 3600000,
      ),
      maxCacheSize: map['maxCacheSize'] as int? ?? 100,
      enableSecureStorage: map['enableSecureStorage'] as bool? ?? true,
      enableDatabase: map['enableDatabase'] as bool? ?? true,
    );
  }

  /// Validate configuration values
  List<String> validate() {
    final errors = <String>[];

    if (maxCacheSize <= 0) {
      errors.add('maxCacheSize must be greater than 0');
    }

    if (defaultCacheDuration.isNegative) {
      errors.add('defaultCacheDuration must not be negative');
    }

    if (encryptionKey != null && encryptionKey!.length < 8) {
      errors.add('encryptionKey must be at least 8 characters long');
    }

    return errors;
  }

  /// Check if configuration is valid
  bool get isValid => validate().isEmpty;

  @override
  String toString() {
    return 'StorageConfig('
        'enableLogging: $enableLogging, '
        'maxCacheSize: $maxCacheSize, '
        'enableSecureStorage: $enableSecureStorage, '
        'enableDatabase: $enableDatabase'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StorageConfig &&
        other.encryptionKey == encryptionKey &&
        other.enableLogging == enableLogging &&
        other.defaultCacheDuration == defaultCacheDuration &&
        other.maxCacheSize == maxCacheSize &&
        other.enableSecureStorage == enableSecureStorage &&
        other.enableDatabase == enableDatabase;
  }

  @override
  int get hashCode {
    return Object.hash(
      encryptionKey,
      enableLogging,
      defaultCacheDuration,
      maxCacheSize,
      enableSecureStorage,
      enableDatabase,
    );
  }
}
