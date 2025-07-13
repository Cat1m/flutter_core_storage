import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/storage_result.dart';
import '../exceptions/storage_exceptions.dart';
import '../utils/storage_utils.dart';
import '../utils/encryption_utils.dart';
import '../utils/serialization_utils.dart';

/// Service for secure storage using FlutterSecureStorage
class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance => _instance!;

  FlutterSecureStorage? _secureStorage;
  static bool _isInitialized = false;

  // Default options for secure storage
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    sharedPreferencesName: 'flutter_secure_storage_prefs',
    preferencesKeyPrefix: 'flutter_secure_storage_',
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accountName: 'flutter_secure_storage_account',
    groupId: null,
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  static const LinuxOptions _linuxOptions = LinuxOptions();
  static const WindowsOptions _windowsOptions = WindowsOptions();
  static const WebOptions _webOptions = WebOptions();
  static const MacOsOptions _macOsOptions = MacOsOptions();

  // Private constructor
  SecureStorageService._();

  /// Initialize the secure storage service
  static Future<void> initialize({
    AndroidOptions? androidOptions,
    IOSOptions? iosOptions,
    LinuxOptions? linuxOptions,
    WindowsOptions? windowsOptions,
    WebOptions? webOptions,
    MacOsOptions? macOsOptions,
  }) async {
    if (_isInitialized) return;

    try {
      _instance = SecureStorageService._();
      _instance!._secureStorage = FlutterSecureStorage(
        aOptions: androidOptions ?? _androidOptions,
        iOptions: iosOptions ?? _iosOptions,
        lOptions: linuxOptions ?? _linuxOptions,
        wOptions: windowsOptions ?? _windowsOptions,
        webOptions: webOptions ?? _webOptions,
        mOptions: macOsOptions ?? _macOsOptions,
      );

      _isInitialized = true;
      debugPrint('✅ SecureStorageService initialized successfully');
    } catch (e) {
      debugPrint('❌ SecureStorageService initialization failed: $e');
      throw StorageInitializationException(
          'Failed to initialize secure storage: $e');
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Get FlutterSecureStorage instance
  FlutterSecureStorage get storage {
    if (_secureStorage == null) {
      throw StorageOperationException(
          'SecureStorageService not initialized. Call initialize() first.');
    }
    return _secureStorage!;
  }

  // ============================================================================
  // BASIC SECURE OPERATIONS
  // ============================================================================

  /// Store a secure value
  Future<StorageResult<bool>> setSecure(String key, String value) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      await storage.write(key: sanitizedKey, value: value);

      debugPrint('🔒 Stored secure value: $sanitizedKey');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to store secure value: $key - $e');
      return StorageResult.failure('Failed to store secure value: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get a secure value
  Future<StorageResult<String?>> getSecure(String key,
      [String? defaultValue]) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final value = await storage.read(key: sanitizedKey) ?? defaultValue;

      debugPrint(
          '🔓 Retrieved secure value: $sanitizedKey${value != null ? ' (found)' : ' (not found)'}');
      return StorageResult.success(value);
    } catch (e) {
      debugPrint('❌ Failed to retrieve secure value: $key - $e');
      return StorageResult.failure('Failed to retrieve secure value: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Remove a secure value
  Future<StorageResult<bool>> removeSecure(String key) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      await storage.delete(key: sanitizedKey);

      debugPrint('🗑️ Removed secure value: $sanitizedKey');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to remove secure value: $key - $e');
      return StorageResult.failure('Failed to remove secure value: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Check if secure key exists
  Future<StorageResult<bool>> containsSecureKey(String key) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final exists = await storage.containsKey(key: sanitizedKey);

      debugPrint('🔍 Secure key exists: $sanitizedKey = $exists');
      return StorageResult.success(exists);
    } catch (e) {
      debugPrint('❌ Failed to check secure key: $key - $e');
      return StorageResult.failure('Failed to check secure key: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get all secure keys
  Future<StorageResult<Set<String>>> getSecureKeys() async {
    try {
      final allData = await storage.readAll();
      final keys = allData.keys.toSet();

      debugPrint('🔑 Retrieved ${keys.length} secure keys');
      return StorageResult.success(keys);
    } catch (e) {
      debugPrint('❌ Failed to get secure keys: $e');
      return StorageResult.failure('Failed to get secure keys: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Clear all secure storage
  Future<StorageResult<bool>> clearSecure() async {
    try {
      await storage.deleteAll();

      debugPrint('🧹 Cleared all secure storage');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to clear secure storage: $e');
      return StorageResult.failure('Failed to clear secure storage: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // OBJECT OPERATIONS (using JSON serialization)
  // ============================================================================

  /// Store any object securely as JSON
  Future<StorageResult<bool>> setSecureObject(
      String key, dynamic object) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final jsonString = SerializationUtils.toJsonString(object);
      return await setSecure(key, jsonString);
    } catch (e) {
      debugPrint('❌ Failed to store secure object: $key - $e');
      return StorageResult.failure('Failed to store secure object: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get object from secure JSON
  Future<StorageResult<T?>> getSecureObject<T>(String key,
      [T? defaultValue]) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final stringResult = await getSecure(key);
      if (!stringResult.success || stringResult.data == null) {
        return StorageResult.success(defaultValue);
      }

      final object = SerializationUtils.fromJsonString<T>(stringResult.data!);
      return StorageResult.success(object ?? defaultValue);
    } catch (e) {
      debugPrint('❌ Failed to retrieve secure object: $key - $e');
      return StorageResult.failure('Failed to retrieve secure object: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // ENCRYPTED OPERATIONS (double encryption)
  // ============================================================================

  /// Store value with additional encryption
  Future<StorageResult<bool>> setEncrypted(
      String key, String value, String encryptionKey) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final encryptedValue =
          EncryptionUtils.encryptString(value, encryptionKey);
      return await setSecure(key, encryptedValue);
    } catch (e) {
      debugPrint('❌ Failed to store encrypted value: $key - $e');
      return StorageResult.failure('Failed to store encrypted value: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get encrypted value
  Future<StorageResult<String?>> getEncrypted(String key, String encryptionKey,
      [String? defaultValue]) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final secureResult = await getSecure(key);
      if (!secureResult.success || secureResult.data == null) {
        return StorageResult.success(defaultValue);
      }

      final decryptedValue =
          EncryptionUtils.decryptString(secureResult.data!, encryptionKey);
      return StorageResult.success(decryptedValue);
    } catch (e) {
      debugPrint('❌ Failed to retrieve encrypted value: $key - $e');
      return StorageResult.failure('Failed to retrieve encrypted value: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Store object with additional encryption
  Future<StorageResult<bool>> setEncryptedObject(
      String key, dynamic object, String encryptionKey) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final jsonString = SerializationUtils.toJsonString(object);
      return await setEncrypted(key, jsonString, encryptionKey);
    } catch (e) {
      debugPrint('❌ Failed to store encrypted object: $key - $e');
      return StorageResult.failure('Failed to store encrypted object: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get encrypted object
  Future<StorageResult<T?>> getEncryptedObject<T>(
      String key, String encryptionKey,
      [T? defaultValue]) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final encryptedResult = await getEncrypted(key, encryptionKey);
      if (!encryptedResult.success || encryptedResult.data == null) {
        return StorageResult.success(defaultValue);
      }

      final object =
          SerializationUtils.fromJsonString<T>(encryptedResult.data!);
      return StorageResult.success(object ?? defaultValue);
    } catch (e) {
      debugPrint('❌ Failed to retrieve encrypted object: $key - $e');
      return StorageResult.failure('Failed to retrieve encrypted object: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // SECURE KEY MANAGEMENT
  // ============================================================================

  /// Generate and store a secure key
  Future<StorageResult<String>> generateAndStoreKey(String keyName,
      [int keyLength = 32]) async {
    try {
      final secureKey = EncryptionUtils.generateSecureKey(keyLength);
      final storeResult = await setSecure(keyName, secureKey);

      if (!storeResult.success) {
        return StorageResult.failure(
            'Failed to store generated key: ${storeResult.error}');
      }

      debugPrint('🔑 Generated and stored secure key: $keyName');
      return StorageResult.success(secureKey);
    } catch (e) {
      debugPrint('❌ Failed to generate and store key: $keyName - $e');
      return StorageResult.failure('Failed to generate and store key: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Derive and store key from password
  Future<StorageResult<String>> deriveAndStoreKey(
      String keyName, String password, String salt) async {
    try {
      final derivedKey = EncryptionUtils.deriveKeyFromPassword(password, salt);
      final storeResult = await setSecure(keyName, derivedKey);

      if (!storeResult.success) {
        return StorageResult.failure(
            'Failed to store derived key: ${storeResult.error}');
      }

      debugPrint('🔑 Derived and stored key from password: $keyName');
      return StorageResult.success(derivedKey);
    } catch (e) {
      debugPrint('❌ Failed to derive and store key: $keyName - $e');
      return StorageResult.failure('Failed to derive and store key: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Rotate encryption key (re-encrypt all data with new key)
  Future<StorageResult<int>> rotateEncryptionKey(String oldKey, String newKey,
      {String? keyPattern}) async {
    try {
      final keysResult = await getSecureKeys();
      if (!keysResult.success) {
        return StorageResult.failure('Failed to get keys: ${keysResult.error}');
      }

      final targetKeys = keyPattern != null
          ? keysResult.data!.where((key) => RegExp(keyPattern).hasMatch(key))
          : keysResult.data!;

      int rotatedCount = 0;

      for (final key in targetKeys) {
        try {
          // Get encrypted value with old key
          final encryptedResult = await getEncrypted(key, oldKey);
          if (encryptedResult.success && encryptedResult.data != null) {
            // Re-encrypt with new key
            final reEncryptResult =
                await setEncrypted(key, encryptedResult.data!, newKey);
            if (reEncryptResult.success) {
              rotatedCount++;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Failed to rotate key for $key: $e');
        }
      }

      debugPrint('🔄 Rotated encryption for $rotatedCount keys');
      return StorageResult.success(rotatedCount);
    } catch (e) {
      debugPrint('❌ Failed to rotate encryption keys: $e');
      return StorageResult.failure('Failed to rotate encryption keys: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // SECURE BACKUP & EXPORT
  // ============================================================================

  /// Export secure data (encrypted)
  Future<StorageResult<Map<String, String>>> exportSecure(
      {String? keyPattern}) async {
    try {
      final allData = await storage.readAll();

      final filteredData = keyPattern != null
          ? Map.fromEntries(allData.entries
              .where((entry) => RegExp(keyPattern).hasMatch(entry.key)))
          : allData;

      debugPrint('📤 Exported ${filteredData.length} secure entries');
      return StorageResult.success(filteredData);
    } catch (e) {
      debugPrint('❌ Failed to export secure data: $e');
      return StorageResult.failure('Failed to export secure data: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Import secure data
  Future<StorageResult<int>> importSecure(Map<String, String> data,
      {bool clearFirst = false}) async {
    try {
      if (clearFirst) {
        await clearSecure();
      }

      int importedCount = 0;
      for (final entry in data.entries) {
        try {
          await storage.write(key: entry.key, value: entry.value);
          importedCount++;
        } catch (e) {
          debugPrint('⚠️ Failed to import secure key ${entry.key}: $e');
        }
      }

      debugPrint('📥 Imported $importedCount/${data.length} secure entries');
      return StorageResult.success(importedCount);
    } catch (e) {
      debugPrint('❌ Failed to import secure data: $e');
      return StorageResult.failure('Failed to import secure data: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Create encrypted backup
  Future<StorageResult<String>> createEncryptedBackup(String backupKey,
      {String? keyPattern}) async {
    try {
      final exportResult = await exportSecure(keyPattern: keyPattern);
      if (!exportResult.success) {
        return StorageResult.failure(
            'Failed to export data: ${exportResult.error}');
      }

      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'keyCount': exportResult.data!.length,
        'data': exportResult.data,
      };

      final encryptedBackup =
          EncryptionUtils.encryptJson(backupData, backupKey);

      debugPrint(
          '💾 Created encrypted backup with ${exportResult.data!.length} keys');
      return StorageResult.success(encryptedBackup);
    } catch (e) {
      debugPrint('❌ Failed to create encrypted backup: $e');
      return StorageResult.failure('Failed to create encrypted backup: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Restore from encrypted backup
  Future<StorageResult<int>> restoreFromEncryptedBackup(
      String encryptedBackup, String backupKey,
      {bool clearFirst = false}) async {
    try {
      final backupData =
          EncryptionUtils.decryptToJson(encryptedBackup, backupKey);
      final data = backupData['data'] as Map<String, dynamic>;
      final stringData =
          data.map((key, value) => MapEntry(key, value.toString()));

      final importResult =
          await importSecure(stringData, clearFirst: clearFirst);

      debugPrint('🔄 Restored ${importResult.data} keys from encrypted backup');
      return importResult;
    } catch (e) {
      debugPrint('❌ Failed to restore from encrypted backup: $e');
      return StorageResult.failure(
          'Failed to restore from encrypted backup: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get secure storage info
  Future<StorageResult<Map<String, dynamic>>> getSecureInfo() async {
    try {
      final keysResult = await getSecureKeys();
      if (!keysResult.success) {
        return StorageResult.failure('Failed to get keys: ${keysResult.error}');
      }

      final info = {
        'keyCount': keysResult.data!.length,
        'isInitialized': _isInitialized,
        'keys': keysResult.data!.toList(),
        'platform': defaultTargetPlatform.toString(),
      };

      return StorageResult.success(info);
    } catch (e) {
      debugPrint('❌ Failed to get secure storage info: $e');
      return StorageResult.failure('Failed to get secure storage info: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Check if secure storage is available
  static Future<StorageResult<bool>> isSecureStorageAvailable() async {
    try {
      const testStorage = FlutterSecureStorage();
      await testStorage.write(key: '_test_key', value: 'test');
      await testStorage.delete(key: '_test_key');

      debugPrint('✅ Secure storage is available');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Secure storage is not available: $e');
      return StorageResult.success(false);
    }
  }

  /// Clean up expired keys (based on naming convention)
  Future<StorageResult<int>> cleanupExpiredKeys() async {
    try {
      final keysResult = await getSecureKeys();
      if (!keysResult.success) {
        return StorageResult.failure('Failed to get keys: ${keysResult.error}');
      }

      int cleanedCount = 0;
      final now = DateTime.now();

      for (final key in keysResult.data!) {
        // Check if key follows expiration naming convention: key_expiry_timestamp
        if (key.contains('_expiry_')) {
          try {
            final parts = key.split('_expiry_');
            if (parts.length == 2) {
              final expiryTimestamp = int.tryParse(parts[1]);
              if (expiryTimestamp != null) {
                final expiryDate =
                    DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
                if (now.isAfter(expiryDate)) {
                  await removeSecure(key);
                  cleanedCount++;
                }
              }
            }
          } catch (e) {
            // Ignore keys with invalid expiry format
          }
        }
      }

      debugPrint('🧹 Cleaned up $cleanedCount expired keys');
      return StorageResult.success(cleanedCount);
    } catch (e) {
      debugPrint('❌ Failed to cleanup expired keys: $e');
      return StorageResult.failure('Failed to cleanup expired keys: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }
}
