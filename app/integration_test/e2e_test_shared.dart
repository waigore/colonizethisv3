import 'dart:math' as math;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eCivilianPanelSnapshot, CtE2eNavalPanelSnapshot;
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        allProvinces,
        buildPlayerView,
        homeFleetIdFor,
        kWorkTargetExplore,
        provinceIdsAdjacentToSeaZone,
        regionIdForSeaZone;
import 'package:colonizethis_models/colonizethis_models.dart' show ProvinceId;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

export 'e2e_test_shared_bundled_explore_failure.dart';
export 'e2e_test_shared_bundled_explore_retry.dart';
export 'e2e_test_shared_civilian_work_tile_pick.dart';
export 'e2e_test_shared_diagnostics.dart';
export 'e2e_test_shared_dismiss_ct_dialog_shell.dart';
export 'e2e_test_shared_final_naval_reach_check.dart';
export 'e2e_test_shared_first_fleet_move.dart';
export 'e2e_test_shared_fleet_reach_loop_test_total_meta.dart';
export 'e2e_test_shared_fleet_reach_scenario_preamble.dart';
export 'e2e_test_shared_panel_open_post_tap_probe.dart';
export 'e2e_test_shared_panel_open_sheet_close.dart';
export 'e2e_test_shared_panels.dart';
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

/// Advances yarn intro lines/choices until the overlay no longer blocks taps.
///
/// The spinner / no-tap-target branches previously each paid a fixed 50 ms
/// pump per loop iteration. Both now share an [e2eAdaptivePollRampAfterIdle]
/// idle pump (25 → 50 → 75 → 100 ms cap) so a long spinner stretch settles
/// with adaptive backoff instead of constant 50 ms frames. The poll cadence
/// is reset to 25 ms whenever a tap advances the overlay or the loading
/// indicator clears, mirroring the prepump-free panel openers landed in this
/// PR. Refs GitHub #2336 AC5 / pump-reduction.
Future<void> e2eAdvanceGameStartIntroUntilDismissed(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  var idlePollMs = 25;
  while (DateTime.now().isBefore(deadline)) {
    if (!e2eGameStartIntroBlocksUi(tester)) {
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
    fail(
      'Timed out after ${timeout.inSeconds}s advancing game start intro. '
      'Last exception: ${tester.takeException()}',
    );
  }
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

/// Taps the first visible **Assign** in the civilian panel work menu (GitHub #2336 H9).
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
  await tester.ensureVisible(firstAssign);
  await tester.pump();
  await tester.tap(firstAssign);
  await e2eWaitUntilAnyFinderHitTestable(
    tester,
    <Finder>[
      find.text('Build improvement'),
      find.text('Prospect'),
      find.text('Explore'),
    ],
    timeout: const Duration(seconds: 5),
    phaseName: 'wait_until_civilian_work_menu',
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
    await tester.ensureVisible(assignHit);
    await tester.pump();
    await tester.tap(assignHit);
    await e2eWaitUntilAnyFinderHitTestable(
      tester,
      <Finder>[
        find.text('Build improvement'),
        find.text('Prospect'),
        find.text('Explore'),
      ],
      timeout: const Duration(seconds: 5),
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
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    final snackAction = find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(TextButton),
    );
    if (snackAction.hitTestable().evaluate().isNotEmpty) {
      await tester.tap(snackAction.first, warnIfMissed: false);
      await e2ePumpUntilFinderEmpty(
        tester,
        find.byType(SnackBar),
        timeout: const Duration(seconds: 2),
      );
      return;
    }
  }
  final ok = find.text('OK').hitTestable();
  if (ok.evaluate().isNotEmpty) {
    await tester.tap(ok.first, warnIfMissed: false);
    await e2ePumpUntilFinderEmpty(
      tester,
      find.text('OK').hitTestable(),
      timeout: const Duration(seconds: 2),
    );
    return;
  }
  if (find.byType(AlertDialog).evaluate().isNotEmpty) {
    for (final label in ['Close', 'OK', 'Cancel', 'Yes']) {
      final hit = find
          .descendant(of: find.byType(AlertDialog), matching: find.text(label))
          .hitTestable();
      if (hit.evaluate().isNotEmpty) {
        await tester.tap(hit.first, warnIfMissed: false);
        await e2ePumpUntilFinderEmpty(
          tester,
          find.byType(AlertDialog),
          timeout: const Duration(seconds: 2),
        );
        return;
      }
    }
    await tester.binding.handlePopRoute();
    await e2ePumpUntilFinderEmpty(
      tester,
      find.byType(AlertDialog),
      timeout: const Duration(seconds: 2),
    );
    return;
  }
  if (find.byType(BottomSheet).evaluate().isNotEmpty) {
    await e2eCloseBottomSheet(tester, perf: perf);
  }
  if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
    final closeCandidates = <Finder>[
      find.text('Cancel'),
      find.text('Close'),
      find.byIcon(Icons.close),
      find.byIcon(Icons.arrow_back),
    ];
    for (final candidate in closeCandidates) {
      final tappable = candidate.hitTestable();
      if (tappable.evaluate().isNotEmpty) {
        await tester.tap(tappable.first, warnIfMissed: false);
        await e2ePumpUntilFinderEmpty(
          tester,
          find.byType(CtDialogShell),
          timeout: const Duration(seconds: 2),
        );
        return;
      }
    }
    await tester.binding.handlePopRoute();
    await e2ePumpUntilFinderEmpty(
      tester,
      find.byType(CtDialogShell),
      timeout: const Duration(seconds: 2),
    );
  }
}

