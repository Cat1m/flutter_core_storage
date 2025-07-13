import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/storage_result.dart';
import '../exceptions/storage_exceptions.dart';
import '../utils/storage_utils.dart';
import '../utils/serialization_utils.dart';

/// Service for simple key-value storage using SharedPreferences
class PreferencesService {
  static PreferencesService? _instance;
  static PreferencesService get instance => _instance!;

  SharedPreferences? _prefs;
  static bool _isInitialized = false;

  // Add this for testing purposes
  @visibleForTesting
  static void setTestInstance(PreferencesService? instance) {
    _instance = instance;
  }

  // Private constructor
  PreferencesService._();

  /// Initialize the preferences service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _instance = PreferencesService._();
      _instance!._prefs = await SharedPreferences.getInstance();
      _isInitialized = true;

      debugPrint('✅ PreferencesService initialized successfully');
    } catch (e) {
      debugPrint('❌ PreferencesService initialization failed: $e');
      throw StorageInitializationException(
          'Failed to initialize SharedPreferences: $e');
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StorageOperationException(
          'PreferencesService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ============================================================================
  // STRING OPERATIONS
  // ============================================================================

  /// Store a string value
  Future<StorageResult<bool>> setString(String key, String value) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final success = await prefs.setString(sanitizedKey, value);

      debugPrint(
          '📝 Stored string: $sanitizedKey = ${value.length > 50 ? '${value.substring(0, 50)}...' : value}');
      return StorageResult.success(success);
    } catch (e) {
      debugPrint('❌ Failed to store string: $key - $e');
      return StorageResult.failure('Failed to store string: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get a string value
  Future<StorageResult<String?>> getString(String key,
      [String? defaultValue]) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final value = prefs.getString(sanitizedKey) ?? defaultValue;

      debugPrint(
          '📖 Retrieved string: $sanitizedKey = ${value?.length != null && value!.length > 50 ? '${value.substring(0, 50)}...' : value}');
      return StorageResult.success(value);
    } catch (e) {
      debugPrint('❌ Failed to retrieve string: $key - $e');
      return StorageResult.failure('Failed to retrieve string: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // INTEGER OPERATIONS
  // ============================================================================

  /// Store an integer value
  Future<StorageResult<bool>> setInt(String key, int value) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final success = await prefs.setInt(sanitizedKey, value);

      debugPrint('📝 Stored int: $sanitizedKey = $value');
      return StorageResult.success(success);
    } catch (e) {
      debugPrint('❌ Failed to store int: $key - $e');
      return StorageResult.failure('Failed to store int: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get an integer value
  Future<StorageResult<int?>> getInt(String key, [int? defaultValue]) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final value = prefs.getInt(sanitizedKey) ?? defaultValue;

      debugPrint('📖 Retrieved int: $sanitizedKey = $value');
      return StorageResult.success(value);
    } catch (e) {
      debugPrint('❌ Failed to retrieve int: $key - $e');
      return StorageResult.failure('Failed to retrieve int: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // BOOLEAN OPERATIONS
  // ============================================================================

  /// Store a boolean value
  Future<StorageResult<bool>> setBool(String key, bool value) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final success = await prefs.setBool(sanitizedKey, value);

      debugPrint('📝 Stored bool: $sanitizedKey = $value');
      return StorageResult.success(success);
    } catch (e) {
      debugPrint('❌ Failed to store bool: $key - $e');
      return StorageResult.failure('Failed to store bool: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get a boolean value
  Future<StorageResult<bool?>> getBool(String key, [bool? defaultValue]) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final value = prefs.getBool(sanitizedKey) ?? defaultValue;

      debugPrint('📖 Retrieved bool: $sanitizedKey = $value');
      return StorageResult.success(value);
    } catch (e) {
      debugPrint('❌ Failed to retrieve bool: $key - $e');
      return StorageResult.failure('Failed to retrieve bool: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // DOUBLE OPERATIONS
  // ============================================================================

  /// Store a double value
  Future<StorageResult<bool>> setDouble(String key, double value) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final success = await prefs.setDouble(sanitizedKey, value);

      debugPrint('📝 Stored double: $sanitizedKey = $value');
      return StorageResult.success(success);
    } catch (e) {
      debugPrint('❌ Failed to store double: $key - $e');
      return StorageResult.failure('Failed to store double: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get a double value
  Future<StorageResult<double?>> getDouble(String key,
      [double? defaultValue]) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final value = prefs.getDouble(sanitizedKey) ?? defaultValue;

      debugPrint('📖 Retrieved double: $sanitizedKey = $value');
      return StorageResult.success(value);
    } catch (e) {
      debugPrint('❌ Failed to retrieve double: $key - $e');
      return StorageResult.failure('Failed to retrieve double: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // STRING LIST OPERATIONS
  // ============================================================================

  /// Store a list of strings
  Future<StorageResult<bool>> setStringList(
      String key, List<String> value) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final success = await prefs.setStringList(sanitizedKey, value);

      debugPrint(
          '📝 Stored string list: $sanitizedKey = [${value.length} items]');
      return StorageResult.success(success);
    } catch (e) {
      debugPrint('❌ Failed to store string list: $key - $e');
      return StorageResult.failure('Failed to store string list: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get a list of strings
  Future<StorageResult<List<String>?>> getStringList(String key,
      [List<String>? defaultValue]) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final value = prefs.getStringList(sanitizedKey) ?? defaultValue;

      debugPrint(
          '📖 Retrieved string list: $sanitizedKey = [${value?.length ?? 0} items]');
      return StorageResult.success(value);
    } catch (e) {
      debugPrint('❌ Failed to retrieve string list: $key - $e');
      return StorageResult.failure('Failed to retrieve string list: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // OBJECT OPERATIONS (using JSON serialization)
  // ============================================================================

  /// Store any object as JSON
  Future<StorageResult<bool>> setObject(String key, dynamic object) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final jsonString = SerializationUtils.toJsonString(object);
      return await setString(key, jsonString);
    } catch (e) {
      debugPrint('❌ Failed to store object: $key - $e');
      return StorageResult.failure('Failed to store object: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get object from JSON
  Future<StorageResult<T?>> getObject<T>(String key, [T? defaultValue]) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final stringResult = await getString(key);
      if (!stringResult.success || stringResult.data == null) {
        return StorageResult.success(defaultValue);
      }

      final object = SerializationUtils.fromJsonString<T>(stringResult.data!);
      return StorageResult.success(object ?? defaultValue);
    } catch (e) {
      debugPrint('❌ Failed to retrieve object: $key - $e');
      return StorageResult.failure('Failed to retrieve object: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // KEY MANAGEMENT
  // ============================================================================

  /// Check if key exists
  Future<StorageResult<bool>> containsKey(String key) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final exists = prefs.containsKey(sanitizedKey);

      debugPrint('🔍 Key exists: $sanitizedKey = $exists');
      return StorageResult.success(exists);
    } catch (e) {
      debugPrint('❌ Failed to check key: $key - $e');
      return StorageResult.failure('Failed to check key: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Remove a key
  Future<StorageResult<bool>> remove(String key) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final success = await prefs.remove(sanitizedKey);

      debugPrint('🗑️ Removed key: $sanitizedKey = $success');
      return StorageResult.success(success);
    } catch (e) {
      debugPrint('❌ Failed to remove key: $key - $e');
      return StorageResult.failure('Failed to remove key: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get all keys
  Future<StorageResult<Set<String>>> getKeys() async {
    try {
      final keys = prefs.getKeys();

      debugPrint('🔑 Retrieved ${keys.length} keys');
      return StorageResult.success(keys);
    } catch (e) {
      debugPrint('❌ Failed to get keys: $e');
      return StorageResult.failure('Failed to get keys: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get keys matching pattern
  Future<StorageResult<Set<String>>> getKeysMatching(String pattern) async {
    try {
      final allKeys = prefs.getKeys();
      final regex = RegExp(pattern);
      final matchingKeys = allKeys.where((key) => regex.hasMatch(key)).toSet();

      debugPrint(
          '🔍 Found ${matchingKeys.length} keys matching pattern: $pattern');
      return StorageResult.success(matchingKeys);
    } catch (e) {
      debugPrint('❌ Failed to get keys matching pattern: $e');
      return StorageResult.failure('Failed to get keys matching pattern: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Clear all preferences
  Future<StorageResult<bool>> clear() async {
    try {
      final success = await prefs.clear();

      debugPrint('🧹 Cleared all preferences: $success');
      return StorageResult.success(success);
    } catch (e) {
      debugPrint('❌ Failed to clear preferences: $e');
      return StorageResult.failure('Failed to clear preferences: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Clear keys matching pattern
  Future<StorageResult<int>> clearMatching(String pattern) async {
    try {
      final keysResult = await getKeysMatching(pattern);
      if (!keysResult.success) {
        return StorageResult.failure(
            keysResult.error ?? 'Failed to get matching keys');
      }

      int removedCount = 0;
      for (final key in keysResult.data!) {
        final removeResult = await remove(key);
        if (removeResult.success && removeResult.data == true) {
          removedCount++;
        }
      }

      debugPrint('🧹 Cleared $removedCount keys matching pattern: $pattern');
      return StorageResult.success(removedCount);
    } catch (e) {
      debugPrint('❌ Failed to clear matching keys: $e');
      return StorageResult.failure('Failed to clear matching keys: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get storage size (approximate)
  Future<StorageResult<int>> getStorageSize() async {
    try {
      final keys = prefs.getKeys();
      int totalSize = 0;

      for (final key in keys) {
        final value = prefs.get(key);
        totalSize += key.length;
        totalSize += SerializationUtils.getObjectSize(value);
      }

      debugPrint('📊 Storage size: ${StorageUtils.formatFileSize(totalSize)}');
      return StorageResult.success(totalSize);
    } catch (e) {
      debugPrint('❌ Failed to calculate storage size: $e');
      return StorageResult.failure('Failed to calculate storage size: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Export all preferences to Map
  Future<StorageResult<Map<String, dynamic>>> export() async {
    try {
      final keys = prefs.getKeys();
      final exported = <String, dynamic>{};

      for (final key in keys) {
        exported[key] = prefs.get(key);
      }

      debugPrint('📤 Exported ${exported.length} preferences');
      return StorageResult.success(exported);
    } catch (e) {
      debugPrint('❌ Failed to export preferences: $e');
      return StorageResult.failure('Failed to export preferences: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Import preferences from Map
  Future<StorageResult<int>> import(Map<String, dynamic> data,
      {bool clearFirst = false}) async {
    try {
      if (clearFirst) {
        await clear();
      }

      int importedCount = 0;
      for (final entry in data.entries) {
        try {
          final value = entry.value;
          bool success = false;

          if (value is String) {
            success = await prefs.setString(entry.key, value);
          } else if (value is int) {
            success = await prefs.setInt(entry.key, value);
          } else if (value is double) {
            success = await prefs.setDouble(entry.key, value);
          } else if (value is bool) {
            success = await prefs.setBool(entry.key, value);
          } else if (value is List<String>) {
            success = await prefs.setStringList(entry.key, value);
          } else {
            // Convert to JSON string for complex objects
            final jsonString = SerializationUtils.toJsonString(value);
            success = await prefs.setString(entry.key, jsonString);
          }

          if (success) importedCount++;
        } catch (e) {
          debugPrint('⚠️ Failed to import key ${entry.key}: $e');
        }
      }

      debugPrint('📥 Imported $importedCount/${data.length} preferences');
      return StorageResult.success(importedCount);
    } catch (e) {
      debugPrint('❌ Failed to import preferences: $e');
      return StorageResult.failure('Failed to import preferences: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Reload preferences from storage
  Future<StorageResult<bool>> reload() async {
    try {
      await prefs.reload();

      debugPrint('🔄 Reloaded preferences');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to reload preferences: $e');
      return StorageResult.failure('Failed to reload preferences: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get detailed info about preferences
  Future<StorageResult<Map<String, dynamic>>> getInfo() async {
    try {
      final keys = prefs.getKeys();
      final sizeResult = await getStorageSize();

      final info = {
        'keyCount': keys.length,
        'totalSize': sizeResult.data ?? 0,
        'formattedSize': StorageUtils.formatFileSize(sizeResult.data ?? 0),
        'isInitialized': _isInitialized,
        'keys': keys.toList(),
      };

      return StorageResult.success(info);
    } catch (e) {
      debugPrint('❌ Failed to get preferences info: $e');
      return StorageResult.failure('Failed to get preferences info: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }
}
