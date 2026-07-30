// Shared E2E_TIMING line filters for dismiss inner-helper perf attribution
// groups (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:flutter_test/flutter_test.dart';

/// Lines emitted by an inner-helper `E2E_TIMING|phase=...` marker.
List<String> e2eTimingLinesForPhase(List<String> lines, String phase) {
  return lines
      .where(
        (line) =>
            line.contains('phase=$phase') && line.startsWith('E2E_TIMING|'),
      )
      .toList();
}

/// Asserts exactly one timing line for [phase] containing [resultMeta].
void expectSingleDismissTimingMeta({
  required List<String> lines,
  required String phase,
  required String resultMeta,
  required String capturedReasonSuffix,
}) {
  final timing = e2eTimingLinesForPhase(lines, phase);
  expect(
    timing,
    hasLength(1),
    reason:
        'Exactly one inner-helper `E2E_TIMING|phase=...` line must be '
        'emitted. Captured: $lines$capturedReasonSuffix',
  );
  expect(
    timing.single,
    contains('|meta=result=$resultMeta'),
    reason: 'Timing line must report `result=$resultMeta`. Captured: $lines',
  );
}

/// Asserts no timing lines for [phase] (default `perf: null` opt-out contract).
void expectNoDismissTimingForPhase({
  required List<String> lines,
  required String phase,
  required String capturedReasonSuffix,
}) {
  final phaseLines = e2eTimingLinesForPhase(lines, phase);
  expect(
    phaseLines,
    isEmpty,
    reason:
        'Default `perf: null` must preserve the byte-quiet contract: no '
        '`E2E_TIMING|phase=$phase` line should be emitted for opt-out '
        'callers. Captured: $lines$capturedReasonSuffix',
  );
}
