part of 'new_game_fleet_reaches_new_world_e2e_test.dart';

/// Locked full-init may succeed only after [GameService] bumps `mapSeed` on a
/// topology/assigner retry (`effectiveSeed + 100003`, …), producing longer
/// coast→warp→New World paths than nominal seed-42 alone. Keep this above the
/// worst observed CI need (Refs #1849 / PR 1849).
const int _kMaxNextTurnTapsForNwFleetReach = 35;

/// Hard cap for any single “wait until UI shows X” poll (`waitUntilFound`,
/// next-turn label settle, panel-open loops). Fail immediately when exceeded.
const Duration _kMaxUiResponseWait = Duration(seconds: 5);

/// Entire fleet e2e must finish within this wall clock (success or guarded fail).
///
/// E2E policy caps wall-clock runtime to 5 minutes so PR feedback remains fast.
const Duration _kFleetE2eMaxWallClock = Duration(minutes: 5);

/// Selects the New World map region via [kCtE2ERegionTabNewWorldKey] when present
/// (reduces ambiguous "New World" text on screen; `SPEC/program/e2e-integration-tests.md`).
///
/// Adaptive replacement for fixed post-tap idle pumps (GitHub #2336 / AC4–AC5):
/// uses [e2ePumpUntilConditionOrIdle] with [e2eNewWorldRegionChipAppearsSelected]
/// so a no-op tap (already-selected) short-circuits before the first pump, while
/// a bounded worst-case wait remains for Linux headless when the tab must flip.
Future<void> _tapNewWorldRegionTabIfPresent(WidgetTester tester) async {
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

/// Map HUD must show **Old World** before issuing naval moves so OW-split
/// fleets and warp orders stay coherent on Linux CI (`SPEC/program/e2e-integration-tests.md`).
///
/// Adaptive replacement for fixed post-tap idle pumps (GitHub #2336 / AC4–AC5):
/// uses [e2ePumpUntilConditionOrIdle] with [e2eOldWorldRegionChipAppearsSelected]
/// so an already-selected chip exits immediately; otherwise polls with adaptive
/// pacing up to a bounded timeout.
Future<void> _tapOldWorldRegionTab(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
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

Finder _radioListTilesInAlertDialogs() {
  return find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byWidgetPredicate(
      (w) => w.runtimeType.toString().startsWith('RadioListTile<'),
    ),
  );
}

/// Prefer cross-region warp row (English copy); else first adjacent sea tile.
///
/// When [allowWarpDestinations] is false, only S–S (radio) destinations are
/// used. Post–#1869 the split fleet may already be in the New World; the move
/// dialog still lists a warp row to the Old World—tapping it every turn
/// prevents sailing along NW seas toward a P–S coastal zone.
Future<void> _pickMoveDestinationAndConfirm(
  WidgetTester tester,
  AppLocalizations l10n, {
  bool allowWarpDestinations = true,
}) async {
  final budget = Stopwatch()..start();
  void ensureBudget(String step) {
    if (budget.elapsed > _kMaxUiResponseWait) {
      fail(
        'Move fleet dialog exceeded ${_kMaxUiResponseWait.inSeconds}s at $step',
      );
    }
  }

  ensureBudget('start');
  await waitUntilFound(
    tester,
    find.byType(AlertDialog),
    timeout: const Duration(seconds: 2),
    phaseName: 'wait_until_found_move_dialog',
  );
  final warpSuffix = l10n.moveFleet_warpLinkToRegion(
    unitsPanelRegionLabel('newWorld'),
  );
  final warp = find.textContaining(warpSuffix);
  if (allowWarpDestinations && warp.evaluate().isNotEmpty) {
    final scrollRoot = find.byKey(kCtE2EMoveFleetDialogScrollRootKey);
    final Finder scrollable;
    if (scrollRoot.evaluate().isNotEmpty) {
      scrollable = find.descendant(
        of: scrollRoot,
        matching: find.byType(Scrollable),
      );
    } else {
      scrollable = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Scrollable),
      );
    }
    if (scrollable.evaluate().isNotEmpty) {
      final sc = scrollable.first;
      if (warp.hitTestable().evaluate().isEmpty) {
        try {
          await tester.scrollUntilVisible(warp.first, 200, scrollable: sc);
        } catch (_) {
          // Row may not be built yet; fall back to drag probing below.
        }
      }
      const maxWarpDragProbes = 8;
      for (var i = 0;
          i < maxWarpDragProbes && warp.hitTestable().evaluate().isEmpty;
          i++) {
        ensureBudget('warp drag $i');
        await tester.drag(sc, const Offset(0, -120));
        // Short-circuit as soon as the warp row becomes hit-testable instead of
        // a single frame pump per drag (Refs #2336 H4 / adaptive polling).
        await e2ePumpUntilConditionOrIdle(
          tester,
          () => warp.hitTestable().evaluate().isNotEmpty,
          timeout: const Duration(milliseconds: 400),
          phaseName: 'pump_until_warp_row_visible_after_move_dialog_drag',
        );
      }
      if (warp.hitTestable().evaluate().isEmpty) {
        fail(
          'Warp row not hit-testable after drag attempts '
          '(within ${_kMaxUiResponseWait.inSeconds}s dialog budget).',
        );
      }
    }
    ensureBudget('before warp tap');
    final hit = warp.hitTestable();
    expect(hit, findsWidgets);
    // Tap the RadioListTile, not only the inner Text, so the tile's selection
    // updates before Confirm (Linux CI / headless can miss implicit tile taps).
    final warpTile = find.ancestor(
      of: hit.first,
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('RadioListTile<'),
      ),
    );
    expect(warpTile, findsWidgets);
    await tester.tap(warpTile.first, warnIfMissed: false);
  } else {
    ensureBudget('sea radio');
    final seaRadio = _radioListTilesInAlertDialogs();
    expect(seaRadio, findsWidgets);
    await tester.tap(seaRadio.first, warnIfMissed: false);
  }
  await waitUntilFound(
    tester,
    find.text(l10n.common_confirm),
    timeout: const Duration(seconds: 2),
    phaseName: 'wait_until_found_move_confirm',
  );
  ensureBudget('confirm');
  final confirm = find.text(l10n.common_confirm).hitTestable();
  expect(confirm, findsWidgets);
  await tester.tap(confirm.first, warnIfMissed: false);
  await e2ePumpUntil(
    tester,
    () => find.byType(AlertDialog).evaluate().isEmpty,
    timeout: const Duration(seconds: 2),
    phaseName: 'pump_until_move_dialog_closed',
  );
  ensureBudget('after confirm');
}

