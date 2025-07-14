// test/integration/storage_integration_test.dart
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helper.dart';

void main() {
  group('Storage Integration Tests', () {
    setUp(() {
      TestHelper.setUp();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      if (StorageService.isInitialized) {
        await StorageService.dispose();
      }
    });

    group('End-to-End User Scenarios', () {
      test('should handle complete user session workflow', () async {
        // Arrange
        await StorageService.initialize(config: StorageConfig.development());

        // Simulate user login
        const userId = 'user123';
        const userToken = 'jwt_token_12345';
        final userProfile = {
          'id': userId,
          'name': 'John Doe',
          'email': 'john@example.com',
          'preferences': {
            'theme': 'dark',
            'notifications': true,
            'language': 'en'
          }
        };

        // Act - Store user session data
        await StorageService.instance.setSecure('auth_token', userToken);
        await StorageService.instance.setObject('user_profile', userProfile);
        await StorageService.instance.setBool('remember_login', true);

        // Cache frequently accessed data
        await StorageService.instance.cache(
          'user_$userId',
          userProfile,
          duration: const Duration(hours: 4),
        );

        // Store user preferences
        final preferences = userProfile['preferences'] as Map<String, dynamic>;
        for (final entry in preferences.entries) {
          await StorageService.instance
              .setObject('pref_${entry.key}', entry.value);
        }

        // Act - Simulate app restart by getting data back
        final retrievedToken =
            await StorageService.instance.getSecure('auth_token');
        final retrievedProfile = await StorageService.instance
            .getObject<Map<String, dynamic>>('user_profile');
        final shouldRememberLogin =
            await StorageService.instance.getBool('remember_login');
        final cachedUser = await StorageService.instance
            .getCached<Map<String, dynamic>>('user_$userId');
        final themePreference =
            await StorageService.instance.getObject<String>('pref_theme');

        // Assert - All data should be retrievable
        expect(retrievedToken, equals(userToken));
        expect(retrievedProfile!['name'], equals('John Doe'));
        expect(shouldRememberLogin, isTrue);
        expect(cachedUser!['email'], equals('john@example.com'));
        expect(themePreference, equals('dark'));

        // Simulate user logout
        await StorageService.instance.removeSecure('auth_token');
        await StorageService.instance.removeCache('user_$userId');
        await StorageService.instance.setBool('remember_login', false);

        // Verify cleanup
        final tokenAfterLogout =
            await StorageService.instance.getSecure('auth_token');
        final cachedAfterLogout = await StorageService.instance
            .getCached<Map<String, dynamic>>('user_$userId');

        expect(tokenAfterLogout, isNull);
        expect(cachedAfterLogout, isNull);
      });

      test('should handle app settings and configuration', () async {
        // Arrange
        await StorageService.initialize();

        final appSettings = {
          'version': '1.2.3',
          'api_endpoint': 'https://api.example.com',
          'features': {
            'dark_mode': true,
            'analytics': false,
            'offline_mode': true,
          },
          'limits': {
            'max_cache_size': 100,
            'request_timeout': 30,
          }
        };

        // Act - Store app configuration
        await StorageService.instance.writeJson('app_config.json', appSettings);

        // Store individual settings for quick access
        await StorageService.instance.setBool('dark_mode_enabled', true);
        await StorageService.instance.setInt('request_timeout', 30);
        await StorageService.instance
            .setString('api_endpoint', 'https://api.example.com');

        // Cache configuration for performance
        await StorageService.instance.cache(
          'app_config',
          appSettings,
          duration: const Duration(days: 1),
        );

        // Act - Retrieve settings in different ways
        final configFromFile = await StorageService.instance
            .readJson<Map<String, dynamic>>('app_config.json');
        final darkModeEnabled =
            await StorageService.instance.getBool('dark_mode_enabled');
        final timeout = await StorageService.instance.getInt('request_timeout');
        final cachedConfig = await StorageService.instance
            .getCached<Map<String, dynamic>>('app_config');

        // Assert
        expect(configFromFile!['version'], equals('1.2.3'));
        expect(darkModeEnabled, isTrue);
        expect(timeout, equals(30));
        expect(cachedConfig!['limits']['max_cache_size'], equals(100));

        // Test configuration updates
        await StorageService.instance.setBool('dark_mode_enabled', false);
        final updatedDarkMode =
            await StorageService.instance.getBool('dark_mode_enabled');
        expect(updatedDarkMode, isFalse);
      });

      test('should handle offline data synchronization scenario', () async {
        // Arrange
        await StorageService.initialize();

        // Simulate offline data queue
        final offlineActions = [
          {
            'type': 'create_post',
            'data': {'title': 'Post 1', 'content': 'Content 1'}
          },
          {
            'type': 'update_profile',
            'data': {'name': 'Updated Name'}
          },
          {
            'type': 'like_post',
            'data': {'post_id': 123}
          },
        ];

        // Act - Store offline actions
        for (int i = 0; i < offlineActions.length; i++) {
          await StorageService.instance.save(
            'offline_queue',
            offlineActions[i],
            key: 'action_$i',
          );
        }

        // Store metadata
        await StorageService.instance
            .setInt('offline_actions_count', offlineActions.length);
        await StorageService.instance
            .setString('last_sync', DateTime.now().toIso8601String());

        // Act - Retrieve offline queue
        final queuedActions = await StorageService.instance
            .getAll<Map<String, dynamic>>('offline_queue');
        final actionCount =
            await StorageService.instance.getInt('offline_actions_count');

        // Assert
        expect(queuedActions, hasLength(3));
        expect(actionCount, equals(3));
        expect(queuedActions.first['type'], equals('create_post'));

        // Simulate sync completion
        await StorageService.instance.clearBox('offline_queue');
        await StorageService.instance.setInt('offline_actions_count', 0);
        await StorageService.instance
            .setString('last_sync', DateTime.now().toIso8601String());

        final actionsAfterSync = await StorageService.instance
            .getAll<Map<String, dynamic>>('offline_queue');
        expect(actionsAfterSync, isEmpty);
      });
    });

    group('Data Migration Scenarios', () {
      test('should handle version migration', () async {
        // Arrange - Simulate old version data
        await StorageService.initialize();

        // Old version data structure
        await StorageService.instance.setString('app_version', '1.0.0');
        await StorageService.instance
            .setString('user_data', '{"id":1,"name":"John"}');

        // Act - Simulate version upgrade
        const newVersion = '2.0.0';
        final currentVersion =
            await StorageService.instance.getString('app_version');

        if (currentVersion == '1.0.0') {
          // Migrate user data from string to object
          final oldUserDataString =
              await StorageService.instance.getString('user_data');
          if (oldUserDataString != null) {
            // In real app, you'd parse JSON properly
            final newUserData = {
              'id': 1,
              'name': 'John',
              'version': newVersion,
              'migrated_at': DateTime.now().toIso8601String(),
            };

            await StorageService.instance
                .setObject('user_profile', newUserData);
            await StorageService.instance
                .remove('user_data'); // Remove old format
          }
        }

        await StorageService.instance.setString('app_version', newVersion);

        // Assert
        final migratedProfile = await StorageService.instance
            .getObject<Map<String, dynamic>>('user_profile');
        final updatedVersion =
            await StorageService.instance.getString('app_version');
        final oldDataExists =
            await StorageService.instance.containsKey('user_data');

        expect(migratedProfile!['name'], equals('John'));
        expect(migratedProfile['version'], equals(newVersion));
        expect(updatedVersion, equals(newVersion));
        expect(oldDataExists, isFalse);
      });

      test('should handle data export and import', () async {
        // Arrange
        await StorageService.initialize();

        // Create test data
        await StorageService.instance.setString('setting1', 'value1');
        await StorageService.instance.setInt('setting2', 42);
        await StorageService.instance.setBool('setting3', true);
        await StorageService.instance.cache('cache1', 'cached_data');

        // Act - Export data
        final exportedData = await StorageService.instance.exportAllData();

        // Clear storage
        await StorageService.instance.clearAllStorage();

        // Verify data is cleared
        final setting1AfterClear =
            await StorageService.instance.getString('setting1');
        expect(setting1AfterClear, isNull);

        // Import data back
        final importResults =
            await StorageService.instance.importAllData(exportedData);

        // Assert
        expect(importResults['preferences'], greaterThan(0));

        final setting1Restored =
            await StorageService.instance.getString('setting1');
        final setting2Restored =
            await StorageService.instance.getInt('setting2');
        final setting3Restored =
            await StorageService.instance.getBool('setting3');

        expect(setting1Restored, equals('value1'));
        expect(setting2Restored, equals(42));
        expect(setting3Restored, equals(true));
      });
    });

    group('Performance and Stress Tests', () {
      test('should handle large number of operations efficiently', () async {
        // Arrange
        await StorageService.initialize();
        const operationCount = 1000;

        // Act - Measure bulk operations
        final stopwatch = Stopwatch()..start();

        // Bulk write operations
        for (int i = 0; i < operationCount; i++) {
          await StorageService.instance.setString('bulk_key_$i', 'value_$i');
        }

        final writeTime = stopwatch.elapsedMilliseconds;
        stopwatch.reset();

        // Bulk read operations
        for (int i = 0; i < operationCount; i++) {
          await StorageService.instance.getString('bulk_key_$i');
        }

        final readTime = stopwatch.elapsedMilliseconds;
        stopwatch.stop();

        // Assert - Operations should complete in reasonable time
        expect(writeTime, lessThan(5000)); // Less than 5 seconds
        expect(readTime, lessThan(3000)); // Less than 3 seconds

        print('Write time for $operationCount operations: ${writeTime}ms');
        print('Read time for $operationCount operations: ${readTime}ms');

        // Cleanup
        await StorageService.instance.clear();
      });

      test('should handle cache performance under load', () async {
        // Arrange
        await StorageService.initialize();
        const cacheOperations = 500;

        // Act - Measure cache operations
        final stopwatch = Stopwatch()..start();

        // Cache operations
        for (int i = 0; i < cacheOperations; i++) {
          await StorageService.instance.cache(
            'perf_key_$i',
            'data_$i',
            duration: Duration(minutes: i % 60 + 1),
          );
        }

        final cacheTime = stopwatch.elapsedMilliseconds;
        stopwatch.reset();

        // Cache retrievals
        int hits = 0;
        for (int i = 0; i < cacheOperations; i++) {
          final result =
              await StorageService.instance.getCached<String>('perf_key_$i');
          if (result != null) hits++;
        }

        final retrieveTime = stopwatch.elapsedMilliseconds;
        stopwatch.stop();

        // Assert
        expect(cacheTime, lessThan(3000));
        expect(retrieveTime, lessThan(2000));
        expect(hits, equals(cacheOperations)); // All should be hits

        final stats = await StorageService.instance.getCacheStats();
        expect(stats['size'], lessThanOrEqualTo(cacheOperations));

        print('Cache time for $cacheOperations operations: ${cacheTime}ms');
        print(
            'Retrieve time for $cacheOperations operations: ${retrieveTime}ms');
        print('Cache hit rate: ${stats['hitRate']}%');
      });

      test('should handle memory usage efficiently', () async {
        // Arrange
        await StorageService.initialize();

        // Create large data objects
        final largeData = List.generate(
            10000,
            (i) =>
                'Large string data item $i that contains substantial content');
        final largeObject = {
          'data': largeData,
          'metadata': {
            'created': DateTime.now().toIso8601String(),
            'size': largeData.length,
          }
        };

        // Act - Store large objects
        await StorageService.instance.setObject('large_object_1', largeObject);
        await StorageService.instance.cache('large_cache_1', largeObject);
        await StorageService.instance.writeJson('large_file.json', largeObject);

        // Retrieve large objects
        final retrievedObject = await StorageService.instance
            .getObject<Map<String, dynamic>>('large_object_1');
        final cachedObject = await StorageService.instance
            .getCached<Map<String, dynamic>>('large_cache_1');
        final fileObject = await StorageService.instance
            .readJson<Map<String, dynamic>>('large_file.json');

        // Assert
        expect(retrievedObject!['data'], hasLength(10000));
        expect(cachedObject!['data'], hasLength(10000));
        expect(fileObject!['data'], hasLength(10000));

        // Get storage info
        final storageInfo = await StorageService.instance.getStorageInfo();
        expect(storageInfo['isInitialized'], isTrue);

        print(
            'Storage info after large operations: ${storageInfo['preferences']}');
      });
    });

    group('Error Recovery Tests', () {
      test('should recover from storage corruption gracefully', () async {
        // Arrange
        await StorageService.initialize();

        // Store valid data
        await StorageService.instance.setString('valid_key', 'valid_value');

        // Simulate partial corruption by storing invalid data
        // Note: In real testing, you might mock the underlying storage to return corrupted data

        // Act - Try to retrieve data with error handling
        final validData = await StorageService.instance.getString('valid_key');

        // Test with non-existent key (simulates missing data)
        final missingData =
            await StorageService.instance.getString('missing_key');

        // Assert
        expect(validData, equals('valid_value'));
        expect(missingData, isNull);

        // Test recovery by reinitializing
        await StorageService.dispose();
        await StorageService.initialize();

        final dataAfterRestart =
            await StorageService.instance.getString('valid_key');
        expect(dataAfterRestart, equals('valid_value'));
      });

      test('should handle concurrent access safely', () async {
        // Arrange
        await StorageService.initialize();

        // Act - Simulate concurrent operations
        final futures = <Future>[];

        // Concurrent writes
        for (int i = 0; i < 50; i++) {
          futures.add(
              StorageService.instance.setString('concurrent_$i', 'value_$i'));
        }

        // Concurrent reads
        for (int i = 0; i < 50; i++) {
          futures.add(StorageService.instance.getString('concurrent_$i'));
        }

        // Concurrent cache operations
        for (int i = 0; i < 50; i++) {
          futures.add(StorageService.instance
              .cache('cache_concurrent_$i', 'cache_value_$i'));
        }

        // Wait for all operations to complete
        await Future.wait(futures);

        // Assert - Verify data integrity
        for (int i = 0; i < 50; i++) {
          final value =
              await StorageService.instance.getString('concurrent_$i');
          expect(value, equals('value_$i'));
        }
      });
    });

    group('Configuration-Specific Tests', () {
      test('should respect minimal configuration limitations', () async {
        // Arrange
        await StorageService.initialize(config: StorageConfig.minimal());

        // Act & Assert - Database operations should fail
        expect(
          () => StorageService.instance.save('test_box', {'data': 'test'}),
          throwsA(isA<Exception>()),
        );

        // Secure storage operations should fail
        expect(
          () => StorageService.instance.setSecure('key', 'value'),
          throwsA(isA<Exception>()),
        );

        // But preferences and cache should work
        await StorageService.instance.setString('test_key', 'test_value');
        await StorageService.instance.cache('cache_key', 'cache_value');

        final prefValue = await StorageService.instance.getString('test_key');
        final cacheValue =
            await StorageService.instance.getCached<String>('cache_key');

        expect(prefValue, equals('test_value'));
        expect(cacheValue, equals('cache_value'));
      });

      test('should respect low memory configuration', () async {
        // Arrange
        await StorageService.initialize(config: StorageConfig.lowMemory());

        // Act - Try to fill cache beyond low memory limits
        for (int i = 0; i < 50; i++) {
          await StorageService.instance.cache('mem_key_$i', 'data_$i');
        }

        // Assert - Cache should respect size limits
        final stats = await StorageService.instance.getCacheStats();
        expect(
            stats['maxSize'], lessThan(50)); // Should be limited for low memory
        expect(stats['size'], lessThanOrEqualTo(stats['maxSize']));
      });

      test('should handle secure configuration properly', () async {
        // Arrange
        await StorageService.initialize(
          config: StorageConfig.secure(encryptionKey: 'test-secure-key-123'),
        );

        // Act - Store sensitive data
        await StorageService.instance
            .setSecure('secret_token', 'super_secret_value');
        await StorageService.instance.setSecureObject('secret_config', {
          'api_key': 'secret_api_key',
          'encryption_enabled': true,
        });

        // Assert
        final token = await StorageService.instance.getSecure('secret_token');
        final config = await StorageService.instance
            .getSecureObject<Map<String, dynamic>>('secret_config');

        expect(token, equals('super_secret_value'));
        expect(config!['api_key'], equals('secret_api_key'));
        expect(config['encryption_enabled'], isTrue);
      });
    });
  });
}
