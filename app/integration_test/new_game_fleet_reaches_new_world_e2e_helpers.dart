part of 'new_game_fleet_reaches_new_world_e2e_test.dart';

class _E2ePerfLog {
  _E2ePerfLog(this.testName);

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

/// Locked full-init may succeed only after [GameService] bumps `mapSeed` on a
/// topology/assigner retry (`effectiveSeed + 100003`, …), producing longer
/// coast→warp→New World paths than nominal seed-42 alone. Keep this above the
/// worst observed CI need (Refs #1849 / PR 1849).
const int _kMaxNextTurnTapsForNwFleetReach = 35;

/// Hard cap for any single “wait until UI shows X” poll (`_waitUntilFound`,
/// next-turn label settle, panel-open loops). Fail immediately when exceeded.
const Duration _kMaxUiResponseWait = Duration(seconds: 5);

/// Overall cap for async new-game setup (map gen + intro), not a single widget
/// poll; still bounded so hung runs exit (`SPEC/program/e2e-integration-tests.md`).
const Duration _kBootstrapNewGameOverallCap = Duration(seconds: 60);

/// Entire fleet e2e must finish within this wall clock (success or guarded fail).
///
/// E2E policy caps wall-clock runtime to 5 minutes so PR feedback remains fast.
const Duration _kFleetE2eMaxWallClock = Duration(minutes: 5);

/// Drive frames without [WidgetTester.pumpAndSettle] (Flame + progress spinners).
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

Future<void> _waitUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = _kMaxUiResponseWait,
  _E2ePerfLog? perf,
  String phaseName = 'wait_until_found',
}) async {
  final cap = timeout > _kMaxUiResponseWait ? _kMaxUiResponseWait : timeout;
  final sw = Stopwatch()..start();
  perf?.bumpCounter('wait_until_found_calls', meta: 'phase=$phaseName');
  while (sw.elapsed < cap) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found');
      return;
    }
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${cap.inSeconds}s waiting for $finder '
    '(max UI response ${_kMaxUiResponseWait.inSeconds}s). '
    'Last exception: ${tester.takeException()}',
  );
}

/// Dismisses blocking bottom sheets, dialog shells, snackbars, and generic OKs.
///
/// [AlertDialog] handling uses common action labels (including **Close** for
/// prior-turn [TurnNewsDialog], `SPEC/ui/turn-news-dialog.md`) plus
/// [WidgetsBinding.handlePopRoute] if none match.
Future<void> _dismissTransientUi(
  WidgetTester tester, {
  _E2ePerfLog? perf,
}) async {
  perf?.bumpCounter('dismiss_transient_ui_calls');
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    final snackAction = find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(TextButton),
    );
    if (snackAction.hitTestable().evaluate().isNotEmpty) {
      await tester.tap(snackAction.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(milliseconds: 200));
      return;
    }
  }
  final ok = find.text('OK').hitTestable();
  if (ok.evaluate().isNotEmpty) {
    await tester.tap(ok.first, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 200));
    return;
  }
  if (find.byType(AlertDialog).evaluate().isNotEmpty) {
    for (final label in ['Close', 'OK', 'Cancel', 'Yes']) {
      final hit = find
          .descendant(of: find.byType(AlertDialog), matching: find.text(label))
          .hitTestable();
      if (hit.evaluate().isNotEmpty) {
        await tester.tap(hit.first, warnIfMissed: false);
        await _pumpFor(tester, const Duration(milliseconds: 250));
        return;
      }
    }
    await tester.binding.handlePopRoute();
    await _pumpFor(tester, const Duration(milliseconds: 200));
    return;
  }
  if (find.byType(BottomSheet).evaluate().isNotEmpty) {
    await _closeBottomSheet(tester, perf: perf);
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
        await _pumpFor(tester, const Duration(milliseconds: 150));
        return;
      }
    }
    await tester.binding.handlePopRoute();
    await _pumpFor(tester, const Duration(milliseconds: 150));
  }
}

