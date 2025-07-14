// test/test_helper.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

/// Test helper to set up the testing environment
class TestHelper {
  /// Set up the test environment
  static void setUp() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set up method channel mocks for platform channels
    _setupMethodChannelMocks();

    // Set up SharedPreferences mock
    SharedPreferences.setMockInitialValues({});

    // Register fallback values for mocktail
    _registerFallbackValues();
  }

  /// Set up method channel mocks for platform-specific features
  static void _setupMethodChannelMocks() {
    // Mock for path_provider
    const MethodChannel('plugins.flutter.io/path_provider')
        // ignore: deprecated_member_use
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getApplicationDocumentsDirectory':
          return '/mock/documents';
        case 'getTemporaryDirectory':
          return '/mock/temp';
        case 'getApplicationSupportDirectory':
          return '/mock/support';
        default:
          return null;
      }
    });

    // Mock for flutter_secure_storage
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
        // ignore: deprecated_member_use
        .setMockMethodCallHandler((MethodCall methodCall) async {
      // Simple in-memory storage for testing
      final Map<String, String> storage = {};

      switch (methodCall.method) {
        case 'write':
          final args = methodCall.arguments as Map;
          storage[args['key']] = args['value'];
          return null;
        case 'read':
          final args = methodCall.arguments as Map;
          return storage[args['key']];
        case 'delete':
          final args = methodCall.arguments as Map;
          storage.remove(args['key']);
          return null;
        case 'deleteAll':
          storage.clear();
          return null;
        case 'readAll':
          return storage;
        case 'containsKey':
          final args = methodCall.arguments as Map;
          return storage.containsKey(args['key']);
        default:
          return null;
      }
    });
  }

  /// Register fallback values for mocktail
  static void _registerFallbackValues() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<String>[]);
    registerFallbackValue(const Duration(hours: 1));
    registerFallbackValue(DateTime.now());
  }

  /// Clean up after tests
  static void tearDown() {
    // Reset method channel handlers
    const MethodChannel('plugins.flutter.io/path_provider')
        // ignore: deprecated_member_use
        .setMockMethodCallHandler(null);
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
        // ignore: deprecated_member_use
        .setMockMethodCallHandler(null);
  }
}