Future<void> _tryNavalMoveSegment(
  WidgetTester tester,
  AppLocalizations l10n, {
  bool useNewWorldMapTabFirst = false,
  bool allowWarpDestinations = true,
  /// When true, the naval panel is already open from a prior [openNavalPanel]
  /// in the same turn iteration — skip close/reopen (Refs #2336 Bottleneck 4).
  bool navalPanelAlreadyOpen = false,
  E2ePerfLog? perf,
}) async {
  final phaseSw = Stopwatch()..start();
  if (useNewWorldMapTabFirst) {
    await _tapNewWorldRegionTabIfPresent(tester);
  } else {
    await _tapOldWorldRegionTab(tester, l10n);
  }
  if (!navalPanelAlreadyOpen) {
    await openNavalPanel(
      tester,
      perf: perf,
      timeout: _kMaxUiResponseWait,
      bottomSheetCloseTimeout: _kMaxUiResponseWait,
    );
  }
  final tappedMove = await _tapMoveOnFirstNonHomeFleet(tester);
  if (!tappedMove) {
    perf?.timing(
      'fleet_move_segment',
      phaseSw.elapsed,
      meta: 'result=no_non_home_move_control',
    );
    return;
  }
  await waitUntilFound(
    tester,
    find.byType(AlertDialog),
    timeout: const Duration(seconds: 2),
    phaseName: 'wait_until_found_move_dialog_after_tap',
  );
  // No legal sea-step this turn: close dialog and rely on the outer loop +
  // next turn (Refs #1831 heuristic path).
  if (find.text(l10n.moveFleet_noAdjacentSeaZones).evaluate().isNotEmpty) {
    final cancel = find.text(l10n.common_cancel).hitTestable();
    expect(cancel, findsOneWidget);
    await tester.tap(cancel, warnIfMissed: false);
    await e2ePumpUntil(
      tester,
      () => find.byType(AlertDialog).evaluate().isEmpty,
      timeout: const Duration(seconds: 2),
      perf: perf,
      phaseName: 'pump_until_cancel_move_dialog_closed',
    );
    perf?.timing(
      'fleet_move_segment',
      phaseSw.elapsed,
      meta: 'result=no_legal_step',
    );
    return;
  }
  if (find.byType(AlertDialog).evaluate().isNotEmpty) {
    await _pickMoveDestinationAndConfirm(
      tester,
      l10n,
      allowWarpDestinations: allowWarpDestinations,
    );
  }
  perf?.timing('fleet_move_segment', phaseSw.elapsed);
}
