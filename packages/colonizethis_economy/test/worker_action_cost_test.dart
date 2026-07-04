// Table-driven unit tests for worker recruit/train costs (Refs #3856).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// Unit tests for `lib/src/economy/worker_action_cost.dart`.
///
/// Pins the shared recruit/train affordability gate
/// (`canAffordRecruitWorker`) and the cost deduction
/// (`applyRecruitWorkerCostDeduction`) used by submission, validation,
/// resolution, and projection so the single source of truth keeps the
/// canonical rejection order and per-tier deltas.
///
/// SPEC/game/workers-and-population.md § Recruiting, Training, and Disbanding.
/// Tied to the colonizethis_economy leaf-package coverage gate (Refs #3290).
void main() {
  group('canAffordRecruitWorker', () {
    for (final scenario in canAffordRecruitWorkerScenarios()) {
      test(scenario.label, () {
        runWorkerActionCostScenario(scenario);
      });
    }
  });

  group('applyRecruitWorkerCostDeduction', () {
    for (final scenario in applyRecruitWorkerCostDeductionScenarios()) {
      test(scenario.label, () {
        runWorkerActionCostScenario(scenario);
      });
    }
  });
}
