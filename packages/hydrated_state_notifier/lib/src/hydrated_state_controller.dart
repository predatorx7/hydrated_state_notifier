import 'hydrated_state_notifier.dart';
import 'hydrated_storage.dart';

typedef StateUpdateCallback<State> = State Function(State state);
typedef FromJsonCallback<State> = State? Function(Map<String, dynamic> json);
typedef ToJsonCallback<State> = Map<String, dynamic>? Function(State state);

/// A [HydratedStateNotifier] that allows modifying its [state] from outside.
///
/// This avoids having to make a [HydratedStateNotifier] subclass for simple scenarios.
class HydratedStateController<State> extends HydratedStateNotifier<State> {
  /// Initialize the state of [StateController].
  HydratedStateController(
    State state, {
    required FromJsonCallback<State> fromJson,
    required ToJsonCallback<State> toJson,
    HydratedStorage? storage,
    String id = '',
    int version = 1,
  })  : _fromJson = fromJson,
        _toJson = toJson,
        super(
          state,
          storage: storage,
          id: id,
          version: version,
        );

  // Remove the protected status
  @override
  State get state => super.state;

  @override
  set state(State value) => super.state = value;

  /// Calls a function with the current [state] and assigns the result as the
  /// new state.
  ///
  /// This allows simplifying the syntax for updating the state when the update
  /// depends on the previous state, such that rather than:
  ///
  /// ```dart
  /// ref.read(provider.notifier).state = ref.read(provider.notifier).state + 1;
  /// ```
  ///
  /// we can do:
  ///
  /// ```dart
  /// ref.read(provider.state).update((state) => state + 1);
  /// ```
  State update(StateUpdateCallback<State> cb) => state = cb(state);

  final FromJsonCallback<State> _fromJson;

  @override
  State? fromJson(Map<String, dynamic> json) {
    return _fromJson(json);
  }

  final ToJsonCallback<State> _toJson;

  @override
  Map<String, dynamic>? toJson(State state) {
    return _toJson(state);
  }
}
