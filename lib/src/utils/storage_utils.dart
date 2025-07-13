import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;

/// Utility functions for storage operations
class StorageUtils {
  // Private constructor to prevent instantiation
  StorageUtils._();

  // ============================================================================
  // KEY VALIDATION AND SANITIZATION
  // ============================================================================

  /// Check if a key is valid for storage
  /// Keys should not be empty, contain only valid characters, and have reasonable length
  static bool isValidKey(String key) {
    if (key.isEmpty) return false;
    if (key.length > 255) return false; // Reasonable key length limit

    // Check for invalid characters that might cause issues
    final invalidChars = RegExp(r'[^\w\-\.\:\/]');
    if (invalidChars.hasMatch(key)) return false;

    // Don't allow keys that start with dots (hidden files)
    if (key.startsWith('.')) return false;

    return true;
  }

  /// Sanitize a key by removing/replacing invalid characters
  static String sanitizeKey(String key) {
    if (key.isEmpty) return 'default_key';

    // Replace invalid characters with underscores
    String sanitized = key.replaceAll(RegExp(r'[^\w\-\.\:\/]'), '_');

    // Remove leading dots
    sanitized = sanitized.replaceAll(RegExp(r'^\.+'), '');

    // Ensure it's not empty after sanitization
    if (sanitized.isEmpty) return 'sanitized_key';

    // Trim to reasonable length
    if (sanitized.length > 255) {
      sanitized = sanitized.substring(0, 255);
    }

    return sanitized;
  }

