import 'dart:math' as math;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
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

/// Default cap for naval-panel open polling (matches prior fleet E2E constant).
const Duration kE2eDefaultNavalOpenTimeout = Duration(seconds: 5);

/// Opens the naval units panel from the empire rail or the first fleet marker,
/// dismissing transient UI and closing conflicting sheets when needed.
///
/// Single canonical implementation for fleet E2E (GitHub #2336); mirrors
/// [e2eOpenCivilianPanel] structure with naval keys and adaptive polling.
Future<void> e2eOpenNavalPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = kE2eDefaultNavalOpenTimeout,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
}) async {
  final phaseSw = Stopwatch()..start();
  final navalPanel = find.byKey(kCtE2ENavalPanelRootKey);
  final markerBtn = find.byKey(kCtE2EOpenFirstFleetMarkerPanelKey);
  final btn = find.byKey(kEmpireNavalUnitsButtonKey);

  Future<bool> pollUntilNavalVisible(Duration budget) async {
    final poll = Stopwatch()..start();
    if (navalPanel.evaluate().isNotEmpty) {
      return true;
    }
    var stepMs = 25;
    while (poll.elapsed < budget) {
      if (navalPanel.evaluate().isNotEmpty) {
        return true;
      }
      await tester.pump(Duration(milliseconds: stepMs));
      stepMs = e2eNextIdlePollStepMs(stepMs);
    }
    return false;
  }

  final sw = Stopwatch()..start();
  var navalPollMs = 25;
  while (sw.elapsed < timeout) {
    if (navalPanel.evaluate().isNotEmpty) {
      perf?.timing('open_panel_naval', phaseSw.elapsed);
      return;
    }
    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await e2eCloseBottomSheet(
        tester,
        perf: perf,
        overallTimeout: bottomSheetCloseTimeout,
      );
      navalPollMs = 25;
      continue;
    }
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await e2eDismissTransientUi(tester, perf: perf);
      navalPollMs = 25;
      continue;
    }
    if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
      await e2eDismissTransientUi(tester, perf: perf);
      navalPollMs = 25;
      continue;
    }
    final markerHit = markerBtn.hitTestable();
    if (markerHit.evaluate().isNotEmpty) {
      await tester.tap(markerHit.first, warnIfMissed: false);
      if (await pollUntilNavalVisible(const Duration(seconds: 2))) {
        perf?.timing('open_panel_naval', phaseSw.elapsed);
        return;
      }
      if (await e2ePumpUntilConditionOrIdle(
        tester,
        () => navalPanel.evaluate().isNotEmpty,
        timeout: const Duration(milliseconds: 600),
        perf: perf,
        phaseName: 'pump_until_naval_visible_after_marker_tap',
      )) {
        perf?.timing('open_panel_naval', phaseSw.elapsed);
        return;
      }
      navalPollMs = 25;
      continue;
    }
    final railHit = btn.hitTestable();
    if (railHit.evaluate().isNotEmpty) {
      await tester.tap(railHit.first, warnIfMissed: false);
      if (await pollUntilNavalVisible(const Duration(seconds: 3))) {
        perf?.timing('open_panel_naval', phaseSw.elapsed);
        return;
      }
      if (await e2ePumpUntilConditionOrIdle(
        tester,
        () => navalPanel.evaluate().isNotEmpty,
        timeout: const Duration(milliseconds: 600),
        perf: perf,
        phaseName: 'pump_until_naval_visible_after_rail_tap',
      )) {
        perf?.timing('open_panel_naval', phaseSw.elapsed);
        return;
      }
      navalPollMs = 25;
      continue;
    }
    await e2eDismissTransientUi(tester, perf: perf);
    await tester.pump(Duration(milliseconds: navalPollMs));
    navalPollMs = e2eAdaptivePollRampAfterIdle(navalPollMs);
  }
  fail(
    'Timed out after ${timeout.inSeconds}s opening naval panel. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Opens a map-marker panel when [markerButton] is tappable and [panelRoot] mounts.
///
/// Shared full-turn path for tile-scoped civilian/naval markers (GitHub #2336 AC2).
Future<void> e2eOpenPanelFromMarker(
  WidgetTester tester, {
  required Finder markerButton,
  required Finder panelRoot,
  Duration timeout = const Duration(seconds: 20),
  E2ePerfLog? perf,
}) async {
  final sw = Stopwatch()..start();
  var panelPollMs = 25;
  while (sw.elapsed < timeout) {
    if (panelRoot.evaluate().isNotEmpty) {
      perf?.timing('open_panel_from_marker', sw.elapsed);
      return;
    }
    final tappable = markerButton.hitTestable();
    if (tappable.evaluate().isEmpty) {
      await e2eDismissTransientUi(tester, perf: perf);
      if (panelRoot.evaluate().isNotEmpty) {
        perf?.timing('open_panel_from_marker', sw.elapsed);
        return;
      }
      if (await e2ePumpUntilConditionOrIdle(
        tester,
        () => markerButton.hitTestable().evaluate().isNotEmpty,
        timeout: Duration(milliseconds: panelPollMs),
        perf: perf,
        phaseName: 'pump_until_marker_hit_testable_after_dismiss',
      )) {
        panelPollMs = 25;
      } else {
        panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
      }
      continue;
    }
    await tester.tap(tappable.first, warnIfMissed: false);
    if (panelRoot.evaluate().isNotEmpty) {
      perf?.timing('open_panel_from_marker', sw.elapsed);
      return;
    }
    await tester.pump();
    if (panelRoot.evaluate().isNotEmpty) {
      perf?.timing('open_panel_from_marker', sw.elapsed);
      return;
    }
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () => panelRoot.evaluate().isNotEmpty,
      timeout: const Duration(seconds: 3),
      perf: perf,
      phaseName: 'pump_until_marker_panel_root_after_tap',
    )) {
      perf?.timing('open_panel_from_marker', sw.elapsed);
      return;
    }
    panelPollMs = 25;
    await tester.pump(Duration(milliseconds: panelPollMs));
    panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
  }
  fail(
    'Timed out after ${timeout.inSeconds}s opening marker panel. '
    'marker=$markerButton panel=$panelRoot Last exception: ${tester.takeException()}',
  );
}

