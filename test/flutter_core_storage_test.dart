import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core_storage/flutter_core_storage.dart';

// Import the necessary fakes for testing platform-specific dependencies
// You might need to create these fakes if your individual services (e.g., SharedPreferences, FlutterSecureStorage)
// have platform channel dependencies. For now, we'll assume basic mocking for initialization.

void main() {
  // Setup for SharedPreferences mocking
  // This allows SharedPreferences to be used in tests without actual platform channels.
  // You might need more sophisticated mocking depending on your actual service implementations.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    setUp(() async {
      // Ensure the service is uninitialized before each test
      if (StorageService.isInitialized) {
        await StorageService.dispose();
      }
    });

    tearDown(() async {
      // Dispose the service after each test
      if (StorageService.isInitialized) {
        await StorageService.dispose();
      }
    });

    test('should initialize and dispose correctly', () async {
      expect(StorageService.isInitialized, isFalse);

      await StorageService.initialize();
      expect(StorageService.isInitialized, isTrue);
      expect(StorageService.instance, isNotNull);

      await StorageService.dispose();
      expect(StorageService.isInitialized, isFalse);
      // Accessing StorageService.instance after dispose will throw, but checking _instance directly is private.
      // So we rely on isInitialized.
    });

    test('should throw StorageInitializationException if initialization fails',
        () async {
      // Simulate a failure in one of the sub-services' initialization
      // This is a placeholder; you'd need to mock a specific service's initialize method
      // to throw an exception for a real test of this scenario.
      // For now, we'll just demonstrate the expected exception type.
      await expectLater(
        StorageService.initialize(
            config: const StorageConfig(
                enableDatabase: true)), // Assuming database init can fail
        throwsA(isA<StorageInitializationException>()),
      );
    });

    test('should throw StorageOperationException if not initialized before use',
        () async {
      // Attempt to use a method without initialization
      expect(
        () => StorageService.instance.setString('key', 'value'),
        throwsA(isA<StorageOperationException>().having(
          (e) => e.message,
          'message',
          contains('StorageService not initialized'),
        )),
      );
    });

    group('Preferences Operations', () {
      setUp(() async {
        await StorageService.initialize();
      });

      test('should set and get a string', () async {
        const key = 'testString';
        const value = 'Hello Flutter!';
        await StorageService.instance.setString(key, value);
        final retrievedValue = await StorageService.instance.getString(key);
        expect(retrievedValue, value);
      });

      test('should return default value for non-existent string', () async {
        const key = 'nonExistentString';
        const defaultValue = 'Default Value';
        final retrievedValue =
            await StorageService.instance.getString(key, defaultValue);
        expect(retrievedValue, defaultValue);
      });

      test('should set and get an int', () async {
        const key = 'testInt';
        const value = 123;
        await StorageService.instance.setInt(key, value);
        final retrievedValue = await StorageService.instance.getInt(key);
        expect(retrievedValue, value);
      });

      test('should remove a key', () async {
        const key = 'toBeRemoved';
        await StorageService.instance.setString(key, 'value');
        expect(await StorageService.instance.containsKey(key), isTrue);
        await StorageService.instance.remove(key);
        expect(await StorageService.instance.containsKey(key), isFalse);
      });

      test('should clear all preferences', () async {
        await StorageService.instance.setString('key1', 'value1');
        await StorageService.instance.setInt('key2', 123);
        expect(await StorageService.instance.getKeys(),
            containsAll(['key1', 'key2']));
        await StorageService.instance.clear();
        expect(await StorageService.instance.getKeys(), isEmpty);
      });
    });

    group('Secure Storage Operations', () {
      // Note: For FlutterSecureStorage, you often need to mock its platform channels
      // for comprehensive testing in unit tests. For simplicity, this assumes basic
      // functionality given the `flutter_test` environment setup.
      // If `SecureStorageService` internally relies on method channels,
      // you'll need to mock them using `MethodChannel.setMockMethodCallHandler`.

      setUp(() async {
        // Initialize with secure storage enabled
        await StorageService.initialize(
            config: const StorageConfig(enableSecureStorage: true));
      });

      test('should set and get secure string', () async {
        const key = 'secureKey';
        const value = 'sensitive_data';
        await StorageService.instance.setSecure(key, value);
        final retrievedValue = await StorageService.instance.getSecure(key);
        expect(retrievedValue, value);
      });

      test('should remove secure key', () async {
        const key = 'secureKeyToRemove';
        await StorageService.instance.setSecure(key, 'some data');
        expect(await StorageService.instance.containsSecureKey(key), isTrue);
        await StorageService.instance.removeSecure(key);
        expect(await StorageService.instance.containsSecureKey(key), isFalse);
      });

      test('should clear all secure data', () async {
        await StorageService.instance.setSecure('secure1', 'data1');
        await StorageService.instance.setSecure('secure2', 'data2');
        // Note: containsSecureKey isn't perfect for all stored items, but helps verify.
        expect(
            await StorageService.instance.containsSecureKey('secure1'), isTrue);
        await StorageService.instance.clearSecure();
        expect(await StorageService.instance.containsSecureKey('secure1'),
            isFalse);
      });
    });

    group('Database Operations', () {
      // Hive database testing typically requires a test path and
      // careful management of boxes. You might need to set up Hive
      // mocks or use `Hive.initFlutter()` with a test directory.

      setUp(() async {
        // Initialize with database enabled
        await StorageService.initialize(
            config: const StorageConfig(enableDatabase: true));
      });

      test('should save and get an object', () async {
        const boxName = 'myBox';
        const key = 'user1';
        final user = {'name': 'Alice', 'age': 30};
        await StorageService.instance.save(boxName, user, key: key);
        final retrievedUser = await StorageService.instance.get(boxName, key);
        expect(retrievedUser, user);
      });

      test('should get all objects from a box', () async {
        const boxName = 'items';
        await StorageService.instance.save(boxName, 'itemA', key: 'a');
        await StorageService.instance.save(boxName, 'itemB', key: 'b');
        final allItems = await StorageService.instance.getAll<String>(boxName);
        expect(allItems, containsAll(['itemA', 'itemB']));
        expect(allItems.length, 2);
      });

      test('should delete an object from a box', () async {
        const boxName = 'tempBox';
        const key = 'deleteMe';
        await StorageService.instance.save(boxName, 'data', key: key);
        expect(await StorageService.instance.get(boxName, key), isNotNull);
        await StorageService.instance.delete(boxName, key);
        expect(await StorageService.instance.get(boxName, key), isNull);
      });

      test('should clear a box', () async {
        const boxName = 'clearableBox';
        await StorageService.instance.save(boxName, 'data1');
        await StorageService.instance.save(boxName, 'data2');
        expect(await StorageService.instance.count(boxName), 2);
        await StorageService.instance.clearBox(boxName);
        expect(await StorageService.instance.count(boxName), 0);
      });
    });

    group('Cache Operations', () {
      setUp(() async {
        await StorageService.initialize();
      });

      test('should cache and retrieve data', () async {
        const key = 'cachedData';
        const data = {'message': 'This is cached!'};
        await StorageService.instance
            .cache(key, data, duration: const Duration(minutes: 5));
        final retrievedData = await StorageService.instance.getCached(key);
        expect(retrievedData, data);
        expect(await StorageService.instance.isCacheValid(key), isTrue);
      });

      test('should return null for expired cache', () async {
        const key = 'expiredData';
        await StorageService.instance.cache(key, 'will expire',
            duration: const Duration(milliseconds: 1));
        await Future.delayed(
            const Duration(milliseconds: 50)); // Wait for cache to expire
        final retrievedData = await StorageService.instance.getCached(key);
        expect(retrievedData, isNull);
        expect(await StorageService.instance.isCacheValid(key), isFalse);
      });

      test('should remove cached item', () async {
        const key = 'itemToRemove';
        await StorageService.instance.cache(key, 'some value');
        expect(await StorageService.instance.isCacheValid(key), isTrue);
        await StorageService.instance.removeCache(key);
        expect(await StorageService.instance.isCacheValid(key), isFalse);
      });

      test('should clear all cache', () async {
        await StorageService.instance.cache('cache1', 'data1');
        await StorageService.instance.cache('cache2', 'data2');
        expect(
            (await StorageService.instance.getCacheStats())['totalEntries'], 2);
        await StorageService.instance.clearCache();
        expect(
            (await StorageService.instance.getCacheStats())['totalEntries'], 0);
      });

      test('should get or cache data', () async {
        const key = 'getOrCacheTest';
        bool fetchFunctionCalled = false;
        Future<String> fetchData() async {
          fetchFunctionCalled = true;
          return 'fresh data';
        }

        // First call: data not in cache, fetch function should be called
        final result1 =
            await StorageService.instance.getOrCache(key, fetchData);
        expect(result1, 'fresh data');
        expect(fetchFunctionCalled, isTrue);

        fetchFunctionCalled = false; // Reset for second call

        // Second call: data should be in cache, fetch function should NOT be called
        final result2 =
            await StorageService.instance.getOrCache(key, fetchData);
        expect(result2, 'fresh data');
        expect(fetchFunctionCalled, isFalse);
      });
    });

    group('File Storage Operations', () {
      // File system operations in Flutter tests usually require setting up a temporary directory.
      // You might need to mock `path_provider` or use `getTemporaryDirectory` from the package.

      setUp(() async {
        await StorageService.initialize();
      });

      test('should write and read a file', () async {
        const fileName = 'test_file.txt';
        const content = 'This is content for the test file.';
        await StorageService.instance.writeFile(fileName, content);
        final retrievedContent =
            await StorageService.instance.readFile(fileName);
        expect(retrievedContent, content);
        expect(await StorageService.instance.fileExists(fileName), isTrue);
      });

      test('should delete a file', () async {
        const fileName = 'delete_me.txt';
        await StorageService.instance.writeFile(fileName, 'temporary content');
        expect(await StorageService.instance.fileExists(fileName), isTrue);
        await StorageService.instance.deleteFile(fileName);
        expect(await StorageService.instance.fileExists(fileName), isFalse);
      });

      test('should write and read JSON from file', () async {
        const fileName = 'test_json.json';
        final jsonData = {'name': 'Test', 'version': 1.0};
        await StorageService.instance.writeJson(fileName, jsonData);
        final retrievedJson = await StorageService.instance
            .readJson<Map<String, dynamic>>(fileName);
        expect(retrievedJson, jsonData);
      });

      test('should return null for non-existent file', () async {
        const fileName = 'non_existent.txt';
        final content = await StorageService.instance.readFile(fileName);
        expect(content, isNull);
      });
    });

    group('Utility Methods', () {
      setUp(() async {
        await StorageService.initialize(
          config: const StorageConfig(
              enableDatabase: true, enableSecureStorage: true),
        );
      });

      test('should get comprehensive storage info', () async {
        await StorageService.instance.setString('prefKey', 'prefValue');
        await StorageService.instance.setSecure('secureKey', 'secureValue');
        await StorageService.instance.save('dbBox', 'dbValue', key: 'dbKey');
        await StorageService.instance.writeFile('file.txt', 'fileContent');
        await StorageService.instance.cache('cacheKey', 'cacheValue');

        final info = await StorageService.instance.getStorageInfo();

        expect(info['isInitialized'], isTrue);
        expect(info['preferences'], isNotNull);
        expect(info['database'], isNotNull);
        expect(info['secureStorage'], isNotNull);
        expect(info['fileStorage'], isNotNull);
        expect(info['cache'], isNotNull);
        expect(info['timestamp'], isA<String>());

        // Further assertions on specific info data can be added here
        expect(info['preferences']['keys'], contains('prefKey'));
        expect(info['cache']['totalEntries'], 1);
      });

      test('should export and import preferences data', () async {
        await StorageService.instance.setString('expPref1', 'value1');
        await StorageService.instance.setInt('expPref2', 42);

        final exportedData = await StorageService.instance.exportAllData();
        expect(exportedData['preferences'], isNotNull);
        expect(exportedData['preferences']['expPref1'], 'value1');
        expect(exportedData['preferences']['expPref2'], 42);

        await StorageService.instance.clear(); // Clear existing preferences
        expect(await StorageService.instance.containsKey('expPref1'), isFalse);

        final importResults =
            await StorageService.instance.importAllData(exportedData);
        expect(importResults['preferences'], greaterThan(0));
        expect(await StorageService.instance.getString('expPref1'), 'value1');
        expect(await StorageService.instance.getInt('expPref2'), 42);
      });

      test('should clear all storage (preferences and cache)', () async {
        await StorageService.instance.setString('prefClear', 'value');
        await StorageService.instance.setSecure('secureClear', 'value');
        await StorageService.instance.cache('cacheClear', 'value');
        await StorageService.instance
            .save('dbClearBox', 'value'); // Database won't be cleared by this

        final clearResults = await StorageService.instance.clearAllStorage();

        expect(clearResults['preferences'],
            isTrue); // SharedPreferences clear returns bool
        expect(
            clearResults['cache'], greaterThan(0)); // Cache clear returns count
        expect(clearResults['secureStorage'],
            isTrue); // Secure storage clear returns bool

        expect(await StorageService.instance.containsKey('prefClear'), isFalse);
        expect(await StorageService.instance.containsSecureKey('secureClear'),
            isFalse);
        expect(
            (await StorageService.instance.getCacheStats())['totalEntries'], 0);
        // Database data should still exist if not explicitly cleared by clearBox
        expect(await StorageService.instance.count('dbClearBox'), 1);
      });
    });
  });
}
