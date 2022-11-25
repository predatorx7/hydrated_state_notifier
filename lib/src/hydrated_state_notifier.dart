import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

import 'exceptions.dart';
import 'hydrated_storage.dart';

part 'hydrated_mixin.dart';

abstract class HydratedStateNotifier<State> extends StateNotifier<State>
    with HydratedMixin<State> {
  /// {@macro hydrated_cubit}
  HydratedStateNotifier(
    State state, {
    Storage? storage,
    this.id = '',
    this.version = 1,
  })  : storage = storage ?? HydratedStateNotifier.commonStorage,
        super(state) {
    hydrate();
  }

  @override
  final String id;

  @override
  final int version;

  @override
  final Storage storage;

  static Storage? _commonStorage;

  /// Setter for instance of [Storage] which will be used to
  /// manage persisting/restoring the [StateNotifier] state.
  static set commonStorage(Storage? commonStorage) =>
      _commonStorage = commonStorage;

  /// Instance of [Storage] which will be used to
  /// manage persisting/restoring the [StateNotifier] state.
  static Storage get commonStorage {
    if (_commonStorage == null) throw const StorageNotFound();
    return _commonStorage!;
  }
}
