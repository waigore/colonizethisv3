part of 'new_game_fleet_reaches_new_world_e2e_test.dart';

Future<bool> _tapMoveOnFirstNonHomeFleet(WidgetTester tester) async {
  Future<bool> tryTap({required bool allowExpandAllFallback}) async {
    final navalRoot = find.byKey(kCtE2ENavalPanelRootKey);
    final tiles = find.descendant(
      of: navalRoot,
      matching: find.byType(ExpansionTile),
    );
    var n = tiles.evaluate().length;
    if (n == 0) {
      // Panel can mount before fleet rows render; poll instead of a fixed delay.
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => tiles.evaluate().isNotEmpty,
        timeout: const Duration(seconds: 2),
        phaseName: 'pump_until_naval_expansion_tiles_render',
      );
      n = tiles.evaluate().length;
      if (n == 0) {
        return false;
      }
    }
    if (n == 1) {
      final onlyTile = tiles.first;
      final onlyHome = find.descendant(
        of: onlyTile,
        matching: find.text('Home Fleet'),
      );
      if (onlyHome.evaluate().isNotEmpty) {
        return false;
      }
    }
    Finder? fallbackMove;
    for (var i = 0; i < n; i++) {
      final sub = tiles.at(i);
      final home = find.descendant(of: sub, matching: find.text('Home Fleet'));
      if (home.evaluate().isNotEmpty) {
        continue;
      }
      final fleetTitle = find.descendant(
        of: sub,
        matching: find.byWidgetPredicate(
          (w) => w is Text && (w.data?.startsWith('Fleet ') ?? false),
        ),
      );
      if (fleetTitle.evaluate().isEmpty) {
        continue;
      }
      var move = find.descendant(of: sub, matching: find.text('Move'));
      if (move.evaluate().isEmpty) {
        final expandIcon = find.descendant(
          of: sub,
          matching: find.byIcon(Icons.expand_more),
        );
        if (expandIcon.evaluate().isNotEmpty) {
          final iconHit = expandIcon.first;
          await tester.ensureVisible(iconHit);
          await tester.tap(iconHit, warnIfMissed: false);
          await waitUntilFound(
            tester,
            find.descendant(of: sub, matching: find.text('Move')),
            timeout: const Duration(seconds: 3),
            phaseName: 'wait_until_found_move_after_expand',
          );
        }
        move = find.descendant(of: sub, matching: find.text('Move'));
      }
      if (move.evaluate().isEmpty) {
        continue;
      }
      final loc = find.descendant(
        of: sub,
        matching: find.byWidgetPredicate(
          (w) => w is Text && e2eTextLooksLikeNewWorldLocationLine(w.data),
        ),
      );
      final hit = move.hitTestable();
      if (hit.evaluate().isEmpty) {
        continue;
      }
      if (loc.evaluate().isNotEmpty) {
        await tester.tap(hit.first, warnIfMissed: false);
        await waitUntilFound(
          tester,
          find.byType(AlertDialog),
          timeout: const Duration(seconds: 3),
          phaseName: 'wait_until_found_move_dialog_after_move_tap',
        );
        return true;
      }
      fallbackMove ??= hit.first;
    }
    if (fallbackMove != null) {
      await tester.tap(fallbackMove, warnIfMissed: false);
      await waitUntilFound(
        tester,
        find.byType(AlertDialog),
        timeout: const Duration(seconds: 3),
        phaseName: 'wait_until_found_move_dialog_after_move_tap_fallback',
      );
      return true;
    }
    if (allowExpandAllFallback) {
      await expandEachExpansionTileOnce(tester);
      return false;
    }
    return false;
  }

  if (await tryTap(allowExpandAllFallback: true)) {
    return true;
  }
  if (await tryTap(allowExpandAllFallback: false)) {
    return true;
  }
  return false;
}

/// Naval-panel location row detection moved to
/// [e2eTextLooksLikeNewWorldLocationLine] (`e2e_test_shared.dart`) so the
/// dash-glyph contract is unit-pinned (Refs GitHub #2336).

/// Non-home human fleet-in-NW detection moved to
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] (`e2e_test_shared.dart`)
/// so the snapshot-driven contract is unit-pinned (Refs GitHub #2336 AC1 /
/// AC2). Call sites pass [ctE2eNavalPanelSnapshot] explicitly.

