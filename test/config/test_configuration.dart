/// Test configuration and constants
class TestConfig {
  // Test timeouts
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration mediumTimeout = Duration(seconds: 15);
  static const Duration longTimeout = Duration(seconds: 30);

  // Test data sizes
  static const int smallDataSize = 100;
  static const int mediumDataSize = 1000;
  static const int largeDataSize = 10000;

  // Performance thresholds
  static const double minOperationsPerSecond = 100;
  static const int maxMemoryUsageMB = 50;
  static const int maxCacheSize = 1000;

  // Test patterns
  static const String testKeyPattern = r'^test_\w+$';
  static const String tempKeyPattern = r'^temp_\w+$';

  /// Get test timeout based on test type
  static Duration getTimeout(String testType) {
    switch (testType) {
      case 'unit':
        return shortTimeout;
      case 'integration':
        return mediumTimeout;
      case 'performance':
        return longTimeout;
      default:
        return mediumTimeout;
    }
  }

  /// Generate test data of specified size
  static String generateTestData(int size) {
    return List.generate(size, (i) => 'test_data_item_$i').join(',');
  }

  /// Generate test object
  static Map<String, dynamic> generateTestObject(int id) {
    return {
      'id': id,
      'name': 'Test Object $id',
      'created_at': DateTime.now().toIso8601String(),
      'data': List.generate(10, (i) => 'item_${id}_$i'),
      'metadata': {
        'version': 1,
        'type': 'test',
        'size': 10,
      }
    };
  }
}

// Example pubspec.yaml dev_dependencies section for testing:
/*
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mocktail: ^1.0.1
  integration_test: ^0.13.0
  test: ^1.24.0
  coverage: ^1.6.0
  very_good_analysis: ^5.1.0

scripts:
  test: flutter test
  test_coverage: flutter test --coverage && genhtml coverage/lcov.info -o coverage/html
  test_integration: flutter test integration_test
  test_performance: flutter test test/performance
*/
