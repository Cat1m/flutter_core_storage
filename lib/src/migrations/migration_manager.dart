import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/storage_result.dart';
import 'base_migration.dart';

/// Manager for database migrations
class MigrationManager {
  static const String _migrationBoxName = '_migrations';
  static const String _versionKey = '_schema_version';

  final List<BaseMigration> _migrations = [];
  Box<dynamic>? _migrationBox;
  bool _isInitialized = false;

  /// Initialize the migration manager
  Future<StorageResult<bool>> initialize() async {
    if (_isInitialized) {
      return StorageResult.success(true);
    }

    try {
      _migrationBox = await Hive.openBox(_migrationBoxName);
      _isInitialized = true;

      debugPrint('✅ MigrationManager initialized successfully');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ MigrationManager initialization failed: $e');
      return StorageResult.failure(
          'Failed to initialize migration manager: $e');
    }
  }

  /// Add a migration
  StorageResult<bool> addMigration(BaseMigration migration) {
    try {
      // Check for duplicate versions
      if (_migrations.any((m) => m.version == migration.version)) {
        return StorageResult.failure(
            'Migration version ${migration.version} already exists');
      }

      _migrations.add(migration);

      // Sort migrations by version
      _migrations.sort((a, b) => a.version.compareTo(b.version));

      debugPrint('📦 Added migration: ${migration.toString()}');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to add migration: $e');
      return StorageResult.failure('Failed to add migration: $e');
    }
  }

  /// Add multiple migrations
  StorageResult<int> addMigrations(List<BaseMigration> migrations) {
    int addedCount = 0;

    for (final migration in migrations) {
      final result = addMigration(migration);
      if (result.success) {
        addedCount++;
      } else {
        debugPrint(
            '⚠️ Failed to add migration v${migration.version}: ${result.error}');
      }
    }

    debugPrint('📦 Added $addedCount/${migrations.length} migrations');
    return StorageResult.success(addedCount);
  }

  /// Get current schema version
  Future<StorageResult<int>> getCurrentVersion() async {
    try {
      if (!_isInitialized) {
        return StorageResult.failure('Migration manager not initialized');
      }

      final version = _migrationBox!.get(_versionKey, defaultValue: 0) as int;

      debugPrint('📊 Current schema version: $version');
      return StorageResult.success(version);
    } catch (e) {
      debugPrint('❌ Failed to get current version: $e');
      return StorageResult.failure('Failed to get current version: $e');
    }
  }

  /// Set current schema version
  Future<StorageResult<bool>> _setCurrentVersion(int version) async {
    try {
      await _migrationBox!.put(_versionKey, version);

      debugPrint('📊 Set schema version to: $version');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to set current version: $e');
      return StorageResult.failure('Failed to set current version: $e');
    }
  }

  /// Get migration history
  Future<StorageResult<List<MigrationRecord>>> getMigrationHistory() async {
    try {
      if (!_isInitialized) {
        return StorageResult.failure('Migration manager not initialized');
      }

      final history = <MigrationRecord>[];

      for (final key in _migrationBox!.keys) {
        if (key != _versionKey &&
            key is String &&
            key.startsWith('migration_')) {
          final data = _migrationBox!.get(key);
          if (data is Map<String, dynamic>) {
            history.add(MigrationRecord.fromJson(data));
          }
        }
      }

      // Sort by version
      history.sort((a, b) => a.version.compareTo(b.version));

      debugPrint('📋 Retrieved migration history: ${history.length} records');
      return StorageResult.success(history);
    } catch (e) {
      debugPrint('❌ Failed to get migration history: $e');
      return StorageResult.failure('Failed to get migration history: $e');
    }
  }

  /// Record migration execution
  Future<StorageResult<bool>> _recordMigration(
    BaseMigration migration,
    bool success, {
    String? error,
  }) async {
    try {
      final record = MigrationRecord(
        version: migration.version,
        description: migration.description,
        appliedAt: DateTime.now(),
        success: success,
        error: error,
      );

      final key = 'migration_${migration.version}';
      await _migrationBox!.put(key, record.toJson());

      debugPrint(
          '📝 Recorded migration: v${migration.version} (success: $success)');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to record migration: $e');
      return StorageResult.failure('Failed to record migration: $e');
    }
  }