/// True when [tileElement] (an [ExpansionTile] element) hosts a
/// [RotationTransition] whose `turns.value` is past the expanded threshold.
///
/// Material's default [ExpansionTile] keeps the [Icons.expand_more] icon
/// mounted whether collapsed or expanded — only its [RotationTransition]
/// flips from `0.0` (collapsed) to `0.5` (expanded). The previous
/// `find.byIcon(Icons.expand_more).isEmpty` heuristic therefore never
/// detected expansion: the loop tapped the same tile up to 32 times,
/// burning the full 800 ms post-tap budget per outer iteration (~26 s
/// per call) without leaving the tile expanded. Reading the rotation
/// state directly is robust against future Material changes that swap the
/// icon for an `expand_less` variant — at 0.5 turns either icon counts as
/// expanded. Refs GitHub #2336 H10 / Bottleneck 6.
bool e2eExpansionTileIsExpanded(Element tileElement) {
  var expanded = false;
  void visit(Element e) {
    if (expanded) return;
    final w = e.widget;
    if (w is RotationTransition && w.turns.value > 0.4) {
      expanded = true;
      return;
    }
    e.visitChildren(visit);
  }

  tileElement.visitChildren(visit);
  return expanded;
}

/// Expands every currently collapsed [ExpansionTile] in the widget tree.
///
/// Reads each tile's [RotationTransition] state via
/// [e2eExpansionTileIsExpanded] so the helper:
/// 1. **Skips already-expanded tiles** (the previous icon-based check
///    misidentified all tiles as collapsed because [Icons.expand_more]
///    stays mounted under [RotationTransition]).
/// 2. **Taps exactly once per collapsed tile**, then polls until the
///    rotation crosses the expanded threshold (or the bounded budget
///    elapses) — no more 26 s no-op cycles per call.
/// 3. **Exits early** once no collapsed tile remains, mirroring the
///    documented "expand each once" contract.
///
/// Panel-rebuild safe: each outer iteration re-enumerates tiles after a
/// successful expand, so a list-view rebuild that shifts tile order does
/// not cause repeated taps on the same tile. Refs GitHub #2336.
Future<void> e2eExpandEachExpansionTileOnce(WidgetTester tester) async {
  for (var safety = 0; safety < 32; safety++) {
    final tiles = find.byType(ExpansionTile);
    final tileElements = tiles.evaluate().toList();
    if (tileElements.isEmpty) {
      return;
    }

    var expandedOne = false;
    for (var j = 0; j < tileElements.length; j++) {
      final tileElement = tileElements[j];
      if (e2eExpansionTileIsExpanded(tileElement)) {
        continue;
      }
      final tileAt = tiles.at(j);
      final expandIcon = find.descendant(
        of: tileAt,
        matching: find.byIcon(Icons.expand_more),
      );
      if (expandIcon.evaluate().isEmpty) {
        continue;
      }
      final iconHit = expandIcon.first;
      await tester.ensureVisible(iconHit);
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => expandIcon.hitTestable().evaluate().isNotEmpty,
        timeout: const Duration(milliseconds: 400),
        phaseName: 'pump_until_expand_icon_tappable',
      );
      await tester.tap(iconHit, warnIfMissed: false);
      await e2ePumpUntilConditionOrIdle(
        tester,
        () {
          final elements = tileAt.evaluate();
          if (elements.isEmpty) return false;
          return e2eExpansionTileIsExpanded(elements.single);
        },
        timeout: const Duration(milliseconds: 800),
        phaseName: 'pump_until_expansion_tile_open',
      );
      expandedOne = true;
      break;
    }
    if (!expandedOne) {
      return;
    }
  }
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

/// True when a [CtChoiceChip] labeled [AppLocalizations.region_oldWorld] exists
/// and is selected (fleet E2E region-tab settle; GitHub #2336).
bool e2eOldWorldRegionChipAppearsSelected(AppLocalizations l10n) {
  final want = l10n.region_oldWorld;
  for (final e in find.byType(CtChoiceChip).evaluate()) {
    final chip = e.widget as CtChoiceChip;
    final lw = chip.label;
    if (lw is Text && lw.data == want) {
      return chip.selected;
    }
  }
  return false;
}

/// True when the E2E-keyed New World region chip subtree shows a selected
/// [CtChoiceChip] (`game_map_controls.dart` / `kCtE2ERegionTabNewWorldKey`).
bool e2eNewWorldRegionChipAppearsSelected() {
  final root = find.byKey(kCtE2ERegionTabNewWorldKey);
  if (root.evaluate().isEmpty) {
    return false;
  }
  final chipFinder = find.descendant(
    of: root,
    matching: find.byType(CtChoiceChip),
  );
  if (chipFinder.evaluate().length != 1) {
    return false;
  }
  return (chipFinder.evaluate().single.widget as CtChoiceChip).selected;
}

