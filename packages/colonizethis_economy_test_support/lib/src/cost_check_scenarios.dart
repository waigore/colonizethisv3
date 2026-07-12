// dart format off
// Table-driven cost-check precondition scenarios (Refs #3939 phase 3 slice 35, #3979).

import 'cost_check_expectations.dart';

/// One row for `CheckPreconditionsInOrderScenario` tables (Refs #3979).
typedef CheckPreconditionsInOrderScenario = ({String label, CheckPreconditionsInOrderPins pins, String? refs});

void runCheckPreconditionsInOrderScenario(CheckPreconditionsInOrderScenario scenario) {
  runCheckPreconditionsInOrderExpectation(scenario.pins);
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
