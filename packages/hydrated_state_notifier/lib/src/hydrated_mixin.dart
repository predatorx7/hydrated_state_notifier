part of 'hydrated_state_notifier.dart';

/// A mixin which enables automatic state persistence
/// for [StateNotifier] class.
///
/// The [hydrate] method must be invoked in the constructor body
/// when using the [HydratedMixin] directly.
///
/// If a mixin is not necessary, it is recommended to
/// extend [HydratedStateNotifier] respectively.
///
/// ```dart
/// class CounterBloc extends HydratedStateNotifier<int> with HydratedMixin {
///  CounterBloc() : super(0) {
///    hydrate();
///  }
///  ...
/// }
/// ```
///
/// See also:
///
/// * [HydratedStateNotifier] to enable automatic state persistence/restoration with [StateNotifier]
///
mixin HydratedMixin<State> on StateNotifier<State> {
  HydratedStorage get storage;

  @protected
  StorageMetadata? getMetadata() {
    try {
      final metaJson = storage.read(
        storageMetadataToken,
      ) as Map<dynamic, dynamic>?;
      if (metaJson != null) {
        return StorageMetadata.fromJson(
          ConversionUtils.forRead(metaJson) ?? <String, Object?>{},
        );
      }
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
    return null;
  }

  @protected
  void updateMetadata() {
    try {
      final now = DateTime.now();
      final oldMetadata = getMetadata() ??
          StorageMetadata(
            createdAt: now,
            updatedAt: now,
            validity: null,
            version: version,
          );

      final metaJson = oldMetadata
          .copyWith(
            validity: validity,
            updatedAt: now,
            version: version,
          )
          .toJson();
      storage
          .write(storageMetadataToken, metaJson)
          .then((_) {}, onError: onError);
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
  }

  @protected
  State? readSavedState() {
    try {
      final metadata = getMetadata();
      if (metadata != null && !metadata.isValid) return null;
      final stateJson = storage.read(storageToken) as Map<dynamic, dynamic>?;
      if (stateJson != null) {
        final convertedJson = ConversionUtils.forRead(
              stateJson,
            ) ??
            <String, dynamic>{};
        final migratedStateJson = migrate(metadata, convertedJson);
        final cachedState = _fromJson(migratedStateJson);
        if (cachedState != null) {
          final didMigrate = !(const DeepCollectionEquality.unordered()).equals(
            migratedStateJson,
            stateJson,
          );
          if (didMigrate) {
            saveState(cachedState);
          }
          return cachedState;
        }
      }
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
    return null;
  }

  @protected
  void saveState(State change) {
    try {
      final stateJson = _toJson(change);
      if (stateJson != null) {
        storage.write(storageToken, stateJson).then((_) {}, onError: onError);
      }
      updateMetadata();
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      rethrow;
    }
  }

  bool _synchronized = false;

  @visibleForTesting
  @protected
  bool get debugSynchronized => _synchronized;

  void hydrate() {
    if (_synchronized) return;
    final cachedState = readSavedState();
    final value = super.state;
    if (cachedState != null && cachedState != value) {
      super.state = cachedState;
    } else if (value != null) {
      saveState(value);
    }
    _synchronized = true;
  }

  Map<String, Object?> migrate(
    StorageMetadata? metadata,
    Map<String, Object?> cachedState,
  ) {
    final savedVersion = metadata?.version;
    if (savedVersion == null || savedVersion == version) return cachedState;
    final migratedState = onMigrate(cachedState, savedVersion, version);
    return migratedState;
  }

  @protected
  Map<String, Object?> onMigrate(
    Map<String, Object?> state,
    int oldVersion,
    int version,
  ) {
    return state;
  }

  @override
  @protected
  State get state {
    if (super.state != null && _synchronized) return super.state!;
    final cachedState = readSavedState();
    if (cachedState != null) {
      super.state = cachedState;
      return cachedState;
    }
    return super.state;
  }

  @override
  @visibleForTesting
  State get debugState {
    late State result;
    assert(() {
      result = state;
      return true;
    }(), '');
    return result;
  }

  @override
  @protected
  @visibleForTesting
  set state(State change) {
    super.state = change;
    saveState(change);
  }

  State? _fromJson(Map<String, Object?> json) {
    return fromJson(json);
  }

  Map<String, dynamic>? _toJson(State state) {
    return ConversionUtils.forWrite(toJson(state));
  }

  /// [id] is used to uniquely identify multiple instances
  /// of the same [HydratedStateNotifier] type.
  /// In most cases it is not necessary;
  /// however, if you wish to intentionally have multiple instances
  /// of the same [HydratedStateNotifier], then you must override [id]
  /// and return a unique identifier for each [HydratedStateNotifier] instance
  /// in order to keep the caches independent of each other.
  String get id;

  /// [version] is used to identify the version of this storage instance.
  /// This can be used to perform migrations.
  /// In most cases it is not necessary to use it;
  int get version;

  Duration? get validity;

  /// Storage prefix which can be overridden to provide a custom
  /// storage namespace.
  /// Defaults to [runtimeType] but should be overridden in cases
  /// where stored data should be resilient to obfuscation or persist
  /// between debug/release builds.
  String get storagePrefix => runtimeType.toString();

  /// `storageToken` is used as registration token for hydrated storage.
  /// Composed of [storagePrefix] and [id].
  @nonVirtual
  String get storageToken => '$storagePrefix$id';

  String get storageMetadataToken => 'metadata.$storageToken';

  /// [clear] is used to wipe or invalidate the cache of a [HydratedStateNotifier].
  /// Calling [clear] will delete the cached state of the bloc
  /// but will not modify the current state of the bloc.
  Future<void> clear() {
    return Future.wait([
      storage.delete(storageToken),
      storage.delete(storageMetadataToken),
    ]);
  }

  /// Responsible for converting the `Map<String, dynamic>` representation
  /// of the bloc state into a concrete instance of the bloc state.
  State? fromJson(Map<String, dynamic> json);

  /// Responsible for converting a concrete instance of the bloc state
  /// into the the `Map<String, dynamic>` representation.
  ///
  /// If [toJson] returns `null`, then no state changes will be persisted.
  Map<String, dynamic>? toJson(State state);
}
