import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

/// True while the game-start intro still shows its blocking shell or spinner.
///
/// [GameStartIntroOverlay] stays mounted after dismissal; only the blocking
/// [CtDialogShell] / [GameStartIntroLoadingIndicator] indicate UI capture.
bool e2eGameStartIntroBlocksUi(WidgetTester tester) {
  if (find.byType(GameStartIntroLoadingIndicator).evaluate().isNotEmpty) {
    return true;
  }
  if (find.byType(GameStartIntroOverlay).evaluate().isEmpty) {
    return false;
  }
  return find
      .descendant(
        of: find.byType(GameStartIntroOverlay),
        matching: find.byType(CtDialogShell),
      )
      .evaluate()
      .isNotEmpty;
}

/// Default phase label emitted by [e2eAdvanceGameStartIntroUntilDismissed]
/// when a caller does not override [E2ePerfLog] attribution.
///
/// The constant is exposed so widget-test pins and downstream perf-marker
/// scrapers (for example the GitHub #2336 AC8 baseline timing pipeline via
/// `tool/run_e2e_timing.sh` / `tool/compare_e2e_timing.sh`) can refer to the
/// canonical label by name instead of hard-coding the literal string. Mirrors
/// the [kE2eDefaultWaitForMapHudPhase] convention introduced for the map-HUD
/// bootstrap wait in PR #2960.
const String kE2eDefaultAdvanceGameStartIntroPhase =
    'advance_game_start_intro_until_dismissed';

/// Counter name bumped on every [e2eAdvanceGameStartIntroUntilDismissed]
/// iteration so a hung intro dismissal surfaces as an attributable counter
/// spike instead of a silent 15 s wall-clock burn (Refs GitHub #2336 AC8 /
/// AC10). Mirrors [kE2eWaitForMapHudIterationsCounter] which carries the same
/// "iteration tally surfaces hangs as a counter spike" contract for the
/// downstream map-HUD wait.
const String kE2eAdvanceGameStartIntroIterationsCounter =
    'advance_game_start_intro_until_dismissed_iterations';

/// Yarn intro control labels tried in order each loop iteration (GitHub #2336).
///
/// The production `game_start_intro` node (one narrative line then
/// `-> I shall.`) is collapsed by `CtDialogueView` into a **single** step whose
/// only control is the Yarn option label `I shall.` (Refs #3628): there is no
/// intermediate Continue line step, so one tap of `I shall.` dismisses the
/// intro. The legacy generic `Continue` label is retained as a defensive
/// fallback (e.g. the asset-load error shell) and tried only after `I shall.`.
const List<String> kE2eGameStartIntroControlLabels = ['I shall.', 'Continue'];

/// Per-control post-tap settle budget after an intro button tap.
///
/// Intermediate controls (for example **Continue** before **I shall.**) do not
/// dismiss the blocking shell; the legacy 5 s [e2ePumpUntilConditionOrIdle]
/// cap per tap therefore burned ~5 s on every bootstrap before the next label
/// could be tried. A shorter cap keeps frame settlement without blocking the
/// multi-label pass (Refs GitHub #2336 AC5 / bootstrap wall-clock).
const Duration kE2eDefaultIntroControlPostTapSettleTimeout = Duration(
  milliseconds: 500,
);

