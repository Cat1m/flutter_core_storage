/// Hive Adapters for database serialization
///
/// Note: Make sure to import your storage exceptions file:
/// import '../exceptions/storage_exceptions.dart';
///
import 'package:flutter_core_storage/src/exceptions/storage_exceptions.dart';
import 'package:hive/hive.dart';
import '../models/database_model.dart';
import '../utils/serialization_utils.dart';

/// Base adapter for Hive type adapters
/// Provides common functionality for serializing/deserializing objects
abstract class BaseAdapter<T> extends TypeAdapter<T> {
  @override
  void write(BinaryWriter writer, T obj) {
    try {
      // Convert object to JSON map
      late Map<String, dynamic> json;

      if (obj is DatabaseModel) {
        json = obj.toJson();
      } else {
        json = SerializationUtils.toMap(obj);
      }

      // Write the number of fields first
      writer.writeInt(json.length);

      // Write each field
      json.forEach((key, value) {
        writer.writeString(key);
        _writeValue(writer, value);
      });
    } catch (e) {
      throw StorageSerializationException(
        'Failed to write object of type $T: $e',
        e,
        T,
        true,
      );
    }
  }

  @override
  T read(BinaryReader reader) {
    try {
      // Read the number of fields
      final fieldCount = reader.readInt();
      final json = <String, dynamic>{};

      // Read each field
      for (int i = 0; i < fieldCount; i++) {
        final key = reader.readString();
        final value = _readValue(reader);
        json[key] = value;
      }

      // Create object from JSON
      return fromJson(json);
    } catch (e) {
      throw StorageSerializationException(
        'Failed to read object of type $T: $e',
        e,
        T,
        false,
      );
    }
  }

  /// Convert JSON map to object
  /// Must be implemented by subclasses
  T fromJson(Map<String, dynamic> json);

  /// Write a value to the binary writer
  void _writeValue(BinaryWriter writer, dynamic value) {
    if (value == null) {
      writer.writeByte(0); // null marker
    } else if (value is String) {
      writer.writeByte(1);
      writer.writeString(value);
    } else if (value is int) {
      writer.writeByte(2);
      writer.writeInt(value);
    } else if (value is double) {
      writer.writeByte(3);
      writer.writeDouble(value);
    } else if (value is bool) {
      writer.writeByte(4);
      writer.writeBool(value);
    } else if (value is List) {
      writer.writeByte(5);
      writer.writeInt(value.length);
      for (final item in value) {
        _writeValue(writer, item);
      }
    } else if (value is Map) {
      writer.writeByte(6);
      writer.writeInt(value.length);
      value.forEach((key, val) {
        writer.writeString(key.toString());
        _writeValue(writer, val);
      });
    } else if (value is DateTime) {
      writer.writeByte(7);
      writer.writeInt(value.millisecondsSinceEpoch);
    } else if (value is Duration) {
      writer.writeByte(8);
      writer.writeInt(value.inMilliseconds);
    } else {
      // For other types, convert to string
      writer.writeByte(9);
      writer.writeString(value.toString());
    }
  }

  /// Read a value from the binary reader
  dynamic _readValue(BinaryReader reader) {
    final type = reader.readByte();

    switch (type) {
      case 0: // null
        return null;
      case 1: // String
        return reader.readString();
      case 2: // int
        return reader.readInt();
      case 3: // double
        return reader.readDouble();
      case 4: // bool
        return reader.readBool();
      case 5: // List
        final length = reader.readInt();
        final list = <dynamic>[];
        for (int i = 0; i < length; i++) {
          list.add(_readValue(reader));
        }
        return list;
      case 6: // Map
        final length = reader.readInt();
        final map = <String, dynamic>{};
        for (int i = 0; i < length; i++) {
          final key = reader.readString();
          final value = _readValue(reader);
          map[key] = value;
        }
        return map;
      case 7: // DateTime
        final millis = reader.readInt();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      case 8: // Duration
        final millis = reader.readInt();
        return Duration(milliseconds: millis);
      case 9: // String (fallback)
        return reader.readString();
      default:
        throw StorageSerializationException(
          'Unknown type marker: $type',
          null,
          null,
          false,
        );
    }
  }
}

/// Generic adapter for simple objects
class GenericObjectAdapter<T> extends BaseAdapter<T> {
  final int _typeId;
  final T Function(Map<String, dynamic>) _fromJsonFunction;

  GenericObjectAdapter(this._typeId, this._fromJsonFunction);

  @override
  int get typeId => _typeId;

