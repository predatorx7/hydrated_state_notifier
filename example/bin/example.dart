import 'package:example/example.dart';
import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';

void main(List<String> arguments) async {
  // Uncomment if flutter
  // WidgetsFlutterBinding.ensureInitialized();
  await setupStorage();

  final controller = BrightnessController(Brightness.light);

  print('First value: ${controller.state}!');

  controller.toggleBrightness();

  print('First value: ${controller.state}!');
}

enum Brightness {
  light,
  dark,
}

class BrightnessController extends HydratedStateNotifier<Brightness> {
  BrightnessController(super.state);

  void toggleBrightness() {
    state = (state == Brightness.light ? Brightness.dark : Brightness.light);
  }

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
