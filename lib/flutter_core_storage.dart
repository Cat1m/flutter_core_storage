/// Flutter Core Storage Service
///
/// A comprehensive storage service package for Flutter applications.
/// 
/// This package provides:
/// - SharedPreferences wrapper for simple key-value storage
/// - Hive database integration for complex data storage
/// - Secure storage for sensitive data (tokens, passwords)
/// - File system operations (read, write, delete files)
/// - Cache management with TTL (Time To Live)
/// - Data serialization helpers
/// - Database migration support
/// - Encryption for sensitive data
///
/// ## Usage
/// 
/// ```dart
/// import 'package:flutter_core_storage/flutter_core_storage.dart';
/// 
/// // Initialize the service
/// await StorageService.initialize();
/// 
/// // Simple key-value storage
/// await StorageService.setString('username', 'john_doe');
/// final username = await StorageService.getString('username');
/// 
/// // Secure storage
/// await StorageService.setSecure('token', 'jwt_token_here');
/// final token = await StorageService.getSecure('token');
/// 
/// // Database operations
/// final user = User(id: 1, name: 'John');
/// await StorageService.save<User>('users', user);
/// final savedUser = await StorageService.get<User>('users', 1);
/// 
/// // Cache with TTL
/// await StorageService.cache('api_data', data, duration: Duration(hours: 1));
/// final cachedData = await StorageService.getCached('api_data');
/// ```
library flutter_core_storage;

// Core services
export 'src/services/storage_service.dart';
export 'src/services/preferences_service.dart';
export 'src/services/database_service.dart';
export 'src/services/secure_storage_service.dart';
export 'src/services/file_storage_service.dart';
export 'src/services/cache_service.dart';

// Models
export 'src/models/storage_config.dart';
export 'src/models/cache_item.dart';
export 'src/models/database_model.dart';
export 'src/models/storage_result.dart';

// Exceptions
export 'src/exceptions/storage_exceptions.dart';

// Utils
export 'src/utils/storage_utils.dart';
export 'src/utils/encryption_utils.dart';
export 'src/utils/serialization_utils.dart';

// Adapters (for Hive)
export 'src/adapters/base_adapter.dart';

// Migrations
export 'src/migrations/migration_manager.dart';
export 'src/migrations/base_migration.dart';
