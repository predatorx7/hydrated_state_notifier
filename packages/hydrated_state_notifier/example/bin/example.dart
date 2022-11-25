import 'package:example/example.dart';
import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';

void main(List<String> arguments) async {
  // Uncomment if flutter
  // WidgetsFlutterBinding.ensureInitialized();
  await setupStorage();
  counterExample();
  brightnessExample();
  multipleCounterExample();
  multipleTypeWithSameKeyExample();
}

void counterExample() {
  print('[start] Counter example');

  final controller = HydratedStateController(
    0,
    fromJson: (json) => json['count'] as int,
    toJson: (state) => {'count': state},
  );

  print('First value: ${controller.state}!');

  controller.state++;

  print('Second value: ${controller.state}!');

  print('[end] Counter example');
}

void brightnessExample() {
  print('[start] Brightness example');

  final controller = BrightnessController(Brightness.light);

  print('First value: ${controller.value}!');

  controller.toggleBrightness();

  print('Second value: ${controller.value}!');

  print('[end] Brightness example');
}

enum Brightness {
  light,
  dark,
}

class CounterController extends HydratedStateNotifier<int> {
  CounterController(String id) : super(0, id: id);

  void increment() => state = state + 1;

  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  @override
  Map<String, int> toJson(int state) => {'value': state};
}

class BrightnessController extends HydratedStateNotifier<Brightness> {
  BrightnessController(super.state);

  void toggleBrightness() {
    state = (state == Brightness.light ? Brightness.dark : Brightness.light);
  }

  Brightness get value => state;

  @override
  Brightness? fromJson(Map<String, dynamic> json) {
    final brightness = json['brightness'];
    if (brightness == null) return null;
    return Brightness.values[brightness];
  }

  @override
  Map<String, dynamic>? toJson(Brightness? state) {
    if (state == null) return null;
    return {'brightness': state.index};
  }
}

void multipleCounterExample() {
  print('[start] Multiple Counter example');

  final controller1 = HydratedStateController(
    0,
    fromJson: (json) => json['count'] as int,
    toJson: (state) => {'count': state},
    id: 'counter1',
  );

  print('controller1 first value: ${controller1.state}!');

  controller1.state++;

  print('controller1 second value: ${controller1.state}!');

  final controller2 = HydratedStateController(
    0,
    fromJson: (json) => json['count'] as int,
    toJson: (state) => {'count': state},
    id: 'counter2',
  );

  print('controller2 first value: ${controller2.state}!');

  controller2.state++;

  print('controller2 second value: ${controller2.state}!');

  print('[end] Multiple Counter example');
}

void multipleTypeWithSameKeyExample() {
  print('[start] Multiple Type using Same keys example');

  final controller1 = BrightnessController1(Brightness.light);

  print('First value: ${controller1.value}!');

  controller1.toggleBrightness();

  print('Second value: ${controller1.value}!');

  final controller2 = BrightnessController2(Brightness.light);

  print('First value: ${controller2.value}!');

  controller2.toggleBrightness();

  print('Second value: ${controller2.value}!');

  print('[end] Multiple Type using Same keys example');
}

class BrightnessController1 extends BrightnessController {
  BrightnessController1(super.state);
}

class BrightnessController2 extends BrightnessController {
  BrightnessController2(super.state);
}
