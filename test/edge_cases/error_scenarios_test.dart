// test/edge_cases/error_scenarios_test.dart
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helper.dart';

void main() {
  group('Error Scenarios and Edge Cases', () {
    setUp(() {
      TestHelper.setUp();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      if (StorageService.isInitialized) {
        await StorageService.dispose();
      }
    });

    test('should handle invalid key formats gracefully', () async {
      await StorageService.initialize();

      // Test various invalid keys
      final invalidKeys = [
        '',
        ' ',
        '\n',
        '\t',
        '...',
        'key with spaces',
        'key\nwith\nnewlines'
      ];

      for (final invalidKey in invalidKeys) {
        expect(
          () => StorageService.instance.setString(invalidKey, 'value'),
          throwsA(isA<StorageOperationException>()),
          reason: 'Should reject invalid key: "$invalidKey"',
        );
      }
    });

    test('should handle extremely large data gracefully', () async {
      await StorageService.initialize();

      // Create very large string
      final largeString = 'x' * 1000000; // 1MB string
      final largeObject = {
        'data': List.generate(
            10000, (i) => 'Large data item $i with substantial content'),
        'metadata': {
          'size': 10000,
          'created': DateTime.now().toIso8601String(),
        }
      };

      // These should either succeed or fail gracefully
      try {
        await StorageService.instance.setString('large_string', largeString);
        final retrieved =
            await StorageService.instance.getString('large_string');
        expect(retrieved, equals(largeString));
      } catch (e) {
        expect(e, isA<StorageOperationException>());
      }

      try {
        await StorageService.instance.setObject('large_object', largeObject);
        final retrieved = await StorageService.instance
            .getObject<Map<String, dynamic>>('large_object');
        expect(retrieved!['data'].length, equals(10000));
      } catch (e) {
        expect(e, isA<StorageOperationException>());
      }
    });

    test('should handle special characters in data', () async {
      await StorageService.initialize();

      final specialData = {
        'unicode': '🔥💯🚀 Unicode test 中文 العربية',
        'quotes': 'String with "quotes" and \'apostrophes\'',
        'newlines': 'Line 1\nLine 2\r\nLine 3',
        'json_escape': '{"nested": "json", "value": 123}',
        'null_char': 'String with\x00null character',
        'html': '<script>alert("xss")</script>',
        'sql': "'; DROP TABLE users; --",
      };

      for (final entry in specialData.entries) {
        await StorageService.instance
            .setString('special_${entry.key}', entry.value);
        final retrieved =
            await StorageService.instance.getString('special_${entry.key}');
        expect(retrieved, equals(entry.value),
            reason: 'Failed for special data: ${entry.key}');
      }
    });

    test('should handle rapid successive operations', () async {
      await StorageService.initialize();

      // Rapid fire operations
      final futures = <Future>[];
      for (int i = 0; i < 100; i++) {
        futures.add(StorageService.instance.setString('rapid_$i', 'value_$i'));
      }

      // All should complete without errors
      await Future.wait(futures);

      // Verify all data was stored correctly
      for (int i = 0; i < 100; i++) {
        final value = await StorageService.instance.getString('rapid_$i');
        expect(value, equals('value_$i'));
      }
    });

    test('should handle type casting edge cases', () async {
      await StorageService.initialize();

      // Store data as one type, try to retrieve as another
      await StorageService.instance.setString('number_as_string', '42');
      await StorageService.instance.setString('bool_as_string', 'true');
      await StorageService.instance
          .setString('json_as_string', '{"key": "value"}');

      // These should work (string to string)
      final numberString =
          await StorageService.instance.getString('number_as_string');
      expect(numberString, equals('42'));

      // Complex object with mixed types
      final mixedObject = {
        'string': 'value',
        'number': 42,
        'bool': true,
        'null_value': null,
        'list': [1, 'two', true, null],
        'nested': {
          'deep': {'value': 'nested'}
        }
      };

      await StorageService.instance.setObject('mixed_object', mixedObject);
      final retrieved = await StorageService.instance
          .getObject<Map<String, dynamic>>('mixed_object');

      expect(retrieved!['string'], equals('value'));
      expect(retrieved['number'], equals(42));
      expect(retrieved['bool'], equals(true));
      expect(retrieved['null_value'], isNull);
      expect(retrieved['list'].length, equals(4));
      expect(retrieved['nested']['deep']['value'], equals('nested'));
    });

    test('should handle cache expiration edge cases', () async {
      await StorageService.initialize();

      // Cache item with very short TTL
      await StorageService.instance.cache(
        'short_ttl',
        'data',
        duration: const Duration(milliseconds: 50),
      );

      // Should be available immediately
      final immediate =
          await StorageService.instance.getCached<String>('short_ttl');
      expect(immediate, equals('data'));

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      // Should be expired now
      final expired =
          await StorageService.instance.getCached<String>('short_ttl');
      expect(expired, isNull);

      // Cache with zero duration (should expire immediately)
      await StorageService.instance.cache(
        'zero_ttl',
        'data',
        duration: Duration.zero,
      );

      final zeroTtl =
          await StorageService.instance.getCached<String>('zero_ttl');
      expect(zeroTtl, isNull);
    });

    test('should handle file system edge cases', () async {
      await StorageService.initialize();

      // Empty file
      await StorageService.instance.writeFile('empty.txt', '');
      final emptyContent = await StorageService.instance.readFile('empty.txt');
      expect(emptyContent, equals(''));

      // File with only whitespace
      await StorageService.instance.writeFile('whitespace.txt', '   \n\t   ');
      final whitespaceContent =
          await StorageService.instance.readFile('whitespace.txt');
      expect(whitespaceContent, equals('   \n\t   '));

      // Non-existent file
      final nonExistent =
          await StorageService.instance.readFile('does_not_exist.txt');
      expect(nonExistent, isNull);

      // Very long filename
      final longFilename = 'a' * 100 + '.txt';
      try {
        await StorageService.instance.writeFile(longFilename, 'content');
        final longFileContent =
            await StorageService.instance.readFile(longFilename);
        expect(longFileContent, equals('content'));
      } catch (e) {
        // Some platforms may reject very long filenames
        expect(e, isA<Exception>());
      }
    });
  });
}
