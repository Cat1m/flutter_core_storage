// test/utils/encryption_utils_test.dart (abbreviated)
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EncryptionUtils', () {
    group('Key Generation', () {
      test('should generate secure keys of correct length', () {
        final key1 = EncryptionUtils.generateSecureKey();
        final key2 = EncryptionUtils.generateSecureKey(16);

        expect(key1, isA<String>());
        expect(key2, isA<String>());
        expect(key1, isNot(equals(key2))); // Should be random
      });

      test('should generate salt', () {
        final salt = EncryptionUtils.generateSalt();
        expect(salt, isA<String>());
        expect(salt.isNotEmpty, isTrue);
      });
    });

    group('String Encryption', () {
      test('should encrypt and decrypt strings', () {
        const plaintext = 'Hello, World!';
        const key = 'test-encryption-key';

        final encrypted = EncryptionUtils.encryptString(plaintext, key);
        final decrypted = EncryptionUtils.decryptString(encrypted, key);

        expect(encrypted, isNot(equals(plaintext)));
        expect(decrypted, equals(plaintext));
      });

      test('should produce different encrypted values for same input', () {
        const plaintext = 'Hello, World!';
        const key = 'test-encryption-key';

        final encrypted1 = EncryptionUtils.encryptString(plaintext, key);
        final encrypted2 = EncryptionUtils.encryptString(plaintext, key);

        expect(encrypted1, isNot(equals(encrypted2))); // Should use random IV
      });
    });

    group('Hash Functions', () {
      test('should generate consistent hashes', () {
        const input = 'test input';

        final hash1 = EncryptionUtils.sha256Hash(input);
        final hash2 = EncryptionUtils.sha256Hash(input);

        expect(hash1, equals(hash2));
        expect(hash1, isA<String>());
        expect(hash1.length, equals(64)); // SHA-256 hex length
      });
    });
  });
}
