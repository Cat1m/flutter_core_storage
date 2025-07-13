import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/storage_result.dart';
import '../models/database_model.dart';
import '../exceptions/storage_exceptions.dart';

import '../utils/serialization_utils.dart';

/// Service for database operations using Hive
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance!;

  static bool _isInitialized = false;

  // Opened boxes cache
  final Map<String, Box> _openBoxes = {};

  // Registered adapters
  final Map<Type, int> _registeredAdapters = {};

  // Database configuration
  String? _encryptionKey;
  bool _compactionEnabled = true;

  // Private constructor
  DatabaseService._();

  /// Initialize the database service
  static Future<void> initialize({
    String? encryptionKey,
    bool compactionEnabled = true,
    List<TypeAdapter>? adapters,
  }) async {
    if (_isInitialized) return;

    try {
      _instance = DatabaseService._();
      _instance!._encryptionKey = encryptionKey;
      _instance!._compactionEnabled = compactionEnabled;

      // Initialize Hive
      await Hive.initFlutter();

      // Register default adapters
      await _instance!._registerDefaultAdapters();

      // Register custom adapters if provided
      if (adapters != null) {
        for (final adapter in adapters) {
          await _instance!._registerAdapter(adapter);
        }
      }

      _isInitialized = true;
      debugPrint('✅ DatabaseService initialized successfully');
    } catch (e) {
      debugPrint('❌ DatabaseService initialization failed: $e');
      throw StorageInitializationException(
          'Failed to initialize database service: $e');
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Dispose the database service
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      // Close all open boxes
      for (final box in _instance!._openBoxes.values) {
        await box.close();
      }
      _instance!._openBoxes.clear();

      // Close Hive
      await Hive.close();

      _instance = null;
      _isInitialized = false;

      debugPrint('✅ DatabaseService disposed successfully');
    } catch (e) {
      debugPrint('❌ DatabaseService disposal failed: $e');
    }
  }

  /// Register default adapters
  Future<void> _registerDefaultAdapters() async {
    // Register built-in adapters here if needed
    debugPrint('📦 Registered default adapters');
  }

  /// Register a type adapter
  Future<StorageResult<bool>> _registerAdapter(TypeAdapter adapter) async {
    try {
      if (_registeredAdapters.containsKey(adapter.runtimeType)) {
        debugPrint('⚠️ Adapter already registered: ${adapter.runtimeType}');
        return StorageResult.success(true);
      }

      Hive.registerAdapter(adapter);
      _registeredAdapters[adapter.runtimeType] = adapter.typeId;

      debugPrint(
          '📦 Registered adapter: ${adapter.runtimeType} (typeId: ${adapter.typeId})');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to register adapter: ${adapter.runtimeType} - $e');
      return StorageResult.failure('Failed to register adapter: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Register adapter externally
  Future<StorageResult<bool>> registerAdapter(TypeAdapter adapter) async {
    return await _registerAdapter(adapter);
  }

  // ============================================================================
  // BOX MANAGEMENT
  // ============================================================================

  /// Open a box
  Future<StorageResult<Box<T>>> openBox<T>(String boxName,
      {bool encrypted = false}) async {
    try {
      if (_openBoxes.containsKey(boxName)) {
        debugPrint('📦 Box already open: $boxName');
        return StorageResult.success(_openBoxes[boxName] as Box<T>);
      }

      Box<T> box;

      if (encrypted && _encryptionKey != null) {
        final encryptionKeyBytes = _encryptionKey!.codeUnits;
        box = await Hive.openBox<T>(
          boxName,
          encryptionCipher: HiveAesCipher(encryptionKeyBytes),
        );
      } else {
        box = await Hive.openBox<T>(boxName);
      }

      _openBoxes[boxName] = box;

      debugPrint('📦 Opened box: $boxName (encrypted: $encrypted)');
      return StorageResult.success(box);
    } catch (e) {
      debugPrint('❌ Failed to open box: $boxName - $e');
      return StorageResult.failure('Failed to open box: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Close a box
  Future<StorageResult<bool>> closeBox(String boxName) async {
    try {
      final box = _openBoxes[boxName];
      if (box == null) {
        debugPrint('⚠️ Box not open: $boxName');
        return StorageResult.success(true);
      }

      await box.close();
      _openBoxes.remove(boxName);

      debugPrint('📦 Closed box: $boxName');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to close box: $boxName - $e');
      return StorageResult.failure('Failed to close box: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get or open box
  Future<StorageResult<Box<T>>> _getBox<T>(String boxName,
      {bool encrypted = false}) async {
    if (_openBoxes.containsKey(boxName)) {
      return StorageResult.success(_openBoxes[boxName] as Box<T>);
    }

    return await openBox<T>(boxName, encrypted: encrypted);
  }

  /// Delete a box (removes all data and the box file)
  Future<StorageResult<bool>> deleteBox(String boxName) async {
    try {
      // Close the box first if it's open
      if (_openBoxes.containsKey(boxName)) {
        await closeBox(boxName);
      }

      await Hive.deleteBoxFromDisk(boxName);

      debugPrint('🗑️ Deleted box: $boxName');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to delete box: $boxName - $e');
      return StorageResult.failure('Failed to delete box: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Check if box exists
  Future<StorageResult<bool>> boxExists(String boxName) async {
    try {
      final exists = await Hive.boxExists(boxName);

      debugPrint('🔍 Box exists: $boxName = $exists');
      return StorageResult.success(exists);
    } catch (e) {
      debugPrint('❌ Failed to check box existence: $boxName - $e');
      return StorageResult.failure('Failed to check box existence: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // BASIC DATABASE OPERATIONS
  // ============================================================================

  /// Save an object to database
  Future<StorageResult<bool>> save<T>(String boxName, T object,
      {dynamic key, bool encrypted = false}) async {
    try {
      final boxResult = await _getBox<T>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;

      // Call beforeSave if object is DatabaseModel
      if (object is DatabaseModel) {
        object.beforeSave();
      }

      if (key != null) {
        await box.put(key, object);
      } else {
        await box.add(object);
      }

      // Call afterSave if object is DatabaseModel
      if (object is DatabaseModel) {
        object.afterSave();
      }

      // Compact box if enabled
      if (_compactionEnabled && box.length % 100 == 0) {
        await box.compact();
      }

      debugPrint(
          '💾 Saved object to database: $boxName${key != null ? '[$key]' : ''}');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to save object: $boxName - $e');
      return StorageResult.failure('Failed to save object: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get an object from database
  Future<StorageResult<T?>> get<T>(String boxName, dynamic key,
      {bool encrypted = false}) async {
    try {
      final boxResult = await _getBox<T>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;
      final object = box.get(key);

      debugPrint(
          '📖 Retrieved object from database: $boxName[$key]${object != null ? ' (found)' : ' (not found)'}');
      return StorageResult.success(object);
    } catch (e) {
      debugPrint('❌ Failed to get object: $boxName[$key] - $e');
      return StorageResult.failure('Failed to get object: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get all objects from a box
  Future<StorageResult<List<T>>> getAll<T>(String boxName,
      {bool encrypted = false}) async {
    try {
      final boxResult = await _getBox<T>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;
      final objects = box.values.toList();

      debugPrint(
          '📖 Retrieved all objects from database: $boxName (${objects.length} items)');
      return StorageResult.success(objects);
    } catch (e) {
      debugPrint('❌ Failed to get all objects: $boxName - $e');
      return StorageResult.failure('Failed to get all objects: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Delete an object from database
  Future<StorageResult<bool>> delete(String boxName, dynamic key,
      {bool encrypted = false}) async {
    try {
      final boxResult = await _getBox<dynamic>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;

      // Get object for beforeDelete callback
      final object = box.get(key);
      if (object is DatabaseModel) {
        object.beforeDelete();
      }

      await box.delete(key);

      // Call afterDelete
      if (object is DatabaseModel) {
        object.afterDelete();
      }

      debugPrint('🗑️ Deleted object from database: $boxName[$key]');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to delete object: $boxName[$key] - $e');
      return StorageResult.failure('Failed to delete object: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Clear all objects from a box
  Future<StorageResult<int>> clearBox(String boxName,
      {bool encrypted = false}) async {
    try {
      final boxResult = await _getBox<dynamic>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;
      final count = box.length;

      await box.clear();

      debugPrint('🧹 Cleared box: $boxName ($count items removed)');
      return StorageResult.success(count);
    } catch (e) {
      debugPrint('❌ Failed to clear box: $boxName - $e');
      return StorageResult.failure('Failed to clear box: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // ADVANCED QUERY OPERATIONS
  // ============================================================================

  /// Find objects matching criteria
  Future<StorageResult<List<T>>> findWhere<T>(
    String boxName,
    bool Function(T) test, {
    bool encrypted = false,
  }) async {
    try {
      final allResult = await getAll<T>(boxName, encrypted: encrypted);
      if (!allResult.success) {
        return StorageResult.failure(
            'Failed to get all objects: ${allResult.error}');
      }

      final filtered = allResult.data!.where(test).toList();

      debugPrint(
          '🔍 Found ${filtered.length} objects matching criteria in $boxName');
      return StorageResult.success(filtered);
    } catch (e) {
      debugPrint('❌ Failed to find objects: $boxName - $e');
      return StorageResult.failure('Failed to find objects: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Find first object matching criteria
  Future<StorageResult<T?>> findFirst<T>(
    String boxName,
    bool Function(T) test, {
    bool encrypted = false,
  }) async {
    try {
      final whereResult =
          await findWhere<T>(boxName, test, encrypted: encrypted);
      if (!whereResult.success) {
        return StorageResult.failure(
            'Failed to find objects: ${whereResult.error}');
      }

      final first =
          whereResult.data!.isNotEmpty ? whereResult.data!.first : null;

      debugPrint(
          '🔍 Found first object matching criteria in $boxName: ${first != null ? 'found' : 'not found'}');
      return StorageResult.success(first);
    } catch (e) {
      debugPrint('❌ Failed to find first object: $boxName - $e');
      return StorageResult.failure('Failed to find first object: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Update objects matching criteria
  Future<StorageResult<int>> updateWhere<T>(
    String boxName,
    bool Function(T) test,
    T Function(T) update, {
    bool encrypted = false,
  }) async {
    try {
      final boxResult = await _getBox<T>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;
      int updatedCount = 0;

      for (final key in box.keys) {
        final object = box.get(key);
        if (object != null && test(object)) {
          final updatedObject = update(object);
          await box.put(key, updatedObject);
          updatedCount++;
        }
      }

      debugPrint('✏️ Updated $updatedCount objects in $boxName');
      return StorageResult.success(updatedCount);
    } catch (e) {
      debugPrint('❌ Failed to update objects: $boxName - $e');
      return StorageResult.failure('Failed to update objects: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Delete objects matching criteria
  Future<StorageResult<int>> deleteWhere<T>(
    String boxName,
    bool Function(T) test, {
    bool encrypted = false,
  }) async {
    try {
      final boxResult = await _getBox<T>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;
      final keysToDelete = <dynamic>[];

      for (final key in box.keys) {
        final object = box.get(key);
        if (object != null && test(object)) {
          keysToDelete.add(key);
        }
      }

      for (final key in keysToDelete) {
        await box.delete(key);
      }

      debugPrint('🗑️ Deleted ${keysToDelete.length} objects from $boxName');
      return StorageResult.success(keysToDelete.length);
    } catch (e) {
      debugPrint('❌ Failed to delete objects: $boxName - $e');
      return StorageResult.failure('Failed to delete objects: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Count objects in box
  Future<StorageResult<int>> count(String boxName,
      {bool encrypted = false}) async {
    try {
      final boxResult = await _getBox<dynamic>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;
      final count = box.length;

      debugPrint('📊 Count objects in $boxName: $count');
      return StorageResult.success(count);
    } catch (e) {
      debugPrint('❌ Failed to count objects: $boxName - $e');
      return StorageResult.failure('Failed to count objects: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Check if key exists
  Future<StorageResult<bool>> containsKey(String boxName, dynamic key,
      {bool encrypted = false}) async {
    try {
      final boxResult = await _getBox<dynamic>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;
      final exists = box.containsKey(key);

      debugPrint('🔍 Key exists in $boxName[$key]: $exists');
      return StorageResult.success(exists);
    } catch (e) {
      debugPrint('❌ Failed to check key existence: $boxName[$key] - $e');
      return StorageResult.failure('Failed to check key existence: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // BATCH OPERATIONS
  // ============================================================================

  /// Save multiple objects
  Future<StorageResult<int>> saveAll<T>(
    String boxName,
    Map<dynamic, T> objects, {
    bool encrypted = false,
  }) async {
    try {
      final boxResult = await _getBox<T>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;

      // Call beforeSave for all DatabaseModel objects
      for (final object in objects.values) {
        if (object is DatabaseModel) {
          object.beforeSave();
        }
      }

      await box.putAll(objects);

      // Call afterSave for all DatabaseModel objects
      for (final object in objects.values) {
        if (object is DatabaseModel) {
          object.afterSave();
        }
      }

      debugPrint('💾 Saved ${objects.length} objects to database: $boxName');
      return StorageResult.success(objects.length);
    } catch (e) {
      debugPrint('❌ Failed to save multiple objects: $boxName - $e');
      return StorageResult.failure('Failed to save multiple objects: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Delete multiple keys
  Future<StorageResult<int>> deleteAll(String boxName, Iterable<dynamic> keys,
      {bool encrypted = false}) async {
    try {
      final boxResult = await _getBox<dynamic>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;

      // Get objects for beforeDelete callback
      final objects = <dynamic>[];
      for (final key in keys) {
        final object = box.get(key);
        if (object != null) {
          objects.add(object);
          if (object is DatabaseModel) {
            object.beforeDelete();
          }
        }
      }

      await box.deleteAll(keys);

      // Call afterDelete
      for (final object in objects) {
        if (object is DatabaseModel) {
          object.afterDelete();
        }
      }

      debugPrint('🗑️ Deleted ${keys.length} objects from database: $boxName');
      return StorageResult.success(keys.length);
    } catch (e) {
      debugPrint('❌ Failed to delete multiple objects: $boxName - $e');
      return StorageResult.failure('Failed to delete multiple objects: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // DATABASE MAINTENANCE
  // ============================================================================

  /// Compact a box (remove deleted entries)
  Future<StorageResult<bool>> compactBox(String boxName,
      {bool encrypted = false}) async {
    try {
      final boxResult = await _getBox<dynamic>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;
      await box.compact();

      debugPrint('🗜️ Compacted box: $boxName');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to compact box: $boxName - $e');
      return StorageResult.failure('Failed to compact box: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get database info
  Future<StorageResult<Map<String, dynamic>>> getDatabaseInfo() async {
    try {
      final openBoxes = _openBoxes.keys.toList();
      final boxesInfo = <Map<String, dynamic>>[];

      for (final boxName in openBoxes) {
        final box = _openBoxes[boxName]!;
        boxesInfo.add({
          'name': boxName,
          'length': box.length,
          'keys': box.keys.toList(),
          'isEmpty': box.isEmpty,
          'isNotEmpty': box.isNotEmpty,
        });
      }

      final info = {
        'isInitialized': _isInitialized,
        'openBoxesCount': _openBoxes.length,
        'openBoxes': openBoxes,
        'boxesInfo': boxesInfo,
        'registeredAdapters': _registeredAdapters.length,
        'encryptionEnabled': _encryptionKey != null,
        'compactionEnabled': _compactionEnabled,
      };

      return StorageResult.success(info);
    } catch (e) {
      debugPrint('❌ Failed to get database info: $e');
      return StorageResult.failure('Failed to get database info: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Export box data to JSON
  Future<StorageResult<Map<String, dynamic>>> exportBox(String boxName,
      {bool encrypted = false}) async {
    try {
      final boxResult = await _getBox<dynamic>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;
      final exportData = <String, dynamic>{};

      for (final key in box.keys) {
        final value = box.get(key);
        exportData[key.toString()] = SerializationUtils.toMap(value);
      }

      final export = {
        'boxName': boxName,
        'timestamp': DateTime.now().toIso8601String(),
        'count': exportData.length,
        'data': exportData,
      };

      debugPrint('📤 Exported box data: $boxName (${exportData.length} items)');
      return StorageResult.success(export);
    } catch (e) {
      debugPrint('❌ Failed to export box: $boxName - $e');
      return StorageResult.failure('Failed to export box: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Import box data from JSON
  Future<StorageResult<int>> importBox(
    String boxName,
    Map<String, dynamic> data, {
    bool clearFirst = false,
    bool encrypted = false,
  }) async {
    try {
      final boxResult = await _getBox<dynamic>(boxName, encrypted: encrypted);
      if (!boxResult.success) {
        return StorageResult.failure('Failed to get box: ${boxResult.error}');
      }

      final box = boxResult.data!;

      if (clearFirst) {
        await box.clear();
      }

      final importData = data['data'] as Map<String, dynamic>? ?? {};
      int importedCount = 0;

      for (final entry in importData.entries) {
        try {
          await box.put(entry.key, entry.value);
          importedCount++;
        } catch (e) {
          debugPrint('⚠️ Failed to import item ${entry.key}: $e');
        }
      }

      debugPrint(
          '📥 Imported box data: $boxName ($importedCount/${importData.length} items)');
      return StorageResult.success(importedCount);
    } catch (e) {
      debugPrint('❌ Failed to import box: $boxName - $e');
      return StorageResult.failure('Failed to import box: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get all box names
  Future<StorageResult<List<String>>> getAllBoxNames() async {
    try {
      // This is a simplified implementation - in reality, you'd need to scan the filesystem
      final openBoxes = _openBoxes.keys.toList();

      debugPrint('📦 All box names: $openBoxes');
      return StorageResult.success(openBoxes);
    } catch (e) {
      debugPrint('❌ Failed to get all box names: $e');
      return StorageResult.failure('Failed to get all box names: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Watch box for changes
  Stream<BoxEvent> watchBox(String boxName, {dynamic key}) {
    final box = _openBoxes[boxName];
    if (box == null) {
      throw StorageOperationException('Box not open: $boxName');
    }

    if (key != null) {
      return box.watch(key: key);
    } else {
      return box.watch();
    }
  }
}