/// Selects the New World map region via [kCtE2ERegionTabNewWorldKey] when
/// present, then awaits the chip flip via [e2ePumpUntilConditionOrIdle] so an
/// already-selected tab short-circuits without paying a fixed post-tap pump.
///
/// Lifted from the formerly private `_tapNewWorldRegionTabIfPresent` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336
/// AC1 / AC2). The helper is silent (no `fail`) when the keyed subtree is
/// absent so callers in scenarios that do not surface the map controls
/// (e.g. capital-panel-only paths) can compose it unconditionally.
///
/// Contract:
/// - **Already-selected short-circuit**: returns immediately without
///   tapping or pumping when [e2eNewWorldRegionChipAppearsSelected] is
///   already `true`. The fleet-reach turn loop calls this helper after
///   every Next-turn resolution (up to `kE2eDefaultFleetReachLoopMaxTurns
///   = 35` times per scenario), plus once inside
///   [e2eTryNavalMoveSegment] for the NW branch and once per
///   [e2eAwaitNwCoastalOrVisibleLandForBundledExplore] iteration; once
///   the NW chip is selected on the first call, every subsequent call
///   would re-tap and re-pump the same already-flipped chip. The
///   short-circuit removes that redundant tap + post-tap settle from
///   the wall-clock-bound hot path (Refs GitHub #2336 Bottleneck 4 /
///   AC5).
/// - No-op (returns immediately) when no hit-testable widget under
///   [kCtE2ERegionTabNewWorldKey] is present.
/// - Otherwise taps the first hit-testable subtree node, then polls
///   [e2eNewWorldRegionChipAppearsSelected] with adaptive backoff up to a
///   500ms cap. Never throws on timeout (best-effort post-tap settle).
Future<void> e2eTapNewWorldRegionTabIfPresent(WidgetTester tester) async {
  if (e2eNewWorldRegionChipAppearsSelected()) {
    return;
  }
  final tab = find.byKey(kCtE2ERegionTabNewWorldKey).hitTestable();
  if (tab.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tab.first, warnIfMissed: false);
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => e2eNewWorldRegionChipAppearsSelected(),
    timeout: const Duration(milliseconds: 500),
    phaseName: 'pump_until_new_world_region_chip_selected',
  );
}

/// Selects the Old World map region via the [CtChoiceChip] whose label
/// matches [AppLocalizations.region_oldWorld], then awaits the chip flip via
/// [e2ePumpUntilConditionOrIdle] so an already-selected tab short-circuits
/// without paying a fixed post-tap pump.
///
/// Lifted from the formerly private `_tapOldWorldRegionTab` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336
/// AC1 / AC2). Map HUD must show **Old World** before issuing naval moves
/// so OW-split fleets and warp orders stay coherent on Linux CI
/// (`SPEC/program/e2e-integration-tests.md`).
///
/// Contract:
/// - **Already-selected short-circuit**: returns immediately without
///   tapping or pumping when [e2eOldWorldRegionChipAppearsSelected] is
///   already `true`. Mirrors the sibling
///   [e2eTapNewWorldRegionTabIfPresent] short-circuit so the OW branch
///   of [e2eTryNavalMoveSegment] does not pay a redundant tap + post-tap
///   settle when the OW chip is already selected (default map state for
///   OW-split fleet scenarios). Refs GitHub #2336 Bottleneck 4 / AC5.
/// - No-op (returns immediately) when no hit-testable Old World [CtChoiceChip]
///   is present.
/// - Otherwise taps the first hit-testable chip, then polls
///   [e2eOldWorldRegionChipAppearsSelected] with adaptive backoff up to a
///   500ms cap. Never throws on timeout (best-effort post-tap settle).
Future<void> e2eTapOldWorldRegionTab(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  if (e2eOldWorldRegionChipAppearsSelected(l10n)) {
    return;
  }
  final chip = find.widgetWithText(CtChoiceChip, l10n.region_oldWorld);
  final hit = chip.hitTestable();
  if (hit.evaluate().isEmpty) {
    return;
  }
  await tester.tap(hit.first, warnIfMissed: false);
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => e2eOldWorldRegionChipAppearsSelected(l10n),
    timeout: const Duration(milliseconds: 500),
    phaseName: 'pump_until_old_world_region_chip_selected',
  );
}