  @override
  T fromJson(Map<String, dynamic> json) {
    return _fromJsonFunction(json);
  }
}

/// Adapter factory for creating adapters dynamically
class AdapterFactory {
  static int _nextTypeId = 100; // Start from 100 to avoid conflicts
  static final Map<Type, TypeAdapter> _adapters = {};
  static final Map<int, Type> _typeIdToType = {};

  /// Create or get adapter for a type
  static TypeAdapter<T> getAdapter<T>({
    required T Function(Map<String, dynamic>) fromJson,
    int? typeId,
  }) {
    final type = T;

    if (_adapters.containsKey(type)) {
      return _adapters[type] as TypeAdapter<T>;
    }

    final id = typeId ?? _nextTypeId++;

    // Check if typeId is already in use
    if (_typeIdToType.containsKey(id)) {
      throw StorageOperationException(
        'Type ID $id is already registered for type ${_typeIdToType[id]}',
        null,
        'registerAdapter',
      );
    }

    final adapter = GenericObjectAdapter<T>(id, fromJson);
    _adapters[type] = adapter;
    _typeIdToType[id] = type;

    return adapter;
  }

  /// Register a custom adapter
  static void registerAdapter<T>(TypeAdapter<T> adapter) {
    final type = T;

    // Check if typeId is already in use by a different type
    if (_typeIdToType.containsKey(adapter.typeId) &&
        _typeIdToType[adapter.typeId] != type) {
      throw StorageOperationException(
        'Type ID ${adapter.typeId} is already registered for type ${_typeIdToType[adapter.typeId]}',
        null,
        'registerAdapter',
      );
    }

    _adapters[type] = adapter;
    _typeIdToType[adapter.typeId] = type;
  }

  /// Get all registered adapters
  static List<TypeAdapter> getAllAdapters() {
    return _adapters.values.toList();
  }

  /// Get adapter for a specific type
  static TypeAdapter<T>? getAdapterForType<T>() {
    return _adapters[T] as TypeAdapter<T>?;
  }

  /// Check if adapter is registered for a type
  static bool hasAdapterForType<T>() {
    return _adapters.containsKey(T);
  }

  /// Get type for a type ID
  static Type? getTypeForId(int typeId) {
    return _typeIdToType[typeId];
  }

  /// Clear all registered adapters
  static void clearAdapters() {
    _adapters.clear();
    _typeIdToType.clear();
    _nextTypeId = 100;
  }

  /// Get next available type ID
  static int getNextTypeId() {
    return _nextTypeId++;
  }

  /// Check if type ID is available
  static bool isTypeIdAvailable(int typeId) {
    return !_typeIdToType.containsKey(typeId);
  }
}

/// Mixin for objects that can be automatically adapted
mixin AutoAdaptable {
  /// Get the type ID for this object
  int get typeId;

  /// Convert to JSON
  Map<String, dynamic> toJson();

  /// Create from JSON - must be implemented by the class using this mixin
  static fromJson(Map<String, dynamic> json) {
    throw UnimplementedError(
        'fromJson must be implemented by the class using AutoAdaptable');
  }

  /// Create adapter for this type
  TypeAdapter createAdapter() {
    return GenericObjectAdapter<dynamic>(
      typeId,
      (json) => (runtimeType as dynamic).fromJson(json),
    );
  }
}

/// Adapter for Map<String, dynamic>
class MapAdapter extends TypeAdapter<Map<String, dynamic>> {
  @override
  final int typeId = 200;

  @override
  Map<String, dynamic> read(BinaryReader reader) {
    try {
      final length = reader.readInt();
      final map = <String, dynamic>{};

      for (int i = 0; i < length; i++) {
        final key = reader.readString();
        final value = _readDynamicValue(reader);
        map[key] = value;
      }

      return map;
    } catch (e) {
      throw StorageSerializationException(
        'Failed to read Map<String, dynamic>: $e',
        e,
        Map<String, dynamic>,
        false,
      );
    }
  }

  @override
  void write(BinaryWriter writer, Map<String, dynamic> obj) {
    try {
      writer.writeInt(obj.length);

      obj.forEach((key, value) {
        writer.writeString(key);
        _writeDynamicValue(writer, value);
      });
    } catch (e) {
      throw StorageSerializationException(
        'Failed to write Map<String, dynamic>: $e',
        e,
        Map<String, dynamic>,
        true,
      );
    }
  }

