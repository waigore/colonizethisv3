import 'dart:math' as math;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared_dismiss_alert_dialog.dart';
import 'e2e_test_shared_dismiss_ct_dialog_shell_broad_sweep.dart';
import 'e2e_test_shared_dismiss_generic_ok.dart';
import 'e2e_test_shared_dismiss_snackbar.dart';

export 'e2e_test_shared_bundled_explore_failure.dart';
export 'e2e_test_shared_bundled_explore_retry.dart';
export 'e2e_test_shared_civilian_work_tile_pick.dart';
export 'e2e_test_shared_diagnostics.dart';
export 'e2e_test_shared_dismiss_alert_dialog.dart';
export 'e2e_test_shared_dismiss_ct_dialog_shell.dart';
export 'e2e_test_shared_dismiss_ct_dialog_shell_broad_sweep.dart';
export 'e2e_test_shared_dismiss_ct_dialog_shell_escalation.dart';
export 'e2e_test_shared_dismiss_generic_ok.dart';
export 'e2e_test_shared_dismiss_snackbar.dart';
export 'e2e_test_shared_expansion_tile.dart';
export 'e2e_test_shared_final_naval_reach_check.dart';
export 'e2e_test_shared_first_fleet_move.dart';
export 'e2e_test_shared_fleet_reach_loop_test_total_meta.dart';
export 'e2e_test_shared_fleet_reach_nw_predicates.dart';
export 'e2e_test_shared_fleet_reach_scenario_preamble.dart';
export 'e2e_test_shared_integration_test_bootstrap.dart';
export 'e2e_test_shared_next_turn_advance.dart';
export 'e2e_test_shared_panel_open_outer_loop.dart';
export 'e2e_test_shared_panel_open_post_tap_probe.dart';
export 'e2e_test_shared_panel_open_sheet_close.dart';
export 'e2e_test_shared_panel_open_trigger_attempt.dart';
export 'e2e_test_shared_panel_text_match.dart';
export 'e2e_test_shared_panels.dart';
export 'e2e_test_shared_region_tabs.dart';
export 'e2e_test_shared_standard_scenario_opener.dart';

/// Next interval after an idle poll pump in E2E busy-wait loops (25→50→75→100 ms).
/// Aligns with [e2eWaitUntilFound] backoff (`SPEC/program/e2e-integration-tests.md`, #2336).
int e2eAdaptivePollRampAfterIdle(int previousMs) {
  if (previousMs < 100) {
    return previousMs + 25;
  }
  return 100;
}

class E2ePerfLog {
  E2ePerfLog(this.testName);

  final String testName;
  final Map<String, int> _counters = <String, int>{};

  void bumpCounter(String name, {int by = 1, String? meta}) {
    _counters[name] = (_counters[name] ?? 0) + by;
    final metaPart = meta == null ? '' : '|meta=$meta';
    debugPrint(
      'E2E_COUNTER|test=$testName|name=$name|value=${_counters[name]}$metaPart',
    );
  }

  void timing(String phase, Duration elapsed, {String? meta}) {
    final metaPart = meta == null ? '' : '|meta=$meta';
    debugPrint(
      'E2E_TIMING|test=$testName|phase=$phase|ms=${elapsed.inMilliseconds}$metaPart',
    );
  }
}

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
    for (final label in ['Continue', 'I shall.']) {
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
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'pump_until_intro_advance_after_$label',
      );
      tapped = true;
      idlePollMs = 25;
      break;
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

Future<void> e2ePumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// Next idle poll step for E2E `while` loops (GitHub #2336 / AC5): doubles the
/// previous pump duration until [maxMs] to reduce wasted frames on headless Linux.
int e2eNextIdlePollStepMs(int currentMs, {int maxMs = 500}) {
  final next = currentMs * 2;
  return next > maxMs ? maxMs : next;
}

/// Pumps with [e2eAdaptivePollRampAfterIdle] pacing until [finder] matches
/// nothing or [timeout] elapses.
///
/// Returns immediately when the finder is already empty. On timeout, returns
/// without throwing so callers can treat the wait as best-effort post-dismiss
/// settle (GitHub #2336 / AC5).
Future<void> e2ePumpUntilFinderEmpty(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
}) async {
  final sw = Stopwatch()..start();
  if (finder.evaluate().isEmpty) {
    return;
  }
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    await tester.pump(Duration(milliseconds: stepMs));
    if (finder.evaluate().isEmpty) {
      return;
    }
    stepMs = e2eAdaptivePollRampAfterIdle(stepMs);
  }
}

/// Default cap for bottom-sheet close polling (GitHub #2336).
const Duration kE2eDefaultBottomSheetCloseTimeout = Duration(seconds: 5);