/// True when [data] reads like the naval-panel location row for a fleet in
/// the New World (for example `New World — Outer Sea`).
///
/// `naval_tree_builder.dart` joins region and location with an **em dash**
/// (`—`), but earlier CI dumps and Material text scaling can normalize the
/// glyph to an **en dash** (`–`) or a plain **hyphen-minus** (`-`). The
/// helper accepts all three so fleet-reach detection
/// ([e2eNavalPanelShowsNonHomeFleetInNewWorld]) is not coupled
/// to one specific Unicode glyph.
///
/// Contract (Refs GitHub #2336):
/// - `null` and empty string -> `false` (nothing to inspect).
/// - String must begin with `"New World"` after trimming leading whitespace
///   (`trimLeft`); trailing whitespace is preserved so callers can spot
///   suspicious tail content in their own assertions.
/// - The character(s) immediately after `"New World"` must reduce, via a
///   second `trimLeft`, to one of `'—'`, `'–'`, or `'-'`. Anything else
///   (alphanumerics, a colon, or no separator at all) -> `false`.
bool e2eTextLooksLikeNewWorldLocationLine(String? data) {
  if (data == null) {
    return false;
  }
  final trimmed = data.trimLeft();
  const prefix = 'New World';
  if (!trimmed.startsWith(prefix)) {
    return false;
  }
  final after = trimmed.substring(prefix.length);
  if (after.isEmpty) {
    return false;
  }
  final rest = after.trimLeft();
  return rest.startsWith('—') || rest.startsWith('–') || rest.startsWith('-');
}

