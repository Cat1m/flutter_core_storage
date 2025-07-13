/// Cache item with TTL support
class CacheItem<T> {
  final T data;
  final DateTime createdAt;
  final Duration? ttl;

  CacheItem({
    required this.data,
    required this.createdAt,
    this.ttl,
  });

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().isAfter(createdAt.add(ttl!));
  }

  Map<String, dynamic> toJson() => {
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'ttl': ttl?.inMilliseconds,
  };

  factory CacheItem.fromJson(Map<String, dynamic> json) {
    return CacheItem<T>(
      data: json['data'] as T,
      createdAt: DateTime.parse(json['createdAt']),
      ttl: json['ttl'] != null 
          ? Duration(milliseconds: json['ttl']) 
          : null,
    );
  }
}
