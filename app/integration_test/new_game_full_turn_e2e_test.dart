import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/fleet_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/l10n/app_localizations.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_app/test_support/civilian_units_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/test_support/naval_units_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/test_support/production_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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

Future<void> _dismissTransientUi(WidgetTester tester) async {
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

Future<void> _openCivilianPanel(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final sw = Stopwatch()..start();
  final empireRailButton = find.byKey(kEmpireCivilianUnitsButtonKey);
  final markerButton = find.byKey(kCtE2EOpenFirstCivilianMarkerPanelKey);
  final civilianPanel = find.byKey(kCtE2ECivilianPanelRootKey);
  final navalPanel = find.byKey(kCtE2ENavalPanelRootKey);
  Future<bool> tryOpen(Finder trigger) async {
    final tappable = trigger.hitTestable();
    if (tappable.evaluate().isEmpty) {
      // Dismiss blocking overlays/dialogs before retrying.
      await _dismissTransientUi(tester);
      return false;
    }
    await tester.tap(tappable.first, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 250));
    final openDeadline = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(openDeadline)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (civilianPanel.evaluate().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  while (sw.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    if (civilianPanel.evaluate().isNotEmpty ||
        navalPanel.evaluate().isNotEmpty) {
      await _closeBottomSheet(tester);
      continue;
    }
    if (empireRailButton.evaluate().isNotEmpty) {
      if (await tryOpen(empireRailButton)) {
        return;
      }
    }
    if (markerButton.evaluate().isNotEmpty) {
      if (await tryOpen(markerButton)) {
        return;
      }
    }
  }
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for a civilian panel opener. '
    'empire=$empireRailButton marker=$markerButton '
    'Last exception: ${tester.takeException()}',
  );
}

Future<void> _openPanelFromMarker(
  WidgetTester tester, {
  required Finder markerButton,
  required Finder panelRoot,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    if (panelRoot.evaluate().isNotEmpty) {
      return;
    }
    final tappable = markerButton.hitTestable();
    if (tappable.evaluate().isEmpty) {
      // Clear transient overlays/dialogs that can block marker taps.
      await _dismissTransientUi(tester);
      continue;
    }
    await tester.tap(tappable.first, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 300));
  }
  fail(
    'Timed out after ${timeout.inSeconds}s opening marker panel. '
    'marker=$markerButton panel=$panelRoot Last exception: ${tester.takeException()}',
  );
}

void _collectTextPreorder(Element element, List<String> out) {
  final w = element.widget;
  if (w is Text) {
    final d = w.data;
    if (d != null && d.isNotEmpty) {
      out.add(d);
    }
  }
  element.visitChildren((child) {
    _collectTextPreorder(child, out);
  });
}

Future<List<String>> _discoverRelocated64pxPngAssets() async {
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

Future<void> _ensureAllRelocated64pxPngsLoad() async {
  final assets = await _discoverRelocated64pxPngAssets();
  final expectedAssets = <String>{
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
  };
  final expectedSorted = expectedAssets.toList()..sort();

  expect(assets, isNotEmpty);
  expect(assets.length, expectedAssets.length);
  expect(assets, orderedEquals(expectedSorted));

  final failures = <String>[];
  for (final assetPath in assets) {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, completer.complete);
      final image = await completer.future;
      image.dispose();
    } catch (e) {
      failures.add('$assetPath ($e)');
    }
  }
  expect(failures, isEmpty);
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

Future<void> _openProductionPanel(WidgetTester tester) async {
  final productionPanel = find.byKey(kCtE2EProductionPanelRootKey);
  final productionButton = find.byKey(kEmpireProductionButtonKey);
  final sw = Stopwatch()..start();
  while (sw.elapsed < const Duration(seconds: 20)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (productionPanel.evaluate().isNotEmpty) {
      return;
    }

    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await _closeBottomSheet(tester);
      continue;
    }

    if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
      await tester.binding.handlePopRoute();
      await _pumpFor(tester, const Duration(milliseconds: 250));
      continue;
    }

    if (productionButton.evaluate().isNotEmpty) {
      final productionButtonHit = productionButton.hitTestable();
      final target =
          productionButtonHit.evaluate().isNotEmpty
              ? productionButtonHit
              : productionButton;
      await tester.tap(target.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(milliseconds: 350));
      if (productionPanel.evaluate().isNotEmpty) {
        return;
      }
    } else {
      // Dismiss transient overlays/dialogs and retry opening from the rail.
      await _dismissTransientUi(tester);
    }
  }

  fail(
    'Timed out opening production panel; '
    'button=$productionButton panel=$productionPanel',
  );
}