  void _writeDynamicValue(BinaryWriter writer, dynamic value) {
    if (value == null) {
      writer.writeByte(0);
    } else if (value is String) {
      writer.writeByte(1);
      writer.writeString(value);
    } else if (value is int) {
      writer.writeByte(2);
      writer.writeInt(value);
    } else if (value is double) {
      writer.writeByte(3);
      writer.writeDouble(value);
    } else if (value is bool) {
      writer.writeByte(4);
      writer.writeBool(value);
    } else if (value is List) {
      writer.writeByte(5);
      writer.writeInt(value.length);
      for (final item in value) {
        _writeDynamicValue(writer, item);
      }
    } else if (value is Map) {
      writer.writeByte(6);
      final map = value as Map<String, dynamic>;
      writer.writeInt(map.length);
      map.forEach((k, v) {
        writer.writeString(k.toString());
        _writeDynamicValue(writer, v);
      });
    } else if (value is DateTime) {
      writer.writeByte(7);
      writer.writeInt(value.millisecondsSinceEpoch);
    } else if (value is Duration) {
      writer.writeByte(8);
      writer.writeInt(value.inMilliseconds);
    } else {
      // Convert to string as fallback
      writer.writeByte(9);
      writer.writeString(value.toString());
    }
  }

  dynamic _readDynamicValue(BinaryReader reader) {
    final type = reader.readByte();

    switch (type) {
      case 0:
        return null;
      case 1:
        return reader.readString();
      case 2:
        return reader.readInt();
      case 3:
        return reader.readDouble();
      case 4:
        return reader.readBool();
      case 5:
        final length = reader.readInt();
        final list = <dynamic>[];
        for (int i = 0; i < length; i++) {
          list.add(_readDynamicValue(reader));
        }
        return list;
      case 6:
        final length = reader.readInt();
        final map = <String, dynamic>{};
        for (int i = 0; i < length; i++) {
          final key = reader.readString();
          final value = _readDynamicValue(reader);
          map[key] = value;
        }
        return map;
      case 7:
        final millis = reader.readInt();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      case 8:
        final millis = reader.readInt();
        return Duration(milliseconds: millis);
      case 9:
        return reader.readString();
      default:
        throw StorageSerializationException(
          'Unknown dynamic type marker: $type',
          null,
          null,
          false,
        );
    }
  }
}

/// Adapter for List<dynamic>
class ListAdapter extends TypeAdapter<List<dynamic>> {
  @override
  final int typeId = 201;

  @override
  List<dynamic> read(BinaryReader reader) {
    try {
      final length = reader.readInt();
      final list = <dynamic>[];

      for (int i = 0; i < length; i++) {
        list.add(_readDynamicValue(reader));
      }

      return list;
    } catch (e) {
      throw StorageSerializationException(
        'Failed to read List<dynamic>: $e',
        e,
        List<dynamic>,
        false,
      );
    }
  }

  @override
  void write(BinaryWriter writer, List<dynamic> obj) {
    try {
      writer.writeInt(obj.length);

      for (final item in obj) {
        _writeDynamicValue(writer, item);
      }
    } catch (e) {
      throw StorageSerializationException(
        'Failed to write List<dynamic>: $e',
        e,
        List<dynamic>,
        true,
      );
    }
  }

  void _writeDynamicValue(BinaryWriter writer, dynamic value) {
    if (value == null) {
      writer.writeByte(0);
    } else if (value is String) {
      writer.writeByte(1);
      writer.writeString(value);
    } else if (value is int) {
      writer.writeByte(2);
      writer.writeInt(value);
    } else if (value is double) {
      writer.writeByte(3);
      writer.writeDouble(value);
    } else if (value is bool) {
      writer.writeByte(4);
      writer.writeBool(value);
    } else if (value is List) {
      writer.writeByte(5);
      writer.writeInt(value.length);
      for (final item in value) {
        _writeDynamicValue(writer, item);
      }
    } else if (value is Map) {
      writer.writeByte(6);
      final map = value as Map<String, dynamic>;
      writer.writeInt(map.length);
      map.forEach((k, v) {
        writer.writeString(k.toString());
        _writeDynamicValue(writer, v);
      });
    } else if (value is DateTime) {
      writer.writeByte(7);
      writer.writeInt(value.millisecondsSinceEpoch);
    } else if (value is Duration) {
      writer.writeByte(8);
      writer.writeInt(value.inMilliseconds);
    } else {
      writer.writeByte(9);
      writer.writeString(value.toString());
    }
  }

