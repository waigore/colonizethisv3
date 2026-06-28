import 'package:colonizethis_economy/src/economy/world_market/gp_treasury_credit_accumulator.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('GpTreasuryCreditAccumulator<int>', () {
    test('starts empty with a zero total', () {
      final acc = GpTreasuryCreditAccumulator<int>(0);
      expect(acc.isEmpty, isTrue);
      expect(acc.total, 0);
      expect(acc.view, isEmpty);
    });

    test('add creates and accumulates entries, total stays incremental', () {
      final acc = GpTreasuryCreditAccumulator<int>(0)
        ..add('gpA', 10)
        ..add('gpB', 5)
        ..add('gpA', 3);
      expect(acc.view, {'gpA': 13, 'gpB': 5});
      expect(acc.total, 18);
      expect(acc.isEmpty, isFalse);
    });

    test('view preserves first-seen insertion order', () {
      final acc = GpTreasuryCreditAccumulator<int>(0)
        ..add('gpC', 1)
        ..add('gpA', 1)
        ..add('gpB', 1)
        ..add('gpA', 1);
      expect(acc.view.keys.toList(), ['gpC', 'gpA', 'gpB']);
    });

    test('view is unmodifiable', () {
      final acc = GpTreasuryCreditAccumulator<int>(0)..add('gpA', 1);
      expect(() => acc.view['gpB'] = 2, throwsUnsupportedError);
    });

    test('incremental total equals the naive re-summed view total', () {
      final acc = GpTreasuryCreditAccumulator<int>(0)
        ..add('gpA', 7)
        ..add('gpB', 11)
        ..add('gpA', 2);
      final naive = acc.view.values.fold<int>(0, (a, b) => a + b);
      expect(acc.total, naive);
    });
  });

  group('GpTreasuryCreditAccumulator<double> (FRR zero-profit semantics)', () {
    test('ensure records a zero entry without changing the total', () {
      final acc = GpTreasuryCreditAccumulator<double>(0.0)
        ..add('gpA', 40.0)
        ..ensure('gpB');
      expect(acc.view, {'gpA': 40.0, 'gpB': 0.0});
      expect(acc.total, 40.0);
    });

    test('ensure is a no-op when the key already has a credit', () {
      final acc = GpTreasuryCreditAccumulator<double>(0.0)
        ..add('gpA', 12.5)
        ..ensure('gpA');
      expect(acc.view, {'gpA': 12.5});
      expect(acc.total, 12.5);
    });

    test('total matches naive re-sum including a zero-profit entry', () {
      final acc = GpTreasuryCreditAccumulator<double>(0.0)
        ..add('gpA', 4.6)
        ..add('gpB', 40.0)
        ..ensure('gpC')
        ..add('gpA', 0.4);
      final naive = acc.view.values.fold<double>(0.0, (a, b) => a + b);
      expect(acc.total, closeTo(naive, 1e-12));
      expect(acc.view['gpC'], 0.0);
    });
  });
}
