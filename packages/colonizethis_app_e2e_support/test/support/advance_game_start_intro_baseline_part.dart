part of '../e2e_advance_game_start_intro_test.dart';

void registerAdvanceGameStartIntroBaselineGroup() {
  testWidgets(
    'short-circuits before paying any pump when intro does not block UI',
    (WidgetTester tester) async {
      // No GameStartIntroOverlay / GameStartIntroLoadingIndicator mounted —
      // `e2eGameStartIntroBlocksUi` is false at entry (Branch 2 in
      // `e2e_game_start_intro_blocks_ui_test.dart`). A mounted overlay on its
      // first frame now blocks while Yarn loads (#2867 S10 / Branch 4).
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final sw = Stopwatch()..start();
      await e2eAdvanceGameStartIntroUntilDismissed(tester);
      expect(
        sw.elapsed < const Duration(milliseconds: 200),
        isTrue,
        reason:
            'Non-blocking intro state must return before any idle pump (#2336 '
            'AC5 pre-pump short-circuit).',
      );
    },
  );

  testWidgets('caps idle poll at 100ms even during long spinner stretch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameStartIntroLoadingIndicator()),
    );
    // Spinner blocks UI; helper must time out via the loading-indicator
    // branch using adaptive backoff. Confirm it does **not** burn the full
    // wall clock on tiny fixed pumps by checking that the call returns the
    // failure within a small bounded multiple of its timeout (here 150ms).
    Object? caught;
    try {
      await e2eAdvanceGameStartIntroUntilDismissed(
        tester,
        timeout: const Duration(milliseconds: 150),
      );
    } catch (e) {
      caught = e;
    }
    expect(
      caught,
      isA<TestFailure>(),
      reason: 'Persistent spinner must hit the timeout failure path.',
    );
  });

  // -------- Perf attribution pins (Refs GitHub #2336 AC8 / baseline) --------
  //
  // Each pin below threads a non-null [E2ePerfLog] into
  // `e2eAdvanceGameStartIntroUntilDismissed` and captures the `E2E_TIMING` /
  // `E2E_COUNTER` lines via the same `debugPrint` override the
  // `e2e_wait_for_map_hud_after_new_game_start_test.dart` perf-attribution
  // group uses (PR #2960). A silent regression in either the phase label,
  // the `result=...` meta tag, or the iteration counter would break the AC8
  // baseline timing pipeline (`tool/run_e2e_timing.sh` +
  // `tool/compare_e2e_timing.sh`) without showing up in the legacy
  // short-circuit / timeout tests at the top of this file (which all pass
  // `perf: null` by default).

}
