// test/services/preferences_service_test.dart
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks/storage_mocks.dart';

void main() {
  group('PreferencesService', () {
    late MockSharedPreferences mockSharedPreferences;
    late PreferencesService preferencesService;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();

      // Mock SharedPreferences.getInstance()
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      reset(mockSharedPreferences);
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // Act
        await PreferencesService.initialize();

        // Assert
        expect(PreferencesService.isInitialized, isTrue);
      });

      test('should not reinitialize if already initialized', () async {
        // Arrange
        await PreferencesService.initialize();
        expect(PreferencesService.isInitialized, isTrue);

        // Act & Assert - should not throw
        await PreferencesService.initialize();
        expect(PreferencesService.isInitialized, isTrue);
      });
    });

    group('String Operations', () {
      setUp(() async {
        await PreferencesService.initialize();
        preferencesService = PreferencesService.instance;
      });

      test('should store string successfully', () async {
        // Arrange
        const key = 'test_key';
        const value = 'test_value';

        // Act
        final result = await preferencesService.setString(key, value);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isTrue);
      });

      test('should retrieve stored string', () async {
        // Arrange
        const key = 'test_key';
        const value = 'test_value';
        await preferencesService.setString(key, value);

        // Act
        final result = await preferencesService.getString(key);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, equals(value));
      });

      test('should return default value for non-existent key', () async {
        // Arrange
        const key = 'non_existent_key';
        const defaultValue = 'default';

        // Act
        final result = await preferencesService.getString(key, defaultValue);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, equals(defaultValue));
      });

      test('should return null for non-existent key without default', () async {
        // Arrange
        const key = 'non_existent_key';

        // Act
        final result = await preferencesService.getString(key);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isNull);
      });

      test('should handle invalid key format', () async {
        // Arrange
        const invalidKey = '';

        // Act
        final result = await preferencesService.setString(invalidKey, 'value');

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Invalid key format'));
      });
    });

    group('Integer Operations', () {
      setUp(() async {
        await PreferencesService.initialize();
        preferencesService = PreferencesService.instance;
      });

      test('should store and retrieve integer', () async {
        // Arrange
        const key = 'int_key';
        const value = 42;

        // Act
        final setResult = await preferencesService.setInt(key, value);
        final getResult = await preferencesService.getInt(key);

        // Assert
        expect(setResult.success, isTrue);
        expect(getResult.success, isTrue);
        expect(getResult.data, equals(value));
      });

      test('should return default value for non-existent integer key',
          () async {
        // Arrange
        const key = 'non_existent_int';
        const defaultValue = 99;

        // Act
        final result = await preferencesService.getInt(key, defaultValue);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, equals(defaultValue));
      });
    });

    group('Boolean Operations', () {
      setUp(() async {
        await PreferencesService.initialize();
        preferencesService = PreferencesService.instance;
      });

      test('should store and retrieve boolean', () async {
        // Arrange
        const key = 'bool_key';
        const value = true;

        // Act
        final setResult = await preferencesService.setBool(key, value);
        final getResult = await preferencesService.getBool(key);

        // Assert
        expect(setResult.success, isTrue);
        expect(getResult.success, isTrue);
        expect(getResult.data, equals(value));
      });
    });

    group('Double Operations', () {
      setUp(() async {
        await PreferencesService.initialize();
        preferencesService = PreferencesService.instance;
      });

      test('should store and retrieve double', () async {
        // Arrange
        const key = 'double_key';
        const value = 3.14;

        // Act
        final setResult = await preferencesService.setDouble(key, value);
        final getResult = await preferencesService.getDouble(key);

        // Assert
        expect(setResult.success, isTrue);
        expect(getResult.success, isTrue);
        expect(getResult.data, equals(value));
      });
    });

    group('String List Operations', () {
      setUp(() async {
        await PreferencesService.initialize();
        preferencesService = PreferencesService.instance;
      });

      test('should store and retrieve string list', () async {
        // Arrange
        const key = 'list_key';
        const value = ['item1', 'item2', 'item3'];

        // Act
        final setResult = await preferencesService.setStringList(key, value);
        final getResult = await preferencesService.getStringList(key);

        // Assert
        expect(setResult.success, isTrue);
        expect(getResult.success, isTrue);
        expect(getResult.data, equals(value));
      });
    });

    group('Object Operations', () {
      setUp(() async {
        await PreferencesService.initialize();
        preferencesService = PreferencesService.instance;
      });

      test('should store and retrieve object as JSON', () async {
        // Arrange
        const key = 'object_key';
        final value = {'name': 'John', 'age': 30, 'active': true};

        // Act
        final setResult = await preferencesService.setObject(key, value);
        final getResult =
            await preferencesService.getObject<Map<String, dynamic>>(key);

        // Assert
        expect(setResult.success, isTrue);
        expect(getResult.success, isTrue);
        expect(getResult.data, equals(value));
      });

      test('should handle complex nested objects', () async {
        // Arrange
        const key = 'complex_object';
        final value = {
          'user': {
            'id': 1,
            'profile': {
              'name': 'John Doe',
              'preferences': ['dark_mode', 'notifications']
            }
          },
          'settings': {'theme': 'dark', 'language': 'en'}
        };

        // Act
        final setResult = await preferencesService.setObject(key, value);
        final getResult =
            await preferencesService.getObject<Map<String, dynamic>>(key);

        // Assert
        expect(setResult.success, isTrue);
        expect(getResult.success, isTrue);
        expect(getResult.data, equals(value));
      });
    });

    group('Key Management', () {
      setUp(() async {
        await PreferencesService.initialize();
        preferencesService = PreferencesService.instance;
      });

      test('should check if key exists', () async {
        // Arrange
        const key = 'existing_key';
        await preferencesService.setString(key, 'value');

        // Act
        final existsResult = await preferencesService.containsKey(key);
        final notExistsResult =
            await preferencesService.containsKey('non_existent');

        // Assert
        expect(existsResult.success, isTrue);
        expect(existsResult.data, isTrue);
        expect(notExistsResult.success, isTrue);
        expect(notExistsResult.data, isFalse);
      });

      test('should remove key', () async {
        // Arrange
        const key = 'key_to_remove';
        await preferencesService.setString(key, 'value');

        // Act
        final removeResult = await preferencesService.remove(key);
        final checkResult = await preferencesService.containsKey(key);

        // Assert
        expect(removeResult.success, isTrue);
        expect(removeResult.data, isTrue);
        expect(checkResult.data, isFalse);
      });

      test('should get all keys', () async {
        // Arrange
        await preferencesService.setString('key1', 'value1');
        await preferencesService.setString('key2', 'value2');
        await preferencesService.setInt('key3', 123);

        // Act
        final result = await preferencesService.getKeys();

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isA<Set<String>>());
        expect(result.data!.length, greaterThanOrEqualTo(3));
        expect(result.data, containsAll(['key1', 'key2', 'key3']));
      });

      test('should clear all preferences', () async {
        // Arrange
        await preferencesService.setString('key1', 'value1');
        await preferencesService.setString('key2', 'value2');

        // Act
        final clearResult = await preferencesService.clear();
        final keysResult = await preferencesService.getKeys();

        // Assert
        expect(clearResult.success, isTrue);
        expect(clearResult.data, isTrue);
        expect(keysResult.data, isEmpty);
      });
    });

    group('Pattern Matching', () {
      setUp(() async {
        await PreferencesService.initialize();
        preferencesService = PreferencesService.instance;
      });

      test('should get keys matching pattern', () async {
        // Arrange
        await preferencesService.setString('user_name', 'john');
        await preferencesService.setString('user_email', 'john@example.com');
        await preferencesService.setString('app_version', '1.0.0');

        // Act
        final result = await preferencesService.getKeysMatching(r'^user_');

        // Assert
        expect(result.success, isTrue);
        expect(result.data, hasLength(2));
        expect(result.data, containsAll(['user_name', 'user_email']));
        expect(result.data, isNot(contains('app_version')));
      });

      test('should clear keys matching pattern', () async {
        // Arrange
        await preferencesService.setString('temp_data1', 'value1');
        await preferencesService.setString('temp_data2', 'value2');
        await preferencesService.setString('permanent_data', 'value3');

        // Act
        final clearResult = await preferencesService.clearMatching(r'^temp_');
        final remainingKeys = await preferencesService.getKeys();

        // Assert
        expect(clearResult.success, isTrue);
        expect(clearResult.data, equals(2));
        expect(remainingKeys.data, contains('permanent_data'));
        expect(remainingKeys.data, isNot(contains('temp_data1')));
        expect(remainingKeys.data, isNot(contains('temp_data2')));
      });
    });

    group('Import/Export', () {
      setUp(() async {
        await PreferencesService.initialize();
        preferencesService = PreferencesService.instance;
      });

      test('should export preferences', () async {
        // Arrange
        await preferencesService.setString('key1', 'value1');
        await preferencesService.setInt('key2', 42);
        await preferencesService.setBool('key3', true);

        // Act
        final result = await preferencesService.export();

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isA<Map<String, dynamic>>());
        expect(result.data!['key1'], equals('value1'));
        expect(result.data!['key2'], equals(42));
        expect(result.data!['key3'], equals(true));
      });

      test('should import preferences', () async {
        // Arrange
        final dataToImport = {
          'imported_string': 'test_value',
          'imported_int': 99,
          'imported_bool': false,
          'imported_list': ['a', 'b', 'c'],
        };

        // Act
        final importResult = await preferencesService.import(dataToImport);
        final stringResult =
            await preferencesService.getString('imported_string');
        final intResult = await preferencesService.getInt('imported_int');

        // Assert
        expect(importResult.success, isTrue);
        expect(importResult.data, equals(4));
        expect(stringResult.data, equals('test_value'));
        expect(intResult.data, equals(99));
      });

      test('should import with clear first option', () async {
        // Arrange
        await preferencesService.setString('existing_key', 'existing_value');
        final dataToImport = {'new_key': 'new_value'};

        // Act
        final importResult =
            await preferencesService.import(dataToImport, clearFirst: true);
        final existingResult =
            await preferencesService.getString('existing_key');
        final newResult = await preferencesService.getString('new_key');

        // Assert
        expect(importResult.success, isTrue);
        expect(existingResult.data, isNull);
        expect(newResult.data, equals('new_value'));
      });
    });

    group('Error Handling', () {
      test('should throw when accessing service before initialization', () {
        // Arrange - Don't initialize the service

        // Act & Assert
        expect(
          () => PreferencesService.instance,
          throwsA(isA<StorageOperationException>()),
        );
      });
    });

    group('Utility Methods', () {
      setUp(() async {
        await PreferencesService.initialize();
        preferencesService = PreferencesService.instance;
      });

      test('should calculate storage size', () async {
        // Arrange
        await preferencesService.setString('key1', 'short');
        await preferencesService.setString(
            'key2', 'a much longer string value for testing');

        // Act
        final result = await preferencesService.getStorageSize();

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isA<int>());
        expect(result.data!, greaterThan(0));
      });

      test('should get preferences info', () async {
        // Arrange
        await preferencesService.setString('test_key', 'test_value');

        // Act
        final result = await preferencesService.getInfo();

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isA<Map<String, dynamic>>());
        expect(result.data!['keyCount'], isA<int>());
        expect(result.data!['totalSize'], isA<int>());
        expect(result.data!['isInitialized'], isTrue);
        expect(result.data!['keys'], isA<List>());
      });

      test('should reload preferences', () async {
        // Act
        final result = await preferencesService.reload();

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isTrue);
      });
    });
  });
}