/// Closes an open [BottomSheet] by issuing a single back-route pop and polling
/// until the sheet leaves the widget tree.
///
/// Shared by full-turn and fleet E2E; [overallTimeout] defaults to
/// [kE2eDefaultBottomSheetCloseTimeout] (previous per-file caps).
///
/// **Why pop once:** the previous implementation called
/// [tester.binding.handlePopRoute] on every poll iteration, even while the
/// dismiss animation was already running. A single pop initiates the dismiss;
/// subsequent calls are wasted work and prevent the loop from short-circuiting
/// on the post-dismiss frame. The replacement pops once, then delegates to
/// [e2ePumpUntilConditionOrIdle] so the loop exits the moment the sheet is
/// gone. If the first pop is dropped (rare; route stack stale), a single
/// retry pop is issued before falling back to the failure path. Refs
/// GitHub #2336 (`pump-reduction` slice).
Future<void> e2eCloseBottomSheet(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration overallTimeout = kE2eDefaultBottomSheetCloseTimeout,
}) async {
  perf?.bumpCounter('close_bottom_sheet_calls');
  bool anyPanelOpen() => find.byType(BottomSheet).evaluate().isNotEmpty;

  if (!anyPanelOpen()) {
    return;
  }

  final sw = Stopwatch()..start();
  await tester.binding.handlePopRoute();
  final firstWindow = overallTimeout < const Duration(seconds: 2)
      ? overallTimeout
      : const Duration(seconds: 2);
  if (await e2ePumpUntilConditionOrIdle(
    tester,
    () => !anyPanelOpen(),
    timeout: firstWindow,
    perf: perf,
    phaseName: 'pump_until_bottom_sheet_closed_after_pop',
  )) {
    perf?.timing('close_bottom_sheet', sw.elapsed);
    return;
  }
  if (!anyPanelOpen()) {
    perf?.timing('close_bottom_sheet', sw.elapsed);
    return;
  }
  // First pop may be dropped if the route stack changed mid-frame (e.g. an
  // overlay raced the pop). Retry once, then wait out the remaining budget.
  await tester.binding.handlePopRoute();
  final remaining = overallTimeout - sw.elapsed;
  if (remaining > Duration.zero) {
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => !anyPanelOpen(),
      timeout: remaining,
      perf: perf,
      phaseName: 'pump_until_bottom_sheet_closed_after_retry',
    );
  }
  if (!anyPanelOpen()) {
    perf?.timing('close_bottom_sheet', sw.elapsed);
    return;
  }

  fail(
    'Timed out after ${overallTimeout.inSeconds}s closing bottom sheet; '
    'panels remained visible',
  );
}

/// Ensures [trigger] is visible (best-effort) and taps its first
/// hit-testable element, falling back to the raw [trigger] when no
/// hit-testable element resolves.
///
/// Encodes the defensive rail/marker tap sequence shared by
/// [e2eOpenCivilianPanel], [e2eOpenNavalPanel], and [e2eOpenProductionPanel]
/// so each panel opener gains uniform off-screen-trigger resilience
/// (Refs GitHub #2336 AC1 / AC2 / AC10; PR #2555 history — the naval rail
/// tap could land off-target until `ensureVisible` + hit-testable resolve
/// was added inline, while the civilian opener kept the brittle raw-tap
/// path that drops the tap when the rail button is rendered but pushed
/// outside the viewport by a transient overlay).
///
/// Contract:
///
/// - When [trigger] resolves to zero elements, returns `false` without
///   tapping. The caller remains responsible for the upstream presence
///   check; the panel-opener `tryOpen` closures already gate on
///   `trigger.evaluate().isNotEmpty` before calling, so this no-op branch
///   is a safety net rather than the primary path.
/// - Calls [WidgetTester.ensureVisible] inside a `try`/`catch (_)` so an
///   `ensureVisible` failure (for example when the trigger is not in any
///   `Scrollable`) does not throw past the helper.
/// - Resolves the tap target via `trigger.hitTestable()`; falls back to
///   the raw [trigger] when no element is hit-testable so the tap still
///   fires from the same canonical position the legacy opener bodies
///   used.
/// - Taps the first resolved element with `warnIfMissed: false` to match
///   the existing panel-opener contract.
/// - Returns `true` when the tap was issued.
Future<bool> e2eEnsureVisibleAndTapHitTestable(
  WidgetTester tester,
  Finder trigger,
) async {
  if (trigger.evaluate().isEmpty) {
    return false;
  }
  try {
    await tester.ensureVisible(trigger);
  } catch (_) {}
  final hit = trigger.hitTestable();
  final target = hit.evaluate().isNotEmpty ? hit : trigger;
  await tester.tap(target.first, warnIfMissed: false);
  return true;
}

