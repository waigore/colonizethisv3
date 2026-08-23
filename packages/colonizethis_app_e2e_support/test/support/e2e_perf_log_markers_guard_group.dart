// Extracted from e2e_perf_log_markers_test.dart (#4598 Slice C).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

void registerE2ePerfLogMarkersGuardGroup() {
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
