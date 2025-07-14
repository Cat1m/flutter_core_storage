// testing_guide.md

/*
# Storage Package Testing Guide

## Overview
This guide covers comprehensive testing for the Flutter Storage Package using mocktail.

## Test Structure

```
test/
├── mocks/
│   └── storage_mocks.dart           # Mock classes and utilities
├── services/
│   ├── preferences_service_test.dart
│   ├── cache_service_test.dart
│   ├── database_service_test.dart
│   ├── secure_storage_service_test.dart
│   ├── file_storage_service_test.dart
│   └── storage_service_test.dart    # Main facade tests
├── models/
│   ├── storage_result_test.dart
│   ├── cache_item_test.dart
│   └── storage_config_test.dart
├── utils/
│   ├── storage_utils_test.dart
│   ├── encryption_utils_test.dart
│   └── serialization_utils_test.dart
├── integration/
│   └── storage_integration_test.dart
├── performance/
│   └── storage_benchmark_test.dart
├── scenarios/
│   └── user_workflow_test.dart
├── edge_cases/
│   └── error_scenarios_test.dart
├── utils/
│   ├── test_data_factory.dart       # Test data generation
│   └── test_assertions.dart         # Custom assertions
├── config/
│   └── test_configuration.dart     # Test configuration
├── test_helper.dart                # Test setup utilities
└── all_tests.dart                  # Test runner
```

## Running Tests

### All Tests
```bash
flutter test
```

### Specific Test Categories
```bash
# Unit tests only
flutter test test/services/ test/models/ test/utils/

# Integration tests
flutter test test/integration/

# Performance tests
flutter test test/performance/

# Scenario tests
flutter test test/scenarios/

# Edge case tests
flutter test test/edge_cases/
```

### With Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Test Categories

### 1. Unit Tests
- Test individual components in isolation
- Mock dependencies using mocktail
- Fast execution (< 5 seconds per test file)
- High code coverage (> 95%)

### 2. Integration Tests
- Test component interactions
- Use real storage backends when possible
- Test complete workflows
- Medium execution time (< 30 seconds)

### 3. Performance Tests
- Measure throughput and latency
- Memory usage validation
- Concurrency testing
- Longer execution time allowed

### 4. Scenario Tests
- Real-world user scenarios
- End-to-end workflows
- Business logic validation
- Data integrity checks

### 5. Edge Case Tests
- Error conditions
- Boundary values
- Invalid inputs
- Recovery scenarios

## Test Data Management

### Using TestDataFactory
```dart
// Generate realistic test data
final user = TestDataFactory.createUser(
  name: 'John Doe',
  email: 'john@example.com',
);

final users = TestDataFactory.createUserList(100);
final largeText = TestDataFactory.createLargeText(50);
```

### Cache Item Testing
```dart
// Valid cache item
final item = TestDataFactory.createCacheItem('data', ttl: Duration(hours: 1));

// Expired cache item
final expired = TestDataFactory.createExpiredCacheItem('data');
```

## Custom Assertions

### StorageResult Assertions
```dart
// Assert success
StorageAssertions.assertSuccess(result);
StorageAssertions.assertData(result, expectedData);

// Assert failure
StorageAssertions.assertFailure(result, 'Expected error message');
```

### Performance Assertions
```dart
StorageAssertions.assertPerformance(
  operations: 1000,
  elapsedMs: stopwatch.elapsedMilliseconds,
  minOpsPerSec: 100,
  operation: 'cache_write',
);
```

### Cache Statistics
```dart
StorageAssertions.assertCacheStats(
  stats,
  expectedHits: 10,
  expectedMisses: 2,
  minHitRate: 80.0,
);
```

## Mock Setup

### Basic Service Mocking
```dart
class MyTest extends StorageTestBase {
  @override
  void setUp() {
    super.setUp();
    
    // Setup specific mock behaviors
    when(() => mockCacheService.getCached<String>(any()))
        .thenAnswer((_) async => StorageResult.success('cached_data'));
  }
}
```

### Method Channel Mocking
```dart
void setUpMethodChannels() {
  const MethodChannel('plugins.flutter.io/path_provider')
      .setMockMethodCallHandler((call) async {
    switch (call.method) {
      case 'getApplicationDocumentsDirectory':
        return '/mock/documents';
      default:
        return null;
    }
  });
}
```

## Best Practices

### 1. Test Organization
- Group related tests together
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- One assertion per test when possible

### 2. Mock Usage
- Mock external dependencies only
- Don't mock the class under test
- Use verify() to check mock interactions
- Reset mocks in tearDown()

### 3. Data Management
- Use TestDataFactory for consistent test data
- Don't rely on specific random values
- Clean up test data in tearDown()
- Isolate tests from each other

### 4. Performance Testing
- Set realistic performance expectations
- Test with different data sizes
- Measure both best and worst case scenarios
- Include concurrency tests

### 5. Error Testing
- Test all error paths
- Verify error messages and types
- Test recovery scenarios
- Use edge case data

## Example Test Patterns

### Testing Async Operations
```dart
test('should handle async operations correctly', () async {
  // Arrange
  await StorageService.initialize();
  
  // Act
  final result = await StorageService.instance.setString('key', 'value');
  
  // Assert
  expect(result, isTrue);
  
  // Verify
  final retrieved = await StorageService.instance.getString('key');
  expect(retrieved, equals('value'));
});
```

### Testing Error Conditions
```dart
test('should handle errors gracefully', () async {
  // Arrange
  await StorageService.initialize();
  
  // Act & Assert
  expect(
    () => StorageService.instance.setString('', 'value'),
    throwsA(isA<StorageOperationException>()),
  );
});
```

### Testing Performance
```dart
test('should meet performance requirements', () async {
  // Arrange
  await StorageService.initialize();
  const operations = 1000;
  
  // Act
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < operations; i++) {
    await StorageService.instance.setString('key_$i', 'value_$i');
  }
  stopwatch.stop();
  
  // Assert
  StorageAssertions.assertPerformance(
    operations: operations,
    elapsedMs: stopwatch.elapsedMilliseconds,
    minOpsPerSec: 100,
    operation: 'preferences_write',
  );
});
```

### Testing Data Integrity
```dart
test('should maintain data integrity', () async {
  // Arrange
  await StorageService.initialize();
  final originalData = TestDataFactory.createUserList(50);
  
  // Act
  for (final user in originalData) {
    await StorageService.instance.save('users', user, key: user['id']);
  }
  
  final retrievedData = await StorageService.instance.getAll<Map<String, dynamic>>('users');
  
  // Assert
  StorageAssertions.assertDataIntegrity(originalData, retrievedData);
});
```

## Continuous Integration

### GitHub Actions Example
```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: flutter test test/integration/
      - run: flutter test test/performance/
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

## Debugging Tests

### Common Issues
1. **Tests hanging**: Check for missing await keywords
2. **Flaky tests**: Ensure proper cleanup and isolation
3. **Mock verification failures**: Check method call arguments
4. **Performance test failures**: Adjust expectations for CI environment

### Debug Output
```dart
test('debug example', () async {
  // Enable debug output
  debugPrint('Starting test...');
  
  // Use test-specific logging
  final result = await StorageService.instance.setString('key', 'value');
  print('Operation result: $result');
  
  // Get detailed storage info
  final info = await StorageService.instance.getStorageInfo();
  print('Storage info: $info');
});
```

## Code Coverage

### Target Coverage
- Unit tests: 95%+
- Integration tests: 80%+
- Overall: 90%+

### Excluded Files
```yaml
# coverage_config.yaml
exclude:
  - '**/*_test.dart'
  - '**/mocks/**'
  - '**/test_helper.dart'
