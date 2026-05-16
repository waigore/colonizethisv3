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
          (w) => w is Text && _textLooksLikeNewWorldLocationLine(w.data),
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

/// `naval_tree_builder.dart` uses an em dash; accept common dash glyphs for CI.
bool _textLooksLikeNewWorldLocationLine(String? data) {
  if (data == null) return false;
  final t = data.trimLeft();
  const prefix = 'New World';
  if (!t.startsWith(prefix)) return false;
  final after = t.substring(prefix.length);
  if (after.isEmpty) return false;
  // Em dash (UI), en dash, hyphen-minus, optional spaces.
  final rest = after.trimLeft();
  return rest.startsWith('—') || rest.startsWith('–') || rest.startsWith('-');
}

/// While the naval bottom sheet is open, [ctE2eNavalPanelSnapshot] mirrors the same
/// [Game] the panel uses (`SPEC/program/e2e-integration-tests.md`). Prefer this on
/// Linux CI: [ExpansionTile] / [Text] preorder can diverge from macOS while world
/// state still shows the voyage completed.
bool _nonHomeHumanFleetInNewWorldFromCtSnapshot() {
  final snap = ctE2eNavalPanelSnapshot;
  if (snap == null) return false;
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

/// [provinceIdsAdjacentToSeaZone] matches edge endpoints exactly. Combined game
/// topology uses prefixed sea node ids (`newWorld|sea5`); some fleet states
/// still carry the regional local id (`sea5`). Try both so coastal detection
/// matches logic/ship-reveal (`SPEC/program/fog-and-exploration-resolution.md`).
Set<String> _nwCoastalProvincesAdjacentToFleetSea(
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

/// Ship reveal only paints coastal land for sea zones with a P–S province edge
/// (`SPEC/program/fog-and-exploration-resolution.md`). Open-ocean NW sea
/// placement satisfies [ _nonHomeHumanFleetInNewWorldFromCtSnapshot ] but never
/// yields fogged/visible NW provinces, so bundled Explore stays disabled.
bool _nonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot() {
  final snap = ctE2eNavalPanelSnapshot;
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
    if (_nwCoastalProvincesAdjacentToFleetSea(
      snap.topology,
      sea,
      regionId,
    ).isNotEmpty) {
      return true;
    }
  }
  return false;
}

bool _playerHasAnyNewWorldFoggedOrBetterFromCtSnapshot() {
  final snap = ctE2eNavalPanelSnapshot;
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

/// Widget-only: a **non–home** fleet row shows [unitsPanelRegionLabel] for New World
/// in the subtitle location line (`New World — …` per `naval_tree_builder.dart`).
bool _navalPanelShowsNonHomeFleetInNewWorld(WidgetTester tester) {
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
        (w) => w is Text && _textLooksLikeNewWorldLocationLine(w.data),
      ),
    );
    if (loc.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

bool _harnessDetectsNonHomeFleetInNewWorld(WidgetTester tester) =>
    _nonHomeHumanFleetInNewWorldFromCtSnapshot() ||
    // Fallback for environments where ct snapshot plumbing is unavailable.
    (ctE2eNavalPanelSnapshot == null &&
        _navalPanelShowsNonHomeFleetInNewWorld(tester));

/// Post–next-turn [ctE2eNavalPanelSnapshot] refresh (see
/// [refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled]) lets fleet loops skip
/// [openNavalPanel] when world state already shows arrival (Refs #2336).
bool _fleetReachDoneFromCtSnapshotOnly() =>
    _nonHomeHumanFleetInNewWorldFromCtSnapshot();

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
    if (_nonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot() ||
        _playerHasAnyNewWorldFoggedOrBetterFromCtSnapshot()) {
      return;
    }
    await openNavalPanel(
      tester,
      timeout: _kMaxUiResponseWait,
      bottomSheetCloseTimeout: _kMaxUiResponseWait,
    );
    if (_nonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot() ||
        _playerHasAnyNewWorldFoggedOrBetterFromCtSnapshot()) {
      await closeBottomSheet(tester, overallTimeout: _kMaxUiResponseWait);
      return;
    }
    await _tryNavalMoveSegment(
      tester,
      l10n,
      useNewWorldMapTabFirst: true,
      allowWarpDestinations: false,
      navalPanelAlreadyOpen: true,
    );
    await closeBottomSheet(tester, overallTimeout: _kMaxUiResponseWait);
    await _advanceOneHumanTurn(tester, l10n);
    if (_nonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot() ||
        _playerHasAnyNewWorldFoggedOrBetterFromCtSnapshot()) {
      return;
    }
  }
  // Some generated maps can keep the non-home fleet in open-ocean NW sea lanes
  // for long bounded stretches; in that case bundled Explore has no visible NW
  // destinations yet. Leave strict assertion to the final Explore-enabled check.
}