/// Coastal sea-zone adjacency lookup with prefixed-id fallback moved to
/// [e2eNwCoastalProvincesAdjacentToFleetSea] (`e2e_test_shared.dart`) so the
/// two-tier `provinceIdsAdjacentToSeaZone` contract is unit-pinned and shared
/// across scenarios (Refs GitHub #2336 AC1 / AC2). The combined topology
/// uses prefixed sea node ids (`newWorld|sea5`) while some fleet states
/// still carry the regional local id (`sea5`); the lifted helper tries
/// both so coastal detection matches logic/ship-reveal
/// (`SPEC/program/fog-and-exploration-resolution.md`).

/// Non-home human fleet-in-NW-coastal-sea detection moved to
/// [e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot]
/// (`e2e_test_shared.dart`) so the snapshot-driven coastal contract is
/// unit-pinned (Refs GitHub #2336 AC1 / AC2). Ship reveal only paints
/// coastal land for sea zones with a P–S province edge
/// (`SPEC/program/fog-and-exploration-resolution.md`). Open-ocean NW sea
/// placement satisfies [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] but
/// never yields fogged/visible NW provinces, so bundled Explore stays
/// disabled. Call sites pass [ctE2eNavalPanelSnapshot] explicitly.

/// NW fogged-or-better detection moved to
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] (`e2e_test_shared.dart`)
/// so the [PlayerView]-driven contract is unit-pinned (Refs GitHub #2336
/// AC1 / AC2). Call sites pass [ctE2eNavalPanelSnapshot] explicitly.

/// Naval-panel widget fallback for fleet-in-NW detection moved to
/// [e2eNavalPanelShowsNonHomeFleetInNewWorld] (`e2e_test_shared.dart`) so the
/// ExpansionTile / location-line contract is unit-pinned (Refs GitHub #2336
/// AC1 / AC2).

/// `_harnessDetectsNonHomeFleetInNewWorld` and `_fleetReachDoneFromCtSnapshotOnly`
/// were lifted into [e2eHarnessDetectsNonHomeFleetInNewWorld] and
/// [e2eFleetReachDoneFromCtSnapshotOnly] (`e2e_test_shared.dart`, Refs #2336
/// AC1 / AC2). Call sites pass [ctE2eNavalPanelSnapshot] explicitly.

/// Post–#1869 only: fleet may sit in open-ocean New World first; ship reveal needs
/// a P–S coastal sea zone (or visibility already updated). Sail / advance until then.
Future<void> _awaitNwCoastalOrVisibleLandForBundledExploreE2e({
  required WidgetTester tester,
  required AppLocalizations l10n,
  required void Function(String step) ensureUnderWallClock,
}) async {
  const maxTurns = 35;
  for (var i = 0; i < maxTurns; i++) {
    ensureUnderWallClock('NW bundled-explore readiness i=$i');
    await dismissTransientUi(tester);
    await _tapNewWorldRegionTabIfPresent(tester);
    if (e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        ) ||
        e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        )) {
      return;
    }
    // Snapshot-backed paths skip redundant naval sheet open/close (Refs #2336).
    if (ctE2eNavalPanelSnapshot == null) {
      await openNavalPanel(
        tester,
        timeout: _kMaxUiResponseWait,
        bottomSheetCloseTimeout: _kMaxUiResponseWait,
      );
      if (e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            ctE2eNavalPanelSnapshot,
          ) ||
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            ctE2eNavalPanelSnapshot,
          )) {
        await closeBottomSheet(tester, overallTimeout: _kMaxUiResponseWait);
        return;
      }
    }
    await _tryNavalMoveSegment(
      tester,
      l10n,
      useNewWorldMapTabFirst: true,
      allowWarpDestinations: false,
      navalPanelAlreadyOpen: ctE2eNavalPanelSnapshot == null,
    );
    await closeBottomSheet(tester, overallTimeout: _kMaxUiResponseWait);
    await advanceOneHumanTurn(tester, l10n: l10n);
    if (e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        ) ||
        e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        )) {
      return;
    }
  }
  // Some generated maps can keep the non-home fleet in open-ocean NW sea lanes
  // for long bounded stretches; in that case bundled Explore has no visible NW
  // destinations yet. Leave strict assertion to the final Explore-enabled check.
}

