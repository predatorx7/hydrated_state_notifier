import 'dart:async';

import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class MockStorage extends Mock implements Storage {}

class MyUuidHydratedStateNotifier extends HydratedStateNotifier<String> {
  MyUuidHydratedStateNotifier() : super(const Uuid().v4());

  @override
  Map<String, String> toJson(String state) => {'value': state};

  @override
  String? fromJson(Map<String, dynamic> json) => json['value'] as String?;
}

class MyCallbackHydratedStateNotifier extends HydratedStateNotifier<int> {
  MyCallbackHydratedStateNotifier({this.onFromJsonCalled}) : super(0);

  final void Function(dynamic)? onFromJsonCalled;

  void increment() => state = (state + 1);

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int? fromJson(dynamic json) {
    onFromJsonCalled?.call(json);
    return json['value'] as int?;
  }

  @override
  ErrorListener get onError {
    return (Object error, StackTrace? stackTrace) {
      //
    };
  }
}

class MyHydratedStateNotifier extends HydratedStateNotifier<int> {
  MyHydratedStateNotifier([
    this._id,
    this._callSuper = true,
    this._storagePrefix,
  ]) : super(0);

  final String? _id;
  final bool _callSuper;
  final String? _storagePrefix;

  @override
  String get id => _id ?? '';

  @override
  String get storagePrefix => _storagePrefix ?? super.storagePrefix;

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int? fromJson(dynamic json) => json['value'] as int?;

  @override
  ErrorListener get onError {
    return (Object error, StackTrace? stackTrace) {
      if (_callSuper) super.onError?.call(error, stackTrace);
    };
  }
}

class MyMultiHydratedStateNotifier extends HydratedStateNotifier<int> {
  MyMultiHydratedStateNotifier(String id)
      : _id = id,
        super(0);

  final String _id;

  @override
  String get id => _id;

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int? fromJson(dynamic json) => json['value'] as int?;
}

