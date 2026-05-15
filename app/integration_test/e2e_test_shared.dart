import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/fleet_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Closes an open [BottomSheet] via repeated [handlePopRoute] polls until gone.
///
/// Shared by full-turn and fleet E2E; [overallTimeout] defaults to
/// [kE2eDefaultBottomSheetCloseTimeout] (previous per-file caps). Refs GitHub #2336.
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
  var closePollMs = 25;
  while (sw.elapsed < overallTimeout) {
    if (!anyPanelOpen()) {
      perf?.timing('close_bottom_sheet', sw.elapsed);
      return;
    }
    await tester.binding.handlePopRoute();
    await tester.pump(Duration(milliseconds: closePollMs));
    closePollMs = e2eAdaptivePollRampAfterIdle(closePollMs);
  }

  fail(
    'Timed out after ${overallTimeout.inSeconds}s closing bottom sheet; '
    'panels remained visible',
  );
}

/// Opens the civilian units panel from the empire rail or the first civilian
/// marker, closing a conflicting naval/civilian sheet first when needed.
///
/// Single canonical implementation for full-turn and fleet E2E (GitHub #2336
/// / AC2). Uses adaptive waits for rail/marker readiness instead of blind
/// idle pumps.
Future<void> e2eOpenCivilianPanel(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
  E2ePerfLog? perf,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  String afterSheetPanelsClearPhase =
      'pump_until_panels_cleared_after_close_sheet_civilian_open',
}) async {
  final sw = Stopwatch()..start();
  final empireRailButton = find.byKey(kEmpireCivilianUnitsButtonKey);
  final markerButton = find.byKey(kCtE2EOpenFirstCivilianMarkerPanelKey);
  final civilianPanel = find.byKey(kCtE2ECivilianPanelRootKey);
  final navalPanel = find.byKey(kCtE2ENavalPanelRootKey);
  Future<bool> tryOpen(Finder trigger) async {
    if (civilianPanel.evaluate().isNotEmpty) {
      return true;
    }
    final tappable = trigger.hitTestable();
    if (tappable.evaluate().isEmpty) {
      await e2eDismissTransientUi(tester, perf: perf);
      return false;
    }
    await tester.tap(tappable.first, warnIfMissed: false);
    if (civilianPanel.evaluate().isNotEmpty) {
      return true;
    }
    await tester.pump();
    if (civilianPanel.evaluate().isNotEmpty) {
      return true;
    }
    return e2ePumpUntilConditionOrIdle(
      tester,
      () => civilianPanel.evaluate().isNotEmpty,
      timeout: const Duration(seconds: 3),
      perf: perf,
      phaseName: 'pump_until_civilian_panel_after_trigger_tap',
    );
  }

  var panelPollMs = 25;
  while (sw.elapsed < timeout) {
    if (civilianPanel.evaluate().isNotEmpty ||
        navalPanel.evaluate().isNotEmpty) {
      await e2eCloseBottomSheet(
        tester,
        perf: perf,
        overallTimeout: bottomSheetCloseTimeout,
      );
      await e2ePumpUntilConditionOrIdle(
        tester,
        () =>
            civilianPanel.evaluate().isEmpty &&
            navalPanel.evaluate().isEmpty &&
            find.byType(BottomSheet).evaluate().isEmpty,
        timeout: const Duration(milliseconds: 600),
        perf: perf,
        phaseName: afterSheetPanelsClearPhase,
      );
      panelPollMs = 25;
      continue;
    }
    if (empireRailButton.evaluate().isNotEmpty) {
      if (await tryOpen(empireRailButton)) {
        perf?.timing('open_panel_civilian', sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (markerButton.evaluate().isNotEmpty) {
      if (await tryOpen(markerButton)) {
        perf?.timing('open_panel_civilian', sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () =>
          empireRailButton.hitTestable().evaluate().isNotEmpty ||
          markerButton.hitTestable().evaluate().isNotEmpty,
      timeout: Duration(milliseconds: panelPollMs),
      perf: perf,
      phaseName: 'pump_until_civilian_rail_or_marker_hit_testable',
    )) {
      panelPollMs = 25;
      continue;
    }
    panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
  }
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for a civilian panel opener. '
    'empire=$empireRailButton marker=$markerButton '
    'Last exception: ${tester.takeException()}',
  );
}

/// Dismisses snackbars, generic OK dialogs, [AlertDialog] actions, bottom sheets,
/// and [CtDialogShell] overlays (union of fleet + full-turn E2E paths).
Future<void> e2eDismissTransientUi(
  WidgetTester tester, {
  E2ePerfLog? perf,
}) async {
  perf?.bumpCounter('dismiss_transient_ui_calls');
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

/// Polls until the next-turn map chip label changes from [turnLabelBefore].
///
/// Evaluates the label **before** the first pump; uses [e2eAdaptivePollRampAfterIdle]
/// on idle pumps (GitHub #2336 / AC5).
Future<Duration> e2eWaitForNextTurnLabelAdvance(
  WidgetTester tester, {
  required String turnLabelBefore,
  required Duration timeout,
  E2ePerfLog? perf,
}) async {
  final sw = Stopwatch()..start();
  var nextTurnPollMs = 25;
  while (sw.elapsed < timeout) {
    final turnAfterFinder = find.descendant(
      of: find.byKey(kGameMapNextTurnButtonKey),
      matching: find.byType(Text),
    );
    if (turnAfterFinder.evaluate().isNotEmpty) {
      final turnAfter = turnAfterFinder.evaluate().single.widget as Text;
      if (turnAfter.data != turnLabelBefore) {
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

/// Loads and decodes each path with bounded concurrency (overlapping I/O +
/// image decode completion) instead of strictly serial awaits.
Future<List<String>> e2eDecodePngAssetPathsParallel(
  List<String> assetPaths, {
  int batchSize = 8,
}) async {
  final failures = <String>[];
  for (var i = 0; i < assetPaths.length; i += batchSize) {
    final end = i + batchSize > assetPaths.length
        ? assetPaths.length
        : i + batchSize;
    final chunk = assetPaths.sublist(i, end);
    final chunkFailures = await Future.wait(
      chunk.map((assetPath) async {
        try {
          final data = await rootBundle.load(assetPath);
          final bytes = data.buffer.asUint8List();
          final completer = Completer<ui.Image>();
          ui.decodeImageFromList(bytes, completer.complete);
          final image = await completer.future;
          image.dispose();
          return null;
        } catch (e) {
          return '$assetPath ($e)';
        }
      }),
    );
    for (final message in chunkFailures) {
      if (message != null) {
        failures.add(message);
      }
    }
  }
  return failures;
}

Future<void> _e2eTapGameStartIntroOverlayContinueIfPresent(
  WidgetTester tester,
) async {
  if (find.text('Continue').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continue').first);
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => find.byType(GameStartIntroOverlay).evaluate().isEmpty,
      timeout: const Duration(milliseconds: 800),
      phaseName: 'pump_until_intro_dismissed_after_continue',
    );
    return;
  }
  if (find.text('I shall.').evaluate().isNotEmpty) {
    await tester.tap(find.text('I shall.').first);
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => find.byType(GameStartIntroOverlay).evaluate().isEmpty,
      timeout: const Duration(milliseconds: 800),
      phaseName: 'pump_until_intro_dismissed_after_i_shall',
    );
  }
}

/// After [Start] is tapped, polls until the in-game map HUD is visible.
///
/// Evaluates success before the first pump; uses exponential backoff on pump
/// intervals (25ms → … capped at 500ms) per `SPEC/program/e2e-integration-tests.md`
/// / issue #2336 adaptive polling guidance.
Future<void> e2eWaitForMapHudAfterNewGameStart(
  WidgetTester tester, {
  Duration overallCap = const Duration(seconds: 60),
}) async {
  final setupDeadline = DateTime.now().add(overallCap);
  var stepMs = 25;
  while (DateTime.now().isBefore(setupDeadline)) {
    if (find.text('Could not create game').evaluate().isNotEmpty) {
      fail(
        'New game setup failed (error dialog). '
        'Exception: ${tester.takeException()}',
      );
    }
    if (find.byKey(kHomeToCapitalButtonKey).evaluate().isNotEmpty) {
      return;
    }
    if (find.byType(GameStartIntroOverlay).evaluate().isNotEmpty) {
      await _e2eTapGameStartIntroOverlayContinueIfPresent(tester);
      stepMs = 25;
      continue;
    }
    if (find.text('Creating game').evaluate().isNotEmpty) {
      await tester.pump(Duration(milliseconds: stepMs));
      stepMs = math.min(500, stepMs * 2);
      continue;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = math.min(500, stepMs * 2);
  }
  fail(
    'Timed out after ${overallCap.inSeconds}s waiting for '
    'map (home→capital). Last exception: ${tester.takeException()}',
  );
}

/// Canonical new-game → map HUD path shared by E2E scenarios (Refs #2336).
Future<void> e2eBootstrapNewGameToMap(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration overallCap = const Duration(seconds: 60),
}) async {
  final phaseSw = Stopwatch()..start();
  await tester.tap(find.text('New Game'));
  await e2eWaitUntilFound(
    tester,
    find.text('Start'),
    timeout: const Duration(seconds: 30),
    perf: perf,
    phaseName: 'wait_until_found_start_button',
  );

  final startButton = find.ancestor(
    of: find.text('Start'),
    matching: find.byType(CtNinePatchButton),
  );
  expect(startButton, findsOneWidget);

  final shellScrollable = find.descendant(
    of: find.byType(CtDialogShell),
    matching: find.byType(Scrollable),
  );
  await tester.dragUntilVisible(
    startButton,
    shellScrollable,
    const Offset(0, -120),
  );
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => startButton.hitTestable().evaluate().isNotEmpty,
    timeout: const Duration(milliseconds: 600),
    perf: perf,
    phaseName: 'pump_until_start_button_tappable_after_drag',
  );
  await tester.ensureVisible(startButton);
  await tester.tap(startButton);
  await tester.pump();

  await e2eWaitForMapHudAfterNewGameStart(tester, overallCap: overallCap);

  expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
  await e2ePumpUntilConditionOrIdle(
    tester,
    () =>
        find.byKey(kHomeToCapitalButtonKey).hitTestable().evaluate().isNotEmpty,
    timeout: const Duration(milliseconds: 800),
    perf: perf,
    phaseName: 'pump_until_home_capital_tappable_after_map',
  );
  perf?.timing('new_game_to_map', phaseSw.elapsed);
}

/// Collects non-empty [Text] data in depth-first preorder (E2E snapshot helpers).
void e2eCollectTextPreorder(Element element, List<String> out) {
  final w = element.widget;
  if (w is Text) {
    final d = w.data;
    if (d != null && d.isNotEmpty) {
      out.add(d);
    }
  }
  element.visitChildren((child) {
    e2eCollectTextPreorder(child, out);
  });
}

/// Relocated 64px map icon paths from the asset manifest (sorted).
Future<List<String>> e2eDiscoverRelocated64pxPngAssets() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets =
      manifest
          .listAssets()
          .where(
            (assetPath) =>
                assetPath.startsWith('assets/icons/64/') &&
                assetPath.endsWith('.png'),
          )
          .toList()
        ..sort();
  return assets;
}

/// Asserts manifest contents match [expectedAssets], then decodes via
/// [e2eDecodePngAssetPathsParallel] (Refs #2336 AC3).
Future<void> e2eEnsureRelocated64pxPngDecode(
  Set<String> expectedAssets, {
  String emptyManifestReason =
      'Expected relocated map icon PNGs under assets/icons/64/, but none were found in the asset manifest.',
  String? countMismatchReason,
  String? orderedMismatchReason,
  String decodeFailuresPrefix =
      'Failed to load one or more relocated 64px PNG assets:',
}) async {
  final assets = await e2eDiscoverRelocated64pxPngAssets();
  final expectedSorted = expectedAssets.toList()..sort();
  expect(assets, isNotEmpty, reason: emptyManifestReason);
  expect(
    assets.length,
    expectedAssets.length,
    reason:
        countMismatchReason ??
        'Unexpected number of relocated 64px PNG assets. '
            'Expected ${expectedAssets.length} map-family files, found ${assets.length}.',
  );
  expect(
    assets,
    orderedEquals(expectedSorted),
    reason:
        orderedMismatchReason ??
        'Relocated 64px PNG manifest entries do not match expected map icon families.',
  );
  final failures = await e2eDecodePngAssetPathsParallel(assets);
  expect(
    failures,
    isEmpty,
    reason: failures.isEmpty
        ? null
        : '$decodeFailuresPrefix\n${failures.join('\n')}',
  );
}

/// Asserts the manifest matches the canonical map icon families, then decodes
/// every PNG via [e2eDecodePngAssetPathsParallel] (bounded concurrency).
///
/// Used by new-game E2E tests that need the same warm-cache behavior.
///
/// Prefer [e2eEnsureAllRelocated64pxPngsLoadSuiteOnce] when each scenario needs
/// the same decode/assert path so work runs at most once per test VM (GitHub
/// #2336 AC3).
Future<void> e2eEnsureAllRelocated64pxPngsLoad() async {
  await e2eEnsureRelocated64pxPngDecode(<String>{
    ...kCivilianIconSlugs.map(
      (slug) => 'assets/icons/64/ui_icon_civ_$slug.png',
    ),
    ...kResourceIconIds.map(
      (resourceId) => 'assets/icons/64/ui_icon_com_$resourceId.png',
    ),
    ...kTownIconIds.map((iconId) => 'assets/icons/64/ui_icon_com_$iconId.png'),
    ...kProvinceLabelIconIds.map(
      (iconId) => 'assets/icons/64/ui_icon_$iconId.png',
    ),
    kFleetMapIcon64PngAssetPath,
  });
}

Future<void>? _e2eAllRelocated64pxPngLoadSuiteFuture;

/// Runs [e2eEnsureAllRelocated64pxPngsLoad] at most once per isolate.
///
/// Subsequent calls await the same future so multiple E2E scenarios in one run
/// do not repeat manifest + parallel decode work (GitHub #2336 AC3).
Future<void> e2eEnsureAllRelocated64pxPngsLoadSuiteOnce() async {
  _e2eAllRelocated64pxPngLoadSuiteFuture ??= e2eEnsureAllRelocated64pxPngsLoad();
  return _e2eAllRelocated64pxPngLoadSuiteFuture!;
}
