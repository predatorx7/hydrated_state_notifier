# Hydrated State Notifier Hive

<p align="center">
<a href="https://pub.dev/packages/hydrated_state_notifier"><img src="https://img.shields.io/pub/v/hydrated_state_notifier.svg" alt="Pub"></a>
<a href="https://github.com/predatorx7/hydrated_state_notifier/actions/workflows/hydrated_state_notifier.yaml"><img src="https://github.com/predatorx7/hydrated_state_notifier/actions/workflows/hydrated_state_notifier.yaml/badge.svg" alt="hydrated_state_notifier"></a>
<a href="https://codecov.io/gh/predatorx7/hydrated_state_notifier" >
<img src="https://codecov.io/gh/predatorx7/hydrated_state_notifier/branch/main/graph/badge.svg?token=B30DQIWOMP"/>
</a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

## Features

An implementation of HydratedStorage from
[hydrated_state_notifier](https://pub.dev/packages/hydrated_state_notifier)
library which automatically persists and restores states built on top of
[hive](https://pub.dev/packages/hive).


## Usage

### Setup `HydratedStorage`

#### Install

Add package to your project with

```sh
dart pub add hydrated_state_notifier hydrated_state_notifier_hive
```

#### Import package

Add below lines in your dart file

```dart
import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';
import 'package:hydrated_state_notifier_hive/hydrated_state_notifier_hive.dart';
```

#### Initialize

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize the common storage by providing [HiveHydratedStorage]. 
  /// You can also provide your own implementation of [HydratedStorage].
  HydratedStorage.storage = await HiveHydratedStorage.build(
    storageDirectory: kIsWeb
        ? ''
        : await getTemporaryDirectory(),
  );

  runApp(App())
}
```

### Create a HydratedStateNotifier

Does automatic state persistence for the [StateNotifier] class.

```dart
class CounterController extends HydratedStateNotifier<int> {
  CounterController() : super(0);

  void increment() => state = state + 1;

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, int> toJson(int state) => { 'value': state };
}
```

Now the `CounterController` will automatically persist/restore their state. We
can increment the counter value, hot restart, kill the app, etc... and the
previous state will be retained.

It uses the same cache for the same type. Use the `id` parameter if you intend
to have different cache for different intance of same type.

```dart
class CounterController extends HydratedStateNotifier<int> {
  CounterController(String id) : super(0, id: id);

  void increment() => state = state + 1;

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, int> toJson(int state) => { 'value': state };
}

CounterController('first_counter');
CounterController('second_counter');
```

### Create a HydratedStateController

A subclass of [HydratedStateNotifier] for simple scenarios.

```dart
final counterController = HydratedStateController(
    0,
    fromJson: (json) => json['count'] as int,
    toJson: (state) => {'count': state},
);
```

Now the `counterController` will automatically persist/restore their state. We
can increment the counter value, hot restart, kill the app, etc... and the
previous state will be retained.

It uses the same cache for the same type. Use the `id` parameter if you intend
to have different cache for different intance of same type.

```dart
final counterController = HydratedStateController(
    0,
    fromJson: (json) => json['count'] as int,
    toJson: (state) => {'count': state},
    id: 'counter_1',
);
```

```dart
final counterController = HydratedStateController(
    0,
    fromJson: (json) => json['count'] as int,
    toJson: (state) => {'count': state},
    id: 'counter_2',
);
```

## HydratedMixin

```dart
class CounterController extends StateNotifier<int> with HydratedMixin {
  CounterController() : super(0) {
    // Hydrate must be called if using HydratedMixin or implementing any 
    // [HydratedStateNotifier], or [HydratedStateController].
    hydrate();
  }

  void increment() => state = state + 1;

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, int> toJson(int state) => { 'value': state };
  
  @override
  String get id => '';
  
  @override
  // Use a common storage or pass another
  HydratedStorage get storage => HydratedStorage.storage;
  
  @override
  // Will be used for writing migrations in a later version
  int get version => 1;
}
```

## HydratedStorage

You can implement a custom Storage by simply implementing the `HydratedStorage` interface and initializing HydratedStateNotifier with the custom Storage.

```dart
// my_hydrated_storage.dart

class MyHydratedStorage implements HydratedStorage {
  @override
  Object? read(String key) {
    // TODO: implement read
  }

  @override
  Future<void> write(String key, Object? value) async {
    // TODO: implement write
  }

  @override
  Future<void> delete(String key) async {
    // TODO: implement delete
  }

  @override
  Future<void> clear() async {
    // TODO: implement clear
  }
}
```

Setting a common storage for all.

```dart
// main.dart

HydratedBloc.storage = MyHydratedStorage();
runApp(MyApp());
```

or providing storage through the parameters:
```dart
final counterController = HydratedStateController(
    0,
    fromJson: (json) => json['count'] as int,
    toJson: (state) => {'count': state},
    storage: MyHydratedStorage(),
);

// or

class CounterController extends HydratedStateNotifier<int> {
  CounterController(String id) : super(0, id: id, storage: MyHydratedStorage());

  void increment() => state = state + 1;

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, int> toJson(int state) => { 'value': state };
}
```

## Additional information

This is based on [hydrated_bloc](https://pub.dev/packages/hydrated_bloc), and
[hydrated_notifier](https://pub.dev/packages/hydrated_notifier).
