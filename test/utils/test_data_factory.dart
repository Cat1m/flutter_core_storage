// test/utils/test_data_factory.dart
import 'dart:math';
import 'package:flutter_core_storage/flutter_core_storage.dart';

/// Factory for generating test data
class TestDataFactory {
  static final Random _random = Random();

  /// Generate random user data
  static Map<String, dynamic> createUser({
    int? id,
    String? name,
    String? email,
    bool? isActive,
    DateTime? createdAt,
  }) {
    final userId = id ?? _random.nextInt(10000);
    return {
      'id': userId,
      'name': name ?? 'User $userId',
      'email': email ?? 'user$userId@example.com',
      'is_active': isActive ?? true,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'profile': {
        'avatar': 'avatar_$userId.jpg',
        'bio': 'This is user $userId bio',
        'preferences': {
          'theme': _random.nextBool() ? 'dark' : 'light',
          'notifications': _random.nextBool(),
          'language': ['en', 'es', 'fr'][_random.nextInt(3)],
        }
      }
    };
  }

  /// Generate random product data
  static Map<String, dynamic> createProduct({
    int? id,
    String? name,
    double? price,
    String? category,
  }) {
    final productId = id ?? _random.nextInt(1000);
    return {
      'id': productId,
      'name': name ?? 'Product $productId',
      'price': price ?? (_random.nextDouble() * 100).toStringAsFixed(2),
      'category':
          category ?? ['electronics', 'clothing', 'books'][_random.nextInt(3)],
      'description': 'Description for product $productId',
      'in_stock': _random.nextBool(),
      'rating': (_random.nextDouble() * 5).toStringAsFixed(1),
      'tags': List.generate(3, (i) => 'tag${productId}_$i'),
    };
  }

  /// Generate settings object
  static Map<String, dynamic> createSettings({
    String? theme,
    bool? notifications,
    String? language,
  }) {
    return {
      'theme': theme ?? 'system',
      'notifications': notifications ?? true,
      'language': language ?? 'en',
      'auto_save': _random.nextBool(),
      'sync_enabled': _random.nextBool(),
      'privacy_mode': _random.nextBool(),
      'advanced': {
        'debug_mode': false,
        'cache_size': _random.nextInt(100) + 50,
        'timeout': _random.nextInt(30) + 10,
      }
    };
  }

  /// Generate list of items for bulk testing
  static List<Map<String, dynamic>> createUserList(int count) {
    return List.generate(count, (i) => createUser(id: i));
  }

  /// Generate large text content
  static String createLargeText(int paragraphs) {
    final lorem = [
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      'Ut enim ad minim veniam, quis nostrud exercitation ullamco.',
      'Duis aute irure dolor in reprehenderit in voluptate velit esse.',
      'Excepteur sint occaecat cupidatat non proident, sunt in culpa.',
    ];

    return List.generate(
            paragraphs, (i) => '${lorem[i % lorem.length]} Paragraph ${i + 1}.')
        .join('\n\n');
  }

  /// Generate cache item for testing
  static CacheItem<T> createCacheItem<T>(
    T data, {
    Duration? ttl,
    DateTime? createdAt,
  }) {
    return CacheItem<T>(
      data: data,
      createdAt: createdAt ?? DateTime.now(),
      ttl: ttl,
    );
  }

  /// Generate expired cache item
  static CacheItem<T> createExpiredCacheItem<T>(T data) {
    return CacheItem<T>(
      data: data,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ttl: const Duration(hours: 1), // Already expired
    );
  }

  /// Generate random file content
  static Map<String, dynamic> createFileContent(String type) {
    switch (type) {
      case 'config':
        return {
          'app_name': 'Test App',
          'version': '1.0.${_random.nextInt(100)}',
          'api_url': 'https://api.example.com/v1',
          'features': {
            'feature_a': _random.nextBool(),
            'feature_b': _random.nextBool(),
            'feature_c': _random.nextBool(),
          }
        };
      case 'log':
        return {
          'timestamp': DateTime.now().toIso8601String(),
          'level': ['INFO', 'WARN', 'ERROR'][_random.nextInt(3)],
          'message': 'Test log message ${_random.nextInt(1000)}',
          'metadata': {
            'user_id': _random.nextInt(1000),
            'session_id': 'session_${_random.nextInt(10000)}',
          }
        };
      default:
        return {
          'type': type,
          'data': 'Generated data for $type',
          'created': DateTime.now().toIso8601String(),
        };
    }
  }
}
