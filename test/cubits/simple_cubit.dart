import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';

class SimpleCubit extends HydratedStateNotifier<int> {
  SimpleCubit() : super(0);

  void increment() => state = (state + 1);

  @override
  Map<String, dynamic> toJson(int state) => <String, dynamic>{'state': state};

  @override
  int fromJson(Map<String, dynamic> json) => json['state'] as int;
}
