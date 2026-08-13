library;

import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
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

    testWidgets(
      'emits result=advanced and a counter value > 1 when the spinner clears '
      'mid-loop',
      (WidgetTester tester) async {
        // Mount the spinner first so iteration 1 hits the blocking branch
        // (loading-indicator), then schedule a fake-async unmount so the
        // helper observes the cleared state on a later iteration via its
        // adaptive idle pump. Mirrors the `result=advanced` pattern landed
        // for `e2eWaitForMapHudAfterNewGameStart` (PR #2960) — the only
        // difference is that this helper polls the intro-blocks predicate
        // instead of the home-to-capital button.
        final controller = IntroSpinnerController(initiallyVisible: true);
        await tester.pumpWidget(
          MaterialApp(
            home: IntroSpinnerHost(
              controller: controller,
              clearAfter: const Duration(milliseconds: 120),
            ),
          ),
        );
        expect(
          find.byType(GameStartIntroLoadingIndicator),
          findsOneWidget,
          reason:
              'Sanity check: the spinner must be mounted at entry so the '
              'helper actually exercises the blocking → advanced transition.',
        );

        final perf = E2ePerfLog('pin_advance_intro');
        final lines = await captureDebugPrintsAsync(() async {
          await e2eAdvanceGameStartIntroUntilDismissed(
            tester,
            perf: perf,
            timeout: const Duration(seconds: 5),
          );
        });

        expect(
          find.byType(GameStartIntroLoadingIndicator),
          findsNothing,
          reason:
              'Sanity check: the helper must have observed the cleared '
              'spinner before returning; an early return on the entry '
              'iteration would imply the host scheduled the unmount before '
              'the first iteration check.',
        );

        final iterationsLines = lines
            .where(
              (line) => line.contains(
                'name=$kE2eAdvanceGameStartIntroIterationsCounter',
              ),
            )
            .toList();
        expect(
          iterationsLines.length,
          greaterThan(1),
          reason:
              'A scheduled-clear success path must bump the iterations '
              'counter on every loop iteration (including the success one), '
              'so the AC8 timing pipeline can attribute the wall-clock cost '
              'to the actual number of polling cycles.',
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
              'polled-advance success path so suite aggregators do not '
              'double-count the intro-dismiss wait.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=advanced'),
          reason:
              'A polled-advance return must report `result=advanced` (not '
              '`already_dismissed`) so the baseline timing pipeline can '
              'separate fast and slow successful paths (#2336 AC8 '
              'attribution).',
        );
      },
    );

    testWidgets(
      'emits result=timeout on the overall-cap fail path when spinner '
      'persists',
      (WidgetTester tester) async {
        // Persistent spinner → the helper hits the timeout fail path. The
        // perf marker must still fire BEFORE the `fail(...)` throw so a
        // hung intro dismissal surfaces in the AC8 timing pipeline
        // alongside the `TestFailure`, instead of as a silent wall-clock
        // burn (matches the contract documented in
        // `SPEC/program/e2e-integration-tests.md` § Determinism /
        // Intro-dismiss perf attribution bullet).
        await tester.pumpWidget(
          const MaterialApp(home: GameStartIntroLoadingIndicator()),
        );
        final perf = E2ePerfLog('pin_advance_intro');
        final lines = <String>[];
        Object? caught;
        try {
          await runWithDebugPrintCapture(lines, () async {
            await e2eAdvanceGameStartIntroUntilDismissed(
              tester,
              perf: perf,
              timeout: const Duration(milliseconds: 150),
            );
          });
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'Sanity check: the timeout-fail-path test must still raise so '
              'the perf assertion below is exercised against the same '
              'fail-fast contract as the no-perf timeout test above.',
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
              'timeout fail path so a hung intro dismissal surfaces in the '
              'AC8 timing pipeline (alongside the `TestFailure`) instead of '
              'as a silent wall-clock burn.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=timeout'),
          reason:
              'The overall-cap fail path must report `result=timeout` so the '
              'baseline timing pipeline can distinguish a hung intro '
              'dismissal from a successful (slow) one (#2336 AC8 / AC10 '
              'attribution).',
        );
      },
    );

    testWidgets(
      'emits no markers when perf is null (default), preserving the opt-in '
      'attribution contract',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final lines = <String>[];
        await runWithDebugPrintCapture(lines, () async {
          await e2eAdvanceGameStartIntroUntilDismissed(tester);
        });
        final introMarkers = lines
            .where(
              (line) =>
                  line.contains(
                    'phase=$kE2eDefaultAdvanceGameStartIntroPhase',
                  ) ||
                  line.contains(
                    'name=$kE2eAdvanceGameStartIntroIterationsCounter',
                  ),
            )
            .toList();
        expect(
          introMarkers,
          isEmpty,
          reason:
              'Default `perf: null` must NOT emit any helper-attribution '
              'markers so callers that opt out of attribution (the legacy '
              'widget-test pins, ad-hoc scenarios, future low-overhead '
              'integration paths) keep their byte-quiet contract.',
        );
      },
    );
  });
}
