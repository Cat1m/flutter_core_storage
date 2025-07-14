// test/performance/storage_benchmark_test.dart
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helper.dart';

void main() {
  group('Storage Performance Benchmarks', () {
    setUp(() {
      TestHelper.setUp();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      if (StorageService.isInitialized) {
        await StorageService.dispose();
      }
    });

    group('Throughput Tests', () {
      test('preferences operations throughput', () async {
        await StorageService.initialize();

        const operations = 1000;
        final results = <String, double>{};

        // String operations
        var stopwatch = Stopwatch()..start();
        for (int i = 0; i < operations; i++) {
          await StorageService.instance.setString('string_$i', 'value_$i');
        }
        stopwatch.stop();
        results['string_writes_per_sec'] =
            operations / (stopwatch.elapsedMilliseconds / 1000);

        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < operations; i++) {
          await StorageService.instance.getString('string_$i');
        }
        stopwatch.stop();
        results['string_reads_per_sec'] =
            operations / (stopwatch.elapsedMilliseconds / 1000);

        // Object operations
        final testObject = {
          'id': 1,
          'name': 'test',
          'data': List.generate(100, (i) => 'item_$i')
        };

        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 100; i++) {
          await StorageService.instance.setObject('object_$i', testObject);
        }
        stopwatch.stop();
        results['object_writes_per_sec'] =
            100 / (stopwatch.elapsedMilliseconds / 1000);

        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 100; i++) {
          await StorageService.instance
              .getObject<Map<String, dynamic>>('object_$i');
        }
        stopwatch.stop();
        results['object_reads_per_sec'] =
            100 / (stopwatch.elapsedMilliseconds / 1000);

        // Print results
        print('\n=== Preferences Performance Benchmark ===');
        results.forEach((key, value) {
          print('$key: ${value.toStringAsFixed(2)}');
        });

        // Assert minimum performance expectations
        expect(results['string_writes_per_sec']!, greaterThan(100));
        expect(results['string_reads_per_sec']!, greaterThan(200));
      });

      test('cache operations throughput', () async {
        await StorageService.initialize();

        const operations = 500;
        final results = <String, double>{};

        // Cache writes
        var stopwatch = Stopwatch()..start();
        for (int i = 0; i < operations; i++) {
          await StorageService.instance.cache('cache_$i', 'cached_value_$i');
        }
        stopwatch.stop();
        results['cache_writes_per_sec'] =
            operations / (stopwatch.elapsedMilliseconds / 1000);

        // Cache reads (hits)
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < operations; i++) {
          await StorageService.instance.getCached<String>('cache_$i');
        }
        stopwatch.stop();
        results['cache_reads_per_sec'] =
            operations / (stopwatch.elapsedMilliseconds / 1000);

        // Cache misses
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < 100; i++) {
          await StorageService.instance.getCached<String>('missing_$i');
        }
        stopwatch.stop();
        results['cache_misses_per_sec'] =
            100 / (stopwatch.elapsedMilliseconds / 1000);

        print('\n=== Cache Performance Benchmark ===');
        results.forEach((key, value) {
          print('$key: ${value.toStringAsFixed(2)}');
        });

        // Assert performance expectations
        expect(results['cache_writes_per_sec']!, greaterThan(50));
        expect(results['cache_reads_per_sec']!, greaterThan(100));
        expect(results['cache_misses_per_sec']!,
            greaterThan(200)); // Misses should be faster
      });
    });

    group('Memory Usage Tests', () {
      test('should measure memory efficiency', () async {
        await StorageService.initialize();

        // Create test data of known sizes
        final smallData = 'small';
        final mediumData = List.generate(1000, (i) => 'item_$i').join(',');
        final largeData =
            List.generate(10000, (i) => 'large_item_$i').join(',');

        // Store different sizes
        await StorageService.instance.cache('small', smallData);
        await StorageService.instance.cache('medium', mediumData);
        await StorageService.instance.cache('large', largeData);

        // Get cache info to check memory usage
        final cacheInfo = await StorageService.instance.getCacheStats();

        print('\n=== Memory Usage Test ===');
        print('Cache size: ${cacheInfo['size']} items');
        print('Max cache size: ${cacheInfo['maxSize']}');
        print('Small data length: ${smallData.length}');
        print('Medium data length: ${mediumData.length}');
        print('Large data length: ${largeData.length}');

        // Verify data can be retrieved
        final retrievedSmall =
            await StorageService.instance.getCached<String>('small');
        final retrievedMedium =
            await StorageService.instance.getCached<String>('medium');
        final retrievedLarge =
            await StorageService.instance.getCached<String>('large');

        expect(retrievedSmall, equals(smallData));
        expect(retrievedMedium, equals(mediumData));
        expect(retrievedLarge, equals(largeData));
      });
    });

    group('Concurrency Tests', () {
      test('should handle concurrent operations efficiently', () async {
        await StorageService.initialize();

        const concurrentOperations = 100;
        final stopwatch = Stopwatch()..start();

        // Create concurrent operations
        final futures = <Future>[];

        // Mix of different operation types
        for (int i = 0; i < concurrentOperations; i++) {
          if (i % 4 == 0) {
            futures.add(StorageService.instance
                .setString('concurrent_pref_$i', 'value_$i'));
          } else if (i % 4 == 1) {
            futures.add(StorageService.instance
                .cache('concurrent_cache_$i', 'cached_$i'));
          } else if (i % 4 == 2) {
            futures.add(StorageService.instance.setObject(
                'concurrent_obj_$i', {'id': i, 'data': 'object_$i'}));
          } else {
            futures.add(StorageService.instance
                .writeFile('concurrent_file_$i.txt', 'file_content_$i'));
          }
        }

        // Wait for all operations
        await Future.wait(futures);
        stopwatch.stop();

        final totalTime = stopwatch.elapsedMilliseconds;
        final operationsPerSecond = concurrentOperations / (totalTime / 1000);

        print('\n=== Concurrency Test ===');
        print('Total operations: $concurrentOperations');
        print('Total time: ${totalTime}ms');
        print(
            'Operations per second: ${operationsPerSecond.toStringAsFixed(2)}');

        // Verify all operations completed successfully
        for (int i = 0; i < concurrentOperations; i++) {
          if (i % 4 == 0) {
            final value =
                await StorageService.instance.getString('concurrent_pref_$i');
            expect(value, equals('value_$i'));
          } else if (i % 4 == 1) {
            final cached = await StorageService.instance
                .getCached<String>('concurrent_cache_$i');
            expect(cached, equals('cached_$i'));
          }
          // Add more verifications as needed
        }

        expect(operationsPerSecond,
            greaterThan(50)); // Minimum expected performance
      });
    });
  });
}