/// `_bundledExploreRejectionDiagnostics` was lifted into the public
/// [e2eBundledExploreRejectionDiagnostics] in `e2e_test_shared.dart`
/// (Refs GitHub #2336 AC1 / AC2). The lifted form takes both
/// [CtE2eNavalPanelSnapshot] and [CtE2eCivilianPanelSnapshot] explicitly
/// rather than reading the global panel snapshots, so the diagnostic
/// surface is deterministic and unit-pinned in
/// `app/test/e2e_bundled_explore_rejection_diagnostics_test.dart`. Call
/// sites compose the global fallback (`x ?? ctE2eNavalPanelSnapshot`)
/// themselves before delegating to the public helper.

/// _exploreAssignEnabledFromCivilianSnapshot was lifted into the public
/// [e2eExploreAssignEnabledFromCivilianSnapshot] in `e2e_test_shared.dart`
/// (Refs GitHub #2336 AC1 / AC2). Call sites consume the public name and
/// pass `ctE2eCivilianPanelSnapshot` explicitly; the integration suite
/// re-exports it through the `e2e_helpers.dart` barrel and pins the
/// contract via
/// `app/test/e2e_explore_assign_enabled_from_civilian_snapshot_test.dart`.

Future<bool> _anyExplorerHasEnabledExploreAssignFleetE2e(
  WidgetTester tester,
) async {
  final snapshotHint = e2eExploreAssignEnabledFromCivilianSnapshot(
    ctE2eCivilianPanelSnapshot,
  );
  if (snapshotHint != null) {
    return snapshotHint;
  }

  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  final exploreTile = find.widgetWithText(ListTile, 'Explore');
  // Adaptive replacement (#2336 AC5 / Bottleneck 5): the prior 300ms post-tap
  // settle plus 50ms fixed wait loop is replaced by a single condition-based
  // wait that evaluates [exploreTile] before the first pump and ramps the
  // pump interval via [e2eAdaptivePollRampAfterIdle]. The hard
  // [_kMaxUiResponseWait] cap is preserved.
  Future<void> waitForAssignSheetSettled() async {
    final wait = Stopwatch()..start();
    var assignPollMs = 25;
    while (wait.elapsed < _kMaxUiResponseWait) {
      if (exploreTile.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(Duration(milliseconds: assignPollMs));
      assignPollMs = e2eAdaptivePollRampAfterIdle(assignPollMs);
    }
  }

  // After [handlePopRoute] the assign sheet can take a frame or two to leave
  // the tree. Replace the prior fixed 200ms pump with a bounded adaptive
  // poll that returns as soon as the sheet finishes dismissing.
  Future<void> waitForAssignSheetDismissed() async {
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => exploreTile.evaluate().isEmpty,
      timeout: const Duration(milliseconds: 400),
      phaseName: 'pump_until_assign_sheet_dismissed',
    );
  }

  final visitedAssignWidgets = <int>{};
  const maxPanelSweepSteps = 16;
  for (var step = 0; step < maxPanelSweepSteps; step++) {
    final assignCandidates = find
        .descendant(of: listView, matching: find.text('Assign'))
        .evaluate()
        .toList();
    for (final assignElement in assignCandidates) {
      final marker = identityHashCode(assignElement.widget);
      if (!visitedAssignWidgets.add(marker)) {
        continue;
      }
      final assignFinder = find.byWidget(assignElement.widget);
      try {
        await tester.ensureVisible(assignFinder);
      } catch (_) {
        continue;
      }
      await tester.tap(assignFinder.first, warnIfMissed: false);
      await waitForAssignSheetSettled();
      if (exploreTile.evaluate().isNotEmpty) {
        final enabled = tester.widget<ListTile>(exploreTile.first).enabled;
        await tester.binding.handlePopRoute();
        await waitForAssignSheetDismissed();
        if (enabled == true) {
          return true;
        }
      } else {
        await tester.binding.handlePopRoute();
        await waitForAssignSheetDismissed();
      }
    }

    await tester.drag(panelScrollable, const Offset(0, -180));
    // Adaptive replacement for the prior 120ms post-drag settle (#2336 AC5):
    // pump a single short frame and let the next iteration short-circuit if
    // new Assign rows are already visible.
    await tester.pump(const Duration(milliseconds: 25));
  }
  return false;
}

/// Taps the map HUD next-turn button, handles the optional confirm dialog,
/// and waits for the next-turn label to advance. This is the fleet e2e's
