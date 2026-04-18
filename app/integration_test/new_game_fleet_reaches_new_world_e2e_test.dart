import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/l10n/app_localizations.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
  required Duration timeout,
}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for $finder. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Dismisses blocking bottom sheets, dialog shells, snackbars, and generic OKs.
///
/// [AlertDialog] handling uses common action labels (including **Close** for
/// prior-turn [TurnNewsDialog], `SPEC/ui/turn-news-dialog.md`) plus
/// [WidgetsBinding.handlePopRoute] if none match.
Future<void> _dismissTransientUi(WidgetTester tester) async {
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
    await _closeBottomSheet(tester);
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

Future<void> _closeBottomSheet(WidgetTester tester) async {
  bool anyPanelOpen() => find.byType(BottomSheet).evaluate().isNotEmpty;

  if (!anyPanelOpen()) {
    return;
  }

  final sw = Stopwatch()..start();
  while (sw.elapsed < const Duration(seconds: 5)) {
    if (!anyPanelOpen()) {
      return;
    }
    await tester.binding.handlePopRoute();
    await _pumpFor(tester, const Duration(milliseconds: 250));
  }

  fail('Timed out closing bottom sheet; panels remained visible');
}

Future<void> _bootstrapNewGameToMap(WidgetTester tester) async {
  await tester.tap(find.text('New Game'));
  await _waitUntilFound(
    tester,
    find.text('Start'),
    timeout: const Duration(seconds: 30),
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

  final setupDeadline = DateTime.now().add(const Duration(minutes: 6));
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
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue').first);
        await tester.pump(const Duration(milliseconds: 200));
      } else if (find.text('I shall.').evaluate().isNotEmpty) {
        await tester.tap(find.text('I shall.').first);
        await tester.pump(const Duration(milliseconds: 200));
      }
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
  expect(reachedMap, isTrue);
  expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 500));
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

Future<void> _openNavalPanel(WidgetTester tester) async {
  final navalPanel = find.byKey(kCtE2ENavalPanelRootKey);
  final btn = find.byKey(kEmpireNavalUnitsButtonKey);
  final sw = Stopwatch()..start();
  while (sw.elapsed < const Duration(seconds: 45)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (navalPanel.evaluate().isNotEmpty) {
      return;
    }
    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await _closeBottomSheet(tester);
      continue;
    }
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await _dismissTransientUi(tester);
      continue;
    }
    if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
      await _dismissTransientUi(tester);
      continue;
    }
    final hit = btn.hitTestable();
    if (hit.evaluate().isNotEmpty) {
      await tester.tap(hit.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(milliseconds: 400));
    } else {
      await _dismissTransientUi(tester);
    }
  }
  fail(
    'Timed out opening naval panel. Last exception: ${tester.takeException()}',
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

Finder _radioListTilesInAlertDialogs() {
  return find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byWidgetPredicate(
      (w) => w.runtimeType.toString().startsWith('RadioListTile<'),
    ),
  );
}

/// Prefer cross-region warp row (English copy); else first adjacent sea tile.
Future<void> _pickMoveDestinationAndConfirm(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await _pumpFor(tester, const Duration(milliseconds: 200));
  final warp = find.textContaining('links to New World');
  if (warp.evaluate().isNotEmpty) {
    final scrollRoot = find.byKey(kCtE2EMoveFleetDialogScrollRootKey);
    if (scrollRoot.evaluate().isNotEmpty) {
      final scrollable = find.descendant(
        of: scrollRoot,
        matching: find.byType(Scrollable),
      );
      if (scrollable.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(warp.first, 80, scrollable: scrollable);
      }
    }
    final hit = warp.hitTestable();
    expect(hit, findsWidgets);
    await tester.tap(hit.first, warnIfMissed: false);
  } else {
    final seaRadio = _radioListTilesInAlertDialogs();
    expect(seaRadio, findsWidgets);
    await tester.tap(seaRadio.first, warnIfMissed: false);
  }
  await _pumpFor(tester, const Duration(milliseconds: 200));
  final confirm = find.text(l10n.common_confirm).hitTestable();
  expect(confirm, findsWidgets);
  await tester.tap(confirm.first, warnIfMissed: false);
  await _pumpFor(tester, const Duration(seconds: 1));
}

Future<void> _tryNavalMoveSegment(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await _tapNewWorldRegionTabIfPresent(tester);
  await _openNavalPanel(tester);
  await _expandEachExpansionTileOnce(tester);
  await _tapMoveOnFirstNonHomeFleet(tester);
  await _pumpFor(tester, const Duration(milliseconds: 300));
  // No legal sea-step this turn: close dialog and rely on the outer loop +
  // next turn (Refs #1831 heuristic path).
  if (find.text(l10n.moveFleet_noAdjacentSeaZones).evaluate().isNotEmpty) {
    final cancel = find.text(l10n.common_cancel).hitTestable();
    expect(cancel, findsOneWidget);
    await tester.tap(cancel, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 250));
    return;
  }
  if (find.byType(AlertDialog).evaluate().isNotEmpty) {
    await _pickMoveDestinationAndConfirm(tester, l10n);
  }
}