  /// Generate a random storage key
  static String generateRandomKey([int length = 16]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // ============================================================================
  // FILE AND DIRECTORY OPERATIONS
  // ============================================================================

  /// Ensure a directory exists, creating it if necessary
  static Future<void> ensureDirectoryExists(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// Get the total size of a directory and its contents
  static Future<int> getDirectorySize(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) return 0;

    int totalSize = 0;
    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          totalSize += stat.size;
        } catch (e) {
          // Ignore files we can't access
        }
      }
    }
    return totalSize;
  }

  /// Clean up old files in a directory based on age
  static Future<int> cleanupOldFiles(String dirPath, Duration maxAge) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) return 0;

    final cutoffTime = DateTime.now().subtract(maxAge);
    int deletedCount = 0;

    await for (final entity in directory.list()) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            await entity.delete();
            deletedCount++;
          }
        } catch (e) {
          // Ignore files we can't access or delete
        }
      }
    }

    return deletedCount;
  }

  /// Get file extension from filename
  static String getFileExtension(String fileName) {
    return path.extension(fileName).toLowerCase();
  }

  /// Check if file is of specified type
  static bool isFileType(String fileName, List<String> extensions) {
    final ext = getFileExtension(fileName);
    return extensions.any((e) => e.toLowerCase() == ext);
  }

  /// Get filename without extension
  static String getFileNameWithoutExtension(String fileName) {
    return path.basenameWithoutExtension(fileName);
  }

  // ============================================================================
  // SIZE FORMATTING
  // ============================================================================

  /// Format file size in bytes to human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    if (i == 0) {
      return '${size.round()} ${suffixes[i]}';
    } else {
      return '${size.toStringAsFixed(1)} ${suffixes[i]}';
    }
  }

  /// Parse human readable file size to bytes
  static int parseFileSize(String sizeStr) {
    final regex =
        RegExp(r'^(\d+(?:\.\d+)?)\s*([KMGT]?B?)$', caseSensitive: false);
    final match = regex.firstMatch(sizeStr.trim());

    if (match == null) return 0;

    final number = double.parse(match.group(1)!);
    final unit = match.group(2)?.toUpperCase() ?? 'B';

    switch (unit) {
      case 'B':
        return number.round();
      case 'KB':
        return (number * 1024).round();
      case 'MB':
        return (number * 1024 * 1024).round();
      case 'GB':
        return (number * 1024 * 1024 * 1024).round();
      case 'TB':
        return (number * 1024 * 1024 * 1024 * 1024).round();
      default:
        return number.round();
    }
  }

  // ============================================================================
  // TIME UTILITIES
  // ============================================================================

  /// Format duration to human readable string
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Check if a timestamp is expired based on TTL
  static bool isExpired(DateTime createdAt, Duration ttl) {
    final expiryTime = createdAt.add(ttl);
    return DateTime.now().isAfter(expiryTime);
  }

  /// Get remaining time until expiry
  static Duration? getRemainingTTL(DateTime createdAt, Duration ttl) {
    final expiryTime = createdAt.add(ttl);
    final now = DateTime.now();

    if (now.isAfter(expiryTime)) {
      return null; // Already expired
    }

    return expiryTime.difference(now);
  }

  // ============================================================================
  // BATCH OPERATIONS
  // ============================================================================

  /// Split a large list into smaller batches
  static List<List<T>> batchList<T>(List<T> list, int batchSize) {
    final batches = <List<T>>[];
    for (int i = 0; i < list.length; i += batchSize) {
      final end = (i + batchSize < list.length) ? i + batchSize : list.length;
      batches.add(list.sublist(i, end));
    }
    return batches;
  }

  /// Process items in batches with a delay between batches
  static Future<List<R>> processBatches<T, R>(
    List<T> items,
    Future<R> Function(T) processor, {
    int batchSize = 10,
    Duration? delay,
  }) async {
    final results = <R>[];
    final batches = batchList(items, batchSize);

    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];
      final batchResults = await Future.wait(
        batch.map((item) => processor(item)),
      );
      results.addAll(batchResults);

      // Add delay between batches if specified
      if (delay != null && i < batches.length - 1) {
        await Future.delayed(delay);
      }
    }

    return results;
  }

  // ============================================================================
  // VALIDATION UTILITIES
  // ============================================================================

  /// Validate file path
  static bool isValidFilePath(String filePath) {
    if (filePath.isEmpty) return false;

    // Check for invalid characters
    final invalidChars = Platform.isWindows
        ? RegExp(r'[<>:"|?*]')
        : RegExp(
            r'[\x00]'); // Only null character is invalid on Unix-like systems

    if (invalidChars.hasMatch(filePath)) return false;

    // Check for reserved names on Windows
    if (Platform.isWindows) {
      final reservedNames = [
        'CON',
        'PRN',
        'AUX',
        'NUL',
        'COM1',
        'COM2',
        'COM3',
        'COM4',
        'COM5',
        'COM6',
        'COM7',
        'COM8',
        'COM9',
        'LPT1',
        'LPT2',
        'LPT3',
        'LPT4',
        'LPT5',
        'LPT6',
        'LPT7',
        'LPT8',
        'LPT9'
      ];
      final fileName = path.basenameWithoutExtension(filePath).toUpperCase();
      if (reservedNames.contains(fileName)) return false;
    }

    return true;
  }

  /// Validate JSON string
  static bool isValidJson(String jsonString) {
    try {
      // This will be implemented in serialization_utils
      return jsonString.trim().startsWith('{') ||
          jsonString.trim().startsWith('[');
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // HASH UTILITIES
  // ============================================================================

  /// Generate a simple hash for a string (not cryptographically secure)
  static int simpleHash(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xffffffff;
    }
    return hash;
  }

  /// Generate a hash-based key from input
  static String generateHashKey(String input, [int maxLength = 32]) {
    final hash = simpleHash(input);
    final hashStr = hash.abs().toString();

    if (hashStr.length <= maxLength) {
      return hashStr;
    } else {
      return hashStr.substring(0, maxLength);
    }
  }

  // ============================================================================
  // RETRY UTILITIES
  // ============================================================================

  /// Retry an operation with exponential backoff
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        // Check if we should retry this error
        if (retryIf != null && !retryIf(error)) {
          rethrow;
        }

        // If this was the last attempt, rethrow the error
        if (attempt >= maxRetries) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);
        delay = Duration(
            milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
      }
    }

    throw StateError(
        'Retry operation failed to complete'); // Should never reach here
  }

  // ============================================================================
  // PLATFORM UTILITIES
  // ============================================================================

  /// Get platform-specific preferences for storage
  static Map<String, dynamic> getPlatformStorageConfig() {
    return {
      'platform': Platform.operatingSystem,
      'isAndroid': Platform.isAndroid,
      'isIOS': Platform.isIOS,
      'isWindows': Platform.isWindows,
      'isMacOS': Platform.isMacOS,
      'isLinux': Platform.isLinux,
      'supportsCaseSensitiveFilenames':
          !Platform.isWindows && !Platform.isMacOS,
      'pathSeparator': Platform.pathSeparator,
      'maxPathLength': Platform.isWindows ? 260 : 4096,
    };
  }

  /// Get safe filename for current platform
  static String getSafeFileName(String fileName) {
    String safe = fileName;

    if (Platform.isWindows) {
      // Replace invalid characters on Windows
      safe = safe.replaceAll(RegExp(r'[<>:"|?*]'), '_');

      // Remove trailing dots and spaces
      safe = safe.replaceAll(RegExp(r'[. ]+$'), '');
    } else {
      // Replace null character on Unix-like systems
      safe = safe.replaceAll('\x00', '_');
    }

    // Ensure it's not empty
    if (safe.isEmpty) {
      safe = 'file';
    }

    return safe;
  }
}
