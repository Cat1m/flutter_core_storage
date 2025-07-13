import 'dart:convert';
import 'dart:typed_data';

/// Utility functions for serialization and deserialization operations
class SerializationUtils {
  // Private constructor to prevent instantiation
  SerializationUtils._();

  // ============================================================================
  // JSON SERIALIZATION
  // ============================================================================

  /// Convert any object to JSON string
  static String toJsonString(dynamic object) {
    try {
      return jsonEncode(object);
    } catch (e) {
      throw Exception('Failed to serialize object to JSON: $e');
    }
  }

  /// Convert JSON string to typed object
  static T? fromJsonString<T>(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);

      // Handle primitive types
      if (T == String) return decoded as T?;
      if (T == int) return (decoded is num ? decoded.toInt() : decoded) as T?;
      if (T == double)
        return (decoded is num ? decoded.toDouble() : decoded) as T?;
      if (T == bool) return decoded as T?;
      if (T == dynamic) return decoded as T?;

      // Handle collections
      if (T.toString().startsWith('List<')) {
        return (decoded as List<dynamic>).cast<dynamic>() as T?;
      }
      if (T.toString().startsWith('Map<')) {
        return (decoded as Map<String, dynamic>) as T?;
      }

      // For other types, return as-is and let the caller handle casting
      return decoded as T?;
    } catch (e) {
      throw Exception('Failed to deserialize JSON to type $T: $e');
    }
  }

  /// Pretty print JSON with indentation
  static String prettyPrintJson(dynamic object, {int indent = 2}) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(object);
    } catch (e) {
      throw Exception('Failed to pretty print JSON: $e');
    }
  }

  /// Minify JSON (remove whitespace)
  static String minifyJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return jsonEncode(decoded);
    } catch (e) {
      throw Exception('Failed to minify JSON: $e');
    }
  }

  /// Validate JSON string
  static bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get JSON string size in bytes
  static int getJsonSize(dynamic object) {
    try {
      final jsonString = toJsonString(object);
      return utf8.encode(jsonString).length;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================================
  // OBJECT CONVERSION
  // ============================================================================

  /// Convert object to Map
  static Map<String, dynamic> toMap(dynamic object) {
    try {
      if (object is Map<String, dynamic>) {
        return object;
      }

      if (object == null) {
        return <String, dynamic>{};
      }

      // Try to convert via JSON
      final jsonString = toJsonString(object);
      final decoded = jsonDecode(jsonString);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        // Wrap non-map objects
        return {'value': decoded};
      }
    } catch (e) {
      throw Exception('Failed to convert object to Map: $e');
    }
  }

  /// Convert Map to typed object
  static T? fromMap<T>(Map<String, dynamic> map) {
    try {
      // Handle primitive types
      if (T == String) return map['value'] as T?;
      if (T == int) return map['value'] as T?;
      if (T == double) return map['value'] as T?;
      if (T == bool) return map['value'] as T?;
      if (T == dynamic) return map as T?;

      // For complex types, convert via JSON
      final jsonString = toJsonString(map);
      return fromJsonString<T>(jsonString);
    } catch (e) {
      throw Exception('Failed to convert Map to type $T: $e');
    }
  }

  /// Convert object to List
  static List<dynamic> toList(dynamic object) {
    try {
      if (object is List) {
        return object;
      }

      if (object == null) {
        return <dynamic>[];
      }

      // Wrap single objects in a list
      return [object];
    } catch (e) {
      throw Exception('Failed to convert object to List: $e');
    }
  }

  /// Deep copy an object via JSON serialization
  static T? deepCopy<T>(T object) {
    try {
      if (object == null) return null;

      final jsonString = toJsonString(object);
      return fromJsonString<T>(jsonString);
    } catch (e) {
      throw Exception('Failed to deep copy object: $e');
    }
  }

  // ============================================================================
  // SIZE ESTIMATION
  // ============================================================================

  /// Estimate object size in bytes (approximate)
  static int getObjectSize(dynamic object) {
    if (object == null) return 0;

    try {
      // For strings, return UTF-8 byte length
      if (object is String) {
        return utf8.encode(object).length;
      }

      // For numbers, return approximate sizes
      if (object is int) return 8; // 64-bit integer
      if (object is double) return 8; // 64-bit double
      if (object is bool) return 1; // 1 byte

      // For collections, calculate recursively
      if (object is List) {
        int size = 0;
        for (final item in object) {
          size += getObjectSize(item);
        }
        return size;
      }

      if (object is Map) {
        int size = 0;
        object.forEach((key, value) {
          size += getObjectSize(key);
          size += getObjectSize(value);
        });
        return size;
      }

      // For other objects, serialize to JSON and measure
      return getJsonSize(object);
    } catch (e) {
      // Fallback: return length of string representation
      return object.toString().length;
    }
  }

  /// Get object size formatted as human readable string
  static String getFormattedObjectSize(dynamic object) {
    final size = getObjectSize(object);
    return _formatBytes(size);
  }

  /// Format bytes to human readable format
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ============================================================================
  // BINARY SERIALIZATION
  // ============================================================================

  /// Convert object to bytes via JSON
  static Uint8List toBytes(dynamic object) {
    try {
      final jsonString = toJsonString(object);
      return Uint8List.fromList(utf8.encode(jsonString));
    } catch (e) {
      throw Exception('Failed to convert object to bytes: $e');
    }
  }

  /// Convert bytes to object via JSON
  static T? fromBytes<T>(Uint8List bytes) {
    try {
      final jsonString = utf8.decode(bytes);
      return fromJsonString<T>(jsonString);
    } catch (e) {
      throw Exception('Failed to convert bytes to object: $e');
    }
  }

  /// Compress JSON string (simple run-length encoding for repeated characters)
  static String compressJson(String jsonString) {
    if (jsonString.isEmpty) return jsonString;

    final buffer = StringBuffer();
    String currentChar = jsonString[0];
    int count = 1;

    for (int i = 1; i < jsonString.length; i++) {
      if (jsonString[i] == currentChar && count < 99) {
        count++;
      } else {
        if (count > 1) {
          buffer.write('$count$currentChar');
        } else {
          buffer.write(currentChar);
        }
        currentChar = jsonString[i];
        count = 1;
      }
    }

    // Write the last sequence
    if (count > 1) {
      buffer.write('$count$currentChar');
    } else {
      buffer.write(currentChar);
    }

    return buffer.toString();
  }

  /// Decompress JSON string (reverse of simple run-length encoding)
  static String decompressJson(String compressedJson) {
    if (compressedJson.isEmpty) return compressedJson;

    final buffer = StringBuffer();
    final regex = RegExp(r'(\d+)(.)');
    int index = 0;

    while (index < compressedJson.length) {
      final match = regex.matchAsPrefix(compressedJson, index);
      if (match != null) {
        final count = int.parse(match.group(1)!);
        final char = match.group(2)!;
        buffer.write(char * count);
        index = match.end;
      } else {
        buffer.write(compressedJson[index]);
        index++;
      }
    }

    return buffer.toString();
  }

  // ============================================================================
  // TYPE UTILITIES
  // ============================================================================

  /// Get type information about an object
  static Map<String, dynamic> getTypeInfo(dynamic object) {
    return {
      'type': object.runtimeType.toString(),
      'isNull': object == null,
      'isString': object is String,
      'isNumber': object is num,
      'isInt': object is int,
      'isDouble': object is double,
      'isBool': object is bool,
      'isList': object is List,
      'isMap': object is Map,
      'isIterable': object is Iterable,
      'size': getObjectSize(object),
      'formattedSize': getFormattedObjectSize(object),
    };
  }

  /// Check if two objects are equivalent (deep comparison via JSON)
  static bool areEquivalent(dynamic obj1, dynamic obj2) {
    try {
      if (identical(obj1, obj2)) return true;
      if (obj1 == null || obj2 == null) return obj1 == obj2;

      final json1 = toJsonString(obj1);
      final json2 = toJsonString(obj2);
      return json1 == json2;
    } catch (e) {
      // Fallback to direct comparison
      return obj1 == obj2;
    }
  }

  /// Sanitize object for JSON serialization (remove non-serializable fields)
  static Map<String, dynamic> sanitizeForJson(Map<String, dynamic> object) {
    final sanitized = <String, dynamic>{};

    object.forEach((key, value) {
      try {
        // Test if the value can be serialized
        jsonEncode(value);
        sanitized[key] = value;
      } catch (e) {
        // Replace non-serializable values with string representation
        sanitized[key] = value.toString();
      }
    });

    return sanitized;
  }

  // ============================================================================
  // MERGE UTILITIES
  // ============================================================================

  /// Deep merge two Maps
  static Map<String, dynamic> deepMerge(
      Map<String, dynamic> map1, Map<String, dynamic> map2) {
    final result = Map<String, dynamic>.from(map1);

    map2.forEach((key, value) {
      if (result.containsKey(key) &&
          result[key] is Map<String, dynamic> &&
          value is Map<String, dynamic>) {
        result[key] = deepMerge(result[key], value);
      } else {
        result[key] = value;
      }
    });

    return result;
  }

  /// Merge two Lists
  static List<T> mergeLists<T>(List<T> list1, List<T> list2,
      {bool removeDuplicates = false}) {
    final result = List<T>.from(list1);

    for (final item in list2) {
      if (!removeDuplicates || !result.contains(item)) {
        result.add(item);
      }
    }

    return result;
  }

  // ============================================================================
  // VALIDATION UTILITIES
  // ============================================================================

  /// Validate object structure against a schema
  static bool validateSchema(dynamic object, Map<String, Type> schema) {
    if (object is! Map<String, dynamic>) return false;

    for (final entry in schema.entries) {
      final key = entry.key;
      final expectedType = entry.value;

      if (!object.containsKey(key)) return false;

      final value = object[key];
      if (value.runtimeType != expectedType) return false;
    }

    return true;
  }

  /// Check if object has circular references
  static bool hasCircularReferences(dynamic object, [Set<dynamic>? visited]) {
    visited ??= <dynamic>{};

    if (visited.contains(object)) return true;

    if (object is Map || object is List) {
      visited.add(object);

      if (object is Map) {
        for (final value in object.values) {
          if (hasCircularReferences(value, visited)) return true;
        }
      } else if (object is List) {
        for (final item in object) {
          if (hasCircularReferences(item, visited)) return true;
        }
      }

      visited.remove(object);
    }

    return false;
  }

  // ============================================================================
  // TRANSFORMATION UTILITIES
  // ============================================================================

  /// Flatten nested Map structure
  static Map<String, dynamic> flattenMap(Map<String, dynamic> map,
      {String separator = '.'}) {
    final flattened = <String, dynamic>{};

    void flatten(Map<String, dynamic> current, String prefix) {
      current.forEach((key, value) {
        final newKey = prefix.isEmpty ? key : '$prefix$separator$key';

        if (value is Map<String, dynamic>) {
          flatten(value, newKey);
        } else {
          flattened[newKey] = value;
        }
      });
    }

    flatten(map, '');
    return flattened;
  }

  /// Unflatten a flattened Map structure
  static Map<String, dynamic> unflattenMap(Map<String, dynamic> flattened,
      {String separator = '.'}) {
    final result = <String, dynamic>{};

    flattened.forEach((key, value) {
      final parts = key.split(separator);
      Map<String, dynamic> current = result;

      for (int i = 0; i < parts.length - 1; i++) {
        final part = parts[i];
        current[part] ??= <String, dynamic>{};
        current = current[part] as Map<String, dynamic>;
      }

      current[parts.last] = value;
    });

    return result;
  }

  /// Convert object keys to camelCase
  static Map<String, dynamic> toCamelCase(Map<String, dynamic> map) {
    final result = <String, dynamic>{};

    map.forEach((key, value) {
      final camelKey = _toCamelCase(key);

      if (value is Map<String, dynamic>) {
        result[camelKey] = toCamelCase(value);
      } else if (value is List) {
        result[camelKey] = value.map((item) {
          return item is Map<String, dynamic> ? toCamelCase(item) : item;
        }).toList();
      } else {
        result[camelKey] = value;
      }
    });

    return result;
  }

  /// Convert object keys to snake_case
  static Map<String, dynamic> toSnakeCase(Map<String, dynamic> map) {
    final result = <String, dynamic>{};

    map.forEach((key, value) {
      final snakeKey = _toSnakeCase(key);

      if (value is Map<String, dynamic>) {
        result[snakeKey] = toSnakeCase(value);
      } else if (value is List) {
        result[snakeKey] = value.map((item) {
          return item is Map<String, dynamic> ? toSnakeCase(item) : item;
        }).toList();
      } else {
        result[snakeKey] = value;
      }
    });

    return result;
  }

  /// Convert string to camelCase
  static String _toCamelCase(String input) {
    final words = input.split(RegExp(r'[_\-\s]+'));
    if (words.isEmpty) return input;

    final result = words.first.toLowerCase();
    return result +
        words
            .skip(1)
            .map((word) => word.isEmpty
                ? ''
                : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join();
  }

  /// Convert string to snake_case
  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceAll(RegExp(r'^_'), '')
        .replaceAll(RegExp(r'[_\-\s]+'), '_')
        .toLowerCase();
  }
}