Future<void> _tapMoveOnFirstNonHomeFleet(WidgetTester tester) async {
  final navalRoot = find.byKey(kCtE2ENavalPanelRootKey);
  final tiles = find.descendant(
    of: navalRoot,
    matching: find.byType(ExpansionTile),
  );
  expect(tiles, findsWidgets);
  final n = tiles.evaluate().length;
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
    final move = find.descendant(of: sub, matching: find.text('Move'));
    if (move.evaluate().isEmpty) {
      continue;
    }
    final hit = move.hitTestable();
    expect(hit, findsWidgets);
    await tester.tap(hit.first, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 400));
    return;
  }
  fail(
    'No Move control for a non-home fleet row. '
    'Last exception: ${tester.takeException()}',
  );
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
        (w) =>
            w is Text && (w.data != null) && w.data!.startsWith('New World —'),
      ),
    );
    if (loc.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

Future<void> _splitHomeFleetOnce(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(find.byKey(kEmpireNavalUnitsButtonKey));
  await _pumpFor(tester, const Duration(milliseconds: 400));
  await _waitUntilFound(
    tester,
    find.byKey(kCtE2ENavalPanelRootKey),
    timeout: const Duration(seconds: 20),
  );
  await _expandEachExpansionTileOnce(tester);
  final navalPanelRoot = find.byKey(kCtE2ENavalPanelRootKey);
  final split = find.descendant(
    of: navalPanelRoot,
    matching: find.text('Split'),
  );
  expect(split, findsWidgets);
  await tester.tap(split.first);
  await _pumpFor(tester, const Duration(milliseconds: 400));

  final moveOneRight = find.descendant(
    of: find.byType(CtDialogShell),
    matching: find.widgetWithText(CtNinePatchButton, '>'),
  );
  expect(moveOneRight, findsWidgets);
  await tester.tap(moveOneRight.first);
  await _pumpFor(tester, const Duration(milliseconds: 200));
  await tester.tap(find.text(l10n.splitFleet_confirm));
  await _pumpFor(tester, const Duration(seconds: 1));
  await _expandEachExpansionTileOnce(tester);
}

Future<void> _advanceOneHumanTurn(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(find.byKey(kGameMapNextTurnButtonKey));
  await _pumpFor(tester, const Duration(milliseconds: 400));
  final confirmNextTurn = find.text(l10n.common_yes).hitTestable();
  if (confirmNextTurn.evaluate().isNotEmpty) {
    await tester.tap(confirmNextTurn.first, warnIfMissed: false);
  }
  await _pumpFor(tester, const Duration(seconds: 2));
}

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'new game → non-home fleet at sea in New World (≤10 Next turn taps)',
    (WidgetTester tester) async {
      expect(
        kCtE2EEnabled,
        isTrue,
        reason:
            'Run with: flutter test integration_test/... --dart-define=CT_E2E=true',
      );

      await tester.binding.setSurfaceSize(const Size(1280, 720));
      await bootstrapForIntegrationTest();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await _bootstrapNewGameToMap(tester);

      final l10n = lookupAppLocalizations(const Locale('en'));

      await _splitHomeFleetOnce(tester, l10n);
      await _closeBottomSheet(tester);

      for (var turnIdx = 0; turnIdx < 10; turnIdx++) {
        await _dismissTransientUi(tester);
        await _tapNewWorldRegionTabIfPresent(tester);
        await _openNavalPanel(tester);
        if (_navalPanelShowsNonHomeFleetInNewWorld(tester)) {
          await _closeBottomSheet(tester);
          return;
        }
        await _closeBottomSheet(tester);

        await _tryNavalMoveSegment(tester, l10n);
        await _closeBottomSheet(tester);

        if (_navalPanelShowsNonHomeFleetInNewWorld(tester)) {
          return;
        }

        await _advanceOneHumanTurn(tester, l10n);
        await _dismissTransientUi(tester);
      }

      await _dismissTransientUi(tester);
      await _tapNewWorldRegionTabIfPresent(tester);
      await _openNavalPanel(tester);
      if (!_navalPanelShowsNonHomeFleetInNewWorld(tester)) {
        fail(
          'After 10 Next turn resolutions, no non-home fleet row shows '
          'location text starting with "New World —" under '
          'kCtE2ENavalPanelRootKey. Last exception: ${tester.takeException()}',
        );
      }
      await _closeBottomSheet(tester);
    },
  );
}