/// Widget-only: true when a **non-home** fleet row under [kCtE2ENavalPanelRootKey]
/// shows a New World location subtitle (`New World — …` per
/// `naval_tree_builder.dart`).
///
/// Lifted from the formerly private `_navalPanelShowsNonHomeFleetInNewWorld` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). Used as the UI fallback in
/// `_harnessDetectsNonHomeFleetInNewWorld` when [ctE2eNavalPanelSnapshot] is
/// null (snapshot plumbing unavailable). A silent rename / fail-open here would
/// stall fleet-reach loops at `_kMaxNextTurnTapsForNwFleetReach (35) × ~5 s`
/// (`SPEC/program/e2e-integration-tests.md` § Determinism, #2336 Bottleneck 4).
///
/// Contract:
/// - Returns `false` when the naval panel root key is absent.
/// - Iterates [ExpansionTile] descendants in stable tree order; skips tiles
///   without a `Text` whose `data` starts with `'Fleet '`.
/// - Returns `true` on the first tile that also has a descendant `Text` matching
///   [e2eTextLooksLikeNewWorldLocationLine].
bool e2eNavalPanelShowsNonHomeFleetInNewWorld(WidgetTester tester) {
  final naval = find.byKey(kCtE2ENavalPanelRootKey);
  if (naval.evaluate().isEmpty) {
    return false;
  }
  final tiles = find.descendant(
    of: naval,
    matching: find.byType(ExpansionTile),
  );
  final n = tiles.evaluate().length;
  for (var i = 0; i < n; i++) {
    final sub = tiles.at(i);
    final fleetTitle = find.descendant(
      of: sub,
      matching: find.byWidgetPredicate(
        (w) => w is Text && (w.data?.startsWith('Fleet ') ?? false),
      ),
    );
    if (fleetTitle.evaluate().isEmpty) {
      continue;
    }
    final loc = find.descendant(
      of: sub,
      matching: find.byWidgetPredicate(
        (w) => w is Text && e2eTextLooksLikeNewWorldLocationLine(w.data),
      ),
    );
    if (loc.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

/// True when [snap] reflects a **non-home human** fleet whose region is
/// `newWorld` — either directly via `Fleet.regionId == 'newWorld'`, or
/// indirectly because the fleet's `seaZoneId` resolves to `newWorld`
/// through `regionIdForSeaZone(snap.topology, …)`.
///
/// Lifted from the formerly private
/// `_nonHomeHumanFleetInNewWorldFromCtSnapshot` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). The fleet-reach loop short-circuit
/// (`_fleetReachDoneFromCtSnapshotOnly`, `_harnessDetectsNonHomeFleetInNewWorld`)
/// and the bundled-explore readiness loop depend on this predicate to
/// terminate within the 35-turn cap when [ctE2eNavalPanelSnapshot] reports
/// arrival — a silent rename / fail-open here would stall the suite at
/// `_kMaxNextTurnTapsForNwFleetReach × ~5 s` (`SPEC/program/e2e-integration-tests.md`
/// § Determinism, #2336 Bottleneck 4).
///
/// Contract:
///
/// - Returns `false` when [snap] is `null` (no snapshot plumbing this turn).
/// - Iterates `snap.game.worldState.fleets` in stable list order; for each
///   fleet skips when `f.ownerId != snap.humanPlayerId`.
/// - Skips the human's home fleet (`homeFleetIdFor(snap.humanPlayerId)`)
///   so that an opening home-fleet-only state never short-circuits the
///   loop on turn 0.
/// - Returns `true` when the first surviving fleet has `regionId ==
///   'newWorld'`.
/// - Otherwise consults `regionIdForSeaZone(snap.topology, sea)` and
///   returns `true` when the seaboard resolves to `newWorld`. A `null`
///   `seaZoneId` (in-port) or a sea zone the topology cannot resolve
///   keeps iterating.
/// - Returns `false` only after every fleet has been considered.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in `app/test/e2e_non_home_human_fleet_in_new_world_from_ct_snapshot_test.dart`
/// carries the behavioural contract.
bool e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
  CtE2eNavalPanelSnapshot? snap,
) {
  if (snap == null) {
    return false;
  }
  final human = snap.humanPlayerId;
  final homeId = homeFleetIdFor(human);
  for (final f in snap.game.worldState.fleets) {
    if (f.ownerId != human) continue;
    if (f.id == homeId) continue;
    if (f.regionId == 'newWorld') return true;
    final sea = f.seaZoneId;
    if (sea != null && regionIdForSeaZone(snap.topology, sea) == 'newWorld') {
      return true;
    }
  }
  return false;
}

/// Snapshot-only fleet-reach loop short-circuit (Refs GitHub #2336
/// Bottleneck 4).
///
/// Returns whether [snap] already reports a **non-home human** fleet in the
/// New World so the fleet-reach turn loop can skip [openNavalPanel] and
/// redundant widget-tree probes on subsequent iterations. Semantically
/// identical to [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] but named for
/// the call-site contract in `new_game_fleet_reaches_new_world_e2e_test.dart`.
///
/// - Returns `false` when [snap] is `null` (keep iterating).
/// - Does **not** consult the widget tree; use
///   [e2eHarnessDetectsNonHomeFleetInNewWorld] when a UI fallback is required.
bool e2eFleetReachDoneFromCtSnapshotOnly(CtE2eNavalPanelSnapshot? snap) =>
    e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(snap);

/// Fleet-reach / bundled-explore arrival probe with snapshot-first semantics.
///
/// Lifted from the formerly private `_harnessDetectsNonHomeFleetInNewWorld`
/// in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2).
///
/// Contract:
///
/// - Returns `true` when [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot]
///   reports arrival for [snap] (including when [snap] is non-null and
///   reports `false` — the widget fallback is **not** consulted in that case).
/// - When [snap] is `null`, falls back to
///   [e2eNavalPanelShowsNonHomeFleetInNewWorld] for environments where CT
///   snapshot plumbing is unavailable.
bool e2eHarnessDetectsNonHomeFleetInNewWorld(
  WidgetTester tester,
  CtE2eNavalPanelSnapshot? snap,
) =>
    e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(snap) ||
    (snap == null && e2eNavalPanelShowsNonHomeFleetInNewWorld(tester));

/// True when the active player's [PlayerView] reports **at least one** tile
/// belonging to a New World province whose visibility is above `unknown`
/// (`fogged` or `fullyVisible`).
///
/// Lifted from the formerly private
/// `_playerHasAnyNewWorldFoggedOrBetterFromCtSnapshot` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). The bundled-explore readiness loop short-circuits on
/// this predicate alongside
/// `_nonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot` — once either
/// path reports NW penetration, the explorer-assign affordance is expected
/// to become enabled within bounded retries. The fleet-reach test's final
/// guard (`new_game_fleet_reaches_new_world_e2e_test.dart`) also uses
/// this predicate to skip-rather-than-fail on CI topology/seed runs where
/// no NW land becomes fogged-or-better within bounded turn retries. A
/// silent rename or fail-open here would either:
///
///   - Stall the bundled-explore readiness loop for the full 35-turn cap
///     (Bottleneck 4 in `SPEC/program/e2e-integration-tests.md`
///     § Determinism), inflating wall-clock budget; or
///   - Convert the strict bundled-explore assertion into a silent skip
///     (returning `true` always) and mask a real Explore-assign regression.
///
/// The function takes the snapshot explicitly rather than reading the
/// mutable `ctE2eNavalPanelSnapshot` global so the contract is
/// deterministic and unit-testable (matches the lifted
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] precedent).
///
/// Contract:
///
/// - Returns `false` when [snap] is `null` (no snapshot plumbing this
///   turn — the readiness loop must keep iterating rather than treat a
///   missing snapshot as either arrival or "no NW land").
/// - Returns `false` when the snapshot's game has zero `newWorld|`
///   provinces (an empty NW region cannot contribute any qualifying
///   tile; skipping the [PlayerView] build is also a perf safeguard).
/// - Otherwise builds the human player's [PlayerView] via
///   [buildPlayerView] and iterates `view.visibilityByTile.entries` in
///   the map's iteration order.
/// - For each `(tileKey, level)` entry, skips tiles whose key does not
///   split into exactly four `|`-delimited parts (`regionId|provinceLocalId|x|y`),
///   whose first segment is not `newWorld`, or whose second segment
///   (province local id) is not present in the snapshot's NW province set.
/// - Returns `true` on the **first** surviving entry whose visibility
///   level name is anything other than `'unknown'` (i.e. `'fogged'` or
///   `'fullyVisible'`).
/// - Returns `false` after every visibility entry has been considered.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in
/// `app/test/e2e_player_has_any_new_world_fogged_or_better_from_ct_snapshot_test.dart`
/// carries the behavioural contract.
bool e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
  CtE2eNavalPanelSnapshot? snap,
) {
  if (snap == null) {
    return false;
  }
  final newWorldProvinceLocalIds = allProvinces(snap.game.worldState)
      .where((p) => ProvinceId.regionIdFrom(p.id) == 'newWorld')
      .map((p) => ProvinceId.localIdFrom(p.id))
      .toSet();
  if (newWorldProvinceLocalIds.isEmpty) {
    return false;
  }
  final view = buildPlayerView(snap.game, snap.topology, snap.humanPlayerId);
  for (final entry in view.visibilityByTile.entries) {
    final parts = entry.key.split('|');
    if (parts.length != 4) {
      continue;
    }
    if (parts[0] != 'newWorld') {
      continue;
    }
    if (!newWorldProvinceLocalIds.contains(parts[1])) {
      continue;
    }
    if (entry.value.name != 'unknown') {
      return true;
    }
  }
  return false;
}