```

## Testing Checklist

### Before Committing
- [ ] All tests pass locally
- [ ] Code coverage meets requirements
- [ ] Performance tests pass
- [ ] No flaky tests
- [ ] Mock cleanup verified
- [ ] Error scenarios tested

### Code Review
- [ ] Test names are descriptive
- [ ] Tests follow AAA pattern
- [ ] Mocks are appropriate
- [ ] Edge cases covered
- [ ] Performance implications considered
- [ ] Documentation updated

## Troubleshooting

### Common Problems

1. **SharedPreferences Mock Issues**
```dart
// Solution: Reset mock values in setUp
SharedPreferences.setMockInitialValues({});
```

2. **Method Channel Errors**
```dart
// Solution: Mock all required channels
TestHelper.setUp(); // Sets up common mocks
```

3. **Async Test Failures**
```dart
// Solution: Always await async operations
await StorageService.initialize();
await future;
```

4. **Memory Leaks in Tests**
```dart
// Solution: Proper cleanup
tearDown(() async {
  if (StorageService.isInitialized) {
    await StorageService.dispose();
  }
});
```

5. **Flaky Performance Tests**
```dart
// Solution: Use relative performance metrics
final baseline = await measureBaseline();
final actual = await measureActual();
expect(actual / baseline, lessThan(2.0)); // Within 2x of baseline
```

## Resources

- [Mocktail Documentation](https://pub.dev/packages/mocktail)
- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Dart Test Package](https://pub.dev/packages/test)
- [Test Coverage](https://pub.dev/packages/coverage)

## Contributing

When adding new tests:
1. Follow existing patterns
2. Add to appropriate test category
3. Update this documentation
4. Ensure CI passes
5. Get code review
*/

// test_runner.dart - Advanced test runner with filtering and reporting

import 'dart:io';
import 'package:args/args.dart';

/// Advanced test runner with filtering and reporting capabilities
class TestRunner {
  static void main(List<String> arguments) {
    final parser = ArgParser()
      ..addOption('category', 
          abbr: 'c',
          help: 'Test category to run',
          allowed: ['unit', 'integration', 'performance', 'scenarios', 'all'],
          defaultsTo: 'all')
      ..addFlag('coverage',
          help: 'Generate coverage report',
          defaultsTo: false)
      ..addFlag('verbose',
          abbr: 'v',
          help: 'Verbose output',
          defaultsTo: false)
      ..addOption('timeout',
          help: 'Test timeout in seconds',
          defaultsTo: '30')
      ..addFlag('help',
          abbr: 'h',
          help: 'Show help',
          negatable: false);

    final results = parser.parse(arguments);

    if (results['help']) {
      print('Storage Package Test Runner\n');
      print(parser.usage);
      return;
    }

    final category = results['category'] as String;
    final coverage = results['coverage'] as bool;
    final verbose = results['verbose'] as bool;
    final timeout = int.parse(results['timeout'] as String);

    runTests(
      category: category,
      coverage: coverage,
      verbose: verbose,
      timeout: timeout,
    );
  }

  static void runTests({
    required String category,
    required bool coverage,
    required bool verbose,
    required int timeout,
  }) {
    print('🚀 Running $category tests...\n');

    final testPaths = _getTestPaths(category);
    final commands = <String>[];

    // Build flutter test command
    var cmd = 'flutter test';
    
    if (coverage) {
      cmd += ' --coverage';
    }
    
    if (verbose) {
      cmd += ' --verbose';
    }
    
    cmd += ' --timeout ${timeout}s';
    
    // Add test paths
    for (final path in testPaths) {
      commands.add('$cmd $path');
    }

    // Execute tests
    for (final command in commands) {
      print('Executing: $command');
      final result = Process.runSync('sh', ['-c', command]);
      
      if (result.exitCode != 0) {
        print('❌ Test failed: ${result.stderr}');
        exit(1);
      } else {
        print('✅ Tests passed');
      }
    }

    // Generate coverage report if requested
    if (coverage) {
      print('\n📊 Generating coverage report...');
      final coverageResult = Process.runSync('sh', ['-c', 
        'genhtml coverage/lcov.info -o coverage/html --quiet']);
      
      if (coverageResult.exitCode == 0) {
        print('✅ Coverage report generated: coverage/html/index.html');
      } else {
        print('⚠️ Coverage report generation failed');
      }
    }

    print('\n🎉 All tests completed successfully!');
  }

  static List<String> _getTestPaths(String category) {
    switch (category) {
      case 'unit':
        return ['test/services/', 'test/models/', 'test/utils/'];
      case 'integration':
        return ['test/integration/'];
      case 'performance':
        return ['test/performance/'];
      case 'scenarios':
        return ['test/scenarios/', 'test/edge_cases/'];
      case 'all':
        return ['test/'];
      default:
        throw ArgumentError('Unknown test category: $category');
    }
  }
}

// Usage examples:
// dart test_runner.dart --category unit --coverage
// dart test_runner.dart --category performance --verbose
// dart test_runner.dart --category all --coverage --timeout 60