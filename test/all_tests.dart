import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'services/preferences_service_test.dart' as preferences_tests;
import 'services/cache_service_test.dart' as cache_tests;
import 'services/storage_service_test.dart' as storage_tests;
import 'models/storage_result_test.dart' as storage_result_tests;
import 'models/cache_item_test.dart' as cache_item_tests;
import 'utils/storage_utils_test.dart' as storage_utils_tests;
import 'utils/encryption_utils_test.dart' as encryption_utils_tests;

import 'test_helper.dart';

// test/all_tests.dart
/// Test runner that imports all test files
/// Run with: flutter test test/all_tests.dart

void main() {
  setUpAll(() {
    TestHelper.setUp();
  });

  tearDownAll(() {
    TestHelper.tearDown();
  });

  group('Storage Package Tests', () {
    group('Services', () {
      preferences_tests.main();
      cache_tests.main();
      storage_tests.main();
    });

    group('Models', () {
      storage_result_tests.main();
      cache_item_tests.main();
    });

    group('Utils', () {
      storage_utils_tests.main();
      encryption_utils_tests.main();
    });
  });
}
