library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'bundled_explore_rejection_harness.dart';

void registerBundledExploreFallbackGroup() {
  group('e2eBundledExploreRejectionDiagnostics — fallback string', () {
    test('null navalSnapshot returns the canonical fallback line', () {
      // A null navalSnapshot must surface as the literal canonical string
      // (no `diag:` lines, no joined newlines, no empty string). The fleet
      // reach test embeds this directly in a `fail()` so a silent rename
      // or empty-string regression would erase the post-mortem signal CI
      // grep relies on.
      expect(
        e2eBundledExploreRejectionDiagnostics(
          navalSnapshot: null,
          civilianSnapshot: null,
        ),
        'No ctE2eNavalPanelSnapshot available for diagnostics.',
        reason:
            'Null navalSnapshot path returns the canonical fallback string '
            'verbatim; this is the early-exit contract (#2336 AC1).',
      );
    });

    test('null navalSnapshot + non-null civilian still returns fallback', () {
      // The null-naval branch fires before the civilian snapshot is read.
      // A regression that swapped argument order or inspected civilian
      // before naval would emit a different diagnostic and mask the
      // missing-naval root cause in CI failure messages.
      expect(
        e2eBundledExploreRejectionDiagnostics(
          navalSnapshot: null,
          civilianSnapshot: civilianSnapshot(
            availableWorkTargets: const {
              'unit-a': <String>[kWorkTargetExplore],
            },
          ),
        ),
        'No ctE2eNavalPanelSnapshot available for diagnostics.',
        reason:
            'Civilian snapshot must not be consulted when navalSnapshot is '
            'null — the canonical fallback line dominates.',
      );
    });
  });

}
