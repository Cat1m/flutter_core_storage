// test/services/cache_service_test.dart
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../mocks/storage_mocks.dart';

void main() {
  group('CacheService', () {
    const testKey = 'test_key';
    const testData = 'test_data';
    const testTTL = Duration(minutes: 30);

    setUp(() {
      StorageTestUtils.setupMockBehaviors();
    });

    tearDown(() async {
      if (CacheService.isInitialized) {
        await CacheService.dispose();
      }
    });

    group('Initialization', () {
      test('should initialize successfully with default values', () async {
        // Act
        await CacheService.initialize();

        // Assert
        expect(CacheService.isInitialized, isTrue);
      });

      test('should initialize with custom configuration', () async {
        // Act
        await CacheService.initialize(
          maxCacheSize: 50,
          defaultTTL: const Duration(minutes: 15),
          cleanupInterval: const Duration(minutes: 5),
        );

        // Assert
        expect(CacheService.isInitialized, isTrue);

        final statsResult = await CacheService.instance.getCacheStats();
        expect(statsResult.success, isTrue);
        expect(statsResult.data!['maxSize'], equals(50));
      });

      test('should not reinitialize if already initialized', () async {
        // Arrange
        await CacheService.initialize();
        expect(CacheService.isInitialized, isTrue);

        // Act & Assert - should not throw
        await CacheService.initialize();
        expect(CacheService.isInitialized, isTrue);
      });

      test('should dispose successfully', () async {
        // Arrange
        await CacheService.initialize();
        await CacheService.instance.cache(testKey, testData);

        // Act
        await CacheService.dispose();

        // Assert
        expect(CacheService.isInitialized, isFalse);
      });
    });

    group('Basic Cache Operations', () {
      setUp(() async {
        await CacheService.initialize();
      });

      test('should cache data successfully', () async {
        // Act
        final result = await CacheService.instance.cache(testKey, testData);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isTrue);
      });

      test('should cache data with custom TTL', () async {
        // Act
        final result = await CacheService.instance.cache(
          testKey,
          testData,
          duration: testTTL,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isTrue);
      });

      test('should retrieve cached data', () async {
        // Arrange
        await CacheService.instance.cache(testKey, testData);

        // Act
        final result = await CacheService.instance.getCached<String>(testKey);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, equals(testData));
      });

      test('should return null for non-existent key', () async {
        // Act
        final result =
            await CacheService.instance.getCached<String>('non_existent');

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isNull);
      });

      test('should check cache validity', () async {
        // Arrange
        await CacheService.instance.cache(testKey, testData);

        // Act
        final validResult = await CacheService.instance.isCacheValid(testKey);
        final invalidResult =
            await CacheService.instance.isCacheValid('non_existent');

        // Assert
        expect(validResult.success, isTrue);
        expect(validResult.data, isTrue);
        expect(invalidResult.success, isTrue);
        expect(invalidResult.data, isFalse);
      });

      test('should remove cached item', () async {
        // Arrange
        await CacheService.instance.cache(testKey, testData);

        // Act
        final removeResult = await CacheService.instance.removeCache(testKey);
        final getResult =
            await CacheService.instance.getCached<String>(testKey);

        // Assert
        expect(removeResult.success, isTrue);
        expect(removeResult.data, isTrue);
        expect(getResult.data, isNull);
      });

      test('should clear all cache', () async {
        // Arrange
        await CacheService.instance.cache('key1', 'data1');
        await CacheService.instance.cache('key2', 'data2');
        await CacheService.instance.cache('key3', 'data3');

        // Act
        final clearResult = await CacheService.instance.clearCache();
        final key1Result =
            await CacheService.instance.getCached<String>('key1');

        // Assert
        expect(clearResult.success, isTrue);
        expect(clearResult.data, equals(3));
        expect(key1Result.data, isNull);
      });

      test('should handle invalid key formats', () async {
        // Act
        final result = await CacheService.instance.cache('', testData);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Invalid key format'));
      });
    });

    group('TTL and Expiration', () {
      setUp(() async {
        await CacheService.initialize();
      });

      test('should expire cached data after TTL', () async {
        // Arrange
        const shortTTL = Duration(milliseconds: 100);
        await CacheService.instance
            .cache(testKey, testData, duration: shortTTL);

        // Act - Wait for expiration
        await Future.delayed(const Duration(milliseconds: 150));
        final result = await CacheService.instance.getCached<String>(testKey);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isNull);
      });

      test('should update TTL of existing item', () async {
        // Arrange
        await CacheService.instance.cache(testKey, testData, duration: testTTL);

        // Act
        final updateResult = await CacheService.instance.updateTTL(
          testKey,
          const Duration(hours: 2),
        );

        // Assert
        expect(updateResult.success, isTrue);
        expect(updateResult.data, isTrue);
      });

      test('should refresh cache item', () async {
        // Arrange
        await CacheService.instance.cache(testKey, testData);

        // Act
        final refreshResult = await CacheService.instance.refreshCache(testKey);

        // Assert
        expect(refreshResult.success, isTrue);
        expect(refreshResult.data, isTrue);
      });

      test('should fail to update TTL for non-existent item', () async {
        // Act
        final result = await CacheService.instance.updateTTL(
          'non_existent',
          testTTL,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('not found'));
      });
    });

    group('Advanced Operations', () {
      setUp(() async {
        await CacheService.initialize();
      });

      test('should get cache item with metadata', () async {
        // Arrange
        await CacheService.instance.cache(testKey, testData, duration: testTTL);

        // Act
        final result =
            await CacheService.instance.getCacheItem<String>(testKey);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isA<CacheItem<String>>());
        expect(result.data!.data, equals(testData));
        expect(result.data!.ttl, equals(testTTL));
        expect(result.data!.isExpired, isFalse);
      });

      test('should get or cache data', () async {
        // Arrange
        var fetchCallCount = 0;
        Future<String> fetchFunction() async {
          fetchCallCount++;
          return 'fetched_data_$fetchCallCount';
        }

        // Act - First call should fetch
        final result1 = await CacheService.instance.getOrCache(
          testKey,
          fetchFunction,
          duration: testTTL,
        );

        // Act - Second call should use cache
        final result2 = await CacheService.instance.getOrCache(
          testKey,
          fetchFunction,
          duration: testTTL,
        );

        // Assert
        expect(result1.success, isTrue);
        expect(result1.data, equals('fetched_data_1'));
        expect(result2.success, isTrue);
        expect(result2.data, equals('fetched_data_1')); // Same data from cache
        expect(fetchCallCount, equals(1)); // Function called only once
      });

      test('should handle complex data types', () async {
        // Arrange
        final complexData = {
          'user': {
            'id': 123,
            'name': 'Test User',
            'preferences': ['dark_mode', 'notifications']
          },
          'metadata': {
            'created': DateTime.now().toIso8601String(),
            'version': 1.5,
          }
        };

        // Act
        await CacheService.instance.cache(testKey, complexData);
        final result = await CacheService.instance
            .getCached<Map<String, dynamic>>(testKey);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, equals(complexData));
      });
    });

    group('Cache Management', () {
      setUp(() async {
        await CacheService.initialize(maxCacheSize: 3);
      });

      test('should evict LRU item when cache is full', () async {
        // Arrange - Fill cache to max capacity
        await CacheService.instance.cache('key1', 'data1');
        await CacheService.instance.cache('key2', 'data2');
        await CacheService.instance.cache('key3', 'data3');

        // Act - Add one more item (should evict oldest)
        await CacheService.instance.cache('key4', 'data4');

        // Assert
        final key1Result =
            await CacheService.instance.getCached<String>('key1');
        final key4Result =
            await CacheService.instance.getCached<String>('key4');

        expect(key1Result.data, isNull); // Should be evicted
        expect(key4Result.data, equals('data4')); // Should exist
      });

      test('should get cache keys', () async {
        // Arrange
        await CacheService.instance.cache('key1', 'data1');
        await CacheService.instance.cache('key2', 'data2');

        // Act
        final result = await CacheService.instance.getCacheKeys();

        // Assert
        expect(result.success, isTrue);
        expect(result.data, hasLength(2));
        expect(result.data, containsAll(['key1', 'key2']));
      });

      test('should get cache keys matching pattern', () async {
        // Arrange
        await CacheService.instance.cache('user_123', 'user_data');
        await CacheService.instance.cache('user_456', 'user_data');
        await CacheService.instance.cache('session_abc', 'session_data');

        // Act
        final result =
            await CacheService.instance.getCacheKeysMatching(r'^user_');

        // Assert
        expect(result.success, isTrue);
        expect(result.data, hasLength(2));
        expect(result.data, containsAll(['user_123', 'user_456']));
        expect(result.data, isNot(contains('session_abc')));
      });

      test('should clear cache matching pattern', () async {
        // Arrange
        await CacheService.instance.cache('temp_1', 'data1');
        await CacheService.instance.cache('temp_2', 'data2');
        await CacheService.instance.cache('permanent', 'data3');

        // Act
        final result =
            await CacheService.instance.clearCacheMatching(r'^temp_');

        // Assert
        expect(result.success, isTrue);
        expect(result.data, equals(2));

        final permanentResult =
            await CacheService.instance.getCached<String>('permanent');
        expect(permanentResult.data, equals('data3'));
      });

      test('should cleanup expired items', () async {
        // Arrange
        const shortTTL = Duration(milliseconds: 50);
        await CacheService.instance.cache('key1', 'data1', duration: shortTTL);
        await CacheService.instance.cache('key2', 'data2'); // Long TTL

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final result = await CacheService.instance.cleanupExpired();

        // Assert
        expect(result.success, isTrue);
        expect(result.data, equals(1)); // One expired item removed

        final key2Result =
            await CacheService.instance.getCached<String>('key2');
        expect(key2Result.data, equals('data2')); // Should still exist
      });
    });

    group('Statistics and Info', () {
      setUp(() async {
        await CacheService.initialize();
      });

      test('should get cache statistics', () async {
        // Arrange
        await CacheService.instance.cache('key1', 'data1');
        await CacheService.instance.getCached<String>('key1'); // Hit
        await CacheService.instance.getCached<String>('non_existent'); // Miss

        // Act
        final result = await CacheService.instance.getCacheStats();

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isA<Map<String, dynamic>>());
        expect(result.data!['size'], equals(1));
        expect(result.data!['hits'], equals(1));
        expect(result.data!['misses'], equals(1));
        expect(result.data!['hitRate'], isA<double>());
        expect(result.data!['isInitialized'], isTrue);
      });

      test('should get detailed cache info', () async {
        // Arrange
        await CacheService.instance.cache('key1', 'data1', duration: testTTL);

        // Act
        final result = await CacheService.instance.getCacheInfo();

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isA<Map<String, dynamic>>());
        expect(result.data!['stats'], isA<Map<String, dynamic>>());
        expect(result.data!['items'], isA<List>());
        expect(result.data!['items'], hasLength(1));

        final item = result.data!['items'][0];
        expect(item['key'], equals('key1'));
        expect(item['isExpired'], isFalse);
        expect(item['dataType'], contains('String'));
      });

      test('should reset statistics', () async {
        // Arrange
        await CacheService.instance.cache('key1', 'data1');
        await CacheService.instance.getCached<String>('key1');

        // Act
        final resetResult = await CacheService.instance.resetStats();
        final statsResult = await CacheService.instance.getCacheStats();

        // Assert
        expect(resetResult.success, isTrue);
        expect(statsResult.data!['hits'], equals(0));
        expect(statsResult.data!['misses'], equals(0));
        expect(statsResult.data!['evictions'], equals(0));
      });
    });

    group('Import/Export', () {
      setUp(() async {
        await CacheService.initialize();
      });

      test('should export cache data', () async {
        // Arrange
        await CacheService.instance.cache('key1', 'data1');
        await CacheService.instance.cache('key2', {'nested': 'object'});

        // Act
        final result = await CacheService.instance.exportCache();

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isA<Map<String, dynamic>>());
        expect(result.data!['cache'], isA<Map<String, dynamic>>());
        expect(result.data!['cache']['key1'], isA<Map<String, dynamic>>());
        expect(result.data!['version'], equals('1.0'));
        expect(result.data!['timestamp'], isA<String>());
      });

      test('should import cache data', () async {
        // Arrange
        final exportData = StorageTestUtils.createTestCacheData();

        // Act
        final result = await CacheService.instance.importCache(exportData);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, greaterThan(0));

        final retrievedResult =
            await CacheService.instance.getCached<String>('test_key');
        expect(retrievedResult.data, equals('test_value'));
      });

      test('should import with clear first option', () async {
        // Arrange
        await CacheService.instance.cache('existing_key', 'existing_data');
        final exportData = StorageTestUtils.createTestCacheData();

        // Act
        final result = await CacheService.instance
            .importCache(exportData, clearFirst: true);

        // Assert
        expect(result.success, isTrue);

        final existingResult =
            await CacheService.instance.getCached<String>('existing_key');
        expect(existingResult.data, isNull);
      });
    });

    group('Configuration', () {
      test('should set cache configuration', () async {
        // Arrange
        await CacheService.initialize();

        // Act
        final result = await CacheService.instance.setConfig(
          maxCacheSize: 50,
          defaultTTL: const Duration(minutes: 45),
        );

        // Assert
        expect(result.success, isTrue);

        final statsResult = await CacheService.instance.getCacheStats();
        expect(statsResult.data!['maxSize'], equals(50));
      });

      test('should evict items when reducing max cache size', () async {
        // Arrange
        await CacheService.initialize(maxCacheSize: 5);

        // Fill cache
        for (int i = 0; i < 5; i++) {
          await CacheService.instance.cache('key$i', 'data$i');
        }

        // Act - Reduce cache size
        await CacheService.instance.setConfig(maxCacheSize: 3);

        // Assert
        final statsResult = await CacheService.instance.getCacheStats();
        expect(statsResult.data!['size'], lessThanOrEqualTo(3));
      });
    });

    group('Error Handling', () {
      test('should throw when accessing service before initialization', () {
        // Act & Assert
        expect(
          () => CacheService.instance,
          throwsA(isA<Exception>()),
        );
      });

      test('should handle serialization errors gracefully', () async {
        // Arrange
        await CacheService.initialize();

        // This would typically cause issues in real serialization
        final problematicData = <String, dynamic>{};
        problematicData['self_reference'] = problematicData;

        // Act
        final result =
            await CacheService.instance.cache(testKey, problematicData);

        // Assert - Should handle gracefully, either succeed or fail with proper error
        expect(result, isA<StorageResult>());
      });
    });
  });
}