/// Returns the set of province ids adjacent to [seaZoneId] in [topology],
/// trying the caller's [seaZoneId] verbatim first and falling back to the
/// region-prefixed form when the verbatim lookup is empty and the input is
/// not already prefixed.
///
/// Lifted from the formerly private `_nwCoastalProvincesAdjacentToFleetSea`
/// helper in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart`
/// (Refs GitHub #2336 AC1 / AC2). The two-tier lookup exists because
/// `provinceIdsAdjacentToSeaZone` (`SPEC/program/fog-and-exploration-resolution.md`)
/// matches edge endpoints exactly, but the combined topology used by the
/// app/turn resolver uses prefixed sea node ids (`newWorld|sea5`) while
/// some live fleet states still carry the regional local id (`sea5`). The
/// fallback keeps coastal detection aligned with the ship-reveal contract
/// regardless of which form is present in the fleet record.
///
/// Contract:
///
/// - First call: `provinceIdsAdjacentToSeaZone(topology, seaZoneId,
///   regionId: regionId)`. If the result is **non-empty**, return it.
/// - Otherwise, if [seaZoneId] is already a prefixed id
///   (`ProvinceId.isPrefixed(seaZoneId)` is true), return an empty
///   set — the verbatim lookup is authoritative and a missing match
///   means the topology genuinely has no adjacent provinces.
/// - Otherwise (verbatim was empty and [seaZoneId] is a bare local id),
///   retry with `ProvinceId.full(regionId, seaZoneId)`.
/// - Return the second-call result, or the empty constant set if even
///   that lookup is empty.
///
/// The function is pure and deterministic — identical inputs always yield
/// identical sets (Refs #2336 AC2 / Bottleneck 6 dedup goal). Taking
/// [topology] and [regionId] explicitly (rather than reading the mutable
/// `ctE2eNavalPanelSnapshot` global) matches the pattern established by
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] and keeps the helper
/// unit-testable without a live snapshot fixture.
Set<String> e2eNwCoastalProvincesAdjacentToFleetSea(
  MapTopology topology,
  String seaZoneId,
  String regionId,
) {
  final direct = provinceIdsAdjacentToSeaZone(
    topology,
    seaZoneId,
    regionId: regionId,
  );
  if (direct.isNotEmpty) return direct;
  if (!ProvinceId.isPrefixed(seaZoneId)) {
    return provinceIdsAdjacentToSeaZone(
      topology,
      ProvinceId.full(regionId, seaZoneId),
      regionId: regionId,
    );
  }
  return const {};
}

/// True when [snap] reflects a **non-home human** fleet sitting in a
/// New World sea zone that has at least one adjacent coastal province
/// (per [e2eNwCoastalProvincesAdjacentToFleetSea]).
///
/// Lifted from the formerly private
/// `_nonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs
/// GitHub #2336 AC1 / AC2). This predicate is the **coastal** companion
/// to [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot]: ship reveal only
/// paints coastal land for sea zones that have a P–S province edge
/// (`SPEC/program/fog-and-exploration-resolution.md`), so a fleet in an
/// open-ocean NW sea satisfies the "fleet in NW" predicate but never
/// yields fogged-or-better NW provinces — leaving bundled Explore
/// disabled. The bundled-explore readiness loop
/// (`_awaitNwCoastalOrVisibleLandForBundledExploreE2e`) therefore
/// short-circuits on this predicate alongside
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot]; a silent
/// rename / fail-open here would stall the readiness loop at
/// `35 × ~5 s` (Bottleneck 4 in `SPEC/program/e2e-integration-tests.md`
/// § Determinism) and inflate the wall-clock cap #2336 is reducing.
///
/// The function takes the snapshot explicitly rather than reading the
/// mutable `ctE2eNavalPanelSnapshot` global so the contract is
/// deterministic and unit-testable (matches the lifted
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] and
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] precedent).
///
/// Contract:
///
/// - Returns `false` when [snap] is `null` (no snapshot plumbing this
///   turn — the readiness loop must keep iterating).
/// - Iterates `snap.game.worldState.fleets` in stable list order; for
///   each fleet skips when `f.ownerId != snap.humanPlayerId`.
/// - Skips the human's home fleet
///   (`homeFleetIdFor(snap.humanPlayerId)`) so an opening
///   home-fleet-only state never short-circuits the loop.
/// - Skips fleets in port (`!f.isAtSea`) and fleets with a `null`
///   `seaZoneId` (cannot resolve adjacency).
/// - Resolves each fleet's region via `f.regionId == 'newWorld'` first
///   (canonical post-warp state); otherwise consults
///   `regionIdForSeaZone(snap.topology, sea)`. Skips when the resolved
///   region is `null` or not exactly `newWorld`
///   (case-sensitive match — pinning the contract against accidental
///   normalization).
/// - Returns `true` on the first fleet whose
///   [e2eNwCoastalProvincesAdjacentToFleetSea] lookup yields a
///   non-empty province set (coastal sea zone with a P–S edge).
/// - Returns `false` after every fleet has been considered.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// pin in
/// `app/test/e2e_non_home_human_fleet_in_coastal_new_world_sea_from_ct_snapshot_test.dart`
/// carries the behavioural contract.
bool e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
  CtE2eNavalPanelSnapshot? snap,
) {
  if (snap == null) return false;
  final human = snap.humanPlayerId;
  final homeId = homeFleetIdFor(human);
  for (final f in snap.game.worldState.fleets) {
    if (f.ownerId != human) continue;
    if (f.id == homeId) continue;
    if (!f.isAtSea || f.seaZoneId == null) continue;
    final sea = f.seaZoneId!;
    final String? regionId = f.regionId == 'newWorld'
        ? 'newWorld'
        : regionIdForSeaZone(snap.topology, sea);
    if (regionId == null || regionId != 'newWorld') continue;
    if (e2eNwCoastalProvincesAdjacentToFleetSea(
      snap.topology,
      sea,
      regionId,
    ).isNotEmpty) {
      return true;
    }
  }
  return false;
}