/// Awaits one of [primary] / [secondary] becoming hit-testable before the
/// outer panel-opener loop attempts a [e2eEnsureVisibleAndTapHitTestable]
/// tap, defending against transient overlays that cover the rail/marker
/// trigger.
///
/// Lifts the inline rail/marker hit-testable wait that the naval opener
/// has carried since PR #2555 (`wait_until_naval_rail_hit_testable` /
/// `wait_until_naval_marker_hit_testable` phases) into a single shared
/// primitive so [e2eOpenCivilianPanel], [e2eOpenNavalPanel], and
/// [e2eOpenProductionPanel] gain identical pre-tap settle semantics.
/// Before this lift, the civilian opener tapped a rail that might not be
/// hit-testable (relying on `e2eEnsureVisibleAndTapHitTestable`'s
/// best-effort scroll-into-view) and let the outer adaptive-poll loop
/// retry on miss; production took the same shape. The naval opener
/// instead waited up to 5 s for one of `[empireRailButton, markerButton]`
/// to become hit-testable before tapping. Refs GitHub #2336 AC1 / AC10
/// (deferred slice from PR #2782).
///
/// Contract:
///
/// - Short-circuits with no pump and no perf event when either [primary]
///   or [secondary] is already hit-testable. The fast-path keeps the
///   no-overlay common case at byte-equivalent cost vs the pre-#2555
///   civilian/production openers.
/// - Otherwise delegates to [e2eWaitUntilAnyFinderHitTestable] with the
///   provided [timeout] and [phaseName]. That helper polls with adaptive
///   backoff (25 → 500 ms cap) and emits `result=found{,_immediate,_at_
///   timeout}` / `result=timeout` perf timings on [perf]. On final
///   timeout it fails via [fail] with the same diagnostic message the
///   inline naval opener has surfaced since PR #2555 (`Timed out after
///   ${timeout.inSeconds}s waiting for any of ...`), so a regression that
///   left the trigger permanently obscured fails with a useful message
///   inside the inner wait rather than silently consuming the outer
///   opener loop's full budget.
/// - When [secondary] is `null`, only [primary] is polled (production
///   opener path — no `markerButton` concept).
Future<void> e2eAwaitPanelOpenerRailHitTestable(
  WidgetTester tester, {
  required Finder primary,
  Finder? secondary,
  Duration timeout = const Duration(seconds: 5),
  E2ePerfLog? perf,
  required String phaseName,
}) async {
  if (primary.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  if (secondary != null && secondary.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  final finders = <Finder>[primary, ?secondary];
  await e2eWaitUntilAnyFinderHitTestable(
    tester,
    finders,
    timeout: timeout,
    perf: perf,
    phaseName: phaseName,
  );
}

/// Civilian work-menu labels surfaced after tapping an `Assign` button in
/// the civilian panel (`Build improvement`, `Prospect`, `Explore`).
///
/// Single source of truth consumed by [e2eAwaitCivilianWorkMenuMounted] (and
/// transitively by [e2eTapFirstAssignInCivilianPanel] and
/// [e2eTapAssignOnCivilianRowWithTitle]) so a label drift in production
/// surfaces in one place. Pinned by the widget test in
/// `app/test/e2e_await_civilian_work_menu_mounted_test.dart` to keep the
/// label set deterministic across SDK upgrades. Refs GitHub #2336 AC1 / AC2 /
/// Bottleneck 6.
const List<String> kE2eCivilianWorkMenuLabels = <String>[
  'Build improvement',
  'Prospect',
  'Explore',
];

/// Default timeout for [e2eAwaitCivilianWorkMenuMounted]. Matches the legacy
/// pre-lift inline `Duration(seconds: 5)` budget shared by
/// [e2eTapFirstAssignInCivilianPanel] and [e2eTapAssignOnCivilianRowWithTitle]
/// (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
const Duration kE2eDefaultCivilianWorkMenuMountTimeout = Duration(seconds: 5);

/// Default phase label emitted by [e2eAwaitCivilianWorkMenuMounted] — matches
/// the legacy inline `wait_until_civilian_work_menu` phase used by
/// [e2eTapFirstAssignInCivilianPanel] before the lift. Callers tapping a
/// title-scoped `Assign` row pass `wait_until_civilian_work_menu_row` to
/// preserve the historical label split.
const String kE2eDefaultCivilianWorkMenuMountPhase =
    'wait_until_civilian_work_menu';

/// Polls until any civilian work-menu label
/// (one of [kE2eCivilianWorkMenuLabels]) becomes hit-testable, using
/// [e2eWaitUntilAnyFinderHitTestable] adaptive backoff (25 → 500 ms cap).
///
/// Lifted from the inline post-`Assign`-tap waits formerly duplicated in
/// [e2eTapFirstAssignInCivilianPanel] (`wait_until_civilian_work_menu`) and
/// [e2eTapAssignOnCivilianRowWithTitle] (`wait_until_civilian_work_menu_row`).
/// Both call sites now delegate here so the label set, the 5 s default
/// timeout, and the underlying poll cadence have a single source of truth.
/// Future callers that tap an `Assign` button (or an upstream affordance that
/// equivalently mounts the work menu) compose this helper directly without
/// duplicating the recipe. Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
///
/// Contract:
///
/// - Builds the finder list from [kE2eCivilianWorkMenuLabels] in declaration
///   order so the existential short-circuit inside
///   [e2eWaitUntilAnyFinderHitTestable] resolves in a deterministic order
///   (`Build improvement` first), matching the pre-lift inline blocks.
/// - On timeout, propagates the [TestFailure] raised by
///   [e2eWaitUntilAnyFinderHitTestable] verbatim — the lift does not change
///   fail-fast semantics. The accompanying widget-test pin in
///   `app/test/e2e_await_civilian_work_menu_mounted_test.dart` exercises both
///   the immediate-found fast path and the timeout path so a regression here
///   surfaces in PR checks rather than as a silent late-timeout in the Linux
///   integration suite.
/// - Emits perf timings via the inner [e2eWaitUntilAnyFinderHitTestable] call
///   only — no extra `wait_until_civilian_work_menu_*` counter so repeated
///   waits in a single scenario are still attributable to the existing
///   `wait_until_any_calls` counter.
Future<void> e2eAwaitCivilianWorkMenuMounted(
  WidgetTester tester, {
  Duration timeout = kE2eDefaultCivilianWorkMenuMountTimeout,
  String phaseName = kE2eDefaultCivilianWorkMenuMountPhase,
  E2ePerfLog? perf,
}) async {
  final finders = <Finder>[
    for (final label in kE2eCivilianWorkMenuLabels) find.text(label),
  ];
  await e2eWaitUntilAnyFinderHitTestable(
    tester,
    finders,
    timeout: timeout,
    perf: perf,
    phaseName: phaseName,
  );
}

/// Taps the first visible **Assign** in the civilian panel work menu (GitHub #2336 H9).
///
/// Settles + taps the resolved Assign via [e2eEnsureVisibleAndTapHitTestable]
/// so the call site picks up the shared `ensureVisible` + `hitTestable()`
/// resolve recipe (the same path the panel-opener rail/marker taps already
/// use). The inline `await tester.pump();` between `ensureVisible` and
/// `tap` is removed because the lifted helper does not insert a settle
/// frame; the shared helper instead resolves `hitTestable()` first and
/// falls back to the raw finder, which is the canonical AC5 / AC10
/// adaptive-pre-tap recipe documented in the e2e-ui-stability rule
/// (Refs GitHub #2336 AC5 / AC10 / Bottleneck 6).
Future<void> e2eTapFirstAssignInCivilianPanel(WidgetTester tester) async {
  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  final assign = find.descendant(of: root, matching: find.text('Assign'));
  expect(assign, findsWidgets);
  final firstAssign = assign.first;
  await tester.scrollUntilVisible(
    firstAssign,
    120,
    scrollable: panelScrollable,
  );
  final didTap = await e2eEnsureVisibleAndTapHitTestable(tester, firstAssign);
  expect(
    didTap,
    isTrue,
    reason:
        'First Assign in civilian panel resolved to zero elements after the '
        'findsWidgets guard passed; the downstream work-menu wait would race '
        'a not-yet-tapped Assign button.',
  );
  // Lifted post-tap work-menu wait: see [e2eAwaitCivilianWorkMenuMounted] for
  // the canonical label set and 5 s timeout. The default phase name preserves
  // the legacy inline `wait_until_civilian_work_menu` label byte-for-byte.
  // Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
  await e2eAwaitCivilianWorkMenuMounted(tester);
}

/// Taps a civilian work-order label (for example `Build improvement`,
/// `Prospect`, or `Explore`) inside the open civilian-panel work menu, using
/// [e2eEnsureVisibleAndTapHitTestable] so the tap fires from a canonical
/// hit-testable position even when the label is rendered slightly off-screen
/// by a transient overlay or a small surface.
///
/// Replaces the legacy raw `tester.tap(find.text(workOrderLabel))` taps in
/// `new_game_full_turn_e2e_test.dart` that ran right after
/// [e2eTapFirstAssignInCivilianPanel] / [e2eTapAssignOnCivilianRowWithTitle].
/// Those tap-Assign helpers only guarantee that *one* of
/// `{Build improvement, Prospect, Explore}` is hit-testable on return — the
/// **specific** label the caller wants may still be obscured (e.g. behind a
/// soft keyboard, a transient bottom sheet, or a viewport that needs scrolling)
/// at the instant of the tap. Wrapping the tap in this helper enforces the
/// e2e-ui-stability rule's *verify visibility before interaction* directive
/// at the same call sites that previously skipped it. Refs GitHub #2336 AC1 /
/// AC2 / AC10; `colonizethis-e2e-ui-stability.mdc`.
///
/// Contract:
///
/// - Throws [TestFailure] via [expect] when no `Text` widget matching
///   [workOrderLabel] is mounted at all, so the surrounding scenario fails
///   fast at the offending step rather than burning the downstream
///   work-tile timeout against an unmounted work menu (the same fail-fast
///   contract documented on [e2eTapFirstAssignInCivilianPanel]).
/// - Delegates to [e2eEnsureVisibleAndTapHitTestable], which best-effort
///   scrolls the label into view, prefers the `hitTestable()` resolution,
///   and falls back to the raw finder when no hit-testable element resolves
///   (the same path the panel-opener rail/marker taps already use).
/// - Throws [TestFailure] when [e2eEnsureVisibleAndTapHitTestable] reports
///   no tap was issued (zero-element resolution after the presence assertion
///   passes — only possible under unusual race conditions where the label
///   vanishes between the assertion and the resolve). This keeps the helper
///   sound for callers that rely on a tap actually firing before the
///   downstream work-tile pick begins.
Future<void> e2eTapCivilianWorkOrderLabel(
  WidgetTester tester,
  String workOrderLabel,
) async {
  final label = find.text(workOrderLabel);
  expect(
    label,
    findsWidgets,
    reason:
        'Civilian work-order label "$workOrderLabel" not found in the open '
        'work menu. Either the preceding Assign tap did not mount the work '
        'menu, or the label name has drifted from the production scaffold.',
  );
  final didTap = await e2eEnsureVisibleAndTapHitTestable(tester, label);
  expect(
    didTap,
    isTrue,
    reason:
        'Civilian work-order label "$workOrderLabel" was present but the '
        'shared ensureVisible/hit-testable tap path issued no tap; the '
        'downstream work-tile pick would race a not-yet-tapped label.',
  );
}

/// Taps **Assign** on a [ListTile] whose title is exactly [unitTypeTitle] (GitHub #2336 H9).
Future<void> e2eTapAssignOnCivilianRowWithTitle(
  WidgetTester tester,
  String unitTypeTitle,
) async {
  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  final titlesInList = find.descendant(
    of: listView,
    matching: find.text(unitTypeTitle),
  );
  final sw = Stopwatch()..start();
  while (titlesInList.evaluate().isEmpty &&
      sw.elapsed < const Duration(seconds: 20)) {
    await tester.drag(panelScrollable, const Offset(0, -120));
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => titlesInList.evaluate().isNotEmpty,
      timeout: const Duration(milliseconds: 200),
      phaseName: 'pump_until_civilian_title_visible_after_scroll_drag',
    );
  }
  expect(
    titlesInList,
    findsWidgets,
    reason:
        'Timed out scrolling civilian panel for a visible "$unitTypeTitle" row',
  );
  final n = titlesInList.evaluate().length;
  for (var i = 0; i < n; i++) {
    final titleAt = titlesInList.at(i);
    await tester.scrollUntilVisible(titleAt, 120, scrollable: panelScrollable);
    await tester.ensureVisible(titleAt);
    final listTile = find.ancestor(
      of: titleAt,
      matching: find.byType(ListTile),
    );
    final assign = find.descendant(of: listTile, matching: find.text('Assign'));
    if (assign.evaluate().isEmpty) {
      continue;
    }
    final assignHit = assign.first;
    final didTap = await e2eEnsureVisibleAndTapHitTestable(tester, assignHit);
    expect(
      didTap,
      isTrue,
      reason:
          'Assign on civilian row "$unitTypeTitle" resolved to zero elements '
          'after the per-row Assign descendant guard passed; the downstream '
          'work-menu wait would race a not-yet-tapped Assign button.',
    );
    // Lifted post-tap work-menu wait: see [e2eAwaitCivilianWorkMenuMounted].
    // The legacy `wait_until_civilian_work_menu_row` phase label is preserved
    // explicitly so the title-scoped sibling helper stays distinguishable in
    // perf-timing dumps (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
    await e2eAwaitCivilianWorkMenuMounted(
      tester,
      phaseName: 'wait_until_civilian_work_menu_row',
    );
    return;
  }
  fail('No idle Assign row for unit type "$unitTypeTitle" in civilian panel');
}

/// Dismisses snackbars, generic OK dialogs, [AlertDialog] actions, bottom sheets,
/// and [CtDialogShell] overlays (union of fleet + full-turn E2E paths).
Future<void> e2eDismissTransientUi(
  WidgetTester tester, {
  E2ePerfLog? perf,
}) async {
  perf?.bumpCounter('dismiss_transient_ui_calls');
  if (e2eGameStartIntroBlocksUi(tester)) {
    await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);
    return;
  }
  // Shared SnackBar dismissal: lifted into [e2eDismissSnackBarIfPresent]
  // so the hit-testable-action tap recipe is single-source-of-truth and
  // pinned by widget tests. The pre-lift inline block checked
  // `snackAction.hitTestable()` for presence but tapped `snackAction.first`
  // (the first [TextButton] without the hit-testable filter), which could
  // miss the tap when the first [TextButton] was covered by another overlay
  // while a later one remained hit-testable. The lifted form taps the
  // hit-testable filter's first match — matching the adjacent AlertDialog
  // and CtDialogShell branches below that already use the filtered finder
  // for both check and tap. Refs GitHub #2336 AC1 / AC2 / AC10.
  if (await e2eDismissSnackBarIfPresent(tester, perf: perf)) {
    return;
  }
  // Shared top-level OK dismissal: lifted into [e2eDismissGenericOkIfPresent]
  // so the legacy `find.text('OK').hitTestable()` tap + 2 s
  // `e2ePumpUntilFinderEmpty` recipe is single-source-of-truth and pinned by
  // widget tests. The pre-lift inline block lived between the SnackBar and
  // AlertDialog branches and targeted a top-level OK button (not nested in
  // an [AlertDialog]) — a stray confirmation banner above the map HUD
  // between phases. The lifted form preserves the legacy English literal
  // (`OK`), the 2 s dismiss budget, and the post-tap return semantics.
  // Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
  if (await e2eDismissGenericOkIfPresent(tester, perf: perf)) {
    return;
  }
  // Shared AlertDialog dismissal: lifted into [e2eDismissAlertDialogIfPresent]
  // so the labelled-button-priority tap + `handlePopRoute` fallback recipe is
  // single-source-of-truth and pinned by widget tests. The lifted form
  // preserves the legacy English label priority (`Close` → `OK` → `Cancel` →
  // `Yes`), the 2 s dismiss budget, and the unconditional `handlePopRoute`
  // fallback when no labelled button is hit-testable. Refs GitHub #2336
  // AC1 / AC2 / Bottleneck 6.
  if (await e2eDismissAlertDialogIfPresent(tester, perf: perf)) {
    return;
  }
  if (find.byType(BottomSheet).evaluate().isNotEmpty) {
    await e2eCloseBottomSheet(tester, perf: perf);
  }
  // Shared CtDialogShell broad-sweep dismissal: lifted into
  // [e2eDismissCtDialogShellBroadSweepIfPresent] so the English-only
  // close-candidate sweep (`Cancel` → `Close` → `Icons.close` →
  // `Icons.arrow_back`) plus the `tester.binding.handlePopRoute()` fallback
  // are single-source-of-truth and pinned by widget tests. After this lift,
  // every overlay branch of the broad-spectrum sweep delegates to a focused
  // shared helper — no inline dismissal recipes remain in this function's
  // overlay branches. Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
  await e2eDismissCtDialogShellBroadSweepIfPresent(tester, perf: perf);
}

