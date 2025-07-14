import 'package:hive/hive.dart';

/// Base class for all database models
/// Provides common functionality for Hive objects
abstract class DatabaseModel {
  /// Unique identifier for the model
  dynamic get id;

  /// Convert model to JSON
  Map<String, dynamic> toJson();

  /// Create model from JSON
  static DatabaseModel fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by subclasses');
  }

  /// Get the box name for this model type
  String get boxName;

  /// Get the Hive type ID for this model
  int get typeId;

  /// Validate model data before saving
  bool validate() => true;

  /// Called before saving to database
  void beforeSave() {}

  /// Called after saving to database
  void afterSave() {}

  /// Called before deleting from database
  void beforeDelete() {}

  /// Called after deleting from database
  void afterDelete() {}

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$runtimeType{id: $id}';
}

/// Mixin for models that track creation and update times
mixin TimestampMixin on DatabaseModel {
  DateTime? get createdAt;
  DateTime? get updatedAt;

  set createdAt(DateTime? value);
  set updatedAt(DateTime? value);

  @override
  void beforeSave() {
    super.beforeSave();
    final now = DateTime.now();
    createdAt ??= now;
    updatedAt = now;
  }
}

/// Mixin for models that support soft deletion
mixin SoftDeleteMixin on DatabaseModel {
  DateTime? get deletedAt;
  set deletedAt(DateTime? value);

  bool get isDeleted => deletedAt != null;

  void softDelete() {
    deletedAt = DateTime.now();
  }

  void restore() {
    deletedAt = null;
  }

  @override
  void beforeDelete() {
    super.beforeDelete();
    softDelete();
  }
}

/// Base repository interface for database operations
abstract class Repository<T extends DatabaseModel> {
  /// Box name for this repository
  String get boxName;

  /// Save an entity
  Future<void> save(T entity);

  /// Find entity by ID
  Future<T?> findById(dynamic id);

  /// Find all entities
  Future<List<T>> findAll();

  /// Find entities by criteria
  Future<List<T>> findWhere(bool Function(T) test);

  /// Delete entity by ID
  Future<void> deleteById(dynamic id);

  /// Delete entity
  Future<void> delete(T entity);

  /// Clear all entities
  Future<void> clear();

  /// Count entities
  Future<int> count();

  /// Check if entity exists
  Future<bool> exists(dynamic id);
}

/// Query builder for complex database queries
class QueryBuilder<T extends DatabaseModel> {
  final Repository<T> _repository;
  final List<bool Function(T)> _conditions = [];
  int? _limit;
  int? _offset;
  int Function(T, T)? _comparator;

  QueryBuilder(this._repository);

  /// Add where condition
  QueryBuilder<T> where(bool Function(T) condition) {
    _conditions.add(condition);
    return this;
  }

  /// Limit results
  QueryBuilder<T> limit(int count) {
    _limit = count;
    return this;
  }

  /// Skip results
  QueryBuilder<T> offset(int count) {
    _offset = count;
    return this;
  }

  /// Sort results
  QueryBuilder<T> orderBy(int Function(T, T) comparator) {
    _comparator = comparator;
    return this;
  }

  /// Execute query
  Future<List<T>> execute() async {
    var results = await _repository.findAll();

    // Apply conditions
    for (final condition in _conditions) {
      results = results.where(condition).toList();
    }

    // Apply sorting
    if (_comparator != null) {
      results.sort(_comparator);
    }

    // Apply pagination
    if (_offset != null) {
      results = results.skip(_offset!).toList();
    }
    if (_limit != null) {
      results = results.take(_limit!).toList();
    }

    return results;
  }

  /// Get first result
  Future<T?> first() async {
    final results = await limit(1).execute();
    return results.isNotEmpty ? results.first : null;
  }

  /// Count results
  Future<int> count() async {
    final results = await execute();
    return results.length;
  }
}

/// Example User model implementation
@HiveType(typeId: 0)
class User extends DatabaseModel with TimestampMixin {
  @override
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  @override
  DateTime? createdAt;

  @HiveField(4)
  @override
  DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
    this.updatedAt,
  });

  @override
  String get boxName => 'users';

  @override
  int get typeId => 0;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      );

  @override
  bool validate() {
    return name.isNotEmpty && email.contains('@');
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
