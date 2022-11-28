import 'dart:async';

import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class MockStorage extends Mock implements HydratedStorage {}

class MyUuidHydratedStateController extends HydratedStateController<String> {
  MyUuidHydratedStateController()
      : super(
          const Uuid().v4(),
          fromJson: (Map<String, dynamic> json) => json['value'] as String?,
          toJson: (String state) => {'value': state},
        );
}

class MyCallbackHydratedStateController extends HydratedStateController<int> {
  MyCallbackHydratedStateController({this.onFromJsonCalled})
      : super(
          0,
          toJson: (int state) => {'value': state},
          fromJson: (dynamic json) {
            onFromJsonCalled?.call(json);
            return json['value'] as int?;
          },
        );

  final void Function(dynamic)? onFromJsonCalled;

  void increment() => state = (state + 1);

  @override
  ErrorListener get onError {
    return (Object error, StackTrace? stackTrace) {
      //
    };
  }
}

class MyHydratedStateController extends HydratedStateController<int> {
  MyHydratedStateController([
    this._id,
    this._callSuper = true,
    this._storagePrefix,
  ]) : super(
          0,
          toJson: (int state) => {'value': state},
          fromJson: (dynamic json) => json['value'] as int?,
        );

  final String? _id;
  final bool _callSuper;
  final String? _storagePrefix;

  @override
  String get id => _id ?? '';

  @override
  String get storagePrefix => _storagePrefix ?? super.storagePrefix;

  @override
  ErrorListener get onError {
    return (Object error, StackTrace? stackTrace) {
      if (_callSuper) super.onError?.call(error, stackTrace);
    };
  }
}

class MyMultiHydratedStateController extends HydratedStateController<int> {
  MyMultiHydratedStateController(String id)
      : _id = id,
        super(
          0,
          toJson: (int state) => {'value': state},
          fromJson: (dynamic json) => json['value'] as int?,
        );

  final String _id;

  @override
  String get id => _id;
}