/// True when [snap] reports at least one civilian-panel unit row whose
/// available work targets include [kWorkTargetExplore]; `null` when no
/// civilian-panel snapshot is plumbed for the current turn.
///
/// Lifted from the formerly private
/// `_exploreAssignEnabledFromCivilianSnapshot` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). The fleet-reach test's
/// `_anyExplorerHasEnabledExploreAssignFleetE2e` helper consults this
/// predicate first to short-circuit the panel-sweep loop when the panel
/// snapshot already exposes an Explore-enabled work-target list — the
/// loop only falls back to the expensive scrolling `Assign` sheet walk
/// when no snapshot is available (the `null` return). The snapshot
/// mirrors `availableWorkTargetIdsForUnitProvider`, which is the same
/// data source that drives enabled `Assign` rows in the live panel
/// (`SPEC/program/e2e-integration-tests.md` § Determinism), so the
/// short-circuit is contractually equivalent to the live walk and a
/// silent rename / fail-open here would re-introduce up to
/// `maxPanelSweepSteps (16) × per-step assign sweep` of wasted frames
/// per fleet-reach turn (Bottleneck 5 in `SPEC/program/e2e-integration-tests.md`
/// § Determinism, #2336 AC5).
///
/// The function takes the snapshot explicitly rather than reading the
/// mutable `ctE2eCivilianPanelSnapshot` global so the contract is
/// deterministic and unit-testable (matches the lifted
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] /
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] /
/// [e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot] precedent).
///
/// Contract:
///
/// - Returns `null` when [snap] is `null` (no civilian-panel snapshot
///   plumbing this turn — caller must fall back to the live `Assign`
///   sheet sweep rather than treat a missing snapshot as either
///   "Explore enabled" or "Explore disabled").
/// - Returns `true` on the **first** unit row whose
///   `availableWorkTargets` list contains [kWorkTargetExplore] (existential
///   short-circuit: the panel only needs one Explore-enabled unit to
///   surface the assign affordance).
/// - Returns `false` after every unit row has been considered with no
///   Explore target found (panel is mounted but no civilian can be
///   assigned Explore right now).
/// - Iterates `snap.availableWorkTargets.values` in the map's iteration
///   order; the `String` target ids are compared with exact equality so
///   case mutations (e.g. `Explore`) never satisfy the predicate.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in
/// `app/test/e2e_explore_assign_enabled_from_civilian_snapshot_test.dart`
/// carries the behavioural contract.
bool? e2eExploreAssignEnabledFromCivilianSnapshot(
  CtE2eCivilianPanelSnapshot? snap,
) {
  if (snap == null) {
    return null;
  }
  for (final targets in snap.availableWorkTargets.values) {
    if (targets.contains(kWorkTargetExplore)) {
      return true;
    }
  }
  return false;
}

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

/// Text inside the map HUD next-turn [CtNinePatchButton] (`game_nextTurnButton`).
String? e2eReadNextTurnButtonLabel(WidgetTester tester) {
  final inner = find.descendant(
    of: find.byKey(kGameMapNextTurnButtonKey),
    matching: find.byType(Text),
  );
  if (inner.evaluate().length != 1) {
    return null;
  }
  final w = inner.evaluate().single.widget;
  return w is Text ? w.data : null;
}

