import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/storage_result.dart';

/// Base class for database migrations
abstract class BaseMigration {
  /// Migration version number (must be unique and sequential)
  int get version;

  /// Migration description
  String get description;

  /// Execute the migration (upgrade)
  Future<StorageResult<bool>> up(Box box);

  /// Rollback the migration (downgrade)
  Future<StorageResult<bool>> down(Box box);

  /// Validate that migration can be applied
  Future<StorageResult<bool>> validate(Box box) async {
    return StorageResult.success(true);
  }

  /// Get migration metadata
  Map<String, dynamic> get metadata => {
        'version': version,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      };

  @override
  String toString() => 'Migration v$version: $description';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseMigration &&
          runtimeType == other.runtimeType &&
          version == other.version;

  @override
  int get hashCode => version.hashCode;
}

/// Migration information stored in database
class MigrationRecord {
  final int version;
  final String description;
  final DateTime appliedAt;
  final bool success;
  final String? error;

  const MigrationRecord({
    required this.version,
    required this.description,
    required this.appliedAt,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'description': description,
        'appliedAt': appliedAt.toIso8601String(),
        'success': success,
        'error': error,
      };

  factory MigrationRecord.fromJson(Map<String, dynamic> json) =>
      MigrationRecord(
        version: json['version'],
        description: json['description'],
        appliedAt: DateTime.parse(json['appliedAt']),
        success: json['success'],
        error: json['error'],
      );

  @override
  String toString() => 'MigrationRecord(v$version, success: $success)';
}

/// Example migration: Add new field to existing data
class AddFieldMigration extends BaseMigration {
  final String fieldName;
  final dynamic defaultValue;
  final bool Function(Map<String, dynamic>) shouldUpdate;

  AddFieldMigration({
    required this.fieldName,
    required this.defaultValue,
    required this.shouldUpdate,
    required int version,
    required String description,
  })  : _version = version,
        _description = description;

  final int _version;
  final String _description;

  @override
  int get version => _version;

  @override
  String get description => _description;

  @override
  Future<StorageResult<bool>> up(Box box) async {
    try {
      // ignore: unused_local_variable
      int updatedCount = 0;

      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map<String, dynamic> && shouldUpdate(value)) {
          if (!value.containsKey(fieldName)) {
            value[fieldName] = defaultValue;
            await box.put(key, value);
            updatedCount++;
          }
        }
      }

      return StorageResult.success(true);
    } catch (e) {
      return StorageResult.failure('Failed to add field $fieldName: $e');
    }
  }

  @override
  Future<StorageResult<bool>> down(Box box) async {
    try {
      // ignore: unused_local_variable
      int updatedCount = 0;

      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map<String, dynamic> && value.containsKey(fieldName)) {
          value.remove(fieldName);
          await box.put(key, value);
          updatedCount++;
        }
      }

      return StorageResult.success(true);
    } catch (e) {
      return StorageResult.failure('Failed to remove field $fieldName: $e');
    }
  }
}

/// Example migration: Rename field
class RenameFieldMigration extends BaseMigration {
  final String oldFieldName;
  final String newFieldName;
  final bool Function(Map<String, dynamic>) shouldUpdate;

  RenameFieldMigration({
    required this.oldFieldName,
    required this.newFieldName,
    required this.shouldUpdate,
    required int version,
    required String description,
  })  : _version = version,
        _description = description;

  final int _version;
  final String _description;

  @override
  int get version => _version;

  @override
  String get description => _description;

  @override
  Future<StorageResult<bool>> up(Box box) async {
    try {
      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map<String, dynamic> && shouldUpdate(value)) {
          if (value.containsKey(oldFieldName) &&
              !value.containsKey(newFieldName)) {
            value[newFieldName] = value.remove(oldFieldName);
            await box.put(key, value);
          }
        }
      }

