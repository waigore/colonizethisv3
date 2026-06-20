/// Pins the **`E2E_COUNTER`** and **`E2E_TIMING`** marker contracts emitted by
/// `E2ePerfLog` in `app/integration_test/e2e_test_shared.dart`
/// (Refs GitHub #2336 AC8 / `SPEC/program/e2e-integration-tests.md`
/// § Baseline / post-refactor timing).
///
/// `E2ePerfLog` is the observability primitive every shared E2E helper uses
/// to attribute wall-clock cost to a specific phase or counter site. The
/// `colonizethis-e2e-ui-stability.mdc` PR runtime rule explicitly names
/// `E2E_TIMING` and `E2E_COUNTER` as the markers a regression must emit so
/// runtime overruns are attributable, and the existing
/// `e2e_pump_until_test.dart` / `e2e_wait_until_found_test.dart` smokes only
/// exercise the helper as a passthrough — neither pins the message format,
/// counter accumulation, or per-instance independence.
///
/// A silent format regression (for example dropping the `test=` field,
/// switching `|` to a different separator, or rounding milliseconds to a
/// different unit) would slip past every other widget/E2E test in the suite
/// and only surface as confusing parser failures in any future tool that
/// scrapes the markers — including downstream consumers a maintainer might
/// add to the AC8 timing pipeline (`tool/run_e2e_timing.sh` /
/// `tool/compare_e2e_timing.sh`).
///
/// These pins capture the exact `debugPrint` output via the standard
/// `debugPrint = ...` override so the contract is enforced at the widget-test
/// layer (`integration_test/` runs on a no-op `app_e2e_linux` lane per
/// `SPEC/program/e2e-integration-tests.md` § CI).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests).
List<String> _captureDebugPrints(void Function() body) {
  final captured = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    captured.add(message ?? '');
  };
  try {
    body();
  } finally {
    debugPrint = original;
  }
  return captured;
}