Future<void> e2eWaitUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration diagnoseAfter = Duration.zero,
  E2ePerfLog? perf,
  String phaseName = 'wait_until_found',
}) async {
  if (finder.evaluate().isNotEmpty) {
    perf?.bumpCounter('wait_until_found_calls', meta: 'phase=$phaseName');
    perf?.timing(phaseName, Duration.zero, meta: 'result=found_immediate');
    return;
  }
  final sw = Stopwatch()..start();
  perf?.bumpCounter('wait_until_found_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    if (finder.evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found');
      return;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = math.min(500, stepMs * 2);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have made [finder] non-empty just as `sw.elapsed` crossed
  // [timeout], so the loop's pre-pump check would never re-evaluate. Match
  // [e2ePumpUntilConditionOrIdle]'s post-pump-check pattern so a successful
  // late pump still returns success instead of falling through to `fail()`.
  // Refs GitHub #2336 AC5 (adaptive polling) / busy-wait final-check fix.
  if (finder.evaluate().isNotEmpty) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=found_at_timeout');
    return;
  }
  if (diagnoseAfter > Duration.zero) {
    await e2ePumpFor(tester, diagnoseAfter);
    if (finder.evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found_during_diagnose');
      return;
    }
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for $finder. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Waits until the shell shows a tappable **New Game** control (replaces a
/// fixed post-[bootstrapForIntegrationTest] pump; GitHub #2336 / AC4–AC5).
Future<void> e2eWaitForNewGameEntry(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 15),
  E2ePerfLog? perf,
}) async {
  await e2eWaitUntilFound(
    tester,
    find.text('New Game').hitTestable(),
    timeout: timeout,
    perf: perf,
    phaseName: 'wait_for_new_game_entry',
  );
}

