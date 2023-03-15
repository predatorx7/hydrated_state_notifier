import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStorage extends Mock implements HydratedStorage {}

class Counter extends StateNotifier<int?> with HydratedMixin {
  Counter(int? state) : super(state);

  @override
  String get id => '';

  @override
  HydratedStorage get storage => HydratedStorage.storage;

  @override
  int? fromJson(Map<String, dynamic> json) {
    return json['value'] as int?;
  }

  @override
  Map<String, dynamic>? toJson(int? state) {
    return {'value': state};
  }

  @override
  int get version => 1;

  @override
  Duration? get validity => null;
}

void main() {
  group('HydratedMixin', () {
    late HydratedStorage storage;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      when<dynamic>(() => storage.read(any())).thenReturn(<String, dynamic>{});
      when(() => storage.delete(any())).thenAnswer((_) async {});
      when(() => storage.clear()).thenAnswer((_) async {});
      HydratedStorage.storage = storage;
    });

    test('Testing cached value in unsynchronized HydratedMixin', () {
      const value = 0;

      final counter = Counter(null);

      expect(
        counter.debugState,
        isNull,
      );

      verify(() => storage.read(counter.storageToken)).called(1);

      counter.state = value;

      when<dynamic>(() => storage.read(any())).thenReturn(<String, dynamic>{
        'value': value,
      });

      expect(
        counter.debugState,
        equals(value),
      );

      verify(() => storage.read(counter.storageToken)).called(1);

      final counter2 = Counter(null);

      expect(
        counter2.debugState,
        equals(value),
      );

      verify(() => storage.read(counter.storageToken)).called(1);

      expect(counter2.debugSynchronized, isFalse);
    });
  });
}
