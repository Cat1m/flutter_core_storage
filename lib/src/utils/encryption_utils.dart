import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

/// Utility functions for encryption and decryption operations
class EncryptionUtils {
  // Private constructor to prevent instantiation
  EncryptionUtils._();

  // Constants for encryption
  static const int _keySize = 32; // 256 bits
  static const int _ivSize = 16; // 128 bits
  static const int _saltSize = 16; // 128 bits
  static const int _iterations = 10000; // PBKDF2 iterations

  // ============================================================================
  // KEY GENERATION
  // ============================================================================

  /// Generate a cryptographically secure random key
  static String generateSecureKey([int length = _keySize]) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Encode(bytes);
  }

  /// Generate a random salt
  static String generateSalt([int length = _saltSize]) {
    return generateSecureKey(length);
  }

  /// Generate a random IV (Initialization Vector)
  static Uint8List generateIV([int length = _ivSize]) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Derive a key from password using PBKDF2
  static String deriveKeyFromPassword(String password, String salt,
      {int iterations = _iterations}) {
    final saltBytes = base64Decode(salt);
    final passwordBytes = utf8.encode(password);

    // Simple PBKDF2 implementation using HMAC-SHA256
    Uint8List derivedKey = Uint8List(_keySize);

    for (int i = 1; i <= (_keySize / 32).ceil(); i++) {
      final block = _pbkdf2Block(passwordBytes, saltBytes, iterations, i);
      final startIndex = (i - 1) * 32;
      final endIndex =
          (startIndex + 32 > _keySize) ? _keySize : startIndex + 32;
      derivedKey.setRange(startIndex, endIndex, block);
    }

    return base64Encode(derivedKey);
  }

  /// PBKDF2 block function
  static Uint8List _pbkdf2Block(
      List<int> password, List<int> salt, int iterations, int blockIndex) {
    // Convert block index to 4-byte big-endian
    final blockBytes = Uint8List(4);
    blockBytes[0] = (blockIndex >> 24) & 0xFF;
    blockBytes[1] = (blockIndex >> 16) & 0xFF;
    blockBytes[2] = (blockIndex >> 8) & 0xFF;
    blockBytes[3] = blockIndex & 0xFF;

    // First iteration: HMAC(password, salt + block_index)
    var hmac = Hmac(sha256, password);
    var u = Uint8List.fromList(hmac.convert([...salt, ...blockBytes]).bytes);
    var result = Uint8List.fromList(u);

    // Subsequent iterations
    for (int i = 1; i < iterations; i++) {
      hmac = Hmac(sha256, password);
      u = Uint8List.fromList(hmac.convert(u).bytes);

      // XOR with result
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  // ============================================================================
  // SIMPLE ENCRYPTION (XOR-based - for basic obfuscation)
  // ============================================================================

  /// Simple XOR-based encryption for basic obfuscation
  /// Note: This is NOT cryptographically secure and should only be used for basic obfuscation
  static String _xorEncrypt(String data, String key) {
    final dataBytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);
    final result = <int>[];

    for (int i = 0; i < dataBytes.length; i++) {
      result.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64Encode(result);
  }

  /// Simple XOR-based decryption
  static String _xorDecrypt(String encryptedData, String key) {
    final dataBytes = base64Decode(encryptedData);
    final keyBytes = utf8.encode(key);
    final result = <int>[];

    for (int i = 0; i < dataBytes.length; i++) {
      result.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return utf8.decode(result);
  }

  // ============================================================================
  // STRING ENCRYPTION/DECRYPTION
  // ============================================================================

  /// Encrypt a string using the provided key
  /// Uses simple XOR encryption for Flutter compatibility
  static String encryptString(String data, String encryptionKey) {
    try {
      // Generate IV and prepend it to the encrypted data
      final iv = generateIV(8); // Smaller IV for XOR
      final ivString = base64Encode(iv);

      // Create a derived key from the provided key and IV
      final derivedKey = _deriveSimpleKey(encryptionKey, ivString);

      // Encrypt the data
      final encrypted = _xorEncrypt(data, derivedKey);

      // Combine IV and encrypted data
      final result = {
        'iv': ivString,
        'data': encrypted,
      };

      return base64Encode(utf8.encode(jsonEncode(result)));
    } catch (e) {
      throw Exception('Failed to encrypt string: $e');
    }
  }

  /// Decrypt a string using the provided key
  static String decryptString(String encryptedData, String encryptionKey) {
    try {
      // Decode the base64 wrapper
      final decodedData = utf8.decode(base64Decode(encryptedData));
      final dataMap = jsonDecode(decodedData) as Map<String, dynamic>;

      final iv = dataMap['iv'] as String;
      final encrypted = dataMap['data'] as String;

      // Create the same derived key
      final derivedKey = _deriveSimpleKey(encryptionKey, iv);

      // Decrypt the data
      return _xorDecrypt(encrypted, derivedKey);
    } catch (e) {
      throw Exception('Failed to decrypt string: $e');
    }
  }

  /// Simple key derivation for XOR encryption
  static String _deriveSimpleKey(String key, String iv) {
    final combined = key + iv;
    final hash = sha256.convert(utf8.encode(combined));
    return base64Encode(hash.bytes);
  }

  // ============================================================================
  // BYTES ENCRYPTION/DECRYPTION
  // ============================================================================

  /// Encrypt bytes using the provided key
  static List<int> encryptBytes(List<int> data, String encryptionKey) {
    try {
      // Convert bytes to base64 string and encrypt
      final dataString = base64Encode(data);
      final encryptedString = encryptString(dataString, encryptionKey);
      return utf8.encode(encryptedString);
    } catch (e) {
      throw Exception('Failed to encrypt bytes: $e');
    }
  }

  /// Decrypt bytes using the provided key
  static List<int> decryptBytes(List<int> encryptedData, String encryptionKey) {
    try {
      // Convert encrypted bytes to string and decrypt
      final encryptedString = utf8.decode(encryptedData);
      final decryptedString = decryptString(encryptedString, encryptionKey);
      return base64Decode(decryptedString);
    } catch (e) {
      throw Exception('Failed to decrypt bytes: $e');
    }
  }

  // ============================================================================
  // JSON ENCRYPTION/DECRYPTION
  // ============================================================================

  /// Encrypt a JSON object to an encrypted string
  static String encryptJson(Map<String, dynamic> data, String encryptionKey) {
    try {
      final jsonString = jsonEncode(data);
      return encryptString(jsonString, encryptionKey);
    } catch (e) {
      throw Exception('Failed to encrypt JSON: $e');
    }
  }

  /// Decrypt an encrypted string to a JSON object
  static Map<String, dynamic> decryptToJson(
      String encryptedData, String encryptionKey) {
    try {
      final decryptedString = decryptString(encryptedData, encryptionKey);
      final decoded = jsonDecode(decryptedString);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        throw Exception('Decrypted data is not a valid JSON object');
      }
    } catch (e) {
      throw Exception('Failed to decrypt to JSON: $e');
    }
  }

  // ============================================================================
  // HASH FUNCTIONS
  // ============================================================================

  /// Generate SHA-256 hash of a string
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate SHA-1 hash of a string
  static String sha1Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Generate MD5 hash of a string
  static String md5Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Generate HMAC-SHA256
  static String hmacSha256(String data, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);
    return digest.toString();
  }

  // ============================================================================
  // PASSWORD UTILITIES
  // ============================================================================

  /// Generate a secure password
  static String generateSecurePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    String charset = '';

    if (includeLowercase) charset += 'abcdefghijklmnopqrstuvwxyz';
    if (includeUppercase) charset += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (includeNumbers) charset += '0123456789';
    if (includeSymbols) charset += '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    if (charset.isEmpty) {
      throw ArgumentError('At least one character type must be included');
    }

    final random = Random.secure();
    final password = List.generate(
      length,
      (index) => charset[random.nextInt(charset.length)],
    ).join();

    return password;
  }

  /// Hash a password for storage (using SHA-256 with salt)
  static String hashPassword(String password, String salt) {
    final combined = password + salt;
    return sha256Hash(combined);
  }

  /// Verify a password against its hash
  static bool verifyPassword(String password, String salt, String hash) {
    final computedHash = hashPassword(password, salt);
    return computedHash == hash;
  }

  // ============================================================================
  // SECURE COMPARISON
  // ============================================================================

  /// Constant-time string comparison to prevent timing attacks
  static bool secureCompare(String a, String b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }

  // ============================================================================
  // ENCODING UTILITIES
  // ============================================================================

  /// Encode bytes to hexadecimal string
  static String bytesToHex(List<int> bytes) {
    return hex.encode(bytes);
  }

  /// Decode hexadecimal string to bytes
  static List<int> hexToBytes(String hexString) {
    return hex.decode(hexString);
  }

  /// URL-safe base64 encoding
  static String base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes);
  }

  /// URL-safe base64 decoding
  static List<int> base64UrlDecode(String encoded) {
    return base64Url.decode(encoded);
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Check if a string is a valid base64
  static bool isValidBase64(String input) {
    try {
      base64Decode(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if a string is a valid hexadecimal
  static bool isValidHex(String input) {
    try {
      hex.decode(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate encryption key strength
  static bool isStrongKey(String key) {
    // Key should be at least 16 characters (128 bits when base64 decoded)
    if (key.length < 16) return false;

    // Check if it's base64 encoded and has sufficient entropy
    if (isValidBase64(key)) {
      final decoded = base64Decode(key);
      return decoded.length >= 16; // At least 128 bits
    }

    // For plain text keys, check length and character variety
    if (key.length < 32) return false; // At least 32 characters for plain text

    final hasLower = key.contains(RegExp(r'[a-z]'));
    final hasUpper = key.contains(RegExp(r'[A-Z]'));
    final hasDigit = key.contains(RegExp(r'[0-9]'));
    final hasSpecial = key.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int varietyCount = 0;
    if (hasLower) varietyCount++;
    if (hasUpper) varietyCount++;
    if (hasDigit) varietyCount++;
    if (hasSpecial) varietyCount++;

    return varietyCount >= 3; // At least 3 types of characters
  }

  // ============================================================================
  // UTILITIES FOR TESTING
  // ============================================================================

  /// Generate test data for encryption testing
  static Map<String, dynamic> generateTestData() {
    return {
      'key': generateSecureKey(),
      'salt': generateSalt(),
      'password': generateSecurePassword(),
      'data':
          'This is test data for encryption: ${DateTime.now().toIso8601String()}',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Benchmark encryption performance
  static Map<String, dynamic> benchmarkEncryption(String data, String key,
      {int iterations = 1000}) {
    final stopwatch = Stopwatch();

    // Benchmark encryption
    stopwatch.start();
    for (int i = 0; i < iterations; i++) {
      encryptString(data, key);
    }
    stopwatch.stop();
    final encryptionTime = stopwatch.elapsedMicroseconds;

    // Benchmark decryption
    final encrypted = encryptString(data, key);
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < iterations; i++) {
      decryptString(encrypted, key);
    }
    stopwatch.stop();
    final decryptionTime = stopwatch.elapsedMicroseconds;

    return {
      'iterations': iterations,
      'dataSize': data.length,
      'encryptionTimeUs': encryptionTime,
      'decryptionTimeUs': decryptionTime,
      'encryptionOpsPerSec': (iterations * 1000000) / encryptionTime,
      'decryptionOpsPerSec': (iterations * 1000000) / decryptionTime,
    };
  }
}