String _bundledExploreRejectionDiagnostics([
  CtE2eNavalPanelSnapshot? lastKnownNavalSnapshot,
]) {
  final navalSnap = lastKnownNavalSnapshot ?? ctE2eNavalPanelSnapshot;
  final civilianSnap = ctE2eCivilianPanelSnapshot;
  if (navalSnap == null) {
    return 'No ctE2eNavalPanelSnapshot available for diagnostics.';
  }
  final game = navalSnap.game;
  final topology = navalSnap.topology;
  final playerId = navalSnap.humanPlayerId;
  final orders = navalSnap.draftOrders;
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestWorkOrders(view, game, topology, orders);

  bool provinceHasFoggedOrBetter(String provinceFullId) {
    final regionId = ProvinceId.regionIdFrom(provinceFullId);
    final localId = ProvinceId.localIdFrom(provinceFullId);
    for (final e in view.visibilityByTile.entries) {
      final parts = e.key.split('|');
      if (parts.length != 4) {
        continue;
      }
      if (parts[0] != regionId || parts[1] != localId) {
        continue;
      }
      if (e.value.name != 'unknown') {
        return true;
      }
    }
    return false;
  }

  final lines = <String>[
    'diag: player=$playerId',
    'diag: civilianSnapshotAvailable=${civilianSnap != null}',
    if (civilianSnap != null)
      'diag: availableWorkTargets=${civilianSnap.availableWorkTargets}',
    'diag: draftMoveOrders=${orders.moveOrdersByPlayerId[playerId]?.map((o) => "${o.unitId}->${Unit.provinceIdFromTileKey(o.destinationTileKey) ?? "?"}").toList() ?? const []}',
    'diag: suggestedExplore=${suggestions.where((o) => o.target == kWorkTargetExplore).map((o) => "${o.unitId}@${Unit.provinceIdFromTileKey(o.targetTileKey) ?? "?"}").toList()}',
  ];

  final explorerUnits =
      view.ownUnits.where((u) => u.type == kUnitTypeExplorer).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  if (explorerUnits.isEmpty) {
    lines.add('diag: no explorer units found in player view.');
    return lines.join('\n');
  }

  final provinces = allProvinces(game.worldState).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final tribeIds = game.tribes.map((t) => t.id).toSet();
  final minorIds = game.minorNations.map((m) => m.id).toSet();
  for (final unit in explorerUnits) {
    lines.add(
      'diag: explorer unit=${unit.id} atProvince=${unit.locationProvinceId} tileKey=${unit.tileKey ?? "(null)"}',
    );
    for (final prov in provinces) {
      final foggedOrBetter = provinceHasFoggedOrBetter(prov.id);
      final owner = prov.ownerId;
      final ownerKind = owner == null
          ? 'none'
          : owner == playerId
          ? 'self'
          : tribeIds.contains(owner)
          ? 'tribe'
          : minorIds.contains(owner)
          ? 'minor'
          : 'gp';
      final targetTileKey = '${prov.id}|0|0';
      final workRes = OrderEngine(initialOrders: orders)
          .addWorkOrderWithContext(
            game,
            topology,
            playerId,
            WorkOrder(
              unitId: unit.id,
              target: kWorkTargetExplore,
              targetTileKey: targetTileKey,
            ),
          );
      final moveRes = OrderEngine(initialOrders: orders)
          .addMoveOrderWithContext(
            game,
            topology,
            playerId,
            MoveOrder(unitId: unit.id, destinationTileKey: '${prov.id}|0|0'),
          );
      lines.add(
        'diag: province=${prov.id} owner=${prov.ownerId ?? "(none)"} ownerKind=$ownerKind '
        'visibleFoggedPlus=$foggedOrBetter '
        'workAccepted=${workRes.isAccepted} workReason=${workRes.reason ?? "(none)"} '
        'moveAccepted=${moveRes.isAccepted} moveReason=${moveRes.reason ?? "(none)"}',
      );
    }
  }
  return lines.join('\n');
}