/// Pumps until [condition] returns true, evaluating [condition] before the
/// first pump and using exponential backoff on pump intervals (same cap as
/// [e2eWaitUntilFound]). Refs GitHub #2336 (`pumpUntil` helper).
Future<void> e2ePumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
  E2ePerfLog? perf,
  String phaseName = 'pump_until',
}) async {
  final sw = Stopwatch()..start();
  perf?.bumpCounter('pump_until_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    if (condition()) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=met');
      return;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = math.min(500, stepMs * 2);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have flipped [condition] just as `sw.elapsed` crossed
  // [timeout], so the loop's pre-pump check would never re-evaluate. Match
  // [e2ePumpUntilConditionOrIdle]'s post-pump-check pattern so a successful
  // late pump still returns success instead of falling through to `fail()`.
  // Refs GitHub #2336 AC5 (adaptive polling) / busy-wait final-check fix.
  if (condition()) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=met_at_timeout');
    return;
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s in e2ePumpUntil ($phaseName). '
    'Last exception: ${tester.takeException()}',
  );
}

/// Pumps until [condition] returns true or [timeout] elapses.
///
/// Evaluates [condition] before the first pump. Uses
/// [e2eAdaptivePollRampAfterIdle] pacing (25→50→75→100 ms cap). Returns whether
/// the condition became true; does **not** throw when [timeout] expires
/// (best-effort post-tap settle; GitHub #2336).
Future<bool> e2ePumpUntilConditionOrIdle(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
  E2ePerfLog? perf,
  String phaseName = 'pump_until_condition_or_idle',
}) async {
  final sw = Stopwatch()..start();
  perf?.bumpCounter(
    'pump_until_condition_or_idle_calls',
    meta: 'phase=$phaseName',
  );
  if (condition()) {
    perf?.timing(phaseName, sw.elapsed, meta: 'result=immediate');
    return true;
  }
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    await tester.pump(Duration(milliseconds: stepMs));
    if (condition()) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=met');
      return true;
    }
    stepMs = e2eAdaptivePollRampAfterIdle(stepMs);
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  return false;
}

