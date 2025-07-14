// test/models/cache_item_test.dart
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheItem', () {
    const testData = 'test_data';
    final testCreatedAt = DateTime.now();
    const testTTL = Duration(minutes: 30);

    group('Creation', () {
      test('should create cache item with all properties', () {
        // Act
        final item = CacheItem(
          data: testData,
          createdAt: testCreatedAt,
          ttl: testTTL,
        );

        // Assert
        expect(item.data, equals(testData));
        expect(item.createdAt, equals(testCreatedAt));
        expect(item.ttl, equals(testTTL));
        expect(item.lastAccessedAt, equals(testCreatedAt));
      });

      test('should create permanent cache item', () {
        // Act
        final item = CacheItem.permanent(testData);

        // Assert
        expect(item.data, equals(testData));
        expect(item.ttl, isNull);
        expect(item.isExpired, isFalse);
      });

      test('should create cache item with seconds TTL', () {
        // Act
        final item = CacheItem.withSeconds(testData, 300);

        // Assert
        expect(item.data, equals(testData));
        expect(item.ttl, equals(const Duration(seconds: 300)));
      });

      test('should create cache item with minutes TTL', () {
        // Act
        final item = CacheItem.withMinutes(testData, 5);

        // Assert
        expect(item.data, equals(testData));
        expect(item.ttl, equals(const Duration(minutes: 5)));
      });

      test('should create cache item with hours TTL', () {
        // Act
        final item = CacheItem.withHours(testData, 2);

        // Assert
        expect(item.data, equals(testData));
        expect(item.ttl, equals(const Duration(hours: 2)));
      });

      test('should create cache item with days TTL', () {
        // Act
        final item = CacheItem.withDays(testData, 7);

        // Assert
        expect(item.data, equals(testData));
        expect(item.ttl, equals(const Duration(days: 7)));
      });
    });

    group('Expiration', () {
      test('should not be expired when within TTL', () {
        // Arrange
        final item = CacheItem(
          data: testData,
          createdAt: DateTime.now(),
          ttl: const Duration(hours: 1),
        );

        // Assert
        expect(item.isExpired, isFalse);
        expect(item.isValid, isTrue);
      });

      test('should be expired when past TTL', () {
        // Arrange
        final pastTime = DateTime.now().subtract(const Duration(hours: 2));
        final item = CacheItem(
          data: testData,
          createdAt: pastTime,
          ttl: const Duration(hours: 1),
        );

        // Assert
        expect(item.isExpired, isTrue);
        expect(item.isValid, isFalse);
      });

      test('should never expire when TTL is null', () {
        // Arrange
        final pastTime = DateTime.now().subtract(const Duration(days: 365));
        final item = CacheItem(
          data: testData,
          createdAt: pastTime,
          ttl: null,
        );

        // Assert
        expect(item.isExpired, isFalse);
        expect(item.isValid, isTrue);
      });

      test('should calculate remaining TTL correctly', () {
        // Arrange
        final item = CacheItem(
          data: testData,
          createdAt: DateTime.now(),
          ttl: const Duration(minutes: 30),
        );

        // Act
        final remaining = item.remainingTTL;

        // Assert
        expect(remaining, isNotNull);
        expect(remaining!.inMinutes, lessThanOrEqualTo(30));
        expect(remaining.inMinutes, greaterThan(29));
      });

      test('should return null remaining TTL when expired', () {
        // Arrange
        final pastTime = DateTime.now().subtract(const Duration(hours: 2));
        final item = CacheItem(
          data: testData,
          createdAt: pastTime,
          ttl: const Duration(hours: 1),
        );

        // Act
        final remaining = item.remainingTTL;

        // Assert
        expect(remaining, isNull);
      });

      test('should calculate expiry time correctly', () {
        // Arrange
        final createdAt = DateTime.now();
        const ttl = Duration(hours: 2);
        final item = CacheItem(
          data: testData,
          createdAt: createdAt,
          ttl: ttl,
        );

        // Act
        final expiryTime = item.expiryTime;

        // Assert
        expect(expiryTime, equals(createdAt.add(ttl)));
      });
    });

    group('Access Tracking', () {
      test('should update last accessed time when marked', () {
        // Arrange
        final item = CacheItem(
          data: testData,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ttl: testTTL,
        );
        final initialAccessTime = item.lastAccessedAt;

        // Act
        item.markAccessed();

        // Assert
        expect(item.lastAccessedAt.isAfter(initialAccessTime), isTrue);
      });

      test('should calculate time since last access', () {
        // Arrange
        final item = CacheItem(
          data: testData,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ttl: testTTL,
        );

        // Act
        final timeSinceAccess = item.timeSinceLastAccess;

        // Assert
        expect(timeSinceAccess.inMinutes, greaterThanOrEqualTo(4));
      });

      test('should calculate age correctly', () {
        // Arrange
        final fiveMinutesAgo =
            DateTime.now().subtract(const Duration(minutes: 5));
        final item = CacheItem(
          data: testData,
          createdAt: fiveMinutesAgo,
          ttl: testTTL,
        );

        // Act
        final age = item.age;

        // Assert
        expect(age.inMinutes, greaterThanOrEqualTo(4));
        expect(age.inMinutes, lessThan(6));
      });
    });

    group('Modifications', () {
      test('should create copy with new TTL', () {
        // Arrange
        final originalItem = CacheItem(
          data: testData,
          createdAt: testCreatedAt,
          ttl: testTTL,
        );
        const newTTL = Duration(hours: 2);

        // Act
        final newItem = originalItem.withTTL(newTTL);

        // Assert
        expect(newItem.data, equals(testData));
        expect(newItem.createdAt, equals(testCreatedAt));
        expect(newItem.ttl, equals(newTTL));
        expect(newItem.lastAccessedAt, equals(originalItem.lastAccessedAt));
      });

      test('should refresh cache item with new creation time', () {
        // Arrange
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final originalItem = CacheItem(
          data: testData,
          createdAt: pastTime,
          ttl: testTTL,
        );

        // Act
        final refreshedItem = originalItem.refresh();

        // Assert
        expect(refreshedItem.data, equals(testData));
        expect(refreshedItem.ttl, equals(testTTL));
        expect(refreshedItem.createdAt.isAfter(pastTime), isTrue);
        expect(refreshedItem.lastAccessedAt.isAfter(pastTime), isTrue);
      });

      test('should create copy with new data', () {
        // Arrange
        final originalItem = CacheItem(
          data: testData,
          createdAt: testCreatedAt,
          ttl: testTTL,
        );
        const newData = 42;

        // Act
        final newItem = originalItem.withData(newData);

        // Assert
        expect(newItem.data, equals(newData));
        expect(newItem.createdAt, equals(testCreatedAt));
        expect(newItem.ttl, equals(testTTL));
      });
    });

    group('Statistics', () {
      test('should provide comprehensive statistics', () {
        // Arrange
        final item = CacheItem(
          data: testData,
          createdAt: DateTime.now(),
          ttl: testTTL,
        );

        // Act
        final stats = item.getStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['createdAt'], isA<String>());
        expect(stats['lastAccessedAt'], isA<String>());
        expect(stats['ttl'], isA<String>());
        expect(stats['isExpired'], isA<bool>());
        expect(stats['isValid'], isA<bool>());
        expect(stats['dataType'], contains('String'));
      });
    });

    group('Serialization', () {
      test('should convert to Map', () {
        // Arrange
        final item = CacheItem(
          data: testData,
          createdAt: testCreatedAt,
          ttl: testTTL,
        );

        // Act
        final map = item.toMap();

        // Assert
        expect(map['data'], equals(testData));
        expect(map['createdAt'], isA<String>());
        expect(map['ttl'], equals(testTTL.inMilliseconds));
        expect(map['lastAccessedAt'], isA<String>());
      });

      test('should create from Map', () {
        // Arrange
        final originalItem = CacheItem(
          data: testData,
          createdAt: testCreatedAt,
          ttl: testTTL,
        );
        final map = originalItem.toMap();

        // Act
        final recreatedItem = CacheItem.fromMap<String>(map);

        // Assert
        expect(recreatedItem.data, equals(testData));
        expect(recreatedItem.createdAt, equals(testCreatedAt));
        expect(recreatedItem.ttl, equals(testTTL));
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        final item1 = CacheItem(
          data: testData,
          createdAt: testCreatedAt,
          ttl: testTTL,
        );
        final item2 = CacheItem(
          data: testData,
          createdAt: testCreatedAt,
          ttl: testTTL,
        );

        // Assert
        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('should not be equal when data differs', () {
        // Arrange
        final item1 = CacheItem(
          data: testData,
          createdAt: testCreatedAt,
          ttl: testTTL,
        );
        final item2 = CacheItem(
          data: 'different_data',
          createdAt: testCreatedAt,
          ttl: testTTL,
        );

        // Assert
        expect(item1, isNot(equals(item2)));
      });
    });
  });
}
