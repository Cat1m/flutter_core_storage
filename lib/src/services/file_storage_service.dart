import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/storage_result.dart';
import '../exceptions/storage_exceptions.dart';
import '../utils/storage_utils.dart';
import '../utils/encryption_utils.dart';
import '../utils/serialization_utils.dart';

/// Service for file storage operations
class FileStorageService {
  static FileStorageService? _instance;
  static FileStorageService get instance => _instance!;

  static bool _isInitialized = false;

  // Directory paths
  Directory? _documentsDirectory;
  Directory? _cacheDirectory;
  Directory? _tempDirectory;
  Directory? _appSupportDirectory;

  // Private constructor
  FileStorageService._();

  /// Initialize the file storage service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _instance = FileStorageService._();

      // Initialize directories
      _instance!._documentsDirectory = await getApplicationDocumentsDirectory();
      _instance!._cacheDirectory = await getTemporaryDirectory();
      _instance!._tempDirectory = await getTemporaryDirectory();
      _instance!._appSupportDirectory = await getApplicationSupportDirectory();

      // Create app-specific subdirectories
      await _instance!._ensureAppDirectoriesExist();

      _isInitialized = true;
      debugPrint('✅ FileStorageService initialized successfully');
    } catch (e) {
      debugPrint('❌ FileStorageService initialization failed: $e');
      throw StorageInitializationException(
          'Failed to initialize file storage: $e');
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Ensure app-specific directories exist
  Future<void> _ensureAppDirectoriesExist() async {
    final appDirs = [
      'data',
      'cache',
      'temp',
      'logs',
      'exports',
      'backups',
    ];

    for (final dirName in appDirs) {
      await StorageUtils.ensureDirectoryExists(
        path.join(_documentsDirectory!.path, dirName),
      );
    }
  }

  /// Get app documents directory path
  String get documentsPath => _documentsDirectory?.path ?? '';

  /// Get app cache directory path
  String get cachePath => _cacheDirectory?.path ?? '';

  /// Get app temp directory path
  String get tempPath => _tempDirectory?.path ?? '';

  /// Get app support directory path
  String get supportPath => _appSupportDirectory?.path ?? '';

  // ============================================================================
  // FILE OPERATIONS - STRING CONTENT
  // ============================================================================

  /// Write string content to file
  Future<StorageResult<bool>> writeFile(String fileName, String content,
      {String? subDir}) async {
    try {
      final filePath = _buildFilePath(fileName, subDir);
      final file = File(filePath);

      // Ensure directory exists
      await StorageUtils.ensureDirectoryExists(file.parent.path);

      await file.writeAsString(content);

      debugPrint('📝 Wrote file: $fileName (${content.length} chars)');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to write file: $fileName - $e');
      return StorageResult.failure('Failed to write file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Read string content from file
  Future<StorageResult<String?>> readFile(String fileName,
      {String? subDir}) async {
    try {
      final filePath = _buildFilePath(fileName, subDir);
      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('📖 File not found: $fileName');
        return StorageResult.success(null);
      }

      final content = await file.readAsString();

      debugPrint('📖 Read file: $fileName (${content.length} chars)');
      return StorageResult.success(content);
    } catch (e) {
      debugPrint('❌ Failed to read file: $fileName - $e');
      return StorageResult.failure('Failed to read file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Append string content to file
  Future<StorageResult<bool>> appendToFile(String fileName, String content,
      {String? subDir}) async {
    try {
      final filePath = _buildFilePath(fileName, subDir);
      final file = File(filePath);

      // Ensure directory exists
      await StorageUtils.ensureDirectoryExists(file.parent.path);

      await file.writeAsString(content, mode: FileMode.append);

      debugPrint('📝 Appended to file: $fileName (${content.length} chars)');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to append to file: $fileName - $e');
      return StorageResult.failure('Failed to append to file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // FILE OPERATIONS - BYTE CONTENT
  // ============================================================================

  /// Write bytes to file
  Future<StorageResult<bool>> writeBytes(String fileName, List<int> bytes,
      {String? subDir}) async {
    try {
      final filePath = _buildFilePath(fileName, subDir);
      final file = File(filePath);

      // Ensure directory exists
      await StorageUtils.ensureDirectoryExists(file.parent.path);

      await file.writeAsBytes(bytes);

      debugPrint('📝 Wrote bytes to file: $fileName (${bytes.length} bytes)');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to write bytes to file: $fileName - $e');
      return StorageResult.failure('Failed to write bytes to file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Read bytes from file
  Future<StorageResult<Uint8List?>> readBytes(String fileName,
      {String? subDir}) async {
    try {
      final filePath = _buildFilePath(fileName, subDir);
      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('📖 File not found: $fileName');
        return StorageResult.success(null);
      }

      final bytes = await file.readAsBytes();

      debugPrint('📖 Read bytes from file: $fileName (${bytes.length} bytes)');
      return StorageResult.success(bytes);
    } catch (e) {
      debugPrint('❌ Failed to read bytes from file: $fileName - $e');
      return StorageResult.failure('Failed to read bytes from file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // JSON OPERATIONS
  // ============================================================================

  /// Write JSON object to file
  Future<StorageResult<bool>> writeJson(String fileName, dynamic object,
      {String? subDir, bool pretty = false}) async {
    try {
      final jsonString = pretty
          ? SerializationUtils.prettyPrintJson(object)
          : SerializationUtils.toJsonString(object);

      return await writeFile(fileName, jsonString, subDir: subDir);
    } catch (e) {
      debugPrint('❌ Failed to write JSON to file: $fileName - $e');
      return StorageResult.failure('Failed to write JSON to file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Read JSON object from file
  Future<StorageResult<T?>> readJson<T>(String fileName,
      {String? subDir}) async {
    try {
      final contentResult = await readFile(fileName, subDir: subDir);
      if (!contentResult.success || contentResult.data == null) {
        return StorageResult.success(null);
      }

      final object = SerializationUtils.fromJsonString<T>(contentResult.data!);
      return StorageResult.success(object);
    } catch (e) {
      debugPrint('❌ Failed to read JSON from file: $fileName - $e');
      return StorageResult.failure('Failed to read JSON from file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // ENCRYPTED FILE OPERATIONS
  // ============================================================================

  /// Write encrypted file
  Future<StorageResult<bool>> writeEncryptedFile(
      String fileName, String content, String encryptionKey,
      {String? subDir}) async {
    try {
      final encryptedContent =
          EncryptionUtils.encryptString(content, encryptionKey);
      return await writeFile(fileName, encryptedContent, subDir: subDir);
    } catch (e) {
      debugPrint('❌ Failed to write encrypted file: $fileName - $e');
      return StorageResult.failure('Failed to write encrypted file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Read encrypted file
  Future<StorageResult<String?>> readEncryptedFile(
      String fileName, String encryptionKey,
      {String? subDir}) async {
    try {
      final contentResult = await readFile(fileName, subDir: subDir);
      if (!contentResult.success || contentResult.data == null) {
        return StorageResult.success(null);
      }

      final decryptedContent =
          EncryptionUtils.decryptString(contentResult.data!, encryptionKey);
      return StorageResult.success(decryptedContent);
    } catch (e) {
      debugPrint('❌ Failed to read encrypted file: $fileName - $e');
      return StorageResult.failure('Failed to read encrypted file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Write encrypted bytes to file
  Future<StorageResult<bool>> writeEncryptedBytes(
      String fileName, List<int> bytes, String encryptionKey,
      {String? subDir}) async {
    try {
      final encryptedBytes = EncryptionUtils.encryptBytes(bytes, encryptionKey);
      return await writeBytes(fileName, encryptedBytes, subDir: subDir);
    } catch (e) {
      debugPrint('❌ Failed to write encrypted bytes: $fileName - $e');
      return StorageResult.failure('Failed to write encrypted bytes: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Read encrypted bytes from file
  Future<StorageResult<List<int>?>> readEncryptedBytes(
      String fileName, String encryptionKey,
      {String? subDir}) async {
    try {
      final bytesResult = await readBytes(fileName, subDir: subDir);
      if (!bytesResult.success || bytesResult.data == null) {
        return StorageResult.success(null);
      }

      final decryptedBytes =
          EncryptionUtils.decryptBytes(bytesResult.data!, encryptionKey);
      return StorageResult.success(decryptedBytes);
    } catch (e) {
      debugPrint('❌ Failed to read encrypted bytes: $fileName - $e');
      return StorageResult.failure('Failed to read encrypted bytes: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // FILE MANAGEMENT
  // ============================================================================

  /// Check if file exists
  Future<StorageResult<bool>> fileExists(String fileName,
      {String? subDir}) async {
    try {
      final filePath = _buildFilePath(fileName, subDir);
      final exists = await File(filePath).exists();

      debugPrint('🔍 File exists: $fileName = $exists');
      return StorageResult.success(exists);
    } catch (e) {
      debugPrint('❌ Failed to check file existence: $fileName - $e');
      return StorageResult.failure('Failed to check file existence: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get file size
  Future<StorageResult<int>> getFileSize(String fileName,
      {String? subDir}) async {
    try {
      final filePath = _buildFilePath(fileName, subDir);
      final file = File(filePath);

      if (!await file.exists()) {
        return StorageResult.success(0);
      }

      final size = await file.length();

      debugPrint(
          '📏 File size: $fileName = ${StorageUtils.formatFileSize(size)}');
      return StorageResult.success(size);
    } catch (e) {
      debugPrint('❌ Failed to get file size: $fileName - $e');
      return StorageResult.failure('Failed to get file size: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Delete file
  Future<StorageResult<bool>> deleteFile(String fileName,
      {String? subDir}) async {
    try {
      final filePath = _buildFilePath(fileName, subDir);
      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('🗑️ File not found for deletion: $fileName');
        return StorageResult.success(
            true); // Consider non-existent file as "deleted"
      }

      await file.delete();

      debugPrint('🗑️ Deleted file: $fileName');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to delete file: $fileName - $e');
      return StorageResult.failure('Failed to delete file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Copy file
  Future<StorageResult<bool>> copyFile(
      String sourceFileName, String destFileName,
      {String? sourceSubDir, String? destSubDir}) async {
    try {
      final sourcePath = _buildFilePath(sourceFileName, sourceSubDir);
      final destPath = _buildFilePath(destFileName, destSubDir);

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return StorageResult.failure(
            'Source file does not exist: $sourceFileName');
      }

      // Ensure destination directory exists
      await StorageUtils.ensureDirectoryExists(File(destPath).parent.path);

      await sourceFile.copy(destPath);

      debugPrint('📋 Copied file: $sourceFileName -> $destFileName');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint(
          '❌ Failed to copy file: $sourceFileName -> $destFileName - $e');
      return StorageResult.failure('Failed to copy file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Move/rename file
  Future<StorageResult<bool>> moveFile(
      String sourceFileName, String destFileName,
      {String? sourceSubDir, String? destSubDir}) async {
    try {
      final sourcePath = _buildFilePath(sourceFileName, sourceSubDir);
      final destPath = _buildFilePath(destFileName, destSubDir);

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return StorageResult.failure(
            'Source file does not exist: $sourceFileName');
      }

      // Ensure destination directory exists
      await StorageUtils.ensureDirectoryExists(File(destPath).parent.path);

      await sourceFile.rename(destPath);

      debugPrint('🚚 Moved file: $sourceFileName -> $destFileName');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint(
          '❌ Failed to move file: $sourceFileName -> $destFileName - $e');
      return StorageResult.failure('Failed to move file: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get file modification time
  Future<StorageResult<DateTime?>> getFileModificationTime(String fileName,
      {String? subDir}) async {
    try {
      final filePath = _buildFilePath(fileName, subDir);
      final file = File(filePath);

      if (!await file.exists()) {
        return StorageResult.success(null);
      }

      final stat = await file.stat();

      debugPrint('🕒 File modification time: $fileName = ${stat.modified}');
      return StorageResult.success(stat.modified);
    } catch (e) {
      debugPrint('❌ Failed to get file modification time: $fileName - $e');
      return StorageResult.failure('Failed to get file modification time: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // DIRECTORY OPERATIONS
  // ============================================================================

  /// List files in directory
  Future<StorageResult<List<String>>> listFiles(
      {String? subDir, String? extension}) async {
    try {
      final dirPath = subDir != null
          ? path.join(_documentsDirectory!.path, subDir)
          : _documentsDirectory!.path;

      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        return StorageResult.success(<String>[]);
      }

      final entities = await directory.list().toList();
      final files = entities
          .whereType<File>()
          .map((file) => path.basename(file.path))
          .where((fileName) =>
              extension == null || fileName.endsWith('.$extension'))
          .toList();

      debugPrint('📂 Listed ${files.length} files in ${subDir ?? 'root'}');
      return StorageResult.success(files);
    } catch (e) {
      debugPrint('❌ Failed to list files: $e');
      return StorageResult.failure('Failed to list files: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Create directory
  Future<StorageResult<bool>> createDirectory(String dirName) async {
    try {
      final dirPath = path.join(_documentsDirectory!.path, dirName);
      await StorageUtils.ensureDirectoryExists(dirPath);

      debugPrint('📁 Created directory: $dirName');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to create directory: $dirName - $e');
      return StorageResult.failure('Failed to create directory: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Delete directory
  Future<StorageResult<bool>> deleteDirectory(String dirName,
      {bool recursive = false}) async {
    try {
      final dirPath = path.join(_documentsDirectory!.path, dirName);
      final directory = Directory(dirPath);

      if (!await directory.exists()) {
        debugPrint('📁 Directory not found for deletion: $dirName');
        return StorageResult.success(true);
      }

      await directory.delete(recursive: recursive);

      debugPrint('🗑️ Deleted directory: $dirName');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to delete directory: $dirName - $e');
      return StorageResult.failure('Failed to delete directory: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get directory size
  Future<StorageResult<int>> getDirectorySize({String? subDir}) async {
    try {
      final dirPath = subDir != null
          ? path.join(_documentsDirectory!.path, subDir)
          : _documentsDirectory!.path;

      final size = await StorageUtils.getDirectorySize(dirPath);

      debugPrint(
          '📊 Directory size: ${subDir ?? 'root'} = ${StorageUtils.formatFileSize(size)}');
      return StorageResult.success(size);
    } catch (e) {
      debugPrint('❌ Failed to get directory size: $e');
      return StorageResult.failure('Failed to get directory size: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Clean up old files
  Future<StorageResult<int>> cleanupOldFiles(Duration maxAge,
      {String? subDir}) async {
    try {
      final dirPath = subDir != null
          ? path.join(_documentsDirectory!.path, subDir)
          : _documentsDirectory!.path;

      final deletedCount = await StorageUtils.cleanupOldFiles(dirPath, maxAge);

      debugPrint('🧹 Cleaned up $deletedCount old files');
      return StorageResult.success(deletedCount);
    } catch (e) {
      debugPrint('❌ Failed to cleanup old files: $e');
      return StorageResult.failure('Failed to cleanup old files: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // CACHE OPERATIONS
  // ============================================================================

  /// Write to cache
  Future<StorageResult<bool>> writeCache(
      String fileName, String content) async {
    try {
      final filePath = path.join(_cacheDirectory!.path, fileName);
      final file = File(filePath);

      await file.writeAsString(content);

      debugPrint('💾 Wrote to cache: $fileName');
      return StorageResult.success(true);
    } catch (e) {
      debugPrint('❌ Failed to write to cache: $fileName - $e');
      return StorageResult.failure('Failed to write to cache: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Read from cache
  Future<StorageResult<String?>> readCache(String fileName) async {
    try {
      final filePath = path.join(_cacheDirectory!.path, fileName);
      final file = File(filePath);

      if (!await file.exists()) {
        return StorageResult.success(null);
      }

      final content = await file.readAsString();

      debugPrint('💾 Read from cache: $fileName');
      return StorageResult.success(content);
    } catch (e) {
      debugPrint('❌ Failed to read from cache: $fileName - $e');
      return StorageResult.failure('Failed to read from cache: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Clear cache
  Future<StorageResult<int>> clearCache() async {
    try {
      final directory = _cacheDirectory!;
      int deletedCount = 0;

      await for (final entity in directory.list()) {
        if (entity is File) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (e) {
            // Ignore individual file deletion errors
          }
        }
      }

      debugPrint('🧹 Cleared cache: $deletedCount files deleted');
      return StorageResult.success(deletedCount);
    } catch (e) {
      debugPrint('❌ Failed to clear cache: $e');
      return StorageResult.failure('Failed to clear cache: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Build file path
  String _buildFilePath(String fileName, String? subDir) {
    if (subDir != null) {
      return path.join(_documentsDirectory!.path, subDir, fileName);
    }
    return path.join(_documentsDirectory!.path, 'data', fileName);
  }

  /// Get file storage info
  Future<StorageResult<Map<String, dynamic>>> getFileStorageInfo() async {
    try {
      final totalSizeResult = await getDirectorySize();
      final cacheSizeResult = await getDirectorySize(subDir: 'cache');
      final filesResult = await listFiles();

      final info = {
        'isInitialized': _isInitialized,
        'documentsPath': documentsPath,
        'cachePath': cachePath,
        'tempPath': tempPath,
        'totalSize': totalSizeResult.data ?? 0,
        'formattedTotalSize':
            StorageUtils.formatFileSize(totalSizeResult.data ?? 0),
        'cacheSize': cacheSizeResult.data ?? 0,
        'formattedCacheSize':
            StorageUtils.formatFileSize(cacheSizeResult.data ?? 0),
        'fileCount': filesResult.data?.length ?? 0,
      };

      return StorageResult.success(info);
    } catch (e) {
      debugPrint('❌ Failed to get file storage info: $e');
      return StorageResult.failure('Failed to get file storage info: $e',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get absolute file path
  String getAbsoluteFilePath(String fileName, {String? subDir}) {
    return _buildFilePath(fileName, subDir);
  }
}
