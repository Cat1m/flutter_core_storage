# Flutter Core Storage 🗄️

A comprehensive storage service package for Flutter applications providing unified access to various storage mechanisms.

## ✨ Features

- **🔑 Simple Key-Value Storage** - SharedPreferences wrapper
- **🗃️ Database Operations** - Hive integration for complex data
- **🔒 Secure Storage** - Encrypted storage for sensitive data
- **📁 File Operations** - Read/write files with ease
- **⏰ Cache Management** - TTL-based caching system
- **🔧 Data Serialization** - JSON helpers and custom adapters
- **🚀 Migration Support** - Database schema migrations
- **🛡️ Type Safety** - Full Dart type safety support

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_core_storage: ^1.0.0
```

### Basic Usage

```dart
import 'package:flutter_core_storage/flutter_core_storage.dart';

// Initialize (call this in main())
await StorageService.initialize();

// Simple key-value storage
await StorageService.instance.setString('username', 'john_doe');
final username = await StorageService.instance.getString('username');

// Secure storage for sensitive data
await StorageService.instance.setSecure('auth_token', 'jwt_token_here');
final token = await StorageService.instance.getSecure('auth_token');

// Cache with automatic expiration
await StorageService.instance.cache(
  'user_data', 
  userData, 
  duration: Duration(hours: 1)
);
final cachedData = await StorageService.instance.getCached('user_data');
```

## 📚 Documentation

### Storage Types

1. **Preferences Storage** - For simple app settings
2. **Secure Storage** - For tokens, passwords, sensitive data
3. **Database Storage** - For complex objects and relationships
4. **File Storage** - For documents, images, large data
5. **Cache Storage** - For temporary data with TTL

### API Reference

[Detailed API documentation coming soon...]

## 🧪 Testing

```bash
flutter test
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Hive](https://pub.dev/packages/hive) for fast database operations
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) for secure data
- [SharedPreferences](https://pub.dev/packages/shared_preferences) for simple storage