void main() {
  suppressLogsForTests();

  group('E2ePerfLog.bumpCounter', () {
    test('emits canonical E2E_COUNTER marker on the first call', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        perf.bumpCounter('turn_loop_iterations');
      });
      expect(
        lines,
        <String>['E2E_COUNTER|test=pin_perf_log|name=turn_loop_iterations|value=1'],
        reason:
            'The first bump must emit the canonical pipe-delimited marker '
            'with test=, name=, and value= fields in that order so any '
            'downstream parser (timing harness, ad-hoc grep, future AC8 '
            'tooling) can split on `|` and `=` without ambiguity.',
      );
    });

    test('increments by 1 by default across successive calls', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        perf.bumpCounter('next_turn_taps');
        perf.bumpCounter('next_turn_taps');
        perf.bumpCounter('next_turn_taps');
      });
      expect(
        lines,
        <String>[
          'E2E_COUNTER|test=pin_perf_log|name=next_turn_taps|value=1',
          'E2E_COUNTER|test=pin_perf_log|name=next_turn_taps|value=2',
          'E2E_COUNTER|test=pin_perf_log|name=next_turn_taps|value=3',
        ],
        reason:
            'Default `by:` must accumulate by 1; if a refactor accidentally '
            'reset the counter or stopped persisting state across calls, '
            'the wall-clock attribution markers would lose monotonicity '
            'and every per-turn counter would silently re-emit value=1.',
      );
    });

    test('accumulates by the explicit `by` step when supplied', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        perf.bumpCounter('frames', by: 5);
        perf.bumpCounter('frames', by: 2);
      });
      expect(
        lines,
        <String>[
          'E2E_COUNTER|test=pin_perf_log|name=frames|value=5',
          'E2E_COUNTER|test=pin_perf_log|name=frames|value=7',
        ],
        reason:
            'A caller that bumps a counter by a non-default step expects the '
            'value field to reflect the running sum; downstream tooling '
            'aggregates totals from the value field, not from line counts.',
      );
    });

    test('appends `|meta=…` suffix when `meta:` is supplied', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        perf.bumpCounter('wait_until_found_calls', meta: 'phase=open_panel');
      });
      expect(
        lines,
        <String>[
          'E2E_COUNTER|test=pin_perf_log|name=wait_until_found_calls|value=1'
              '|meta=phase=open_panel',
        ],
        reason:
            'Many callers (e2eWaitUntilFound, e2eWaitUntilAnyFinderHitTestable, '
            'e2ePumpUntil, e2eDismissTransientUi) attach `meta=phase=…` so a '
            'single counter name can be sliced by phase in post-run analysis.',
      );
    });

    test('omits the `|meta=…` suffix when `meta:` is null', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        perf.bumpCounter('plain_counter');
      });
      expect(lines, hasLength(1));
      expect(
        lines.single.contains('|meta='),
        isFalse,
        reason:
            'Null `meta:` must produce no `|meta=` tail; otherwise parsers '
            'that key on the marker shape would see a trailing empty field '
            'and mis-attribute the counter.',
      );
    });

    test('tracks counters independently within the same instance', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        perf.bumpCounter('a');
        perf.bumpCounter('b');
        perf.bumpCounter('a');
        perf.bumpCounter('b', by: 4);
      });
      expect(
        lines,
        <String>[
          'E2E_COUNTER|test=pin_perf_log|name=a|value=1',
          'E2E_COUNTER|test=pin_perf_log|name=b|value=1',
          'E2E_COUNTER|test=pin_perf_log|name=a|value=2',
          'E2E_COUNTER|test=pin_perf_log|name=b|value=5',
        ],
        reason:
            'Counters must be keyed by name within a single E2ePerfLog so a '
            'scenario with multiple counter sites (turn loops, panel opens, '
            'next-turn taps) sees per-name running totals — not a shared '
            'global tally.',
      );
    });
  });

  group('E2ePerfLog.timing', () {
    test('emits canonical E2E_TIMING marker with milliseconds', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        perf.timing('open_panel_civilian', const Duration(milliseconds: 123));
      });
      expect(
        lines,
        <String>[
          'E2E_TIMING|test=pin_perf_log|phase=open_panel_civilian|ms=123',
        ],
        reason:
            'Pipe-delimited marker with test=, phase=, ms= in that order; '
            'AC8 / `colonizethis-e2e-ui-stability.mdc` PR runtime rule pin '
            'this exact shape so a regression that drops or reorders any '
            'field is attributable.',
      );
    });

    test('uses Duration.inMilliseconds (truncates sub-millisecond input)', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        // 1500 microseconds == 1.5ms; Duration.inMilliseconds truncates to 1.
        perf.timing('phase_a', const Duration(microseconds: 1500));
        perf.timing('phase_b', Duration.zero);
        perf.timing('phase_c', const Duration(seconds: 2));
      });
      expect(
        lines,
        <String>[
          'E2E_TIMING|test=pin_perf_log|phase=phase_a|ms=1',
          'E2E_TIMING|test=pin_perf_log|phase=phase_b|ms=0',
          'E2E_TIMING|test=pin_perf_log|phase=phase_c|ms=2000',
        ],
        reason:
            'Switching the unit (for example to microseconds) or rounding '
            'differently would silently break every comparison the AC8 '
            'pipeline does on the `ms=` field.',
      );
    });

    test('appends `|meta=…` suffix when `meta:` is supplied', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        perf.timing(
          'fleet_move_segment',
          const Duration(milliseconds: 250),
          meta: 'result=no_legal_step',
        );
      });
      expect(
        lines,
        <String>[
          'E2E_TIMING|test=pin_perf_log|phase=fleet_move_segment|ms=250'
              '|meta=result=no_legal_step',
        ],
        reason:
            'Several helpers (e.g. `_tryNavalMoveSegment`, '
            '`e2eAdvanceOneHumanTurn`, `e2eWaitUntilFound`) attach a '
            '`result=` qualifier so the same phase name can carry distinct '
            'outcomes (`result=found`, `result=timeout`, `result=advanced`); '
            'losing the suffix would collapse those branches into one bucket.',
      );
    });

    test('omits the `|meta=…` suffix when `meta:` is null', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        perf.timing('plain_phase', const Duration(milliseconds: 7));
      });
      expect(lines, hasLength(1));
      expect(
        lines.single.contains('|meta='),
        isFalse,
        reason:
            'A null `meta:` must emit no trailing `|meta=` token so plain '
            'phase timings do not leave a dangling empty field for parsers.',
      );
    });

    test('does not mutate counter state', () {
      final perf = E2ePerfLog('pin_perf_log');
      final lines = _captureDebugPrints(() {
        perf.bumpCounter('mixed');
        perf.timing('mixed', const Duration(milliseconds: 9));
        perf.bumpCounter('mixed');
      });
      expect(
        lines,
        <String>[
          'E2E_COUNTER|test=pin_perf_log|name=mixed|value=1',
          'E2E_TIMING|test=pin_perf_log|phase=mixed|ms=9',
          'E2E_COUNTER|test=pin_perf_log|name=mixed|value=2',
        ],
        reason:
            'A `timing` call must not bump or reset the same-named counter; '
            'callers commonly share a label between a phase timing and a '
            'call counter (e.g. `open_panel_civilian`) and rely on the two '
            'tallies staying independent.',
      );
    });
  });

  group('E2ePerfLog testName', () {
    test('embeds the constructor-supplied testName in every marker', () {
      final perf = E2ePerfLog('new_game_full_turn');
      final lines = _captureDebugPrints(() {
        perf.bumpCounter('open_panel_civilian');
        perf.timing('open_panel_civilian', const Duration(milliseconds: 12));
      });
      expect(
        lines,
        <String>[
          'E2E_COUNTER|test=new_game_full_turn|name=open_panel_civilian|value=1',
          'E2E_TIMING|test=new_game_full_turn|phase=open_panel_civilian|ms=12',
        ],
        reason:
            'AC8 timing analysis groups markers by `test=` so each scenario '
            'totals independently; mis-quoting or losing the testName would '
            'mix per-scenario phase totals in any downstream report.',
      );
    });

    test('keeps counters scoped to a single instance', () {
      final perfA = E2ePerfLog('scenario_a');
      final perfB = E2ePerfLog('scenario_b');
      final lines = _captureDebugPrints(() {
        perfA.bumpCounter('shared');
        perfB.bumpCounter('shared');
        perfA.bumpCounter('shared');
      });
      expect(
        lines,
        <String>[
          'E2E_COUNTER|test=scenario_a|name=shared|value=1',
          'E2E_COUNTER|test=scenario_b|name=shared|value=1',
          'E2E_COUNTER|test=scenario_a|name=shared|value=2',
        ],
        reason:
            'Two perf logs in the same isolate (for example two test cases '
            'running back-to-back) must not share a counter table; a shared '
            'tally would corrupt per-scenario value= fields.',
      );
    });
  });
}
