/// Represents an item stored in cache with TTL (Time To Live) support
class CacheItem<T> {
  /// The cached data
  final T data;

  /// When the item was created
  final DateTime createdAt;

  /// Time to live duration (null means no expiration)
  final Duration? ttl;

  /// When the item was last accessed (for LRU eviction)
  DateTime _lastAccessedAt;

  CacheItem({
    required this.data,
    required this.createdAt,
    this.ttl,
  }) : _lastAccessedAt = createdAt;

  /// Get when the item was last accessed
  DateTime get lastAccessedAt => _lastAccessedAt;

  /// Update the last accessed time
  void markAccessed() {
    _lastAccessedAt = DateTime.now();
  }

  /// Check if the item has expired
  bool get isExpired {
    if (ttl == null) return false;
    final expiryTime = createdAt.add(ttl!);
    return DateTime.now().isAfter(expiryTime);
  }

  /// Check if the item is still valid (not expired)
  bool get isValid => !isExpired;

  /// Get the expiry time (null if no TTL)
  DateTime? get expiryTime {
    return ttl != null ? createdAt.add(ttl!) : null;
  }

  /// Get remaining TTL duration (null if expired or no TTL)
  Duration? get remainingTTL {
    if (ttl == null) return null;

    final expiry = expiryTime!;
    final now = DateTime.now();

    if (now.isAfter(expiry)) {
      return null; // Expired
    }

    return expiry.difference(now);
  }

  /// Get how long the item has existed
  Duration get age => DateTime.now().difference(createdAt);

  /// Get how long since the item was last accessed
  Duration get timeSinceLastAccess =>
      DateTime.now().difference(_lastAccessedAt);

  /// Create a copy with updated TTL
  CacheItem<T> withTTL(Duration? newTTL) {
    return CacheItem<T>(
      data: data,
      createdAt: createdAt,
      ttl: newTTL,
    ).._lastAccessedAt = _lastAccessedAt;
  }

  /// Create a copy with refreshed creation time (reset age)
  CacheItem<T> refresh() {
    final now = DateTime.now();
    return CacheItem<T>(
      data: data,
      createdAt: now,
      ttl: ttl,
    ).._lastAccessedAt = now;
  }

  /// Create a copy with new data but same metadata
  CacheItem<U> withData<U>(U newData) {
    return CacheItem<U>(
      data: newData,
      createdAt: createdAt,
      ttl: ttl,
    ).._lastAccessedAt = _lastAccessedAt;
  }

  /// Get cache item statistics
  Map<String, dynamic> getStats() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'lastAccessedAt': _lastAccessedAt.toIso8601String(),
      'ttl': ttl?.toString(),
      'expiryTime': expiryTime?.toIso8601String(),
      'remainingTTL': remainingTTL?.toString(),
      'age': age.toString(),
      'timeSinceLastAccess': timeSinceLastAccess.toString(),
      'isExpired': isExpired,
      'isValid': isValid,
      'dataType': data.runtimeType.toString(),
    };
  }

  /// Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'ttl': ttl?.inMilliseconds,
      'lastAccessedAt': _lastAccessedAt.toIso8601String(),
    };
  }

  /// Create from Map
  static CacheItem<T> fromMap<T>(Map<String, dynamic> map) {
    final createdAt = DateTime.parse(map['createdAt'] as String);
    final ttlMillis = map['ttl'] as int?;
    final ttl = ttlMillis != null ? Duration(milliseconds: ttlMillis) : null;
    final lastAccessedString = map['lastAccessedAt'] as String?;

    final item = CacheItem<T>(
      data: map['data'] as T,
      createdAt: createdAt,
      ttl: ttl,
    );

    if (lastAccessedString != null) {
      item._lastAccessedAt = DateTime.parse(lastAccessedString);
    }

    return item;
  }

  /// Create a cache item that never expires
  static CacheItem<T> permanent<T>(T data) {
    return CacheItem<T>(
      data: data,
      createdAt: DateTime.now(),
      ttl: null,
    );
  }

  /// Create a cache item with TTL in seconds
  static CacheItem<T> withSeconds<T>(T data, int seconds) {
    return CacheItem<T>(
      data: data,
      createdAt: DateTime.now(),
      ttl: Duration(seconds: seconds),
    );
  }

  /// Create a cache item with TTL in minutes
  static CacheItem<T> withMinutes<T>(T data, int minutes) {
    return CacheItem<T>(
      data: data,
      createdAt: DateTime.now(),
      ttl: Duration(minutes: minutes),
    );
  }

  /// Create a cache item with TTL in hours
  static CacheItem<T> withHours<T>(T data, int hours) {
    return CacheItem<T>(
      data: data,
      createdAt: DateTime.now(),
      ttl: Duration(hours: hours),
    );
  }

  /// Create a cache item with TTL in days
  static CacheItem<T> withDays<T>(T data, int days) {
    return CacheItem<T>(
      data: data,
      createdAt: DateTime.now(),
      ttl: Duration(days: days),
    );
  }

  @override
  String toString() {
    return 'CacheItem<${T.toString()}>(data: $data, createdAt: $createdAt, ttl: $ttl, isExpired: $isExpired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheItem<T> &&
        other.data == data &&
        other.createdAt == createdAt &&
        other.ttl == ttl;
  }

  @override
  int get hashCode {
    return Object.hash(data, createdAt, ttl);
  }
}
