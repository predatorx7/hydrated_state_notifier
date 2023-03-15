import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

import 'conversion_utils.dart';
import 'hydrated_storage.dart';
import 'metadata.dart';

part 'hydrated_mixin.dart';

abstract class HydratedStateNotifier<State> extends StateNotifier<State>
    with HydratedMixin<State> {
  /// {@macro hydrated_cubit}
  HydratedStateNotifier(
    State state, {
    HydratedStorage? storage,
    this.id = '',
    this.version = 1,
    this.validity,
  })  : storage = storage ?? HydratedStorage.storage,
        super(state) {
    hydrate();
  }

  @override
  final String id;

  @override
  final int version;

  @override
  final Duration? validity;

  @override
  final HydratedStorage storage;
}