/// Text inside the map HUD next-turn [CtNinePatchButton] (`game_nextTurnButton`).
String? _readNextTurnButtonLabel(WidgetTester tester) {
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

/// When the civilian panel is open, [ctE2eCivilianPanelSnapshot] mirrors
/// [availableWorkTargetIdsForUnitProvider] — the same work-target ids that
/// drive enabled Assign rows. Returns `null` when no snapshot is available.
bool? _exploreAssignEnabledFromCivilianSnapshot() {
  final snap = ctE2eCivilianPanelSnapshot;
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

Future<bool> _anyExplorerHasEnabledExploreAssignFleetE2e(
  WidgetTester tester,
) async {
  final snapshotHint = _exploreAssignEnabledFromCivilianSnapshot();
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
/// `waitForNextTurnLabelAdvance` helper referenced by #2336 AC5: success is
/// checked before each pump and intervals ramp via
/// [e2eAdaptivePollRampAfterIdle] (25→50→75→100 ms cap), while the
/// [_kMaxUiResponseWait] post-tap budget is preserved. The final label poll
/// evaluates the label before each idle pump, matching [e2eWaitForNextTurnLabelAdvance].
Future<void> _advanceOneHumanTurn(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
}) async {
  final phaseSw = Stopwatch()..start();
  final before = _readNextTurnButtonLabel(tester);
  await tester.tap(find.byKey(kGameMapNextTurnButtonKey));
  perf?.bumpCounter('next_turn_taps');

  // After tapping Next Turn the app either pops a confirm dialog or starts
  // resolving immediately. Poll adaptively for whichever lands first so we
  // never pay a worst-case fixed settle here.
  final confirmFinder = find.text(l10n.common_yes);
  await e2ePumpUntilConditionOrIdle(
    tester,
    () {
      if (confirmFinder.hitTestable().evaluate().isNotEmpty) {
        return true;
      }
      final maybeAfter = _readNextTurnButtonLabel(tester);
      return maybeAfter != null && maybeAfter != before;
    },
    timeout: const Duration(milliseconds: 400),
    perf: perf,
    phaseName: 'pump_until_next_turn_confirm_or_label_advanced',
  );
  final earlyAfter = _readNextTurnButtonLabel(tester);
  if (earlyAfter != null && earlyAfter != before) {
    perf?.timing('next_turn_advance', phaseSw.elapsed);
    return;
  }

  final confirmNextTurn = confirmFinder.hitTestable();
  if (confirmNextTurn.evaluate().isNotEmpty) {
    await tester.tap(confirmNextTurn.first, warnIfMissed: false);
    // Adaptive replacement for the prior fixed 150ms settle (#2336 AC5):
    // briefly pump to flush the confirm tap so the next-turn label poll
    // below evaluates a fresh widget tree, then fall through to the
    // condition-first poll loop.
    await tester.pump();
  }

  final sw = Stopwatch()..start();
  // Check before the first pump so already-advanced labels short-circuit
  // (same ordering as [e2eWaitForNextTurnLabelAdvance] in e2e_test_shared).
  final immediateAfter = _readNextTurnButtonLabel(tester);
  if (immediateAfter != null && immediateAfter != before) {
    perf?.timing('next_turn_advance', phaseSw.elapsed);
    return;
  }
  var labelPollMs = 25;
  while (sw.elapsed < _kMaxUiResponseWait) {
    final after = _readNextTurnButtonLabel(tester);
    if (after != null && after != before) {
      perf?.timing('next_turn_advance', phaseSw.elapsed);
      return;
    }
    await tester.pump(Duration(milliseconds: labelPollMs));
    labelPollMs = e2eAdaptivePollRampAfterIdle(labelPollMs);
  }
  fail(
    'Next turn label did not change within ${_kMaxUiResponseWait.inSeconds}s '
    '(before=${before ?? '(null)'}). Last exception: ${tester.takeException()}',
  );
}