  /// Migrate database to latest version
  Future<StorageResult<int>> migrate(String boxName,
      {bool dryRun = false}) async {
    try {
      if (!_isInitialized) {
        return StorageResult.failure('Migration manager not initialized');
      }

      final box = await Hive.openBox(boxName);
      final currentVersionResult = await getCurrentVersion();

      if (!currentVersionResult.success) {
        return StorageResult.failure(
            'Failed to get current version: ${currentVersionResult.error}');
      }

      final currentVersion = currentVersionResult.data!;
      final pendingMigrations =
          _migrations.where((m) => m.version > currentVersion).toList();

      if (pendingMigrations.isEmpty) {
        debugPrint('✅ Database is up to date (v$currentVersion)');
        return StorageResult.success(0);
      }

      debugPrint(
          '🚀 Starting migration from v$currentVersion to v${pendingMigrations.last.version}');
      debugPrint(
          '📦 Pending migrations: ${pendingMigrations.map((m) => 'v${m.version}').join(', ')}');

      if (dryRun) {
        debugPrint('🧪 Dry run mode - no changes will be made');
        return StorageResult.success(pendingMigrations.length);
      }

      int appliedCount = 0;

      for (final migration in pendingMigrations) {
        debugPrint(
            '⬆️ Applying migration v${migration.version}: ${migration.description}');

        try {
          // Validate migration
          final validateResult = await migration.validate(box);
          if (!validateResult.success) {
            final error =
                'Migration validation failed: ${validateResult.error}';
            await _recordMigration(migration, false, error: error);
            return StorageResult.failure(error);
          }

          // Apply migration
          final result = await migration.up(box);

          if (result.success) {
            await _setCurrentVersion(migration.version);
            await _recordMigration(migration, true);
            appliedCount++;

            debugPrint('✅ Applied migration v${migration.version}');
          } else {
            final error = 'Migration failed: ${result.error}';
            await _recordMigration(migration, false, error: error);
            return StorageResult.failure(error);
          }
        } catch (e) {
          final error = 'Migration threw exception: $e';
          await _recordMigration(migration, false, error: error);
          return StorageResult.failure(error);
        }
      }

      await box.close();

      debugPrint('🎉 Successfully applied $appliedCount migrations');
      return StorageResult.success(appliedCount);
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      return StorageResult.failure('Migration failed: $e');
    }
  }

  /// Migrate to specific version
  Future<StorageResult<int>> migrateTo(String boxName, int targetVersion,
      {bool dryRun = false}) async {
    try {
      if (!_isInitialized) {
        return StorageResult.failure('Migration manager not initialized');
      }

      final box = await Hive.openBox(boxName);
      final currentVersionResult = await getCurrentVersion();

      if (!currentVersionResult.success) {
        return StorageResult.failure(
            'Failed to get current version: ${currentVersionResult.error}');
      }

      final currentVersion = currentVersionResult.data!;

      if (currentVersion == targetVersion) {
        debugPrint('✅ Already at target version v$targetVersion');
        return StorageResult.success(0);
      }

      if (targetVersion > currentVersion) {
        // Forward migration
        final migrationsToApply = _migrations
            .where(
                (m) => m.version > currentVersion && m.version <= targetVersion)
            .toList();

        return await _applyMigrations(box, migrationsToApply, dryRun: dryRun);
      } else {
        // Rollback migration
        final migrationsToRollback = _migrations
            .where(
                (m) => m.version > targetVersion && m.version <= currentVersion)
            .toList()
            .reversed
            .toList();

        return await _rollbackMigrations(
            box, migrationsToRollback, targetVersion,
            dryRun: dryRun);
      }
    } catch (e) {
      debugPrint('❌ Migration to v$targetVersion failed: $e');
      return StorageResult.failure('Migration to v$targetVersion failed: $e');
    }
  }

  /// Apply migrations forward
  Future<StorageResult<int>> _applyMigrations(
    Box box,
    List<BaseMigration> migrations, {
    bool dryRun = false,
  }) async {
    if (dryRun) {
      debugPrint('🧪 Dry run: Would apply ${migrations.length} migrations');
      return StorageResult.success(migrations.length);
    }

    int appliedCount = 0;

    for (final migration in migrations) {
      debugPrint(
          '⬆️ Applying migration v${migration.version}: ${migration.description}');

      final result = await migration.up(box);

      if (result.success) {
        await _setCurrentVersion(migration.version);
        await _recordMigration(migration, true);
        appliedCount++;

        debugPrint('✅ Applied migration v${migration.version}');
      } else {
        await _recordMigration(migration, false, error: result.error);
        return StorageResult.failure(
            'Migration v${migration.version} failed: ${result.error}');
      }
    }

    return StorageResult.success(appliedCount);
  }

  /// Rollback migrations
  Future<StorageResult<int>> _rollbackMigrations(
    Box box,
    List<BaseMigration> migrations,
    int targetVersion, {
    bool dryRun = false,
  }) async {
    if (dryRun) {
      debugPrint('🧪 Dry run: Would rollback ${migrations.length} migrations');
      return StorageResult.success(migrations.length);
    }

    int rolledBackCount = 0;

    for (final migration in migrations) {
      debugPrint(
          '⬇️ Rolling back migration v${migration.version}: ${migration.description}');

      final result = await migration.down(box);

      if (result.success) {
        rolledBackCount++;
        debugPrint('✅ Rolled back migration v${migration.version}');
      } else {
        return StorageResult.failure(
            'Rollback v${migration.version} failed: ${result.error}');
      }
    }

    await _setCurrentVersion(targetVersion);

    return StorageResult.success(rolledBackCount);
  }

