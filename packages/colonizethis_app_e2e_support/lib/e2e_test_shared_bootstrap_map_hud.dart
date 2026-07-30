import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

/// Default phase label emitted by [e2eWaitForMapHudAfterNewGameStart] when a
/// caller does not override [E2ePerfLog] attribution.
///
/// The constant is exposed so widget-test pins and downstream perf-marker
/// scrapers (for example the GitHub #2336 AC8 baseline timing tool) can refer
/// to the legacy label by name instead of hard-coding the literal string.
const String kE2eDefaultWaitForMapHudPhase =
    'wait_for_map_hud_after_new_game_start';

/// Counter name bumped on every [e2eWaitForMapHudAfterNewGameStart] iteration
/// so a hung bootstrap surfaces as an attributable counter spike instead of a
/// silent 60 s wall-clock burn (Refs GitHub #2336 AC8 / AC10).
const String kE2eWaitForMapHudIterationsCounter =
    'wait_for_map_hud_after_new_game_start_iterations';

/// After [Start] is tapped, polls until the in-game map HUD is visible.
///
/// Evaluates success before the first pump; uses [e2eNextIdlePollStepMs]
/// (25ms → doubling capped at 500ms) per
/// `SPEC/program/e2e-integration-tests.md` § *Adaptive poll pacing* /
/// GitHub #2336 AC5 adaptive polling guidance.
///
/// Perf attribution (Refs GitHub #2336 AC8 / baseline measurement):
///
/// - When [perf] is non-null, emits one `E2E_TIMING|phase=[phaseName]` line
///   on every return path with a `result=...` meta tag distinguishing
///   `result=already_mounted` (entry-iteration short-circuit; counter
///   value `1`), `result=advanced` (HUD landed on a later iteration after
///   one or more pumps), `result=error_dialog` (fail-fast on
///   `Could not create game`), and `result=timeout` (overall-cap fail path).
///   The phase label defaults to [kE2eDefaultWaitForMapHudPhase].
/// - Bumps the [kE2eWaitForMapHudIterationsCounter] counter once per loop
///   iteration (including the iteration that returns success) so a hung
///   bootstrap surfaces as a counter spike instead of a silent wall-clock
///   burn. The counter is incremented before the early-exit checks for that
///   iteration so the `result=already_mounted` short-circuit reports
///   `value=1`.
Future<void> e2eWaitForMapHudAfterNewGameStart(
  WidgetTester tester, {
  Duration overallCap = const Duration(seconds: 60),
  E2ePerfLog? perf,
  String phaseName = kE2eDefaultWaitForMapHudPhase,
}) async {
  final sw = Stopwatch()..start();
  final setupDeadline = DateTime.now().add(overallCap);
  var stepMs = 25;
  var iterations = 0;
  while (DateTime.now().isBefore(setupDeadline)) {
    iterations += 1;
    perf?.bumpCounter(
      kE2eWaitForMapHudIterationsCounter,
      meta: 'phase=$phaseName',
    );
    if (find.text('Could not create game').evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=error_dialog');
      fail(
        'New game setup failed (error dialog). '
        'Exception: ${tester.takeException()}',
      );
    }
    if (find.byKey(kHomeToCapitalButtonKey).evaluate().isNotEmpty) {
      await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);
      perf?.timing(
        phaseName,
        sw.elapsed,
        meta: iterations == 1 ? 'result=already_mounted' : 'result=advanced',
      );
      return;
    }
    if (e2eGameStartIntroBlocksUi(tester)) {
      await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);
      stepMs = 25;
      continue;
    }
    if (find.text('Creating game').evaluate().isNotEmpty) {
      await tester.pump(Duration(milliseconds: stepMs));
      stepMs = e2eNextIdlePollStepMs(stepMs);
      continue;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = e2eNextIdlePollStepMs(stepMs);
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${overallCap.inSeconds}s waiting for '
    'map (home→capital). Last exception: ${tester.takeException()}',
  );
}