  dynamic _readDynamicValue(BinaryReader reader) {
    final type = reader.readByte();

    switch (type) {
      case 0:
        return null;
      case 1:
        return reader.readString();
      case 2:
        return reader.readInt();
      case 3:
        return reader.readDouble();
      case 4:
        return reader.readBool();
      case 5:
        final length = reader.readInt();
        final list = <dynamic>[];
        for (int i = 0; i < length; i++) {
          list.add(_readDynamicValue(reader));
        }
        return list;
      case 6:
        final length = reader.readInt();
        final map = <String, dynamic>{};
        for (int i = 0; i < length; i++) {
          final key = reader.readString();
          final value = _readDynamicValue(reader);
          map[key] = value;
        }
        return map;
      case 7:
        final millis = reader.readInt();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      case 8:
        final millis = reader.readInt();
        return Duration(milliseconds: millis);
      case 9:
        return reader.readString();
      default:
        throw StorageSerializationException(
          'Unknown dynamic type marker: $type',
          null,
          null,
          false,
        );
    }
  }
}

/// Adapter for DateTime
class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  final int typeId = 202;

  @override
  DateTime read(BinaryReader reader) {
    final millis = reader.readInt();
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}

/// Adapter for Duration
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 203;

  @override
  Duration read(BinaryReader reader) {
    final millis = reader.readInt();
    return Duration(milliseconds: millis);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMilliseconds);
  }
}

/// Utility functions for adapter management
class AdapterUtils {
  static final Set<int> _registeredTypeIds = <int>{};

  /// Check if an adapter is registered for a type ID
  static bool isAdapterRegistered(int typeId) {
    return Hive.isAdapterRegistered(typeId);
  }

  /// Check if a type has an adapter in our factory
  static bool hasAdapterForType<T>() {
    return AdapterFactory.hasAdapterForType<T>();
  }

  /// Get type ID for a registered adapter (from our factory)
  static int? getTypeIdForType<T>() {
    final adapter = AdapterFactory.getAdapterForType<T>();
    return adapter?.typeId;
  }

  /// Register common adapters
  static void registerCommonAdapters() {
    if (!isAdapterRegistered(200)) {
      Hive.registerAdapter(MapAdapter());
      _registeredTypeIds.add(200);
    }

    if (!isAdapterRegistered(201)) {
      Hive.registerAdapter(ListAdapter());
      _registeredTypeIds.add(201);
    }

    if (!isAdapterRegistered(202)) {
      Hive.registerAdapter(DateTimeAdapter());
      _registeredTypeIds.add(202);
    }

    if (!isAdapterRegistered(203)) {
      Hive.registerAdapter(DurationAdapter());
      _registeredTypeIds.add(203);
    }
  }

  /// Register all adapters from the factory
  static void registerAllFactoryAdapters() {
    final adapters = AdapterFactory.getAllAdapters();
    for (final adapter in adapters) {
      if (!isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
        _registeredTypeIds.add(adapter.typeId);
      }
    }
  }

  /// Get all registered type IDs
  static Set<int> getRegisteredTypeIds() {
    return Set.from(_registeredTypeIds);
  }

  /// Register a single adapter with safety checks
  static void registerAdapter<T>(TypeAdapter<T> adapter) {
    if (isAdapterRegistered(adapter.typeId)) {
      throw StorageOperationException(
        'Adapter with type ID ${adapter.typeId} is already registered',
        null,
        'registerAdapter',
      );
    }

    Hive.registerAdapter(adapter);
    AdapterFactory.registerAdapter(adapter);
    _registeredTypeIds.add(adapter.typeId);
  }

  /// Clear our tracking (Note: This doesn't unregister from Hive)
  static void clearTracking() {
    _registeredTypeIds.clear();
    AdapterFactory.clearAdapters();
  }

  /// Get adapter information
  static Map<String, dynamic> getAdapterInfo() {
    return {
      'registeredTypeIds': _registeredTypeIds.toList(),
      'factoryAdapters': AdapterFactory.getAllAdapters().length,
      'commonAdaptersRegistered':
          [200, 201, 202, 203].every(isAdapterRegistered),
    };
  }
}

/// Example User adapter implementation
/// You would create this for your specific User model
/*
class UserAdapter extends BaseAdapter<User> {
  @override
  final int typeId = 1;

  @override
  User fromJson(Map<String, dynamic> json) {
    return User.fromJson(json);
  }
}

// Usage example:
// void registerUserAdapter() {
//   AdapterUtils.registerAdapter(UserAdapter());
// }
*/
