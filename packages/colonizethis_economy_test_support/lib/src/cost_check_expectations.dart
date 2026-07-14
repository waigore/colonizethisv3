// Compact checkPreconditionsInOrder assertions (Refs #3939 phase 3 slice 35).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';
import 'cost_check_scenarios.dart';
// dart format off
/// One precondition step in a [checkPreconditionsInOrder] pin row.
typedef CostPreconditionStep = ({String failReason, bool pass, bool trackEvaluation});
/// Pins for [checkPreconditionsInOrder] rows.
typedef CheckPreconditionsInOrderPins = ({List<CostPreconditionStep> steps, String? expectedReason, List<String>? expectedEvaluated});
void runCheckPreconditionsInOrderExpectation(CheckPreconditionsInOrderPins pins) {
  final evaluated = <String>[];
  final preconditions = <CostPrecondition>[
    for (final step in pins.steps)
      (
        failReason: step.failReason,
        check: () {
          if (step.trackEvaluation) {
            evaluated.add(step.failReason);
          }
          return step.pass;
        },
      ),
  ];
  expect(checkPreconditionsInOrder(preconditions), pins.expectedReason);
  if (pins.expectedEvaluated != null) {
    expect(evaluated, pins.expectedEvaluated);
  }
}
CheckPreconditionsInOrderScenario checkPreconditionsInOrderScenario({required String label, required CheckPreconditionsInOrderPins pins, String? refs}) =>
    (label: label, pins: pins, refs: refs);
// dart format on
