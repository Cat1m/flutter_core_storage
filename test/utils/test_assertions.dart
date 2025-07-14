// test/utils/test_assertions.dart
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Custom assertions for storage testing
class StorageAssertions {
  /// Assert that a StorageResult is successful
  static void assertSuccess<T>(StorageResult<T> result, [String? message]) {
    expect(result.success, isTrue,
        reason: message ?? 'Expected successful result');
    expect(result.error, isNull,
        reason: 'Expected no error in successful result');
  }

  /// Assert that a StorageResult failed
  static void assertFailure<T>(StorageResult<T> result,
      [String? expectedError]) {
    expect(result.success, isFalse, reason: 'Expected failed result');
    expect(result.error, isNotNull,
        reason: 'Expected error message in failed result');
    if (expectedError != null) {
      expect(result.error, contains(expectedError));
    }
  }

  /// Assert that a StorageResult has specific data
  static void assertData<T>(StorageResult<T> result, T expectedData) {
    assertSuccess(result);
    expect(result.data, equals(expectedData));
  }

  /// Assert cache hit/miss statistics
  static void assertCacheStats(
    Map<String, dynamic> stats, {
    int? expectedHits,
    int? expectedMisses,
    int? expectedSize,
    double? minHitRate,
  }) {
    if (expectedHits != null) {
      expect(stats['hits'], equals(expectedHits),
          reason: 'Cache hits mismatch');
    }
    if (expectedMisses != null) {
      expect(stats['misses'], equals(expectedMisses),
          reason: 'Cache misses mismatch');
    }
    if (expectedSize != null) {
      expect(stats['size'], equals(expectedSize),
          reason: 'Cache size mismatch');
    }
    if (minHitRate != null) {
      expect(stats['hitRate'], greaterThanOrEqualTo(minHitRate),
          reason: 'Hit rate below minimum expected');
    }
  }

  /// Assert file operations
  static void assertFileExists(bool exists, [String? fileName]) {
    expect(exists, isTrue,
        reason:
            'Expected file to exist${fileName != null ? ': $fileName' : ''}');
  }

  /// Assert file content
  static void assertFileContent(String? content, String expected,
      [String? fileName]) {
    expect(content, isNotNull,
        reason:
            'Expected file content to exist${fileName != null ? ' for $fileName' : ''}');
    expect(content, equals(expected),
        reason:
            'File content mismatch${fileName != null ? ' for $fileName' : ''}');
  }

  /// Assert performance metrics
  static void assertPerformance({
    required int operations,
    required int elapsedMs,
    required double minOpsPerSec,
    String? operation,
  }) {
    final opsPerSec = operations / (elapsedMs / 1000);
    expect(opsPerSec, greaterThanOrEqualTo(minOpsPerSec),
        reason: 'Performance below expected for ${operation ?? 'operation'}: '
            '${opsPerSec.toStringAsFixed(2)} ops/sec < $minOpsPerSec ops/sec');
  }

  /// Assert data integrity after operations
  static void assertDataIntegrity<T>(List<T> original, List<T> retrieved) {
    expect(retrieved.length, equals(original.length),
        reason: 'Data count mismatch');
    for (int i = 0; i < original.length; i++) {
      expect(retrieved[i], equals(original[i]),
          reason: 'Data integrity failed at index $i');
    }
  }
}
