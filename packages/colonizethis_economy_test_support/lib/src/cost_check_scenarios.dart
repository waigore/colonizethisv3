// dart format off
// Table-driven cost-check precondition scenarios and compact assertions
// (Refs #3939 phase 3 slice 35, #3979; pair merged Refs #4049).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';
/// One precondition step in a [checkPreconditionsInOrder] pin row.
typedef CostPreconditionStep = ({String failReason, bool pass, bool trackEvaluation});
/// Pins for [checkPreconditionsInOrder] rows.
typedef CheckPreconditionsInOrderPins = ({List<CostPreconditionStep> steps, String? expectedReason, List<String>? expectedEvaluated});
/// One row for `CheckPreconditionsInOrderScenario` tables (Refs #3979).
typedef CheckPreconditionsInOrderScenario = ({String label, CheckPreconditionsInOrderPins pins, String? refs});
CheckPreconditionsInOrderScenario checkPreconditionsInOrderScenario({required String label, required CheckPreconditionsInOrderPins pins, String? refs}) =>
    (label: label, pins: pins, refs: refs);
void runCheckPreconditionsInOrderScenario(CheckPreconditionsInOrderScenario scenario) {
  runCheckPreconditionsInOrderExpectation(scenario.pins);
}
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
/// Canonical scenarios for [checkPreconditionsInOrder].
List<CheckPreconditionsInOrderScenario> checkPreconditionsInOrderScenarios() => [
  checkPreconditionsInOrderScenario(label: 'returns null when every check passes', pins: (steps: [(failReason: 'a', pass: true, trackEvaluation: false), (failReason: 'b', pass: true, trackEvaluation: false), (failReason: 'c', pass: true, trackEvaluation: false)], expectedReason: null, expectedEvaluated: null), refs: '#3517'),
  checkPreconditionsInOrderScenario(label: 'returns the first failing reason in list order', pins: (steps: [(failReason: 'tech', pass: true, trackEvaluation: false), (failReason: 'workers', pass: false, trackEvaluation: false), (failReason: 'treasury', pass: false, trackEvaluation: false)], expectedReason: 'workers', expectedEvaluated: null), refs: '#3517'),
  checkPreconditionsInOrderScenario(label: 'honours canonical priority: earlier failure wins over later', pins: (steps: [(failReason: 'tech', pass: false, trackEvaluation: false), (failReason: 'materials', pass: false, trackEvaluation: false)], expectedReason: 'tech', expectedEvaluated: null), refs: '#3517'),
  checkPreconditionsInOrderScenario(label: 'short-circuits: no later check runs once one fails', pins: (steps: [(failReason: 'first', pass: true, trackEvaluation: true), (failReason: 'second', pass: false, trackEvaluation: true), (failReason: 'third', pass: true, trackEvaluation: true)], expectedReason: 'second', expectedEvaluated: ['first', 'second']), refs: '#3517'),
  checkPreconditionsInOrderScenario(label: 'empty precondition list passes (returns null)', pins: (steps: [], expectedReason: null, expectedEvaluated: null), refs: '#3517'),
];
// dart format on
