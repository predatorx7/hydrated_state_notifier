import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';

class BadCubit extends HydratedStateNotifier<BadState?> {
  BadCubit() : super(null);

  void setBad([dynamic badObject = Object]) => state = (BadState(badObject));

  @override
  Map<String, dynamic>? toJson(BadState? state) => state?.toJson();

  @override
  BadState? fromJson(Map<String, dynamic> json) => null;
}

class BadState {
  BadState(this.badObject);

  final dynamic badObject;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bad_obj': badObject,
    };
  }
}

class VeryBadObject {
  dynamic toJson() {
    return Object;
  }
}
