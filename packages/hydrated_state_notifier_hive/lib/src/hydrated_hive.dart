import 'dart:async';

import 'package:hive/hive.dart';
// ignore: implementation_imports
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';
import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';

import 'hydrated_cipher.dart';

// Copied kIsWeb from flutter foundation library
const bool _kIsWeb = identical(0, 0.0);

/// {@template hydrated_storage}
/// Implementation of [HydratedStorage] which uses [package:hive](https://pub.dev/packages/hive)
/// to persist and retrieve state changes from the local device.
/// {@endtemplate}
class HiveHydratedStorage implements HydratedStorage {
  /// {@macro hydrated_storage}
  @visibleForTesting
  HiveHydratedStorage(this._box);

  /// Returns an instance of [HiveHydratedStorage].
  /// [storageDirectory] is required.
  ///
  /// For web, use [webStorageDirectory] as the `storageDirectory`
  ///
  /// ```dart
  /// import 'package:flutter/foundation.dart';
  /// import 'package:flutter/material.dart';
  ///
  /// import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';
  /// import 'package:path_provider/path_provider.dart';
  ///
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   final storage = await HydratedStorage.build(
  ///     storageDirectory: kIsWeb
  ///       ? HydratedStorage.webStorageDirectory
  ///       : await getTemporaryDirectory(),
  ///   );
  ///   HydratedBlocOverrides.runZoned(
  ///     () => runApp(App()),
  ///     storage: storage,
  ///   );
  /// }
  /// ```
  ///
  /// With [encryptionCipher] you can provide custom encryption.
  /// Following snippet shows how to make default one:
  /// ```dart
  /// import 'package:crypto/crypto.dart';
  /// import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';
  ///
  /// const password = 'hydration';
  /// final byteskey = sha256.convert(utf8.encode(password)).bytes;
  /// return HydratedAesCipher(byteskey);
  /// ```
  static Future<HiveHydratedStorage> build({
    required String storageDirectoryPath,
    HydratedCipher? encryptionCipher,
  }) {
    return _lock.synchronized(() async {
      if (_instance != null) return _instance!;
      // Use HiveImpl directly to avoid conflicts with existing Hive.init
      // https://github.com/hivedb/hive/issues/336
      hive = HiveImpl();
      Box<dynamic> box;

      if (_kIsWeb) {
        box = await hive.openBox<dynamic>(
          'hydrated_box',
          encryptionCipher: encryptionCipher,
        );
      } else {
        hive.init(storageDirectoryPath);
        box = await hive.openBox<dynamic>(
          'hydrated_box',
          encryptionCipher: encryptionCipher,
        );
      }

      return _instance = HiveHydratedStorage(box);
    });
  }

  /// Internal instance of [HiveImpl].
  /// It should only be used for testing.
  @visibleForTesting
  static HiveInterface hive = HiveImpl();

  static final _lock = Lock();
  static HiveHydratedStorage? _instance;

  final Box _box;

  @override
  dynamic read(String key) => _box.isOpen ? _box.get(key) : null;

  @override
  Future<void> write(String key, dynamic value) async {
    if (_box.isOpen) {
      return _lock.synchronized(() => _box.put(key, value));
    }
  }

  @override
  Future<void> delete(String key) async {
    if (_box.isOpen) {
      return _lock.synchronized(() => _box.delete(key));
    }
  }

  @override
  Future<void> clear() async {
    if (_box.isOpen) {
      _instance = null;
      return _lock.synchronized(_box.clear);
    }
  }
}