Future<void> _closeBottomSheet(WidgetTester tester, {_E2ePerfLog? perf}) async {
  perf?.bumpCounter('close_bottom_sheet_calls');
  bool anyPanelOpen() => find.byType(BottomSheet).evaluate().isNotEmpty;

  if (!anyPanelOpen()) {
    return;
  }

  final sw = Stopwatch()..start();
  while (sw.elapsed < _kMaxUiResponseWait) {
    if (!anyPanelOpen()) {
      perf?.timing('close_bottom_sheet', sw.elapsed);
      return;
    }
    await tester.binding.handlePopRoute();
    await _pumpFor(tester, const Duration(milliseconds: 250));
  }

  fail(
    'Timed out after ${_kMaxUiResponseWait.inSeconds}s closing bottom sheet; '
    'panels remained visible',
  );
}

Future<void> _tapGameStartIntroOverlayContinueIfPresent(
  WidgetTester tester,
) async {
  if (find.text('Continue').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continue').first);
    await tester.pump(const Duration(milliseconds: 200));
    return;
  }
  if (find.text('I shall.').evaluate().isNotEmpty) {
    await tester.tap(find.text('I shall.').first);
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _bootstrapNewGameToMap(
  WidgetTester tester, {
  _E2ePerfLog? perf,
}) async {
  final phaseSw = Stopwatch()..start();
  await tester.tap(find.text('New Game'));
  await _waitUntilFound(
    tester,
    find.text('Start'),
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
  await tester.pump(const Duration(milliseconds: 200));
  await tester.ensureVisible(startButton);
  await tester.tap(startButton);
  await tester.pump();

  final setupDeadline = DateTime.now().add(_kBootstrapNewGameOverallCap);
  var reachedMap = false;
  while (DateTime.now().isBefore(setupDeadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text('Could not create game').evaluate().isNotEmpty) {
      fail(
        'New game setup failed (error dialog). '
        'Exception: ${tester.takeException()}',
      );
    }
    final introOpen = find.byType(GameStartIntroOverlay).evaluate().isNotEmpty;
    if (introOpen) {
      await _tapGameStartIntroOverlayContinueIfPresent(tester);
      continue;
    }
    final creating = find.text('Creating game').evaluate().isNotEmpty;
    if (creating) {
      continue;
    }
    if (find.byKey(kHomeToCapitalButtonKey).evaluate().isNotEmpty) {
      reachedMap = true;
      break;
    }
  }
  if (!reachedMap) {
    fail(
      'Timed out after ${_kBootstrapNewGameOverallCap.inSeconds}s waiting for '
      'map (home→capital). Last exception: ${tester.takeException()}',
    );
  }
  expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 500));
  perf?.timing('new_game_to_map', phaseSw.elapsed);
}

Future<void> _expandEachExpansionTileOnce(WidgetTester tester) async {
  for (var safety = 0; safety < 32; safety++) {
    final tiles = find.byType(ExpansionTile);
    final n = tiles.evaluate().length;
    if (n == 0) return;

    var expandedOne = false;
    for (var j = 0; j < n; j++) {
      final expandIcon = find.descendant(
        of: tiles.at(j),
        matching: find.byIcon(Icons.expand_more),
      );
      if (expandIcon.evaluate().isEmpty) continue;
      final iconHit = expandIcon.first;
      await tester.ensureVisible(iconHit);
      await _pumpFor(tester, const Duration(milliseconds: 80));
      await tester.tap(iconHit, warnIfMissed: false);
      await _pumpFor(tester, const Duration(milliseconds: 250));
      expandedOne = true;
      break;
    }
    if (!expandedOne) return;
  }
}

Future<void> _openNavalPanel(WidgetTester tester, {_E2ePerfLog? perf}) async {
  final phaseSw = Stopwatch()..start();
  final navalPanel = find.byKey(kCtE2ENavalPanelRootKey);
  final markerBtn = find.byKey(kCtE2EOpenFirstFleetMarkerPanelKey);
  final btn = find.byKey(kEmpireNavalUnitsButtonKey);
  final sw = Stopwatch()..start();
  while (sw.elapsed < _kMaxUiResponseWait) {
    await tester.pump(const Duration(milliseconds: 100));
    if (navalPanel.evaluate().isNotEmpty) {
      perf?.timing('open_panel_naval', phaseSw.elapsed);
      return;
    }
    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await _closeBottomSheet(tester, perf: perf);
      continue;
    }
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await _dismissTransientUi(tester, perf: perf);
      continue;
    }
    if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
      await _dismissTransientUi(tester, perf: perf);
      continue;
    }
    final markerHit = markerBtn.hitTestable();
    if (markerHit.evaluate().isNotEmpty) {
      await tester.tap(markerHit.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(milliseconds: 250));
      continue;
    }
    final railHit = btn.hitTestable();
    if (railHit.evaluate().isNotEmpty) {
      await tester.tap(railHit.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(milliseconds: 400));
    } else {
      await _dismissTransientUi(tester, perf: perf);
    }
  }
  fail(
    'Timed out after ${_kMaxUiResponseWait.inSeconds}s opening naval panel. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Selects the New World map region via [kCtE2ERegionTabNewWorldKey] when present
/// (reduces ambiguous "New World" text on screen; `SPEC/program/e2e-integration-tests.md`).
Future<void> _tapNewWorldRegionTabIfPresent(WidgetTester tester) async {
  final tab = find.byKey(kCtE2ERegionTabNewWorldKey).hitTestable();
  if (tab.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tab.first, warnIfMissed: false);
  await _pumpFor(tester, const Duration(milliseconds: 250));
}

/// Map HUD must show **Old World** before issuing naval moves so OW-split
/// fleets and warp orders stay coherent on Linux CI (`SPEC/program/e2e-integration-tests.md`).
Future<void> _tapOldWorldRegionTab(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  final hit = find
      .widgetWithText(CtChoiceChip, l10n.region_oldWorld)
      .hitTestable();
  if (hit.evaluate().isEmpty) {
    return;
  }
  await tester.tap(hit.first, warnIfMissed: false);
  await _pumpFor(tester, const Duration(milliseconds: 250));
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
  await _pumpFor(tester, const Duration(milliseconds: 200));
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
      for (var i = 0; i < 36 && warp.hitTestable().evaluate().isEmpty; i++) {
        ensureBudget('warp drag $i');
        await tester.drag(sc, const Offset(0, -120));
        await _pumpFor(tester, const Duration(milliseconds: 50));
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
  await _pumpFor(tester, const Duration(milliseconds: 200));
  ensureBudget('confirm');
  final confirm = find.text(l10n.common_confirm).hitTestable();
  expect(confirm, findsWidgets);
  await tester.tap(confirm.first, warnIfMissed: false);
  await _pumpFor(tester, const Duration(milliseconds: 300));
  ensureBudget('after confirm');
}

Future<void> _tryNavalMoveSegment(
  WidgetTester tester,
  AppLocalizations l10n, {
  bool useNewWorldMapTabFirst = false,
  bool allowWarpDestinations = true,
  _E2ePerfLog? perf,
}) async {
  final phaseSw = Stopwatch()..start();
  if (useNewWorldMapTabFirst) {
    await _tapNewWorldRegionTabIfPresent(tester);
  } else {
    await _tapOldWorldRegionTab(tester, l10n);
  }
  await _openNavalPanel(tester, perf: perf);
  final tappedMove = await _tapMoveOnFirstNonHomeFleet(tester);
  if (!tappedMove) {
    perf?.timing(
      'fleet_move_segment',
      phaseSw.elapsed,
      meta: 'result=no_non_home_move_control',
    );
    return;
  }
  await _pumpFor(tester, const Duration(milliseconds: 300));
  // No legal sea-step this turn: close dialog and rely on the outer loop +
  // next turn (Refs #1831 heuristic path).
  if (find.text(l10n.moveFleet_noAdjacentSeaZones).evaluate().isNotEmpty) {
    final cancel = find.text(l10n.common_cancel).hitTestable();
    expect(cancel, findsOneWidget);
    await tester.tap(cancel, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 250));
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
