// test/utils/storage_utils_test.dart (abbreviated)
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageUtils', () {
    group('Key Validation', () {
      test('should validate valid keys', () {
        expect(StorageUtils.isValidKey('valid_key'), isTrue);
        expect(StorageUtils.isValidKey('user:123'), isTrue);
        expect(StorageUtils.isValidKey('app.settings'), isTrue);
      });

      test('should reject invalid keys', () {
        expect(StorageUtils.isValidKey(''), isFalse);
        expect(StorageUtils.isValidKey('.hidden'), isFalse);
        expect(StorageUtils.isValidKey('key with spaces'), isFalse);
      });

      test('should sanitize keys', () {
        expect(StorageUtils.sanitizeKey('key with spaces'),
            equals('key_with_spaces'));
        expect(StorageUtils.sanitizeKey('.hidden'), equals('hidden'));
        expect(StorageUtils.sanitizeKey(''), equals('default_key'));
      });
    });

    group('File Size Formatting', () {
      test('should format bytes correctly', () {
        expect(StorageUtils.formatFileSize(0), equals('0 B'));
        expect(StorageUtils.formatFileSize(512), equals('512 B'));
        expect(StorageUtils.formatFileSize(1024), equals('1.0 KB'));
        expect(StorageUtils.formatFileSize(1536), equals('1.5 KB'));
        expect(StorageUtils.formatFileSize(1048576), equals('1.0 MB'));
      });

      test('should parse file sizes correctly', () {
        expect(StorageUtils.parseFileSize('512 B'), equals(512));
        expect(StorageUtils.parseFileSize('1.5 KB'), equals(1536));
        expect(StorageUtils.parseFileSize('2 MB'), equals(2097152));
      });
    });
  });
}
