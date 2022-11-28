import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStorage extends Mock implements HydratedStorage {}

class UnsupportedFakeData {}

class SerializableFakeData {
  dynamic toJson() {
    return <String>[
      'apple',
      'orange',
      'mango',
    ];
  }
}

void main() {
  group('HydratedCyclicError', () {
    test('toString override is correct', () {
      expect(
        HydratedCyclicError(<String, dynamic>{}).toString(),
        'Cyclic error while state traversing',
      );
    });
    group('reproducing cyclic errors', () {
      late HydratedStorage storage;

      setUp(() {
        storage = MockStorage();
        when(() => storage.write(any(), any<dynamic>()))
            .thenAnswer((_) async {});
        when<dynamic>(() => storage.read(any()))
            .thenReturn(<String, dynamic>{});
        when(() => storage.delete(any())).thenAnswer((_) async {});
        when(() => storage.clear()).thenAnswer((_) async {});
        HydratedStorage.storage = storage;
      });

      test('description', () {
        final Map<String, dynamic> cyclicErrorData = {
          'some': 'object',
        };

        cyclicErrorData['value'] = cyclicErrorData;

        final complexController = HydratedStateController<Map<String, dynamic>>(
          const {},
          fromJson: (_) => _,
          toJson: (_) => _,
        );

        expect(
          () => complexController.update((state) => cyclicErrorData),
          throwsA(isA<HydratedCyclicError>()),
        );
      });
    });
  });

  group('HydratedUnsupportedError', () {
    late HydratedStorage storage;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      when<dynamic>(() => storage.read(any())).thenReturn(<String, dynamic>{});
      when(() => storage.delete(any())).thenAnswer((_) async {});
      when(() => storage.clear()).thenAnswer((_) async {});
      HydratedStorage.storage = storage;
    });

    test('Reproducing HydratedUnsupportedError error with custom object', () {
      final Map<String, dynamic> data = {
        'some': 'object',
      };

      data['value'] = UnsupportedFakeData();

      final complexController = HydratedStateController<Map<String, dynamic>>(
        const {},
        fromJson: (_) => _,
        toJson: (_) => _,
      );

      expect(
        () => complexController.update((state) => data),
        throwsA(isA<HydratedUnsupportedError>()),
      );
    });

    test(
        'Passing json serializable object which should not throw HydratedUnsupportedError',
        () {
      final Map<String, dynamic> data = {
        'some': 'object',
      };

      data['value'] = SerializableFakeData();

      final complexController = HydratedStateController<Map<String, dynamic>>(
        const {},
        fromJson: (_) => _,
        toJson: (_) => _,
      );

      expect(
        () => complexController.update((state) => data),
        returnsNormally,
      );
    });
  });
}
