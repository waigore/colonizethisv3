library;

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'advance_game_start_intro_harness.dart';

void registerAdvanceGameStartIntroPerfGroup() {
  group('e2eAdvanceGameStartIntroUntilDismissed perf attribution', () {
    test('phase constant matches the documented '
        '`advance_game_start_intro_until_dismissed` label', () {
      expect(
        kE2eDefaultAdvanceGameStartIntroPhase,
        'advance_game_start_intro_until_dismissed',
        reason:
            'Phase constant must stay byte-equivalent so the AC8 baseline '
            'timing pipeline can key on the same phase=... label as the '
            'docs in `SPEC/program/e2e-integration-tests.md` § '
            'Determinism (Intro-dismiss perf attribution bullet).',
      );
    });

    test('counter constant matches the documented '
        '`advance_game_start_intro_until_dismissed_iterations` label', () {
      expect(
        kE2eAdvanceGameStartIntroIterationsCounter,
        'advance_game_start_intro_until_dismissed_iterations',
        reason:
            'Counter constant must stay byte-equivalent so the AC8 baseline '
            'timing pipeline can key on the same name=... label as the docs '
            'in `SPEC/program/e2e-integration-tests.md` § Determinism '
            '(Intro-dismiss perf attribution bullet).',
      );
    });

    testWidgets(
      'emits result=already_dismissed with iterations counter value=1 when '
      'intro does not block at entry',
      (WidgetTester tester) async {
        // No GameStartIntroOverlay / GameStartIntroLoadingIndicator mounted →
        // `e2eGameStartIntroBlocksUi` is false at iteration 1, so the helper
        // must short-circuit immediately and report the dedicated
        // `result=already_dismissed` meta tag with counter value `1`.
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final perf = E2ePerfLog('pin_advance_intro');
        final lines = await captureDebugPrintsAsync(() async {
          await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);
        });

        final iterationsCounter = lines
            .where(
              (line) => line.contains(
                'name=$kE2eAdvanceGameStartIntroIterationsCounter',
              ),
            )
            .toList();
        expect(
          iterationsCounter,
          hasLength(1),
          reason:
              'The entry-iteration short-circuit must still bump the '
              'iterations counter once so a hung intro dismissal is '
              'distinguishable from a fast success in post-run analysis '
              '(#2336 AC8).',
        );
        expect(
          iterationsCounter.single,
          contains('|value=1'),
          reason:
              'Counter value at the already_dismissed short-circuit must be 1 '
              '(the single completed iteration) so the AC8 timing pipeline '
              'can use the counter as the de-duplicated intro-iteration '
              'tally without double-counting the entry frame.',
        );
        expect(
          iterationsCounter.single,
          contains('|meta=phase=$kE2eDefaultAdvanceGameStartIntroPhase'),
          reason:
              'Counter meta must carry the phase label so downstream parsers '
              'can slice the counter by the same phase=... key used by the '
              'timing marker.',
        );

        final timingLines = lines
            .where(
              (line) =>
                  line.contains(
                    'phase=$kE2eDefaultAdvanceGameStartIntroPhase',
                  ) &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'already_dismissed short-circuit so suite aggregators do not '
              'double-count the intro-dismiss wait.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=already_dismissed'),
          reason:
              'The entry-iteration short-circuit must report '
              '`result=already_dismissed` so the baseline timing pipeline can '
              'separate fast already-dismissed returns from successful '
              'polled / tapped advances (#2336 AC8 attribution).',
        );
      },
    );
  });
}