      return StorageResult.success(true);
    } catch (e) {
      return StorageResult.failure(
          'Failed to rename field $oldFieldName to $newFieldName: $e');
    }
  }

  @override
  Future<StorageResult<bool>> down(Box box) async {
    try {
      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map<String, dynamic> && value.containsKey(newFieldName)) {
          value[oldFieldName] = value.remove(newFieldName);
          await box.put(key, value);
        }
      }

      return StorageResult.success(true);
    } catch (e) {
      return StorageResult.failure(
          'Failed to rollback rename field $newFieldName to $oldFieldName: $e');
    }
  }
}

/// Example migration: Transform field values
class TransformFieldMigration extends BaseMigration {
  final String fieldName;
  final dynamic Function(dynamic) transform;
  final dynamic Function(dynamic) reverseTransform;
  final bool Function(Map<String, dynamic>) shouldUpdate;

  TransformFieldMigration({
    required this.fieldName,
    required this.transform,
    required this.reverseTransform,
    required this.shouldUpdate,
    required int version,
    required String description,
  })  : _version = version,
        _description = description;

  final int _version;
  final String _description;

  @override
  int get version => _version;

  @override
  String get description => _description;

  @override
  Future<StorageResult<bool>> up(Box box) async {
    try {
      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map<String, dynamic> &&
            shouldUpdate(value) &&
            value.containsKey(fieldName)) {
          try {
            value[fieldName] = transform(value[fieldName]);
            await box.put(key, value);
          } catch (e) {
            // Log but continue with other records
            if (kDebugMode) {
              print('Warning: Failed to transform $fieldName for key $key: $e');
            }
          }
        }
      }

      return StorageResult.success(true);
    } catch (e) {
      return StorageResult.failure('Failed to transform field $fieldName: $e');
    }
  }

  @override
  Future<StorageResult<bool>> down(Box box) async {
    try {
      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map<String, dynamic> && value.containsKey(fieldName)) {
          try {
            value[fieldName] = reverseTransform(value[fieldName]);
            await box.put(key, value);
          } catch (e) {
            if (kDebugMode) {
              print(
                  'Warning: Failed to reverse transform $fieldName for key $key: $e');
            }
          }
        }
      }

      return StorageResult.success(true);
    } catch (e) {
      return StorageResult.failure(
          'Failed to reverse transform field $fieldName: $e');
    }
  }
}

/// Custom migration class for complex operations
class CustomMigration extends BaseMigration {
  final Future<StorageResult<bool>> Function(Box) _upFunction;
  final Future<StorageResult<bool>> Function(Box) _downFunction;
  final Future<StorageResult<bool>> Function(Box)? _validateFunction;

  CustomMigration({
    required int version,
    required String description,
    required Future<StorageResult<bool>> Function(Box) up,
    required Future<StorageResult<bool>> Function(Box) down,
    Future<StorageResult<bool>> Function(Box)? validate,
  })  : _version = version,
        _description = description,
        _upFunction = up,
        _downFunction = down,
        _validateFunction = validate;

  final int _version;
  final String _description;

  @override
  int get version => _version;

  @override
  String get description => _description;

  @override
  Future<StorageResult<bool>> up(Box box) => _upFunction(box);

  @override
  Future<StorageResult<bool>> down(Box box) => _downFunction(box);

  @override
  Future<StorageResult<bool>> validate(Box box) {
    return _validateFunction?.call(box) ?? super.validate(box);
  }
}

/// Migration builder for fluent API
class MigrationBuilder {
  int? _version;
  String? _description;
  Future<StorageResult<bool>> Function(Box)? _upFunction;
  Future<StorageResult<bool>> Function(Box)? _downFunction;
  Future<StorageResult<bool>> Function(Box)? _validateFunction;

  /// Set migration version
  MigrationBuilder version(int version) {
    _version = version;
    return this;
  }

  /// Set migration description
  MigrationBuilder description(String description) {
    _description = description;
    return this;
  }

  /// Set up function
  MigrationBuilder up(Future<StorageResult<bool>> Function(Box) up) {
    _upFunction = up;
    return this;
  }

  /// Set down function
  MigrationBuilder down(Future<StorageResult<bool>> Function(Box) down) {
    _downFunction = down;
    return this;
  }

