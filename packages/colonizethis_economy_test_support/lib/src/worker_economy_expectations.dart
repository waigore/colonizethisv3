// Compact worker labour primitive assertions (Refs #3939 phase 3 slice 33).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'worker_economy_scenarios.dart';

/// Pins for [effectiveLabourFromIdleCounts] rows.
typedef IdleLabourPins = ({WorkerIdleCounts idle, int expected});

void runIdleLabourExpectation(IdleLabourPins pins) {
  expect(effectiveLabourFromIdleCounts(pins.idle), pins.expected);
}

WorkerEconomyScenario idleLabourScenario({
  required String label,
  required IdleLabourPins pins,
}) => (label: label, run: () => runIdleLabourExpectation(pins), refs: null);

/// Pins for [effectiveLabourForWorkers] rows.
typedef EffectiveLabourPins = ({
  WorkerPool workers,
  Stockpile stockpile,
  int militaryUnits,
  int expected,
});

void runEffectiveLabourExpectation(EffectiveLabourPins pins) {
  final labour = effectiveLabourForWorkers(
    workers: pins.workers,
    stockpile: pins.stockpile,
    militaryUnits: pins.militaryUnits,
  );
  expect(labour, pins.expected);
}

WorkerEconomyScenario effectiveLabourScenario({
  required String label,
  required EffectiveLabourPins pins,
}) =>
    (label: label, run: () => runEffectiveLabourExpectation(pins), refs: null);
