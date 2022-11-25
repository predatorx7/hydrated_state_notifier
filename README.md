# Hydrated State Notifier

## Features

An extension to the [state_notifier](https://pub.dev/packages/state_notifier)
library which automatically persists and restores states built on top of
[hive](https://pub.dev/packages/hive).

## Usage

### Setup `HydratedStorage`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize storage
  HydratedStateNotifier.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
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

## Additional information

This is based on [hydrated_bloc](https://pub.dev/packages/hydrated_bloc).