void main() {
  group('HydratedStateNotifier', () {
    late Storage storage;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      when<dynamic>(() => storage.read(any())).thenReturn(<String, dynamic>{});
      when(() => storage.delete(any())).thenAnswer((_) async {});
      when(() => storage.clear()).thenAnswer((_) async {});
      HydratedStateNotifier.storage = storage;
    });

    test('reads from storage once upon initialization', () {
      MyCallbackHydratedStateNotifier();
      verify<dynamic>(() => storage.read('MyCallbackHydratedStateNotifier'))
          .called(1);
    });

    test(
        'reads from storage once upon initialization w/custom storagePrefix/id',
        () {
      const storagePrefix = '__storagePrefix__';
      const id = '__id__';
      MyHydratedStateNotifier(id, true, storagePrefix);
      verify<dynamic>(() => storage.read('$storagePrefix$id')).called(1);
    });

    test('writes to storage when onChange is called w/custom storagePrefix/id',
        () {
      const change = 0;
      const expected = <String, int>{'value': 0};
      const storagePrefix = '__storagePrefix__';
      const id = '__id__';
      // ignore: invalid_use_of_protected_member
      MyHydratedStateNotifier(id, true, storagePrefix).state = change;
      verify(() => storage.write('$storagePrefix$id', expected)).called(2);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache value exists', () {
      when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
      final cubit = MyCallbackHydratedStateNotifier();
      expect(cubit.state, 42);
      cubit.increment();
      expect(cubit.state, 43);
      verify<dynamic>(() => storage.read('MyCallbackHydratedStateNotifier'))
          .called(1);
    });

    test(
        'does not deserialize state on subsequent state changes '
        'when cache value exists', () {
      final fromJsonCalls = <dynamic>[];
      when<dynamic>(() => storage.read(any())).thenReturn({'value': 42});
      final cubit = MyCallbackHydratedStateNotifier(
        onFromJsonCalled: fromJsonCalls.add,
      );
      expect(cubit.state, 42);
      cubit.increment();
      expect(cubit.state, 43);
      expect(fromJsonCalls, [
        {'value': 42}
      ]);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache is empty', () {
      when<dynamic>(() => storage.read(any())).thenReturn(null);
      final cubit = MyCallbackHydratedStateNotifier();
      expect(cubit.state, 0);
      cubit.increment();
      expect(cubit.state, 1);
      verify<dynamic>(() => storage.read('MyCallbackHydratedStateNotifier'))
          .called(1);
    });

    test('does not deserialize state when cache is empty', () {
      final fromJsonCalls = <dynamic>[];
      when<dynamic>(() => storage.read(any())).thenReturn(null);
      final cubit = MyCallbackHydratedStateNotifier(
        onFromJsonCalled: fromJsonCalls.add,
      );
      expect(cubit.state, 0);
      cubit.increment();
      expect(cubit.state, 1);
      expect(fromJsonCalls, isEmpty);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache is malformed', () {
      when<dynamic>(() => storage.read(any())).thenReturn('{');
      final cubit = MyCallbackHydratedStateNotifier();
      expect(cubit.state, 0);
      cubit.increment();
      expect(cubit.state, 1);
      verify<dynamic>(() => storage.read('MyCallbackHydratedStateNotifier'))
          .called(1);
    });

    test('does not deserialize state when cache is malformed', () {
      final fromJsonCalls = <dynamic>[];
      runZonedGuarded(
        () {
          when<dynamic>(() => storage.read(any())).thenReturn('{');
          MyCallbackHydratedStateNotifier(onFromJsonCalled: fromJsonCalls.add);
        },
        (_, __) {
          expect(fromJsonCalls, isEmpty);
        },
      );
    });

    group('SingleHydratedStateNotifier', () {
      test('should throw StorageNotFound when storage is null', () {
        HydratedStateNotifier.storage = null;
        expect(
          () => MyHydratedStateNotifier(),
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
          'HydratedStateNotifier.storage = await HydratedStorage.build();',
        );
      });

      test('storage getter returns correct storage instance', () {
        final storage = MockStorage();
        HydratedStateNotifier.storage = storage;
        expect(HydratedStateNotifier.storage, storage);
      });

      test('should call storage.write when onChange is called', () {
        final transition = 0;
        final expected = <String, int>{'value': 0};
        MyHydratedStateNotifier().state = transition;
        verify(() => storage.write('MyHydratedStateNotifier', expected))
            .called(2);
      });

      test('should call storage.write when onChange is called with cubit id',
          () {
        final cubit = MyHydratedStateNotifier('A');
        final transition = 0;
        final expected = <String, int>{'value': 0};
        cubit.state = transition;
        verify(() => storage.write('MyHydratedStateNotifierA', expected))
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
            MyHydratedStateNotifier().state = transition;
            await Future<void>.delayed(const Duration(seconds: 300));
            fail('should throw');
          },
          (error, _) {
            expect(error.toString(), 'Exception: oops');
          },
        );
      });

      test('stores initial state when instantiated', () {
        MyHydratedStateNotifier();
        verify(
          () => storage.write('MyHydratedStateNotifier', {'value': 0}),
        ).called(1);
      });

      test('initial state should return 0 when fromJson returns null', () {
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        expect(MyHydratedStateNotifier().state, 0);
        verify<dynamic>(() => storage.read('MyHydratedStateNotifier'))
            .called(1);
      });

      test('initial state should return 0 when deserialization fails', () {
        when<dynamic>(() => storage.read(any())).thenThrow(Exception('oops'));
        expect(MyHydratedStateNotifier('', false).state, 0);
      });

      test('initial state should return 101 when fromJson returns 101', () {
        when<dynamic>(() => storage.read(any())).thenReturn({'value': 101});
        expect(MyHydratedStateNotifier().state, 101);
        verify<dynamic>(() => storage.read('MyHydratedStateNotifier'))
            .called(1);
      });

      group('clear', () {
        test('calls delete on storage', () async {
          await MyHydratedStateNotifier().clear();
          verify(() => storage.delete('MyHydratedStateNotifier')).called(1);
        });
      });
    });

    group('MultiHydratedStateNotifier', () {
      test('initial state should return 0 when fromJson returns null', () {
        when<dynamic>(() => storage.read(any())).thenReturn(null);
        expect(MyMultiHydratedStateNotifier('A').state, 0);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierA'),
        ).called(1);

        expect(MyMultiHydratedStateNotifier('B').state, 0);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierB'),
        ).called(1);
      });

      test('initial state should return 101/102 when fromJson returns 101/102',
          () {
        when<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierA'),
        ).thenReturn({'value': 101});
        expect(MyMultiHydratedStateNotifier('A').state, 101);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierA'),
        ).called(1);

        when<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierB'),
        ).thenReturn({'value': 102});
        expect(MyMultiHydratedStateNotifier('B').state, 102);
        verify<dynamic>(
          () => storage.read('MyMultiHydratedStateNotifierB'),
        ).called(1);
      });

      group('clear', () {
        test('calls delete on storage', () async {
          await MyMultiHydratedStateNotifier('A').clear();
          verify(() => storage.delete('MyMultiHydratedStateNotifierA'))
              .called(1);
          verifyNever(() => storage.delete('MyMultiHydratedStateNotifierB'));

          await MyMultiHydratedStateNotifier('B').clear();
          verify(() => storage.delete('MyMultiHydratedStateNotifierB'))
              .called(1);
        });
      });
    });

    group('MyUuidHydratedStateNotifier', () {
      test('stores initial state when instantiated', () {
        MyUuidHydratedStateNotifier();
        verify(
          () => storage.write('MyUuidHydratedStateNotifier', any<dynamic>()),
        ).called(1);
      });

      test('correctly caches computed initial state', () {
        dynamic cachedState;
        when<dynamic>(() => storage.read(any())).thenReturn(cachedState);
        when(
          () => storage.write(any(), any<dynamic>()),
        ).thenAnswer((_) => Future<void>.value());
        MyUuidHydratedStateNotifier();
        final captured = verify(
          () => storage.write(
              'MyUuidHydratedStateNotifier', captureAny<dynamic>()),
        ).captured;
        cachedState = captured.first;
        when<dynamic>(() => storage.read(any())).thenReturn(cachedState);
        MyUuidHydratedStateNotifier();
        final secondCaptured = verify(
          () => storage.write(
              'MyUuidHydratedStateNotifier', captureAny<dynamic>()),
        ).captured;
        final dynamic initialStateB = secondCaptured.first;

        expect(initialStateB, cachedState);
      });
    });
  });
}
