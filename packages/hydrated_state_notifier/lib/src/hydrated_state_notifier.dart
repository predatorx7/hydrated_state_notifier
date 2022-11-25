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
    HydratedStorage? storage,
    this.id = '',
    this.version = 1,
  })  : storage = storage ?? HydratedStorage.storage,
        super(state) {
    hydrate();
  }

  @override
  final String id;

  @override
  final int version;

  @override
  final HydratedStorage storage;
}