/// Polls until the next-turn map chip label changes from [turnLabelBefore].
///
/// Evaluates the label **before** the first pump; uses [e2eAdaptivePollRampAfterIdle]
/// on idle pumps (GitHub #2336 / AC5). When a
/// [TurnResolutionProcessingDialog] appears, completion also requires that dialog
/// to clear before accepting a label change (avoids racing mid-resolution UI).
Future<Duration> e2eWaitForNextTurnLabelAdvance(
  WidgetTester tester, {
  required String turnLabelBefore,
  required Duration timeout,
  E2ePerfLog? perf,
}) async {
  final sw = Stopwatch()..start();
  var nextTurnPollMs = 25;
  var sawProcessingDialog = false;
  while (sw.elapsed < timeout) {
    if (find.byType(TurnResolutionProcessingDialog).evaluate().isNotEmpty) {
      sawProcessingDialog = true;
    }
    final label = e2eReadNextTurnButtonLabel(tester);
    if (label != null && label != turnLabelBefore) {
      if (!sawProcessingDialog ||
          find.byType(TurnResolutionProcessingDialog).evaluate().isEmpty) {
        perf?.timing(
          'next_turn_wall_clock',
          sw.elapsed,
          meta: 'result=advanced',
        );
        return sw.elapsed;
      }
    }
    await tester.pump(Duration(milliseconds: nextTurnPollMs));
    nextTurnPollMs = e2eAdaptivePollRampAfterIdle(nextTurnPollMs);
  }
  // Final check after the loop exits on the timeout edge: the most recent
  // pump may have advanced the next-turn label (and/or cleared the
  // [TurnResolutionProcessingDialog]) just as `sw.elapsed` crossed [timeout],
  // so the loop's pre-pump check would never re-evaluate. Match the
  // post-pump-check pattern used by the strict busy-wait siblings
  // ([e2eWaitUntilFound], [e2ePumpUntil], [e2eWaitUntilAnyFinderHitTestable])
  // so a successful late pump still returns the elapsed wall clock instead
  // of falling through to `fail()`. Refs GitHub #2336 AC5 (adaptive polling)
  // / busy-wait final-check fix.
  if (find.byType(TurnResolutionProcessingDialog).evaluate().isNotEmpty) {
    sawProcessingDialog = true;
  }
  final lateLabel = e2eReadNextTurnButtonLabel(tester);
  if (lateLabel != null && lateLabel != turnLabelBefore) {
    if (!sawProcessingDialog ||
        find.byType(TurnResolutionProcessingDialog).evaluate().isEmpty) {
      perf?.timing(
        'next_turn_wall_clock',
        sw.elapsed,
        meta: 'result=advanced_at_timeout',
      );
      return sw.elapsed;
    }
  }
  perf?.timing('next_turn_wall_clock', sw.elapsed, meta: 'result=timeout');
  fail(
    'Next turn label did not advance within ${timeout.inSeconds}s. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Taps Next turn, confirms when prompted, and waits for resolution to finish.
///
/// Shared by full-turn and fleet E2E (GitHub #2336 AC5). Uses adaptive polls for
/// the confirm-or-advanced gate and [kE2eNextTurnResolutionTimeout] for the label
/// poll after confirm.
Future<Duration> e2eAdvanceOneHumanTurn(
  WidgetTester tester, {
  required AppLocalizations l10n,
  E2ePerfLog? perf,
  Duration timeout = kE2eNextTurnResolutionTimeout,
}) async {
  final phaseSw = Stopwatch()..start();
  final before = e2eReadNextTurnButtonLabel(tester);
  await tester.tap(find.byKey(kGameMapNextTurnButtonKey));
  perf?.bumpCounter('next_turn_taps');

  final confirmFinder = find.text(l10n.common_yes);
  await e2ePumpUntilConditionOrIdle(
    tester,
    () {
      if (confirmFinder.hitTestable().evaluate().isNotEmpty) {
        return true;
      }
      final maybeAfter = e2eReadNextTurnButtonLabel(tester);
      return maybeAfter != null && maybeAfter != before;
    },
    timeout: const Duration(seconds: 5),
    perf: perf,
    phaseName: 'pump_until_next_turn_confirm_or_label_advanced',
  );
  final earlyAfter = e2eReadNextTurnButtonLabel(tester);
  if (earlyAfter != null && earlyAfter != before) {
    perf?.timing('next_turn_advance', phaseSw.elapsed);
    return phaseSw.elapsed;
  }

  final confirmNextTurn = confirmFinder.hitTestable();
  if (confirmNextTurn.evaluate().isNotEmpty) {
    await tester.tap(confirmNextTurn.first, warnIfMissed: false);
    // Skip the legacy zero-duration settle pump here: the immediate
    // [e2eWaitForNextTurnLabelAdvance] call already evaluates the label
    // before its first pump and pumps with adaptive backoff. The extra
    // [tester.pump] burned one full-render frame per turn for nothing.
    // Refs GitHub #2336 pump-reduction slice.
  }

  if (before == null) {
    fail(
      'Next turn button label missing before advance. '
      'Last exception: ${tester.takeException()}',
    );
  }
  final labelWait = await e2eWaitForNextTurnLabelAdvance(
    tester,
    turnLabelBefore: before,
    timeout: timeout,
    perf: perf,
  );
  perf?.timing('next_turn_advance', phaseSw.elapsed);
  return labelWait;
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