/// Advances yarn intro lines/choices until the overlay no longer blocks taps.
///
/// The spinner / no-tap-target branches previously each paid a fixed 50 ms
/// pump per loop iteration. Both now share an [e2eAdaptivePollRampAfterIdle]
/// idle pump (25 → 50 → 75 → 100 ms cap) so a long spinner stretch settles
/// with adaptive backoff instead of constant 50 ms frames. The poll cadence
/// is reset to 25 ms whenever a tap advances the overlay or the loading
/// indicator clears, mirroring the prepump-free panel openers landed in this
/// PR. Refs GitHub #2336 AC5 / pump-reduction.
///
/// **Multi-label pass:** each loop iteration tries every label in
/// [kE2eGameStartIntroControlLabels] without breaking after the first tap.
/// Intermediate controls (for example **Continue** before **I shall.**) keep
/// the blocking shell mounted; the per-control post-tap settle uses
/// [kE2eDefaultIntroControlPostTapSettleTimeout] (500 ms) instead of the
/// legacy 5 s cap so bootstrap does not burn ~5 s waiting for full dismissal
/// before the next control is tapped.
///
/// Perf attribution (Refs GitHub #2336 AC8 / baseline measurement):
///
/// - When [perf] is non-null, emits one `E2E_TIMING|phase=[phaseName]` line
///   on every return path with a `result=...` meta tag distinguishing
///   `result=already_dismissed` (entry-iteration short-circuit; counter
///   value `1`), `result=advanced` (intro stopped blocking on a later
///   iteration after one or more pumps or taps), and `result=timeout`
///   (overall-cap fail path). The phase label defaults to
///   [kE2eDefaultAdvanceGameStartIntroPhase].
/// - Bumps the [kE2eAdvanceGameStartIntroIterationsCounter] counter once per
///   loop iteration (including the iteration that returns success) so a
///   hung intro dismissal surfaces as a counter spike instead of a silent
///   wall-clock burn. The counter is incremented before the early-exit check
///   for that iteration so the `result=already_dismissed` short-circuit
///   reports `value=1`.
/// - With `perf: null` (the default for the existing widget-test pins and any
///   opt-out callers) the helper emits no `E2E_TIMING` / `E2E_COUNTER` lines.
Future<void> e2eAdvanceGameStartIntroUntilDismissed(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = const Duration(seconds: 15),
  String phaseName = kE2eDefaultAdvanceGameStartIntroPhase,
}) async {
  final sw = Stopwatch()..start();
  final deadline = DateTime.now().add(timeout);
  var idlePollMs = 25;
  var iterations = 0;
  while (DateTime.now().isBefore(deadline)) {
    iterations += 1;
    perf?.bumpCounter(
      kE2eAdvanceGameStartIntroIterationsCounter,
      meta: 'phase=$phaseName',
    );
    if (!e2eGameStartIntroBlocksUi(tester)) {
      perf?.timing(
        phaseName,
        sw.elapsed,
        meta: iterations == 1 ? 'result=already_dismissed' : 'result=advanced',
      );
      return;
    }
    if (find.byType(GameStartIntroLoadingIndicator).evaluate().isNotEmpty) {
      await tester.pump(Duration(milliseconds: idlePollMs));
      idlePollMs = e2eAdaptivePollRampAfterIdle(idlePollMs);
      continue;
    }
    final overlay = find.byType(GameStartIntroOverlay);
    var tapped = false;
    for (final label in kE2eGameStartIntroControlLabels) {
      if (!e2eGameStartIntroBlocksUi(tester)) {
        break;
      }
      final control = find
          .descendant(of: overlay, matching: find.text(label))
          .hitTestable();
      if (control.evaluate().isEmpty) {
        continue;
      }
      await tester.tap(control.first, warnIfMissed: false);
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => !e2eGameStartIntroBlocksUi(tester),
        timeout: kE2eDefaultIntroControlPostTapSettleTimeout,
        perf: perf,
        phaseName: 'pump_until_intro_advance_after_$label',
      );
      tapped = true;
      idlePollMs = 25;
    }
    if (!tapped) {
      await tester.pump(Duration(milliseconds: idlePollMs));
      idlePollMs = e2eAdaptivePollRampAfterIdle(idlePollMs);
    }
  }
  if (e2eGameStartIntroBlocksUi(tester)) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
    fail(
      'Timed out after ${timeout.inSeconds}s advancing game start intro. '
      'Last exception: ${tester.takeException()}',
    );
  }
  // Implicit success: the wall-clock deadline elapsed but the intro stopped
  // blocking on the very last iteration (rare, but observable in CI where
  // the loop's deadline check races a final tap). Attribute as
  // `result=advanced` — the helper still returned without the fail-path —
  // so the AC8 timing pipeline does not silently bucket the success into
  // `result=timeout`.
  perf?.timing(phaseName, sw.elapsed, meta: 'result=advanced');
}