Future<void> _tapFirstAssignInCivilianPanel(WidgetTester tester) async {
  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  final assign = find.descendant(
    of: root,
    matching: find.text('Assign'),
  );
  expect(assign, findsWidgets);
  final firstAssign = assign.first;
  await tester.scrollUntilVisible(
    firstAssign,
    120,
    scrollable: panelScrollable,
  );
  await tester.ensureVisible(firstAssign);
  await _pumpFor(tester, const Duration(milliseconds: 100));
  await tester.tap(firstAssign);
  await _pumpFor(tester, const Duration(milliseconds: 300));
}

/// Taps Assign on a [ListTile] whose title is exactly [unitTypeTitle]
/// (e.g. [Unit.type] like `Explorer`). Scrolls the panel [Scrollable] until the
/// row is visible, then taps Assign.
Future<void> _tapAssignOnCivilianRowWithTitle(
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
  // Scope titles to the list: several units share the same display title
  // (e.g. multiple `Explorer` rows); `find.text` under the root can match
  // unrelated widgets and break `scrollUntilVisible`.
  final titlesInList = find.descendant(
    of: listView,
    matching: find.text(unitTypeTitle),
  );
  expect(titlesInList, findsWidgets);
  final n = titlesInList.evaluate().length;
  for (var i = 0; i < n; i++) {
    final titleAt = titlesInList.at(i);
    await tester.scrollUntilVisible(
      titleAt,
      120,
      scrollable: panelScrollable,
    );
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
    await _pumpFor(tester, const Duration(milliseconds: 100));
    await tester.tap(assignHit);
    await _pumpFor(tester, const Duration(milliseconds: 300));
    return;
  }
  fail('No idle Assign row for unit type "$unitTypeTitle" in civilian panel');
}