/// Opens the production screen from the empire rail, closing conflicting sheets
/// and dialogs first (GitHub #2336 H7 / shared full-turn path).
Future<void> e2eOpenProductionPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final productionPanel = find.byKey(kCtE2EProductionPanelRootKey);
  final productionButton = find.byKey(kEmpireProductionButtonKey);
  final sw = Stopwatch()..start();
  var idlePollMs = 25;
  while (sw.elapsed < timeout) {
    if (productionPanel.evaluate().isNotEmpty) {
      perf?.timing('open_panel_production', sw.elapsed);
      return;
    }

    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await e2eCloseBottomSheet(tester, perf: perf);
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => find.byType(BottomSheet).evaluate().isEmpty,
        timeout: const Duration(milliseconds: 600),
        perf: perf,
        phaseName: 'pump_until_sheet_cleared_production_open',
      );
      idlePollMs = 25;
      continue;
    }

    if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
      await tester.binding.handlePopRoute();
      await e2ePumpUntil(
        tester,
        () => find.byType(CtDialogShell).evaluate().isEmpty,
        timeout: const Duration(seconds: 2),
        perf: perf,
        phaseName: 'pump_until_production_path_shell_cleared',
      );
      idlePollMs = 25;
      continue;
    }

    if (productionButton.evaluate().isNotEmpty) {
      final productionButtonHit = productionButton.hitTestable();
      final target = productionButtonHit.evaluate().isNotEmpty
          ? productionButtonHit
          : productionButton;
      await tester.tap(target.first, warnIfMissed: false);
      if (productionPanel.evaluate().isNotEmpty) {
        perf?.timing('open_panel_production', sw.elapsed);
        return;
      }
      idlePollMs = 25;
      await tester.pump();
      if (productionPanel.evaluate().isNotEmpty) {
        perf?.timing('open_panel_production', sw.elapsed);
        return;
      }
      await e2eWaitUntilFound(
        tester,
        productionPanel,
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'wait_until_production_panel_after_rail_tap',
      );
      if (productionPanel.evaluate().isNotEmpty) {
        perf?.timing('open_panel_production', sw.elapsed);
        return;
      }
      if (await e2ePumpUntilConditionOrIdle(
        tester,
        () => productionPanel.evaluate().isNotEmpty,
        timeout: const Duration(milliseconds: 600),
        perf: perf,
        phaseName: 'pump_until_production_panel_after_rail_tap_miss',
      )) {
        perf?.timing('open_panel_production', sw.elapsed);
        return;
      }
      idlePollMs = 25;
      continue;
    }
    await e2eDismissTransientUi(tester, perf: perf);
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () =>
          productionPanel.evaluate().isNotEmpty ||
          productionButton.hitTestable().evaluate().isNotEmpty,
      timeout: Duration(milliseconds: idlePollMs),
      perf: perf,
      phaseName: 'pump_until_production_entry_after_dismiss_transient',
    )) {
      idlePollMs = 25;
    } else {
      idlePollMs = e2eAdaptivePollRampAfterIdle(idlePollMs);
    }
  }

  fail(
    'Timed out opening production panel; '
    'button=$productionButton panel=$productionPanel',
  );
}

/// Splits the home fleet once via the naval panel (GitHub #2336 H8).
Future<void> e2eSplitHomeFleetOnce(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration openNavalTimeout = kE2eDefaultNavalOpenTimeout,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
}) async {
  final phaseSw = Stopwatch()..start();
  await e2eOpenNavalPanel(
    tester,
    perf: perf,
    timeout: openNavalTimeout,
    bottomSheetCloseTimeout: bottomSheetCloseTimeout,
  );
  await e2eExpandEachExpansionTileOnce(tester);
  final navalPanelRoot = find.byKey(kCtE2ENavalPanelRootKey);
  final split = find.descendant(
    of: navalPanelRoot,
    matching: find.text('Split'),
  );
  expect(split, findsWidgets);
  await tester.tap(split.first, warnIfMissed: false);
  await e2eWaitUntilFound(
    tester,
    find.descendant(
      of: find.byType(CtDialogShell),
      matching: find.widgetWithText(CtNinePatchButton, '>'),
    ),
    timeout: const Duration(seconds: 4),
    perf: perf,
    phaseName: 'wait_until_found_split_nudge_right',
  );

  final moveOneRight = find.descendant(
    of: find.byType(CtDialogShell),
    matching: find.widgetWithText(CtNinePatchButton, '>'),
  );
  expect(moveOneRight, findsWidgets);
  await tester.tap(moveOneRight.first);
  await e2eWaitUntilFound(
    tester,
    find.text(l10n.splitFleet_confirm),
    timeout: const Duration(seconds: 4),
    perf: perf,
    phaseName: 'wait_until_found_split_confirm',
  );
  await tester.tap(find.text(l10n.splitFleet_confirm));
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => find.byType(CtDialogShell).evaluate().isEmpty,
    timeout: const Duration(milliseconds: 500),
    perf: perf,
    phaseName: 'pump_until_split_dialog_shell_cleared',
  );
  await e2eExpandEachExpansionTileOnce(tester);
  perf?.timing('fleet_split', phaseSw.elapsed);
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