// `e2eOldWorldRegionChipAppearsSelected`,
// `e2eNewWorldRegionChipAppearsSelected`,
// `e2eTapNewWorldRegionTabIfPresent`, and `e2eTapOldWorldRegionTab` live in
// `e2e_test_shared_region_tabs.dart` and are surfaced from this barrel via
// the `export` directive at the top of the file so the map region-tab
// predicate + tap-and-settle group stays separable from the panel-opener
// and panel-action helpers in this file. The extraction keeps this file
// under the repo-lint `dart_file_non_comment_line_size` budget
// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines) and matches the
// barrel-re-export pattern already used by the fleet-reach NW predicates
// (`e2e_test_shared_fleet_reach_nw_predicates.dart`), the panel-opener
// helpers (`e2e_test_shared_panel_open_*.dart`), and the panel-action
// helpers (`e2e_test_shared_panel_text_*.dart`). Refs GitHub #2336 AC1 /
// AC2 / Bottleneck 6.

// `e2eTextLooksLikeNewWorldLocationLine`,
// `e2eNavalPanelShowsNonHomeFleetInNewWorld`,
// `e2eNonHomeHumanFleetInNewWorldFromCtSnapshot`,
// `e2eFleetReachDoneFromCtSnapshotOnly`,
// `e2eHarnessDetectsNonHomeFleetInNewWorld`,
// `e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot`,
// `e2eNwCoastalProvincesAdjacentToFleetSea`,
// `e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot`, and
// `e2eExploreAssignEnabledFromCivilianSnapshot` live in
// `e2e_test_shared_fleet_reach_nw_predicates.dart` and are surfaced from this
// barrel via the `export` directive at the top of the file so the
// snapshot-first / widget-fallback fleet-in-NW detection group stays
// separable from the panel-opener and panel-action helpers in this file.
// The extraction keeps this file under the repo-lint
// `dart_file_non_comment_line_size` budget
// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines) and matches the
// barrel-re-export pattern already used by the panel-opener helpers
// (`e2e_test_shared_panel_open_*.dart`) and the panel-action helpers
// (`e2e_test_shared_panel_text_*.dart`). Refs GitHub #2336 AC1 / AC2 /
// Bottleneck 6.

