import 'dart:math' as math;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

export 'e2e_test_shared_panels.dart';

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

/// Expands one collapsed [ExpansionTile] per outer iteration (panel rebuild safe).
Future<void> e2eExpandEachExpansionTileOnce(WidgetTester tester) async {
  for (var safety = 0; safety < 32; safety++) {
    final tiles = find.byType(ExpansionTile);
    final n = tiles.evaluate().length;
    if (n == 0) {
      return;
    }

    var expandedOne = false;
    for (var j = 0; j < n; j++) {
      final expandIcon = find.descendant(
        of: tiles.at(j),
        matching: find.byIcon(Icons.expand_more),
      );
      if (expandIcon.evaluate().isEmpty) {
        continue;
      }
      final iconHit = expandIcon.first;
      final tileAt = tiles.at(j);
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
        () => find
            .descendant(of: tileAt, matching: find.byIcon(Icons.expand_more))
            .evaluate()
            .isEmpty,
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
  if (diagnoseAfter > Duration.zero) {
    await e2ePumpFor(tester, diagnoseAfter);
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
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for any of $finders. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Post-confirm turn resolution wait aligned with the 15s usability budget
/// (`colonizethis-turn-resolution-budget.mdc`).
const Duration kE2eNextTurnResolutionTimeout = Duration(seconds: 15);

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

