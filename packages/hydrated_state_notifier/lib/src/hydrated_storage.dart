import 'package:meta/meta.dart';

import 'exceptions.dart';

/// Interface which is used to persist and retrieve state changes.
abstract class HydratedStorage {
  /// Returns value for key
  Object? read(String key);

  /// Persists key value pair
  Future<void> write(String key, Object? value);

  /// Deletes key value pair
  Future<void> delete(String key);

  /// Clears all key value pairs from storage
  Future<void> clear();

  static HydratedStorage? _storage;

  /// Setter for instance of [HydratedStorage] which will be used to
  /// manage persisting/restoring the [StateNotifier] state.
  static set storage(HydratedStorage commonStorage) => _storage = commonStorage;

  @visibleForTesting
  static setStorageNull() => _storage = null;

  /// Instance of [HydratedStorage] which will be used to
  /// manage persisting/restoring the [StateNotifier] state.
  static HydratedStorage get storage {
    if (_storage == null) throw const StorageNotFound();
    return _storage!;
  }
}