/// Returns after the first [Finder] has at least one hit-testable match.
Future<void> e2eWaitUntilAnyFinderHitTestable(
  WidgetTester tester,
  List<Finder> finders, {
  required Duration timeout,
  E2ePerfLog? perf,
  String phaseName = 'wait_until_any',
}) async {
  if (finders.isEmpty) {
    return;
  }
  for (final finder in finders) {
    if (finder.hitTestable().evaluate().isNotEmpty) {
      perf?.bumpCounter('wait_until_any_calls', meta: 'phase=$phaseName');
      perf?.timing(phaseName, Duration.zero, meta: 'result=found_immediate');
      return;
    }
  }
  final sw = Stopwatch()..start();
  perf?.bumpCounter('wait_until_any_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    for (final finder in finders) {
      if (finder.hitTestable().evaluate().isNotEmpty) {
        perf?.timing(phaseName, sw.elapsed, meta: 'result=found');
        return;
      }
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = math.min(500, stepMs * 2);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have made one of [finders] hit-testable just as `sw.elapsed`
  // crossed [timeout], so the loop's pre-pump check would never re-evaluate.
  // Match [e2ePumpUntilConditionOrIdle]'s post-pump-check pattern so a
  // successful late pump still returns success instead of falling through to
  // `fail()`. Refs GitHub #2336 AC5 (adaptive polling) / busy-wait
  // final-check fix.
  for (final finder in finders) {
    if (finder.hitTestable().evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found_at_timeout');
      return;
    }
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for any of $finders. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Post-confirm turn resolution wait aligned with the 15s usability budget
/// (`colonizethis-turn-resolution-budget.mdc`).
const Duration kE2eNextTurnResolutionTimeout = Duration(seconds: 15);

/// Default 5-minute wall-clock cap per E2E scenario path.
///
/// Matches the **PR runtime rule** in `SPEC/program/e2e-integration-tests.md`
/// § Determinism and the `colonizethis-e2e-ui-stability.mdc` 5-minute rule:
/// any single integration-test scenario that exceeds this cap must fail fast
/// and emit timing markers so the regression is attributable.
const Duration kE2eMaxWallClock = Duration(minutes: 5);

/// Returns a callable wall-clock guard for the start of an E2E scenario.
///
/// Pattern:
///
/// ```dart
/// final wallClock = Stopwatch()..start();
/// final ensureUnderWallClock = e2eMakeWallClockGuard(
///   testName: 'new_game_full_turn',
///   stopwatch: wallClock,
/// );
/// // ... checkpoint after each major phase ...
/// ensureUnderWallClock('after bootstrap');
/// ```
///
/// The returned function fails the surrounding test (via `fail`) when the
/// elapsed wall-clock time exceeds [cap]. [testName] and the per-call `step`
/// label are emitted in the failure message so a regression is attributable
/// to a specific checkpoint and scenario, matching the fail-fast contract
/// documented in `SPEC/program/e2e-integration-tests.md` § Determinism
/// (Refs GitHub #2336 / `colonizethis-e2e-ui-stability.mdc`).
void Function(String step) e2eMakeWallClockGuard({
  required String testName,
  required Stopwatch stopwatch,
  Duration cap = kE2eMaxWallClock,
}) {
  return (String step) {
    if (stopwatch.elapsed > cap) {
      fail(
        '$testName exceeded ${cap.inMinutes} minute wall clock '
        'at $step (elapsed=${stopwatch.elapsed.inSeconds}s).',
      );
    }
  };
}

/// Returns a [Finder] matching every `RadioListTile<…>` widget that is a
/// descendant of any currently-mounted [AlertDialog].
///
/// Contract (issue #2336 AC1 / AC2):
///
///   - Composes `find.descendant(of: find.byType(AlertDialog), matching: …)`
///     so the search is scoped to dialog subtrees only — `RadioListTile`s
///     outside an [AlertDialog] (panels, settings sheets, etc.) are never
///     returned. Naval / civilian / production move dialogs all surface
///     destination tiles via `RadioListTile<…>`; scoping to [AlertDialog]
///     keeps the move-segment helpers from accidentally hitting a panel
///     radio.
///   - The matcher inspects [Widget.runtimeType] via `toString()` so it
///     accepts any generic instantiation
///     (`RadioListTile<String>`, `RadioListTile<int>`, etc.) without
///     pulling in the concrete type argument. The fleet-reach move dialog
///     parameterises radio tiles on the destination string id; binding to
///     `RadioListTile<String>` directly would silently miss future
///     dialogs that switch to a different parameter type.
///   - Pure — the function reads no globals, returns a new [Finder] on
///     every call, and never throws. The returned [Finder] is lazy and
///     only resolves against the active widget tree when iterated, which
///     keeps it safe to construct outside an `await tester.pump()`
///     boundary.
///
/// Mirrors the lifted public-name pattern used by
/// `e2eNonHomeHumanFleetInNewWorldFromCtSnapshot` and
/// `e2eNavalPanelShowsNonHomeFleetInNewWorld` so callers consume the
/// AC1 barrel (`e2e_helpers.dart`) only. A silent rename or accidental
/// scope-removal (matching every `RadioListTile` across the tree)
/// would re-introduce false positives in move-segment dialogs that
/// also host non-destination radios on the surrounding screen
/// (Refs `SPEC/program/e2e-integration-tests.md` § Determinism).
Finder e2eRadioListTilesInAlertDialogs() {
  return find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byWidgetPredicate(
      (w) => w.runtimeType.toString().startsWith('RadioListTile<'),
    ),
  );
}
