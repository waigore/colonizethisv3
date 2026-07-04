// Table-driven GpTreasuryCreditAccumulator scenarios (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

/// One row in [gpTreasuryCreditIntScenarios].
typedef GpTreasuryCreditIntScenario = ({
  String label,
  void Function(GpTreasuryCreditAccumulator<int> acc) setup,
  void Function(GpTreasuryCreditAccumulator<int> acc) verify,
  String? refs,
});

/// Canonical int accumulator scenarios.
List<GpTreasuryCreditIntScenario> gpTreasuryCreditIntScenarios() => [
  (
    label: 'starts empty with a zero total',
    setup: (_) {},
    verify: (acc) {
      expect(acc.isEmpty, isTrue);
      expect(acc.total, 0);
      expect(acc.view, isEmpty);
    },
    refs: null,
  ),
  (
    label: 'add creates and accumulates entries, total stays incremental',
    setup: (acc) => acc
      ..add('gpA', 10)
      ..add('gpB', 5)
      ..add('gpA', 3),
    verify: (acc) {
      expect(acc.view, {'gpA': 13, 'gpB': 5});
      expect(acc.total, 18);
      expect(acc.isEmpty, isFalse);
    },
    refs: null,
  ),
  (
    label: 'view preserves first-seen insertion order',
    setup: (acc) => acc
      ..add('gpC', 1)
      ..add('gpA', 1)
      ..add('gpB', 1)
      ..add('gpA', 1),
    verify: (acc) {
      expect(acc.view.keys.toList(), ['gpC', 'gpA', 'gpB']);
    },
    refs: null,
  ),
  (
    label: 'view is unmodifiable',
    setup: (acc) => acc.add('gpA', 1),
    verify: (acc) {
      expect(() => acc.view['gpB'] = 2, throwsUnsupportedError);
    },
    refs: null,
  ),
  (
    label: 'incremental total equals the naive re-summed view total',
    setup: (acc) => acc
      ..add('gpA', 7)
      ..add('gpB', 11)
      ..add('gpA', 2),
    verify: (acc) {
      final naive = acc.view.values.fold<int>(0, (a, b) => a + b);
      expect(acc.total, naive);
    },
    refs: null,
  ),
];

/// One row in [gpTreasuryCreditDoubleScenarios].
typedef GpTreasuryCreditDoubleScenario = ({
  String label,
  void Function(GpTreasuryCreditAccumulator<double> acc) setup,
  void Function(GpTreasuryCreditAccumulator<double> acc) verify,
  String? refs,
});

/// Canonical double accumulator scenarios (FRR zero-profit semantics).
List<GpTreasuryCreditDoubleScenario> gpTreasuryCreditDoubleScenarios() => [
  (
    label: 'ensure records a zero entry without changing the total',
    setup: (acc) => acc
      ..add('gpA', 40.0)
      ..ensure('gpB'),
    verify: (acc) {
      expect(acc.view, {'gpA': 40.0, 'gpB': 0.0});
      expect(acc.total, 40.0);
    },
    refs: null,
  ),
  (
    label: 'ensure is a no-op when the key already has a credit',
    setup: (acc) => acc
      ..add('gpA', 12.5)
      ..ensure('gpA'),
    verify: (acc) {
      expect(acc.view, {'gpA': 12.5});
      expect(acc.total, 12.5);
    },
    refs: null,
  ),
  (
    label: 'total matches naive re-sum including a zero-profit entry',
    setup: (acc) => acc
      ..add('gpA', 4.6)
      ..add('gpB', 40.0)
      ..ensure('gpC')
      ..add('gpA', 0.4),
    verify: (acc) {
      final naive = acc.view.values.fold<double>(0.0, (a, b) => a + b);
      expect(acc.total, closeTo(naive, 1e-12));
      expect(acc.view['gpC'], 0.0);
    },
    refs: null,
  ),
];

/// Runs an int accumulator scenario row.
void runGpTreasuryCreditIntScenario(GpTreasuryCreditIntScenario scenario) {
  final acc = GpTreasuryCreditAccumulator<int>(0);
  scenario.setup(acc);
  scenario.verify(acc);
}

/// Runs a double accumulator scenario row.
void runGpTreasuryCreditDoubleScenario(GpTreasuryCreditDoubleScenario scenario) {
  final acc = GpTreasuryCreditAccumulator<double>(0.0);
  scenario.setup(acc);
  scenario.verify(acc);
}