  /// Rollback to previous version
  Future<StorageResult<bool>> rollback(String boxName) async {
    try {
      final currentVersionResult = await getCurrentVersion();
      if (!currentVersionResult.success) {
        return StorageResult.failure(
            'Failed to get current version: ${currentVersionResult.error}');
      }

      final currentVersion = currentVersionResult.data!;

      if (currentVersion <= 0) {
        return StorageResult.failure(
            'Already at initial version, cannot rollback');
      }

      // Find the migration to rollback
      final migrationToRollback = _migrations.firstWhere(
        (m) => m.version == currentVersion,
        orElse: () => throw StateError('Migration v$currentVersion not found'),
      );

      final box = await Hive.openBox(boxName);

      debugPrint('⬇️ Rolling back migration v${migrationToRollback.version}');

      final result = await migrationToRollback.down(box);

      if (result.success) {
        // Set version to previous migration version or 0
        final previousVersion = _migrations
            .where((m) => m.version < currentVersion)
            .map((m) => m.version)
            .fold<int>(0, (prev, current) => current > prev ? current : prev);

        await _setCurrentVersion(previousVersion);
        await box.close();

        debugPrint('✅ Successfully rolled back to v$previousVersion');
        return StorageResult.success(true);
      } else {
        await box.close();
        return StorageResult.failure('Rollback failed: ${result.error}');
      }
    } catch (e) {
      debugPrint('❌ Rollback failed: $e');
      return StorageResult.failure('Rollback failed: $e');
    }
  }

  /// Reset database to initial state
  Future<StorageResult<bool>> reset(String boxName) async {
    try {
      final box = await Hive.openBox(boxName);

      debugPrint('🔄 Resetting database to initial state');

      await box.clear();
      await _setCurrentVersion(0);

      // Clear migration history for this box
      final keysToRemove = _migrationBox!.keys
          .where((key) => key is String && key.startsWith('migration_'))
          .toList();

      for (final key in keysToRemove) {
        await _migrationBox!.delete(key);
      }

      await box.close();

      debugPrint('✅ Database reset successfully');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Database reset failed: $e');
      return StorageResult.failure('Database reset failed: $e');
    }
  }

  /// Get migration status
  Future<StorageResult<Map<String, dynamic>>> getStatus() async {
    try {
      final currentVersionResult = await getCurrentVersion();
      final historyResult = await getMigrationHistory();

      if (!currentVersionResult.success) {
        return StorageResult.failure(
            'Failed to get current version: ${currentVersionResult.error}');
      }

      final currentVersion = currentVersionResult.data!;
      final history =
          historyResult.success ? historyResult.data! : <MigrationRecord>[];

      final pendingMigrations =
          _migrations.where((m) => m.version > currentVersion).toList();
      final availableMigrations = _migrations
          .map((m) => {
                'version': m.version,
                'description': m.description,
                'applied':
                    history.any((h) => h.version == m.version && h.success),
              })
          .toList();

      final status = {
        'currentVersion': currentVersion,
        'latestVersion': _migrations.isNotEmpty ? _migrations.last.version : 0,
        'isUpToDate': pendingMigrations.isEmpty,
        'pendingMigrations': pendingMigrations.length,
        'totalMigrations': _migrations.length,
        'availableMigrations': availableMigrations,
        'history': history.map((h) => h.toJson()).toList(),
      };

      return StorageResult.success(status);
    } catch (e) {
      debugPrint('❌ Failed to get migration status: $e');
      return StorageResult.failure('Failed to get migration status: $e');
    }
  }

  /// Check if migrations are needed
  Future<StorageResult<bool>> needsMigration() async {
    try {
      final currentVersionResult = await getCurrentVersion();
      if (!currentVersionResult.success) {
        return StorageResult.failure(
            'Failed to get current version: ${currentVersionResult.error}');
      }

      final currentVersion = currentVersionResult.data!;
      final hasNewerMigrations =
          _migrations.any((m) => m.version > currentVersion);

      return StorageResult.success(hasNewerMigrations);
    } catch (e) {
      return StorageResult.failure('Failed to check migration status: $e');
    }
  }

  /// Dispose migration manager
  Future<void> dispose() async {
    try {
      if (_migrationBox != null) {
        await _migrationBox!.close();
        _migrationBox = null;
      }

      _migrations.clear();
      _isInitialized = false;

      debugPrint('✅ MigrationManager disposed successfully');
    } catch (e) {
      debugPrint('❌ MigrationManager disposal failed: $e');
    }
  }
}
