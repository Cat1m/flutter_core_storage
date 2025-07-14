// test/mocks/storage_mocks.dart
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'dart:io';

// ============================================================================
// MOCK CLASSES
// ============================================================================

/// Mock for SharedPreferences
class MockSharedPreferences extends Mock implements SharedPreferences {}

/// Mock for FlutterSecureStorage
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Mock for Hive Box
class MockHiveBox<T> extends Mock implements Box<T> {}

/// Mock for File
class MockFile extends Mock implements File {}

/// Mock for Directory
class MockDirectory extends Mock implements Directory {}

// Service Mocks
class MockPreferencesService extends Mock implements PreferencesService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockFileStorageService extends Mock implements FileStorageService {}

class MockCacheService extends Mock implements CacheService {}

// ============================================================================
// TEST UTILITIES
// ============================================================================

class StorageTestUtils {
  /// Create a successful StorageResult
  static StorageResult<T> successResult<T>(T data) {
    return StorageResult.success(data);
  }

  /// Create a failed StorageResult
  static StorageResult<T> failureResult<T>(String error,
      [Exception? exception]) {
    return StorageResult.failure(error, exception);
  }

  /// Create test user data
  static Map<String, dynamic> createTestUserData({
    int id = 1,
    String name = 'Test User',
    String email = 'test@example.com',
  }) {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create test cache data
  static Map<String, dynamic> createTestCacheData() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'config': {'maxCacheSize': 100},
      'cache': {
        'test_key': {
          'data': 'test_value',
          'createdAt': DateTime.now().toIso8601String(),
          'ttl': 3600000,
        }
      },
    };
  }

  /// Setup common mock behaviors
  static void setupMockBehaviors() {
    // Register fallback values for mocktail
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(const Duration(hours: 1));
    registerFallbackValue(DateTime.now());
  }
}

// ============================================================================
// BASE TEST CLASS
// ============================================================================

abstract class StorageTestBase {
  late MockPreferencesService mockPreferencesService;
  late MockDatabaseService mockDatabaseService;
  late MockSecureStorageService mockSecureStorageService;
  late MockFileStorageService mockFileStorageService;
  late MockCacheService mockCacheService;

  void setUp() {
    StorageTestUtils.setupMockBehaviors();

    mockPreferencesService = MockPreferencesService();
    mockDatabaseService = MockDatabaseService();
    mockSecureStorageService = MockSecureStorageService();
    mockFileStorageService = MockFileStorageService();
    mockCacheService = MockCacheService();
  }

  void tearDown() {
    reset(mockPreferencesService);
    reset(mockDatabaseService);
    reset(mockSecureStorageService);
    reset(mockFileStorageService);
    reset(mockCacheService);
  }
}
