// Perf attribution pins for `e2eWaitForMapHudAfterNewGameStart` (Slice D / #4195).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart'
    show E2ePerfLog;
import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap.dart';

import 'wait_map_hud_harness.dart';

void registerWaitMapHudPerfGroup() {
  group('e2eWaitForMapHudAfterNewGameStart perf attribution', () {
    testWidgets(
      'emits result=already_mounted with iterations counter value=1 when HUD is '
      'already mounted at entry',
      (WidgetTester tester) async {
        await pumpWaitMapHudHost(tester, initial: WaitMapHudSetupPhase.mapHud);
        final perf = E2ePerfLog('pin_wait_for_map_hud');
        final lines = await captureWaitMapHudDebugPrintsAsync(() async {
          await e2eWaitForMapHudAfterNewGameStart(
            tester,
            overallCap: const Duration(seconds: 5),
            perf: perf,
          );
        });

        final iterationsCounter = lines
            .where(
              (line) =>
                  line.contains('name=$kE2eWaitForMapHudIterationsCounter'),
            )
            .toList();
        expect(
          iterationsCounter,
          hasLength(1),
          reason:
              'The entry-iteration short-circuit must still bump the '
              'iterations counter once so a hung bootstrap is distinguishable '
              'from a fast success in post-run analysis (#2336 AC8).',
        );
        expect(
          iterationsCounter.single,
          contains('|value=1'),
          reason:
              'Counter value at the already_mounted short-circuit must be 1 '
              '(the single completed iteration) so the AC8 timing pipeline '
              'can use the counter as the de-duplicated bootstrap-iteration '
              'tally without double-counting the entry frame.',
        );
        expect(
          iterationsCounter.single,
          contains('|meta=phase=$kE2eDefaultWaitForMapHudPhase'),
          reason:
              'Counter meta must carry the phase label so downstream parsers '
              'can slice the counter by the same phase=... key used by the '
              'timing marker.',
        );

        final timingLines = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultWaitForMapHudPhase') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'success path so suite aggregators do not double-count the '
              'bootstrap wait.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=already_mounted'),
          reason:
              'The entry-iteration short-circuit must report '
              '`result=already_mounted` so the baseline timing pipeline can '
              'separate fast already-mounted returns from successful polled '
              'advances (#2336 AC8 attribution).',
        );
      },
    );

    testWidgets(
      'emits result=advanced and a counter value > 1 when the HUD lands during '
      'the poll loop',
      (WidgetTester tester) async {
        await pumpWaitMapHudHost(
          tester,
          initial: WaitMapHudSetupPhase.creatingGame,
          transitionAfter: const Duration(milliseconds: 120),
          transitionTo: WaitMapHudSetupPhase.mapHud,
        );
        final perf = E2ePerfLog('pin_wait_for_map_hud');
        final lines = await captureWaitMapHudDebugPrintsAsync(() async {
          await e2eWaitForMapHudAfterNewGameStart(
            tester,
            overallCap: const Duration(seconds: 5),
            perf: perf,
          );
        });

        final iterationsLines = lines
            .where(
              (line) =>
                  line.contains('name=$kE2eWaitForMapHudIterationsCounter'),
            )
            .toList();
        expect(
          iterationsLines.length,
          greaterThan(1),
          reason:
              'A scheduled-transition success path must bump the iterations '
              'counter on every loop iteration (including the success one), '
              'so the AC8 timing pipeline can attribute the wall-clock cost '
              'to the actual number of polling cycles.',
        );

        final timingLines = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultWaitForMapHudPhase') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'polled-advance success path.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=advanced'),
          reason:
              'A polled-advance return must report `result=advanced` (not '
              '`already_mounted`) so the baseline timing pipeline can '
              'separate fast and slow successful paths (#2336 AC8 '
              'attribution).',
        );
      },
    );

    testWidgets('emits result=timeout on the overall-cap fail path', (
      WidgetTester tester,
    ) async {
      await pumpWaitMapHudHost(tester, initial: WaitMapHudSetupPhase.idle);
      final perf = E2ePerfLog('pin_wait_for_map_hud');
      final lines = <String>[];
      Object? caught;
      try {
        await runWaitMapHudDebugPrintCapture(lines, () async {
          await e2eWaitForMapHudAfterNewGameStart(
            tester,
            overallCap: const Duration(milliseconds: 150),
            perf: perf,
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
            'fail-fast contract as the no-perf timeout test.',
      );

      final timingLines = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultWaitForMapHudPhase') &&
                line.startsWith('E2E_TIMING|'),
          )
          .toList();
      expect(
        timingLines,
        hasLength(1),
        reason:
            'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
            'timeout fail path so a hung bootstrap surfaces in the AC8 '
            'timing pipeline (alongside the `TestFailure`) instead of as a '
            'silent wall-clock burn.',
      );
      expect(
        timingLines.single,
        contains('|meta=result=timeout'),
        reason:
            'The overall-cap fail path must report `result=timeout` so the '
            'baseline timing pipeline can distinguish a hung bootstrap from '
            'a successful (slow) one (#2336 AC8 / AC10 attribution).',
      );
    });

    testWidgets(
      'emits result=error_dialog before failing on "Could not create game"',
      (WidgetTester tester) async {
        await pumpWaitMapHudHost(
          tester,
          initial: WaitMapHudSetupPhase.errorDialog,
        );
        final perf = E2ePerfLog('pin_wait_for_map_hud');
        final lines = <String>[];
        Object? caught;
        try {
          await runWaitMapHudDebugPrintCapture(lines, () async {
            await e2eWaitForMapHudAfterNewGameStart(
              tester,
              overallCap: const Duration(seconds: 5),
              perf: perf,
            );
          });
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'Sanity check: the error-dialog branch must still raise so the '
              'perf assertion below covers the same fail-fast contract as '
              'the no-perf error-dialog test.',
        );

        final timingLines = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultWaitForMapHudPhase') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'error-dialog fail-fast path so a broken new-game setup is '
              'attributable in the AC8 timing pipeline (alongside the '
              '`TestFailure`).',
        );
        expect(
          timingLines.single,
          contains('|meta=result=error_dialog'),
          reason:
              'The error-dialog fail path must report `result=error_dialog` '
              '(distinct from `result=timeout`) so the baseline timing '
              'pipeline can separate fast setup-failure paths from genuine '
              'wall-clock overruns (#2336 AC8 / AC10 attribution).',
        );
      },
    );
  });
}
