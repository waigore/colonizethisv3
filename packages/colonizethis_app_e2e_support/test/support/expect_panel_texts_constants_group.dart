library;

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'expect_panel_texts_harness.dart';

void registerExpectPanelTextsConstantsGroup() {
  group('e2eExpectPanelTextsMatchSnapshot — default constants', () {
    test(
      'kE2eDefaultExpectPanelTextsPhase preserves the documented phase '
      'literal',
      () {
        expect(
          kE2eDefaultExpectPanelTextsPhase,
          'wait_until_found_panel_for_text_assertion',
          reason:
              'Callers that omit `phaseName` rely on this canonical default '
              '(used in the AC1 barrel signature and the helper signature) '
              'so AC8 timing tables can attribute generic invocations to a '
              'single bucket. A silent rename would orphan that bucket and '
              'fragment attribution across runs.',
        );
      },
    );

    test(
      'kE2eDefaultExpectPanelTextsTimeout preserves the 20-second budget '
      'used by the pre-lift inline closures',
      () {
        expect(
          kE2eDefaultExpectPanelTextsTimeout,
          const Duration(seconds: 20),
          reason:
              'The full-turn pre-lift closures '
              '(`expectCivilianPanelTexts` / `expectNavalPanelTexts` / '
              '`expectProductionPanelTexts`) all used a 20-second timeout. '
              'A silent change to the default would inflate the per-panel '
              'wall-clock budget #2336 is reducing.',
        );
      },
    );

    test(
      'kE2eDefaultExpectPanelTextsSnapshotReaderTimeout caps the post-mount '
      'reader poll at 2 seconds',
      () {
        expect(
          kE2eDefaultExpectPanelTextsSnapshotReaderTimeout,
          const Duration(seconds: 2),
          reason:
              'The bounded post-mount snapshot-reader poll closes the race '
              'between the panel-root mount and the post-frame snapshot '
              'setter (Refs #2336 AC10). Two seconds is generous compared '
              'with the typical single-frame turnaround; raising it would '
              'inflate the AC9 wall-clock budget on the slow path, while '
              'shortening it would re-introduce the same false '
              '`null snapshot` failure on slower CI runners.',
        );
      },
    );

    test(
      'kE2eDefaultExpectPanelTextsSnapshotReaderPhase preserves the '
      'attribution label for AC8 timing tables',
      () {
        expect(
          kE2eDefaultExpectPanelTextsSnapshotReaderPhase,
          'pump_until_panel_snapshot_populated',
          reason:
              'AC8 timing tables attribute the post-mount snapshot-setter '
              'wait to this dedicated phase label so its latency stays '
              'separate from the panel-root mount slice; a silent rename '
              'would orphan that bucket.',
        );
      },
    );
  });

}