  /// Set validate function
  MigrationBuilder validate(
      Future<StorageResult<bool>> Function(Box) validate) {
    _validateFunction = validate;
    return this;
  }

  /// Add field to all matching records
  MigrationBuilder addField(
    String fieldName,
    dynamic defaultValue, {
    bool Function(Map<String, dynamic>)? where,
  }) {
    return up((box) async {
      try {
        for (final key in box.keys) {
          final value = box.get(key);
          if (value is Map<String, dynamic>) {
            if (where == null || where(value)) {
              if (!value.containsKey(fieldName)) {
                value[fieldName] = defaultValue;
                await box.put(key, value);
              }
            }
          }
        }
        return StorageResult.success(true);
      } catch (e) {
        return StorageResult.failure('Failed to add field $fieldName: $e');
      }
    });
  }

  /// Remove field from all matching records
  MigrationBuilder removeField(
    String fieldName, {
    bool Function(Map<String, dynamic>)? where,
  }) {
    return up((box) async {
      try {
        for (final key in box.keys) {
          final value = box.get(key);
          if (value is Map<String, dynamic>) {
            if (where == null || where(value)) {
              if (value.containsKey(fieldName)) {
                value.remove(fieldName);
                await box.put(key, value);
              }
            }
          }
        }
        return StorageResult.success(true);
      } catch (e) {
        return StorageResult.failure('Failed to remove field $fieldName: $e');
      }
    });
  }

  /// Rename field in all matching records
  MigrationBuilder renameField(
    String oldName,
    String newName, {
    bool Function(Map<String, dynamic>)? where,
  }) {
    return up((box) async {
      try {
        for (final key in box.keys) {
          final value = box.get(key);
          if (value is Map<String, dynamic>) {
            if (where == null || where(value)) {
              if (value.containsKey(oldName) && !value.containsKey(newName)) {
                value[newName] = value.remove(oldName);
                await box.put(key, value);
              }
            }
          }
        }
        return StorageResult.success(true);
      } catch (e) {
        return StorageResult.failure(
            'Failed to rename field $oldName to $newName: $e');
      }
    });
  }

  /// Build the migration
  BaseMigration build() {
    if (_version == null) {
      throw ArgumentError('Migration version is required');
    }
    if (_description == null) {
      throw ArgumentError('Migration description is required');
    }
    if (_upFunction == null) {
      throw ArgumentError('Migration up function is required');
    }
    if (_downFunction == null) {
      throw ArgumentError('Migration down function is required');
    }

    return CustomMigration(
      version: _version!,
      description: _description!,
      up: _upFunction!,
      down: _downFunction!,
      validate: _validateFunction,
    );
  }
}

/// Helper functions for creating migrations
class MigrationHelper {
  /// Create a migration builder
  static MigrationBuilder create() => MigrationBuilder();

  /// Create add field migration
  static BaseMigration addField({
    required int version,
    required String description,
    required String fieldName,
    required dynamic defaultValue,
    bool Function(Map<String, dynamic>)? where,
  }) {
    return AddFieldMigration(
      fieldName: fieldName,
      defaultValue: defaultValue,
      shouldUpdate: where ?? (_) => true,
      version: version,
      description: description,
    );
  }

  /// Create rename field migration
  static BaseMigration renameField({
    required int version,
    required String description,
    required String oldName,
    required String newName,
    bool Function(Map<String, dynamic>)? where,
  }) {
    return RenameFieldMigration(
      oldFieldName: oldName,
      newFieldName: newName,
      shouldUpdate: where ?? (_) => true,
      version: version,
      description: description,
    );
  }

  /// Create transform field migration
  static BaseMigration transformField({
    required int version,
    required String description,
    required String fieldName,
    required dynamic Function(dynamic) transform,
    required dynamic Function(dynamic) reverseTransform,
    bool Function(Map<String, dynamic>)? where,
  }) {
    return TransformFieldMigration(
      fieldName: fieldName,
      transform: transform,
      reverseTransform: reverseTransform,
      shouldUpdate: where ?? (_) => true,
      version: version,
      description: description,
    );
  }
}
