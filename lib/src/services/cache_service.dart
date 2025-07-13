import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/storage_result.dart';
import '../models/cache_item.dart';
import '../exceptions/storage_exceptions.dart';
import '../utils/storage_utils.dart';
import '../utils/serialization_utils.dart';

/// Service for cache management with TTL (Time To Live) support
class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance!;

  static bool _isInitialized = false;

  // In-memory cache storage
  final Map<String, CacheItem<dynamic>> _cache = <String, CacheItem<dynamic>>{};

  // Cache configuration
  int _maxCacheSize = 100;
  Duration _defaultTTL = const Duration(hours: 1);
  Timer? _cleanupTimer;

  // Statistics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  // Private constructor
  CacheService._();

  /// Initialize the cache service
  static Future<void> initialize({
    int maxCacheSize = 100,
    Duration defaultTTL = const Duration(hours: 1),
    Duration cleanupInterval = const Duration(minutes: 10),
  }) async {
    if (_isInitialized) return;

    try {
      _instance = CacheService._();
      _instance!._maxCacheSize = maxCacheSize;
      _instance!._defaultTTL = defaultTTL;

      // Start cleanup timer
      _instance!._startCleanupTimer(cleanupInterval);

      _isInitialized = true;
      debugPrint(
          '✅ CacheService initialized successfully (maxSize: $maxCacheSize, defaultTTL: $defaultTTL)');
    } catch (e) {
      debugPrint('❌ CacheService initialization failed: $e');
      throw StorageInitializationException(
          'Failed to initialize cache service: $e');
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Dispose the cache service
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      _instance!._cleanupTimer?.cancel();
      _instance!._cache.clear();
      _instance = null;
      _isInitialized = false;

      debugPrint('✅ CacheService disposed successfully');
    } catch (e) {
      debugPrint('❌ CacheService disposal failed: $e');
    }
  }

  /// Start cleanup timer
  void _startCleanupTimer(Duration interval) {
    _cleanupTimer = Timer.periodic(interval, (_) {
      _cleanupExpiredItems();
    });
  }

  // ============================================================================
  // BASIC CACHE OPERATIONS
  // ============================================================================

  /// Store data in cache with TTL
  Future<StorageResult<bool>> cache(String key, dynamic data,
      {Duration? duration}) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final ttl = duration ?? _defaultTTL;

      // Check if cache is full and evict if necessary
      if (_cache.length >= _maxCacheSize && !_cache.containsKey(sanitizedKey)) {
        _evictLeastRecentlyUsed();
      }

      final cacheItem = CacheItem<dynamic>(
        data: data,
        createdAt: DateTime.now(),
        ttl: ttl,
      );

      _cache[sanitizedKey] = cacheItem;

      debugPrint('💾 Cached data: $sanitizedKey (TTL: ${ttl.toString()})');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to cache data: $key - $e');
      return StorageResult.failure('Failed to cache data: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get data from cache (returns null if expired or not found)
  Future<StorageResult<T?>> getCached<T>(String key) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final cacheItem = _cache[sanitizedKey];

      if (cacheItem == null) {
        _misses++;
        debugPrint('💔 Cache miss: $sanitizedKey');
        return StorageResult.success(null);
      }

      if (cacheItem.isExpired) {
        _cache.remove(sanitizedKey);
        _misses++;
        debugPrint('⏰ Cache expired: $sanitizedKey');
        return StorageResult.success(null);
      }

      _hits++;
      debugPrint('✅ Cache hit: $sanitizedKey');

      // Try to cast the data to the requested type
      if (cacheItem.data is T) {
        return StorageResult.success(cacheItem.data as T);
      } else {
        // Try to deserialize if it's a different type
        try {
          final jsonString = SerializationUtils.toJsonString(cacheItem.data);
          final deserializedData =
              SerializationUtils.fromJsonString<T>(jsonString);
          return StorageResult.success(deserializedData);
        } catch (e) {
          debugPrint('⚠️ Failed to cast cached data to type $T: $e');
          return StorageResult.success(cacheItem.data as T?);
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to get cached data: $key - $e');
      return StorageResult.failure('Failed to get cached data: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Check if cache item exists and is valid (not expired)
  Future<StorageResult<bool>> isCacheValid(String key) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final cacheItem = _cache[sanitizedKey];

      if (cacheItem == null) {
        return StorageResult.success(false);
      }

      final isValid = !cacheItem.isExpired;

      debugPrint('🔍 Cache valid: $sanitizedKey = $isValid');
      return StorageResult.success(isValid);
    } catch (e) {
      debugPrint('❌ Failed to check cache validity: $key - $e');
      return StorageResult.failure('Failed to check cache validity: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Remove item from cache
  Future<StorageResult<bool>> removeCache(String key) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final removed = _cache.remove(sanitizedKey) != null;

      debugPrint('🗑️ Removed from cache: $sanitizedKey = $removed');
      return StorageResult.success(removed);
    } catch (e) {
      debugPrint('❌ Failed to remove from cache: $key - $e');
      return StorageResult.failure('Failed to remove from cache: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Clear all cache
  Future<StorageResult<int>> clearCache() async {
    try {
      final count = _cache.length;
      _cache.clear();

      // Reset statistics
      _hits = 0;
      _misses = 0;
      _evictions = 0;

      debugPrint('🧹 Cleared cache: $count items removed');
      return StorageResult.success(count);
    } catch (e) {
      debugPrint('❌ Failed to clear cache: $e');
      return StorageResult.failure('Failed to clear cache: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // ADVANCED CACHE OPERATIONS
  // ============================================================================

  /// Update cache item TTL
  Future<StorageResult<bool>> updateTTL(String key, Duration newTTL) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final cacheItem = _cache[sanitizedKey];

      if (cacheItem == null) {
        return StorageResult.failure('Cache item not found: $key');
      }

      // Create new cache item with updated TTL
      final updatedItem = CacheItem<dynamic>(
        data: cacheItem.data,
        createdAt: cacheItem.createdAt,
        ttl: newTTL,
      );

      _cache[sanitizedKey] = updatedItem;

      debugPrint('⏰ Updated cache TTL: $sanitizedKey = ${newTTL.toString()}');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to update cache TTL: $key - $e');
      return StorageResult.failure('Failed to update cache TTL: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Refresh cache item (reset creation time)
  Future<StorageResult<bool>> refreshCache(String key) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final cacheItem = _cache[sanitizedKey];

      if (cacheItem == null) {
        return StorageResult.failure('Cache item not found: $key');
      }

      // Create new cache item with current time
      final refreshedItem = CacheItem<dynamic>(
        data: cacheItem.data,
        createdAt: DateTime.now(),
        ttl: cacheItem.ttl,
      );

      _cache[sanitizedKey] = refreshedItem;

      debugPrint('🔄 Refreshed cache: $sanitizedKey');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to refresh cache: $key - $e');
      return StorageResult.failure('Failed to refresh cache: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get cache item with metadata
  Future<StorageResult<CacheItem<T>?>> getCacheItem<T>(String key) async {
    try {
      if (!StorageUtils.isValidKey(key)) {
        return StorageResult.failure('Invalid key format: $key');
      }

      final sanitizedKey = StorageUtils.sanitizeKey(key);
      final cacheItem = _cache[sanitizedKey];

      if (cacheItem == null) {
        return StorageResult.success(null);
      }

      // Create typed cache item
      final typedItem = CacheItem<T>(
        data: cacheItem.data as T,
        createdAt: cacheItem.createdAt,
        ttl: cacheItem.ttl,
      );

      debugPrint('📋 Retrieved cache item with metadata: $sanitizedKey');
      return StorageResult.success(typedItem);
    } catch (e) {
      debugPrint('❌ Failed to get cache item: $key - $e');
      return StorageResult.failure('Failed to get cache item: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get or cache data (get from cache or execute function if not cached)
  Future<StorageResult<T>> getOrCache<T>(
    String key,
    Future<T> Function() fetchFunction, {
    Duration? duration,
  }) async {
    try {
      // Try to get from cache first
      final cachedResult = await getCached<T>(key);
      if (cachedResult.success && cachedResult.data != null) {
        return StorageResult.success(cachedResult.data!);
      }

      // Fetch new data
      final newData = await fetchFunction();

      // Cache the new data
      await cache(key, newData, duration: duration);

      debugPrint('🔄 Fetched and cached new data: $key');
      return StorageResult.success(newData);
    } catch (e) {
      debugPrint('❌ Failed to get or cache data: $key - $e');
      return StorageResult.failure('Failed to get or cache data: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  /// Manually cleanup expired items
  Future<StorageResult<int>> cleanupExpired() async {
    try {
      final removedCount = _cleanupExpiredItems();

      debugPrint('🧹 Manual cleanup: $removedCount expired items removed');
      return StorageResult.success(removedCount);
    } catch (e) {
      debugPrint('❌ Failed to cleanup expired items: $e');
      return StorageResult.failure('Failed to cleanup expired items: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Internal cleanup method
  int _cleanupExpiredItems() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _cache.forEach((key, item) {
      if (item.isExpired) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint(
          '🧹 Auto cleanup: ${keysToRemove.length} expired items removed');
    }

    return keysToRemove.length;
  }

  /// Evict least recently used item (simple LRU implementation)
  void _evictLeastRecentlyUsed() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    _cache.forEach((key, item) {
      if (oldestTime == null || item.createdAt.isBefore(oldestTime!)) {
        oldestTime = item.createdAt;
        oldestKey = key;
      }
    });

    if (oldestKey != null) {
      _cache.remove(oldestKey);
      _evictions++;
      debugPrint('⚡ Evicted LRU item: $oldestKey');
    }
  }

  /// Get all cache keys
  Future<StorageResult<List<String>>> getCacheKeys() async {
    try {
      final keys = _cache.keys.toList();

      debugPrint('🔑 Retrieved ${keys.length} cache keys');
      return StorageResult.success(keys);
    } catch (e) {
      debugPrint('❌ Failed to get cache keys: $e');
      return StorageResult.failure('Failed to get cache keys: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get cache keys matching pattern
  Future<StorageResult<List<String>>> getCacheKeysMatching(
      String pattern) async {
    try {
      final regex = RegExp(pattern);
      final matchingKeys =
          _cache.keys.where((key) => regex.hasMatch(key)).toList();

      debugPrint(
          '🔍 Found ${matchingKeys.length} cache keys matching pattern: $pattern');
      return StorageResult.success(matchingKeys);
    } catch (e) {
      debugPrint('❌ Failed to get matching cache keys: $e');
      return StorageResult.failure('Failed to get matching cache keys: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Clear cache matching pattern
  Future<StorageResult<int>> clearCacheMatching(String pattern) async {
    try {
      final keysResult = await getCacheKeysMatching(pattern);
      if (!keysResult.success) {
        return StorageResult.failure(
            keysResult.error ?? 'Failed to get matching keys');
      }

      int removedCount = 0;
      for (final key in keysResult.data!) {
        if (_cache.remove(key) != null) {
          removedCount++;
        }
      }

      debugPrint(
          '🧹 Cleared $removedCount cache items matching pattern: $pattern');
      return StorageResult.success(removedCount);
    } catch (e) {
      debugPrint('❌ Failed to clear cache matching pattern: $e');
      return StorageResult.failure('Failed to clear cache matching pattern: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // CACHE STATISTICS & INFO
  // ============================================================================

  /// Get cache statistics
  Future<StorageResult<Map<String, dynamic>>> getCacheStats() async {
    try {
      final totalAccess = _hits + _misses;
      final hitRate = totalAccess > 0 ? (_hits / totalAccess * 100) : 0.0;

      final stats = {
        'size': _cache.length,
        'maxSize': _maxCacheSize,
        'hits': _hits,
        'misses': _misses,
        'evictions': _evictions,
        'hitRate': hitRate,
        'totalAccess': totalAccess,
        'defaultTTL': _defaultTTL.toString(),
        'isInitialized': _isInitialized,
      };

      return StorageResult.success(stats);
    } catch (e) {
      debugPrint('❌ Failed to get cache statistics: $e');
      return StorageResult.failure('Failed to get cache statistics: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get detailed cache info
  Future<StorageResult<Map<String, dynamic>>> getCacheInfo() async {
    try {
      final now = DateTime.now();
      final itemsInfo = <Map<String, dynamic>>[];

      _cache.forEach((key, item) {
        final remainingTTL = item.ttl != null
            ? item.createdAt.add(item.ttl!).difference(now)
            : null;

        itemsInfo.add({
          'key': key,
          'createdAt': item.createdAt.toIso8601String(),
          'ttl': item.ttl?.toString(),
          'remainingTTL': remainingTTL?.toString(),
          'isExpired': item.isExpired,
          'dataType': item.data.runtimeType.toString(),
          'dataSize': SerializationUtils.getObjectSize(item.data),
        });
      });

      // Sort by creation time (newest first)
      itemsInfo.sort((a, b) => DateTime.parse(b['createdAt'])
          .compareTo(DateTime.parse(a['createdAt'])));

      final statsResult = await getCacheStats();
      final info = {
        'stats': statsResult.data ?? {},
        'items': itemsInfo,
      };

      return StorageResult.success(info);
    } catch (e) {
      debugPrint('❌ Failed to get cache info: $e');
      return StorageResult.failure('Failed to get cache info: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Reset cache statistics
  Future<StorageResult<bool>> resetStats() async {
    try {
      _hits = 0;
      _misses = 0;
      _evictions = 0;

      debugPrint('📊 Reset cache statistics');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to reset cache statistics: $e');
      return StorageResult.failure('Failed to reset cache statistics: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Set cache configuration
  Future<StorageResult<bool>> setConfig({
    int? maxCacheSize,
    Duration? defaultTTL,
  }) async {
    try {
      if (maxCacheSize != null) {
        _maxCacheSize = maxCacheSize;

        // Evict items if current size exceeds new max size
        while (_cache.length > _maxCacheSize) {
          _evictLeastRecentlyUsed();
        }
      }

      if (defaultTTL != null) {
        _defaultTTL = defaultTTL;
      }

      debugPrint(
          '⚙️ Updated cache config: maxSize=$_maxCacheSize, defaultTTL=$_defaultTTL');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to set cache config: $e');
      return StorageResult.failure('Failed to set cache config: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Export cache data
  Future<StorageResult<Map<String, dynamic>>> exportCache() async {
    try {
      final exportData = <String, Map<String, dynamic>>{};

      _cache.forEach((key, item) {
        exportData[key] = {
          'data': item.data,
          'createdAt': item.createdAt.toIso8601String(),
          'ttl': item.ttl?.inMilliseconds,
        };
      });

      final export = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'config': {
          'maxCacheSize': _maxCacheSize,
          'defaultTTL': _defaultTTL.inMilliseconds,
        },
        'stats': {
          'hits': _hits,
          'misses': _misses,
          'evictions': _evictions,
        },
        'cache': exportData,
      };

      debugPrint('📤 Exported cache data: ${exportData.length} items');
      return StorageResult.success(export);
    } catch (e) {
      debugPrint('❌ Failed to export cache: $e');
      return StorageResult.failure('Failed to export cache: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Import cache data
  Future<StorageResult<int>> importCache(Map<String, dynamic> data,
      {bool clearFirst = false}) async {
    try {
      if (clearFirst) {
        await clearCache();
      }

      final cacheData = data['cache'] as Map<String, dynamic>? ?? {};
      int importedCount = 0;

      cacheData.forEach((key, itemData) {
        try {
          final item = itemData as Map<String, dynamic>;
          final createdAt = DateTime.parse(item['createdAt']);
          final ttlMillis = item['ttl'] as int?;
          final ttl =
              ttlMillis != null ? Duration(milliseconds: ttlMillis) : null;

          final cacheItem = CacheItem<dynamic>(
            data: item['data'],
            createdAt: createdAt,
            ttl: ttl,
          );

          _cache[key] = cacheItem;
          importedCount++;
        } catch (e) {
          debugPrint('⚠️ Failed to import cache item $key: $e');
        }
      });

      // Import stats if available
      final stats = data['stats'] as Map<String, dynamic>?;
      if (stats != null) {
        _hits = stats['hits'] ?? 0;
        _misses = stats['misses'] ?? 0;
        _evictions = stats['evictions'] ?? 0;
      }

      debugPrint(
          '📥 Imported cache data: $importedCount/${cacheData.length} items');
      return StorageResult.success(importedCount);
    } catch (e) {
      debugPrint('❌ Failed to import cache: $e');
      return StorageResult.failure('Failed to import cache: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // Add this for testing purposes
  @visibleForTesting
  static void setTestInstance(CacheService? instance) {
    _instance = instance;
  }
}