void main() {
  group('HydratedStateController', () {
    late HydratedStorage storage;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      when<dynamic>(() => storage.read(any())).thenReturn(<String, dynamic>{});
      when(() => storage.delete(any())).thenAnswer((_) async {});
      when(() => storage.clear()).thenAnswer((_) async {});
      HydratedStorage.storage = storage;
    });

    test('reads from storage once upon initialization', () {
      MyCallbackHydratedStateController();
      verify<dynamic>(() => storage.read('MyCallbackHydratedStateController'))
          .called(1);
    });

    test(
        'reads from storage once upon initialization w/custom storagePrefix/id',
        () {
      const storagePrefix = '__storagePrefix__';
      const id = '__id__';
      MyHydratedStateController(id, true, storagePrefix);
      verify<dynamic>(() => storage.read('$storagePrefix$id')).called(1);
    });

    test('writes to storage when onChange is called w/custom storagePrefix/id',
        () {
      const change = 0;
      const expected = <String, int>{'value': 0};
      const storagePrefix = '__storagePrefix__';
      const id = '__id__';
      // ignore: invalid_use_of_protected_member
      MyHydratedStateController(id, true, storagePrefix).state = change;
      verify(() => storage.write('$storagePrefix$id', expected)).called(2);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache value exists', () {
      when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
      final cubit = MyCallbackHydratedStateController();
      expect(cubit.debugState, 42);
      cubit.increment();
      expect(cubit.debugState, 43);
      verify<dynamic>(() => storage.read('MyCallbackHydratedStateController'))
          .called(1);
    });

    test(
        'does not deserialize state on subsequent state changes '
        'when cache value exists', () {
      final fromJsonCalls = <dynamic>[];
      when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
      final cubit = MyCallbackHydratedStateController(
        onFromJsonCalled: fromJsonCalls.add,
      );
      expect(cubit.debugState, 42);
      cubit.increment();
      expect(cubit.debugState, 43);
      expect(fromJsonCalls, [
        {'value': 42}
      ]);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache is empty', () {
      when<dynamic>(() => storage.read(any())).thenReturn(null);
      final cubit = MyCallbackHydratedStateController();
      expect(cubit.debugState, 0);
      cubit.increment();
      expect(cubit.debugState, 1);
      verify<dynamic>(() => storage.read('MyCallbackHydratedStateController'))
          .called(1);
    });

    test('does not deserialize state when cache is empty', () {
      final fromJsonCalls = <dynamic>[];
      when<dynamic>(() => storage.read(any())).thenReturn(null);
      final cubit = MyCallbackHydratedStateController(
        onFromJsonCalled: fromJsonCalls.add,
      );
      expect(cubit.debugState, 0);
      cubit.increment();
      expect(cubit.debugState, 1);
      expect(fromJsonCalls, isEmpty);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache is malformed', () {
      when<dynamic>(() => storage.read(any())).thenReturn('{');
      final cubit = MyCallbackHydratedStateController();
      expect(cubit.debugState, 0);
      cubit.increment();
      expect(cubit.debugState, 1);
      verify<dynamic>(() => storage.read('MyCallbackHydratedStateController'))
          .called(1);
    });

    test('does not deserialize state when cache is malformed', () {
      final fromJsonCalls = <dynamic>[];
      runZonedGuarded(
        () {
          when<dynamic>(() => storage.read(any())).thenReturn('{');
          MyCallbackHydratedStateController(
              onFromJsonCalled: fromJsonCalls.add);
        },
        (_, __) {
          expect(fromJsonCalls, isEmpty);
        },
      );
    });

    group('SingleHydratedStateController', () {
      test('should throw StorageNotFound when storage is null', () {
        HydratedStorage.setStorageNull();
        expect(
          () => MyHydratedStateController(),
          throwsA(isA<StorageNotFound>()),
        );
      });

      test('StorageNotFound overrides toString', () {
        expect(
          // ignore: prefer_const_constructors
          StorageNotFound().toString(),
          'Storage was accessed before it was initialized.\n'
          'Please ensure that storage has been initialized.\n'
          '\n'
          'For example:\n\n'
          'HydratedStorage.storage = await HiveHydratedStorage.build();',
        );
      });

      test('storage getter returns correct storage instance', () {
        final storage = MockStorage();
        HydratedStorage.storage = storage;
        expect(HydratedStorage.storage, storage);
      });

      test('should call storage.write when onChange is called', () {
        final transition = 0;
        final expected = <String, int>{'value': 0};
        MyHydratedStateController().state = transition;
        verify(() => storage.write('MyHydratedStateController', expected))
            .called(2);
      });

      test('should call storage.write when onChange is called with cubit id',
          () {
        final cubit = MyHydratedStateController('A');
        final transition = 0;
        final expected = <String, int>{'value': 0};
        cubit.state = transition;
        verify(() => storage.write('MyHydratedStateControllerA', expected))
            .called(2);
      });

      test('should throw BlocUnhandledErrorException when storage.write throws',
          () {
        runZonedGuarded(
          () async {
            final expectedError = Exception('oops');
            final transition = 0;
            when(
              () => storage.write(any(), any<dynamic>()),
            ).thenThrow(expectedError);
            MyHydratedStateController().state = transition;
            await Future<void>.delayed(const Duration(seconds: 300));
            fail('should throw');
          },
          (error, _) {
            expect(error.toString(), 'Exception: oops');
          },
        );
      });

      test('stores initial state when instantiated', () {
        MyHydratedStateController();
        verify(
          () => storage.write('MyHydratedStateController', {'value': 0}),
        ).called(1);
      });

      test('initial state should return 0 when fromJson returns null', () {
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        expect(MyHydratedStateController().debugState, 0);
        verify<dynamic>(() => storage.read('MyHydratedStateController'))
            .called(1);
      });

      test('initial state should return 0 when deserialization fails', () {
        when<dynamic>(() => storage.read(any())).thenThrow(Exception('oops'));
        expect(MyHydratedStateController('', false).debugState, 0);
      });

      test('initial state should return 101 when fromJson returns 101', () {
        when<dynamic>(() => storage.read(any())).thenReturn({'value': 101});
        expect(MyHydratedStateController().debugState, 101);
        verify<dynamic>(() => storage.read('MyHydratedStateController'))
            .called(1);
      });

      group('clear', () {
        test('calls delete on storage', () async {
          await MyHydratedStateController().clear();
          verify(() => storage.delete('MyHydratedStateController')).called(1);
        });
      });
    });

    group('MultiHydratedStateController', () {
      test('initial state should return 0 when fromJson returns null', () {
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        expect(MyMultiHydratedStateController('A').debugState, 0);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateControllerA'),
        ).called(1);

        expect(MyMultiHydratedStateController('B').debugState, 0);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateControllerB'),
        ).called(1);
      });

      test('initial state should return 101/102 when fromJson returns 101/102',
          () {
        when<dynamic>(
          () => storage.read('MyMultiHydratedStateControllerA'),
        ).thenReturn({'value': 101});
        expect(MyMultiHydratedStateController('A').debugState, 101);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateControllerA'),
        ).called(1);

        when<dynamic>(
          () => storage.read('MyMultiHydratedStateControllerB'),
        ).thenReturn({'value': 102});
        expect(MyMultiHydratedStateController('B').debugState, 102);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateControllerB'),
        ).called(1);
      });

      group('clear', () {
        test('calls delete on storage', () async {
          await MyMultiHydratedStateController('A').clear();
          verify(() => storage.delete('MyMultiHydratedStateControllerA'))
              .called(1);
          verifyNever(() => storage.delete('MyMultiHydratedStateControllerB'));

          await MyMultiHydratedStateController('B').clear();
          verify(() => storage.delete('MyMultiHydratedStateControllerB'))
              .called(1);
        });
      });
    });

    group('MyUuidHydratedStateController', () {
      test('stores initial state when instantiated', () {
        MyUuidHydratedStateController();
        verify(
          () => storage.write('MyUuidHydratedStateController', any<dynamic>()),
        ).called(1);
      });

      test('correctly caches computed initial state', () {
        dynamic cachedState;
        when<dynamic>(() {
          return storage.read(any());
        }).thenReturn(cachedState);
        when(
          () {
            return storage.write(any(), any<dynamic>());
          },
        ).thenAnswer((_) => Future<void>.value());
        MyUuidHydratedStateController();

        final captured = verify(() {
          return storage.write(
            'MyUuidHydratedStateController',
            captureAny<dynamic>(),
          );
        }).captured;

        cachedState = captured.first;
        when<dynamic>(() => storage.read(any())).thenReturn(cachedState);

        final cachedValue = storage.read(
          'MyUuidHydratedStateController',
        );

        final dynamic initialStateB = cachedValue;

        expect(initialStateB, cachedState);
      });
    });
  });
}