Future<void> _expandEachExpansionTileOnce(WidgetTester tester) async {
  final tiles = find.byType(ExpansionTile);
  final n = tiles.evaluate().length;
  for (var j = 0; j < n; j++) {
    final expandIcon = find.descendant(
      of: tiles.at(j),
      matching: find.byIcon(Icons.expand_more),
    );
    if (expandIcon.evaluate().isNotEmpty) {
      final iconHit = expandIcon.first;
      await tester.ensureVisible(iconHit);
      await _pumpFor(tester, const Duration(milliseconds: 80));
      await tester.tap(iconHit);
      await _pumpFor(tester, const Duration(milliseconds: 250));
    }
  }
}

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'new game → full human turn: civilians, naval split/move, production',
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
      await _ensureAllRelocated64pxPngsLoad();

      await _bootstrapNewGameToMap(tester);

      final l10n = lookupAppLocalizations(const Locale('en'));

      Future<void> expectCivilianPanelTexts() async {
        await _waitUntilFound(
          tester,
          find.byKey(kCtE2ECivilianPanelRootKey),
          timeout: const Duration(seconds: 20),
        );
        final snap = ctE2eCivilianPanelSnapshot;
        expect(snap, isNotNull);
        final expected = civilianUnitsPanelExpectedTexts(snap!, l10n);
        final actual = <String>[];
        _collectTextPreorder(
          tester.element(find.byKey(kCtE2ECivilianPanelRootKey)),
          actual,
        );
        expect(actual, orderedEquals(expected));
      }

      Future<void> expectNavalPanelTexts({required bool expanded}) async {
        await _waitUntilFound(
          tester,
          find.byKey(kCtE2ENavalPanelRootKey),
          timeout: const Duration(seconds: 20),
        );
        final snap = ctE2eNavalPanelSnapshot;
        expect(snap, isNotNull);
        final expected = navalUnitsPanelExpectedTexts(
          snap!,
          l10n,
          fleetTilesExpanded: expanded,
        );
        final actual = <String>[];
        _collectTextPreorder(
          tester.element(find.byKey(kCtE2ENavalPanelRootKey)),
          actual,
        );
        if (!expanded) {
          expect(actual, orderedEquals(expected));
          return;
        }
        final collapsedExpected = navalUnitsPanelExpectedTexts(
          snap,
          l10n,
          fleetTilesExpanded: false,
        );
        expect(
          actual,
          anyOf(orderedEquals(expected), orderedEquals(collapsedExpected)),
        );
      }

      Future<void> expectProductionPanelTexts() async {
        await _waitUntilFound(
          tester,
          find.byKey(kCtE2EProductionPanelRootKey),
          timeout: const Duration(seconds: 20),
        );
        final snap = ctE2eProductionPanelSnapshot;
        expect(snap, isNotNull);
        final expected = productionPanelWideExpectedTexts(snap!, l10n);
        final actual = <String>[];
        _collectTextPreorder(
          tester.element(find.byKey(kCtE2EProductionPanelRootKey)),
          actual,
        );
        expect(actual, orderedEquals(expected));
      }

      // --- Civilian (empire rail): baseline ---
      await _openCivilianPanel(tester);
      await expectCivilianPanelTexts();
      await _closeBottomSheet(tester);

      // --- Builder: build improvement + first legal tile (e2e tap target) ---
      await _openCivilianPanel(tester);
      await _tapFirstAssignInCivilianPanel(tester);
      await tester.tap(find.text('Build improvement'));
      await _pumpFor(tester, const Duration(milliseconds: 400));
      await tester.tap(find.byKey(kCtE2ESelectFirstValidWorkTileKey));
      await _pumpFor(tester, const Duration(milliseconds: 500));
      await _closeBottomSheet(tester);

      // --- Explorer: prospect + first legal tile ---
      await _openCivilianPanel(tester);
      await _tapAssignOnCivilianRowWithTitle(tester, 'Explorer');
      await tester.tap(find.text('Prospect'));
      await _pumpFor(tester, const Duration(milliseconds: 400));
      await tester.tap(find.byKey(kCtE2ESelectFirstValidWorkTileKey));
      await _pumpFor(tester, const Duration(milliseconds: 500));
      await _closeBottomSheet(tester);

      // --- Civilian rail: after draft orders ---
      await tester.tap(find.byKey(kEmpireCivilianUnitsButtonKey));
      await _pumpFor(tester, const Duration(milliseconds: 400));
      await expectCivilianPanelTexts();
      await _closeBottomSheet(tester);

      // --- Naval rail: collapsed ---
      await tester.tap(find.byKey(kEmpireNavalUnitsButtonKey));
      await _pumpFor(tester, const Duration(milliseconds: 400));
      await expectNavalPanelTexts(expanded: false);
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
      await tester.tap(find.text('Confirm Split'));
      await _pumpFor(tester, const Duration(seconds: 1));

      // Split triggers a panel refresh; ensure fleet tiles are expanded again.
      await _expandEachExpansionTileOnce(tester);
      final moveButtons = find.descendant(
        of: navalPanelRoot,
        matching: find.text('Move'),
      );
      if (moveButtons.evaluate().isNotEmpty) {
        await tester.tap(moveButtons.first);
        await _pumpFor(tester, const Duration(milliseconds: 400));

        final seaRadio = find.byType(RadioListTile<dynamic>);
        if (seaRadio.evaluate().isNotEmpty) {
          await tester.tap(seaRadio.first);
          await _pumpFor(tester, const Duration(milliseconds: 200));
        }
        final confirm = find.text('Confirm');
        if (confirm.evaluate().isNotEmpty) {
          await tester.tap(confirm.first);
          await _pumpFor(tester, const Duration(seconds: 1));
        }
      }
      if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
        final closeCandidates = <Finder>[
          find.text(l10n.common_cancel),
          find.text(l10n.common_close),
          find.byIcon(Icons.close),
        ];
        for (final candidate in closeCandidates) {
          final tappable = candidate.hitTestable();
          if (tappable.evaluate().isNotEmpty) {
            await tester.tap(tappable.first, warnIfMissed: false);
            await _pumpFor(tester, const Duration(milliseconds: 300));
            break;
          }
        }
      }

      await _expandEachExpansionTileOnce(tester);
      await expectNavalPanelTexts(expanded: true);
      await _closeBottomSheet(tester);

      // --- Civilian + naval from first map markers (tile scope) ---
      await _openPanelFromMarker(
        tester,
        markerButton: find.byKey(kCtE2EOpenFirstCivilianMarkerPanelKey),
        panelRoot: find.byKey(kCtE2ECivilianPanelRootKey),
      );
      await expectCivilianPanelTexts();
      await _closeBottomSheet(tester);

      await _openPanelFromMarker(
        tester,
        markerButton: find.byKey(kCtE2EOpenFirstFleetMarkerPanelKey),
        panelRoot: find.byKey(kCtE2ENavalPanelRootKey),
      );
      await expectNavalPanelTexts(expanded: false);
      await _closeBottomSheet(tester);

      // --- Next turn ---
      final turnBefore =
          find
                  .descendant(
                    of: find.byKey(kGameMapNextTurnButtonKey),
                    matching: find.byType(Text),
                  )
                  .evaluate()
                  .single
                  .widget
              as Text;
      final turnLabelBefore = turnBefore.data!;

      await tester.tap(find.byKey(kGameMapNextTurnButtonKey));
      await _pumpFor(tester, const Duration(milliseconds: 400));
      final confirmNextTurn = find.text(l10n.common_yes).hitTestable();
      if (confirmNextTurn.evaluate().isNotEmpty) {
        await tester.tap(confirmNextTurn.first, warnIfMissed: false);
      }
      await _pumpFor(tester, const Duration(seconds: 3));

      final turnAfter =
          find
                  .descendant(
                    of: find.byKey(kGameMapNextTurnButtonKey),
                    matching: find.byType(Text),
                  )
                  .evaluate()
                  .single
                  .widget
              as Text;
      expect(turnAfter.data, isNot(turnLabelBefore));

      // --- Production (post-resolution stockpiles) ---
      await _openProductionPanel(tester);
      await expectProductionPanelTexts();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await _pumpFor(tester, const Duration(milliseconds: 500));
      expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
    },
  );
}
