import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/storage_config.dart';
import '../exceptions/storage_exceptions.dart';
import 'preferences_service.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';
import 'file_storage_service.dart';
import 'cache_service.dart';

/// Main Storage Service - Facade for all storage operations
///
/// This is the main entry point for all storage operations.
/// It provides a unified interface for:
/// - Simple preferences (SharedPreferences)
/// - Database operations (Hive)
/// - Secure storage (FlutterSecureStorage)
/// - File operations
/// - Cache management
///

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance!;

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  // Service instances
  PreferencesService get _prefs => PreferencesService.instance;
  DatabaseService get _database {
    if (!DatabaseService.isInitialized) {
      throw const StorageOperationException(
        'Database service is not initialized. Set enableDatabase: true in StorageConfig.',
        null,
        'database_access',
      );
    }
    return DatabaseService.instance;
  }

  SecureStorageService get _secure {
    if (!SecureStorageService.isInitialized) {
      throw const StorageOperationException(
        'Secure storage service is not initialized. Set enableSecureStorage: true in StorageConfig.',
        null,
        'secure_storage_access',
      );
    }
    return SecureStorageService.instance;
  }

  FileStorageService get _files => FileStorageService.instance;
  CacheService get _cache => CacheService.instance;

  // Private constructor
  StorageService._();

  /// Initialize the storage service
  /// Must be called before using any storage operations
  static Future<void> initialize({
    StorageConfig? config,
  }) async {
    if (_isInitialized) return;

    _instance = StorageService._();

    try {
      final cfg = config ?? const StorageConfig();

      if (cfg.enableLogging) {
        debugPrint(
            '🔧 Initializing StorageService with config: ${cfg.toString()}');
      }

      // Initialize all storage services
      await PreferencesService.initialize();
      if (cfg.enableLogging) debugPrint('✓ PreferencesService initialized');

      if (cfg.enableDatabase) {
        await DatabaseService.initialize(
          encryptionKey: cfg.encryptionKey,
          compactionEnabled: true, // Default value
        );
        if (cfg.enableLogging) debugPrint('✓ DatabaseService initialized');
      }

      if (cfg.enableSecureStorage) {
        await SecureStorageService.initialize();
        if (cfg.enableLogging) debugPrint('✓ SecureStorageService initialized');
      }

      await FileStorageService.initialize();
      if (cfg.enableLogging) debugPrint('✓ FileStorageService initialized');

      await CacheService.initialize(
        maxCacheSize: cfg.maxCacheSize,
        defaultTTL: cfg.defaultCacheDuration,
        cleanupInterval: const Duration(minutes: 10), // Default value
      );
      if (cfg.enableLogging) debugPrint('✓ CacheService initialized');

      _isInitialized = true;
      debugPrint('✅ Storage Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Storage Service initialization failed: $e');
      throw StorageInitializationException(
          'Failed to initialize storage: $e', e);
    }
  }

  /// Dispose all storage services
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      // Dispose services that were initialized
      if (DatabaseService.isInitialized) {
        await DatabaseService.dispose();
      }

      if (CacheService.isInitialized) {
        await CacheService.dispose();
      }

      _isInitialized = false;
      _instance = null;
      debugPrint('✅ Storage Service disposed successfully');
    } catch (e) {
      debugPrint('❌ Storage Service disposal failed: $e');
    }
  }

  /// Check if storage service is initialized
  void _checkInitialized() {
    if (!_isInitialized) {
      throw const StorageOperationException(
        'StorageService not initialized. Call StorageService.initialize() first.',
        null,
        'checkInitialized',
      );
    }
  }

  // ============================================================================
  // SIMPLE KEY-VALUE STORAGE (SharedPreferences)
  // ============================================================================

  /// Store a string value
  Future<bool> setString(String key, String value) async {
    _checkInitialized();
    final result = await _prefs.setString(key, value);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'setString');
    }
    return result.data!;
  }

  /// Get a string value
  Future<String?> getString(String key, [String? defaultValue]) async {
    _checkInitialized();
    final result = await _prefs.getString(key, defaultValue);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getString');
    }
    return result.data;
  }

  /// Store an integer value
  Future<bool> setInt(String key, int value) async {
    _checkInitialized();
    final result = await _prefs.setInt(key, value);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'setInt');
    }
    return result.data!;
  }

  /// Get an integer value
  Future<int?> getInt(String key, [int? defaultValue]) async {
    _checkInitialized();
    final result = await _prefs.getInt(key, defaultValue);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getInt');
    }
    return result.data;
  }

  /// Store a boolean value
  Future<bool> setBool(String key, bool value) async {
    _checkInitialized();
    final result = await _prefs.setBool(key, value);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'setBool');
    }
    return result.data!;
  }

  /// Get a boolean value
  Future<bool?> getBool(String key, [bool? defaultValue]) async {
    _checkInitialized();
    final result = await _prefs.getBool(key, defaultValue);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getBool');
    }
    return result.data;
  }

  /// Store a double value
  Future<bool> setDouble(String key, double value) async {
    _checkInitialized();
    final result = await _prefs.setDouble(key, value);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'setDouble');
    }
    return result.data!;
  }

  /// Get a double value
  Future<double?> getDouble(String key, [double? defaultValue]) async {
    _checkInitialized();
    final result = await _prefs.getDouble(key, defaultValue);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getDouble');
    }
    return result.data;
  }

  /// Store a list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    _checkInitialized();
    final result = await _prefs.setStringList(key, value);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'setStringList');
    }
    return result.data!;
  }

  /// Get a list of strings
  Future<List<String>?> getStringList(String key,
      [List<String>? defaultValue]) async {
    _checkInitialized();
    final result = await _prefs.getStringList(key, defaultValue);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getStringList');
    }
    return result.data;
  }

  /// Store any object as JSON
  Future<bool> setObject(String key, dynamic object) async {
    _checkInitialized();
    final result = await _prefs.setObject(key, object);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'setObject');
    }
    return result.data!;
  }

  /// Get object from JSON
  Future<T?> getObject<T>(String key, [T? defaultValue]) async {
    _checkInitialized();
    final result = await _prefs.getObject<T>(key, defaultValue);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getObject');
    }
    return result.data;
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    _checkInitialized();
    final result = await _prefs.remove(key);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'remove');
    }
    return result.data!;
  }

  /// Clear all preferences
  Future<bool> clear() async {
    _checkInitialized();
    final result = await _prefs.clear();
    if (!result.success) {
      throw StorageOperationException(result.error!, result.exception, 'clear');
    }
    return result.data!;
  }

  /// Check if key exists in preferences
  Future<bool> containsKey(String key) async {
    _checkInitialized();
    final result = await _prefs.containsKey(key);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'containsKey');
    }
    return result.data!;
  }

  /// Get all preference keys
  Future<Set<String>> getKeys() async {
    _checkInitialized();
    final result = await _prefs.getKeys();
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getKeys');
    }
    return result.data!;
  }

  // ============================================================================
  // SECURE STORAGE
  // ============================================================================

  /// Store sensitive data securely
  Future<void> setSecure(String key, String value) async {
    _checkInitialized();
    final result = await _secure.setSecure(key, value);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'setSecure');
    }
  }

  /// Get sensitive data securely
  Future<String?> getSecure(String key, [String? defaultValue]) async {
    _checkInitialized();
    final result = await _secure.getSecure(key, defaultValue);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getSecure');
    }
    return result.data;
  }

  /// Store secure object as JSON
  Future<void> setSecureObject(String key, dynamic object) async {
    _checkInitialized();
    final result = await _secure.setSecureObject(key, object);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'setSecureObject');
    }
  }

  /// Get secure object from JSON
  Future<T?> getSecureObject<T>(String key, [T? defaultValue]) async {
    _checkInitialized();
    final result = await _secure.getSecureObject<T>(key, defaultValue);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getSecureObject');
    }
    return result.data;
  }

  /// Remove secure data
  Future<void> removeSecure(String key) async {
    _checkInitialized();
    final result = await _secure.removeSecure(key);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'removeSecure');
    }
  }

  /// Clear all secure data
  Future<void> clearSecure() async {
    _checkInitialized();
    final result = await _secure.clearSecure();
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'clearSecure');
    }
  }

  /// Check if secure key exists
  Future<bool> containsSecureKey(String key) async {
    _checkInitialized();
    final result = await _secure.containsSecureKey(key);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'containsSecureKey');
    }
    return result.data!;
  }

  // ============================================================================
  // DATABASE OPERATIONS (Hive)
  // ============================================================================

  /// Save an object to database
  Future<void> save<T>(String boxName, T object,
      {dynamic key, bool encrypted = false}) async {
    _checkInitialized();
    final result = await _database.save<T>(boxName, object,
        key: key, encrypted: encrypted);
    if (!result.success) {
      throw StorageOperationException(result.error!, result.exception, 'save');
    }
  }

  /// Get an object from database
  Future<T?> get<T>(String boxName, dynamic key,
      {bool encrypted = false}) async {
    _checkInitialized();
    final result = await _database.get<T>(boxName, key, encrypted: encrypted);
    if (!result.success) {
      throw StorageOperationException(result.error!, result.exception, 'get');
    }
    return result.data;
  }

  /// Get all objects from a box
  Future<List<T>> getAll<T>(String boxName, {bool encrypted = false}) async {
    _checkInitialized();
    final result = await _database.getAll<T>(boxName, encrypted: encrypted);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getAll');
    }
    return result.data!;
  }

  /// Delete an object from database
  Future<void> delete(String boxName, dynamic key,
      {bool encrypted = false}) async {
    _checkInitialized();
    final result = await _database.delete(boxName, key, encrypted: encrypted);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'delete');
    }
  }

  /// Clear all objects from a box
  Future<int> clearBox(String boxName, {bool encrypted = false}) async {
    _checkInitialized();
    final result = await _database.clearBox(boxName, encrypted: encrypted);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'clearBox');
    }
    return result.data!;
  }

  /// Find objects matching criteria
  Future<List<T>> findWhere<T>(String boxName, bool Function(T) test,
      {bool encrypted = false}) async {
    _checkInitialized();
    final result =
        await _database.findWhere<T>(boxName, test, encrypted: encrypted);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'findWhere');
    }
    return result.data!;
  }

  /// Count objects in box
  Future<int> count(String boxName, {bool encrypted = false}) async {
    _checkInitialized();
    final result = await _database.count(boxName, encrypted: encrypted);
    if (!result.success) {
      throw StorageOperationException(result.error!, result.exception, 'count');
    }
    return result.data!;
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  /// Cache data with TTL
  Future<void> cache(String key, dynamic data, {Duration? duration}) async {
    _checkInitialized();
    final result = await _cache.cache(key, data, duration: duration);
    if (!result.success) {
      throw StorageOperationException(result.error!, result.exception, 'cache');
    }
  }

  /// Get cached data (returns null if expired)
  Future<T?> getCached<T>(String key) async {
    _checkInitialized();
    final result = await _cache.getCached<T>(key);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getCached');
    }
    return result.data;
  }

  /// Check if cache item exists and not expired
  Future<bool> isCacheValid(String key) async {
    _checkInitialized();
    final result = await _cache.isCacheValid(key);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'isCacheValid');
    }
    return result.data!;
  }

  /// Remove cached item
  Future<void> removeCache(String key) async {
    _checkInitialized();
    final result = await _cache.removeCache(key);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'removeCache');
    }
  }

  /// Clear all cache
  Future<int> clearCache() async {
    _checkInitialized();
    final result = await _cache.clearCache();
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'clearCache');
    }
    return result.data!;
  }

  /// Get or cache data (get from cache or execute function if not cached)
  Future<T> getOrCache<T>(String key, Future<T> Function() fetchFunction,
      {Duration? duration}) async {
    _checkInitialized();
    final result =
        await _cache.getOrCache<T>(key, fetchFunction, duration: duration);
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getOrCache');
    }
    return result.data!;
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    _checkInitialized();
    final result = await _cache.getCacheStats();
    if (!result.success) {
      throw StorageOperationException(
          result.error!, result.exception, 'getCacheStats');
    }
    return result.data!;
  }

  // ============================================================================
  // FILE OPERATIONS
  // ============================================================================

  /// Write string to file
  Future<bool> writeFile(String fileName, String content,
      {String? subDir}) async {
    _checkInitialized();
    final result = await _files.writeFile(fileName, content, subDir: subDir);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, fileName, 'writeFile');
    }
    return result.data!;
  }

  /// Read string from file
  Future<String?> readFile(String fileName, {String? subDir}) async {
    _checkInitialized();
    final result = await _files.readFile(fileName, subDir: subDir);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, fileName, 'readFile');
    }
    return result.data;
  }

  /// Write bytes to file
  Future<bool> writeBytes(String fileName, List<int> bytes,
      {String? subDir}) async {
    _checkInitialized();
    final result = await _files.writeBytes(fileName, bytes, subDir: subDir);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, fileName, 'writeBytes');
    }
    return result.data!;
  }

  /// Read bytes from file
  Future<List<int>?> readBytes(String fileName, {String? subDir}) async {
    _checkInitialized();
    final result = await _files.readBytes(fileName, subDir: subDir);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, fileName, 'readBytes');
    }
    return result.data?.toList();
  }

  /// Write JSON object to file
  Future<bool> writeJson(String fileName, dynamic object,
      {String? subDir, bool pretty = false}) async {
    _checkInitialized();
    final result = await _files.writeJson(fileName, object,
        subDir: subDir, pretty: pretty);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, fileName, 'writeJson');
    }
    return result.data!;
  }

  /// Read JSON object from file
  Future<T?> readJson<T>(String fileName, {String? subDir}) async {
    _checkInitialized();
    final result = await _files.readJson<T>(fileName, subDir: subDir);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, fileName, 'readJson');
    }
    return result.data;
  }

  /// Delete file
  Future<bool> deleteFile(String fileName, {String? subDir}) async {
    _checkInitialized();
    final result = await _files.deleteFile(fileName, subDir: subDir);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, fileName, 'deleteFile');
    }
    return result.data!;
  }

  /// Check if file exists
  Future<bool> fileExists(String fileName, {String? subDir}) async {
    _checkInitialized();
    final result = await _files.fileExists(fileName, subDir: subDir);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, fileName, 'fileExists');
    }
    return result.data!;
  }

  /// Get file size
  Future<int> getFileSize(String fileName, {String? subDir}) async {
    _checkInitialized();
    final result = await _files.getFileSize(fileName, subDir: subDir);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, fileName, 'getFileSize');
    }
    return result.data!;
  }

  /// Copy file
  Future<bool> copyFile(String sourceFileName, String destFileName,
      {String? sourceSubDir, String? destSubDir}) async {
    _checkInitialized();
    final result = await _files.copyFile(sourceFileName, destFileName,
        sourceSubDir: sourceSubDir, destSubDir: destSubDir);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, sourceFileName, 'copyFile');
    }
    return result.data!;
  }

  /// Move/rename file
  Future<bool> moveFile(String sourceFileName, String destFileName,
      {String? sourceSubDir, String? destSubDir}) async {
    _checkInitialized();
    final result = await _files.moveFile(sourceFileName, destFileName,
        sourceSubDir: sourceSubDir, destSubDir: destSubDir);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, sourceFileName, 'moveFile');
    }
    return result.data!;
  }

  /// List files in directory
  Future<List<String>> listFiles({String? subDir, String? extension}) async {
    _checkInitialized();
    final result = await _files.listFiles(subDir: subDir, extension: extension);
    if (!result.success) {
      throw FileStorageException(
          result.error!, result.exception, subDir, 'listFiles');
    }
    return result.data!;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get comprehensive storage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    _checkInitialized();

    try {
      final prefsInfo = await _prefs.getInfo();
      final dbInfo = await _database.getDatabaseInfo();
      final secureInfo = await _secure.getSecureInfo();
      final fileInfo = await _files.getFileStorageInfo();
      final cacheInfo = await _cache.getCacheStats();

      return {
        'isInitialized': _isInitialized,
        'preferences': prefsInfo.data ?? {},
        'database': dbInfo.data ?? {},
        'secureStorage': secureInfo.data ?? {},
        'fileStorage': fileInfo.data ?? {},
        'cache': cacheInfo.data ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw StorageOperationException(
          'Failed to get storage info: $e', e, 'getStorageInfo');
    }
  }

  /// Export all storage data (for backup)
  Future<Map<String, dynamic>> exportAllData() async {
    _checkInitialized();

    try {
      final prefsExport = await _prefs.export();
      final cacheExport = await _cache.exportCache();

      return {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'preferences': prefsExport.data ?? {},
        'cache': cacheExport.data ?? {},
        // Note: Secure storage and database exports require additional parameters
        // and should be handled separately for security reasons
      };
    } catch (e) {
      throw StorageOperationException(
          'Failed to export data: $e', e, 'exportAllData');
    }
  }

  /// Import storage data (for restore)
  Future<Map<String, int>> importAllData(Map<String, dynamic> data,
      {bool clearFirst = false}) async {
    _checkInitialized();

    try {
      final results = <String, int>{};

      // Import preferences
      if (data.containsKey('preferences')) {
        final prefsResult =
            await _prefs.import(data['preferences'], clearFirst: clearFirst);
        results['preferences'] = prefsResult.data ?? 0;
      }

      // Import cache
      if (data.containsKey('cache')) {
        final cacheResult =
            await _cache.importCache(data['cache'], clearFirst: clearFirst);
        results['cache'] = cacheResult.data ?? 0;
      }

      return results;
    } catch (e) {
      throw StorageOperationException(
          'Failed to import data: $e', e, 'importAllData');
    }
  }

  /// Clear all storage (nuclear option - use with caution!)
  Future<Map<String, dynamic>> clearAllStorage() async {
    _checkInitialized();

    try {
      final results = <String, dynamic>{};

      // Clear preferences
      final prefsResult = await _prefs.clear();
      results['preferences'] = prefsResult.data ?? false;

      // Clear cache
      final cacheResult = await _cache.clearCache();
      results['cache'] = cacheResult.data ?? 0;

      // Clear secure storage
      final secureResult = await _secure.clearSecure();
      results['secureStorage'] = secureResult.data ?? false;

      // Note: Database and files are not cleared automatically for safety
      // Use clearBox() and file deletion methods separately if needed

      return results;
    } catch (e) {
      throw StorageOperationException(
          'Failed to clear all storage: $e', e, 'clearAllStorage');
    }
  }
}
