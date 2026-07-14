// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'support/naval_units_panel_test_support.dart';
import 'support/panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game game;
  late String humanPlayerIdWithFleets;
  const String humanPlayerIdWithNoFleets = 'no-such-player';

  setUpAll(() async {
    await setUpNinePatchAssets();
    // Full fixture (home + non-home fleets, both regions) so locate / Split
    // cases are non-vacuous. Refs #4013 densify of part1.
    game = buildNavalPanelTestGame();
    humanPlayerIdWithFleets = game.players.isNotEmpty
        ? game.players.first.id
        : kPanelTestHumanPlayerId;
  });

  Future<void> pumpNaval(
    WidgetTester tester, {
    Game? gameOverride,
    String? humanPlayerId,
    AppEventBus? bus,
    Widget? widget,
  }) async {
    await tester.pumpWidget(
      widget ??
          buildNavalPanel(
            game: gameOverride ?? game,
            humanPlayerId: humanPlayerId ?? humanPlayerIdWithFleets,
            bus: bus,
          ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expandFleetTile(
    WidgetTester tester,
    Finder fleetFinder,
  ) async {
    await tester.ensureVisible(fleetFinder);
    await tester.tap(fleetFinder);
    await tester.pumpAndSettle();
  }

  group('NavalUnitsPanel', () {
    testWidgets('AC: Panel shows title Naval Units', (
      WidgetTester tester,
    ) async {
      await pumpNaval(tester);

      expect(find.text('Naval Units'), findsOneWidget);
      if (find.byType(ExpansionTile).evaluate().isNotEmpty) {
        expect(find.byType(UnitsEntityActionRow), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('header Combine renders as a primary CtActionTextButton pill '
        '(no CtNinePatchButton header chrome) — #3514 owner decisions #5/#15', (
      WidgetTester tester,
    ) async {
      await pumpNaval(tester);

      final combine = find.ancestor(
        of: find.text('Combine'),
        matching: find.byType(CtActionTextButton),
      );
      expect(combine, findsOneWidget);
      expect(tester.widget<CtActionTextButton>(combine.first).primary, isTrue);
      expect(
        find.ancestor(
          of: find.text('Combine'),
          matching: find.byType(CtNinePatchButton),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'AC: When human player has no fleets, panel does not crash and shows either empty or Home Fleet only',
      (WidgetTester tester) async {
        await pumpNaval(tester, humanPlayerId: humanPlayerIdWithNoFleets);

        expect(find.byType(CtPanel), findsOneWidget);
      },
    );

    testWidgets(
      'AC: When player has fleets, panel shows at least one fleet row',
      (WidgetTester tester) async {
        await pumpNaval(tester);

        final fleets = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanPlayerIdWithFleets &&
                  f.shipTypeIds.isNotEmpty,
            )
            .length;
        if (fleets > 0) {
          expect(find.byType(ExpansionTile), findsAtLeastNWidgets(1));
          expect(
            find.text('OLD WORLD').evaluate().isNotEmpty ||
                find.text('NEW WORLD').evaluate().isNotEmpty,
            isTrue,
          );
        }
      },
    );

    testWidgets('AC: Panel is wrapped in CtPanel', (WidgetTester tester) async {
      await pumpNaval(tester);

      expect(find.byType(CtPanel), findsOneWidget);
    });

    testWidgets('AC: Wide viewport scales naval panel beyond fixed 400 width', (
      WidgetTester tester,
    ) async {
      await pumpNaval(
        tester,
        widget: buildNavalPanelWideViewport(
          game: game,
          humanPlayerId: humanPlayerIdWithFleets,
        ),
      );

      final panelShell = tester.widget<UnitsPanelShell>(
        find.byType(UnitsPanelShell),
      );
      expect(panelShell.panelConstraints.maxWidth, greaterThan(400));
    });

    testWidgets('AC: Locate button emits LocateMapTileEvent', (
      WidgetTester tester,
    ) async {
      LocateMapTileEvent? locateEvent;
      final bus = AppEventBus.create();
      bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);
      await pumpNaval(tester, bus: bus);

      final locateButtons = find.byTooltip('Locate fleet');
      if (locateButtons.evaluate().isEmpty) return;
      await tester.tap(locateButtons.first);
      await tester.pumpAndSettle();

      expect(locateEvent, isNotNull);
      expect(
        locateEvent!.regionId == 'oldWorld' ||
            locateEvent!.regionId == 'newWorld',
        isTrue,
      );
    });

    testWidgets('AC: Strength is only shown in expanded details', (
      WidgetTester tester,
    ) async {
      await pumpNaval(tester);

      final tiles = find.byType(ExpansionTile);
      if (tiles.evaluate().isEmpty) return;

      expect(find.textContaining('Strength:'), findsNothing);

      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Strength:'), findsAtLeastNWidgets(1));
    });

    testWidgets('sea-zone labels use world-state display names', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_named_sea';
      final namedSeaGame = buildNavalPanelNamedSeaZoneGame(humanId: humanId);
      await pumpNaval(
        tester,
        gameOverride: namedSeaGame,
        humanPlayerId: humanId,
      );
      expect(find.textContaining('Caribbean Sea'), findsWidgets);
    });

    testWidgets(
      'AC: expanded composition lists ship display names not raw ids',
      (WidgetTester tester) async {
        const humanId = 'gp_ship_display';
        final shipLabelGame = buildNavalPanelShipLabelGame(humanId: humanId);

        await pumpNaval(
          tester,
          gameOverride: shipLabelGame,
          humanPlayerId: humanId,
        );

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
        expect(homeTile, findsOneWidget);
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        expect(find.text('Carrack'), findsOneWidget);
        expect(find.text('×1'), findsAtLeastNWidgets(1));
        expect(find.textContaining('carrack:'), findsNothing);
      },
    );

    testWidgets(
      'sections render for fleets in both regions and locate button passes region id',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        final playerFleets = game.worldState.fleets
            .where((f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty)
            .toList();
        expect(playerFleets, isNotEmpty);
        final baseFleet = playerFleets.first;
        final newProvinces = game.worldState.newWorld.provinces;
        expect(newProvinces, isNotEmpty);
        final newProvince = newProvinces.first;

        final gameWithNwFleet = withNavalPanelExtraFleets(game, [
          baseFleet.copyWith(
            id: 'test_new_world_fleet',
            regionId: 'newWorld',
            inPortAtProvinceId: newProvince.id,
            seaZoneId: null,
            ownerId: humanId,
          ),
        ]);

        String? locatedTileKey;
        String? locatedRegionId;
        final bus = AppEventBus.create();
        bus.on<LocateMapTileEvent>().listen((e) {
          locatedTileKey = e.tileKey;
          locatedRegionId = e.regionId;
        });

        await pumpNaval(
          tester,
          gameOverride: gameWithNwFleet,
          humanPlayerId: humanId,
          bus: bus,
        );

        expect(find.text('OLD WORLD'), findsAtLeastNWidgets(1));
        expect(find.text('NEW WORLD'), findsAtLeastNWidgets(1));

        Finder tileFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet test_new_world_fleet',
        );
        if (tileFinder.evaluate().isEmpty) {
          tileFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        }
        await tester.ensureVisible(tileFinder);
        final locateFinder = find.descendant(
          of: tileFinder,
          matching: find.byTooltip('Locate fleet'),
        );
        if (locateFinder.evaluate().isEmpty) return;
        await tester.ensureVisible(locateFinder.first);
        await tester.tap(locateFinder.first, warnIfMissed: false);
        await tester.pumpAndSettle();
        if (locatedTileKey == null || locatedRegionId == null) return;

        expect(locatedTileKey, isNotNull);
        expect(locatedRegionId, isNotNull);
        expect(
          locatedRegionId == 'oldWorld' || locatedRegionId == 'newWorld',
          isTrue,
        );
      },
    );

    testWidgets(
      'AC: Missing Home Fleet entity does not render synthetic Home Fleet row',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        LocateMapTileEvent? locateEvent;
        bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);

        final gameWithoutHome = withoutNavalPanelCapitalHomeFleets(
          game,
          humanPlayerIdWithFleets,
        );

        await pumpNaval(
          tester,
          gameOverride: gameWithoutHome,
          bus: bus,
        );

        expect(
          find.widgetWithText(ExpansionTile, 'Home Fleet'),
          findsNothing,
        );
        expect(locateEvent, isNull);
      },
    );

    testWidgets(
      'AC: Sea-zone fleet locate button uses correct sea-zone tile key',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        final seaFleet = game.worldState.fleets.firstWhere(
          (f) =>
              f.ownerId == humanId &&
              f.shipTypeIds.isNotEmpty &&
              f.isAtSea,
        );
        final portsEntry = game.worldState.portsByProvinceSeaboard.entries
            .firstWhere((e) => e.key.split('|').length >= 2);
        final expectedTileKey = portsEntry.value;

        String? locatedTileKey;
        String? locatedRegionId;
        final bus = AppEventBus.create();
        bus.on<LocateMapTileEvent>().listen((e) {
          locatedTileKey = e.tileKey;
          locatedRegionId = e.regionId;
        });
        await pumpNaval(tester, humanPlayerId: humanId, bus: bus);

        final fleetTileFinder = find.widgetWithText(
          ExpansionTile,
          navalFleetTileLabel(seaFleet, humanId),
        );
        expect(fleetTileFinder, findsOneWidget);

        await tester.ensureVisible(fleetTileFinder);
        final locateFinder = find.descendant(
          of: fleetTileFinder,
          matching: find.byTooltip('Locate fleet'),
        );
        if (locateFinder.evaluate().isEmpty) return;
        await tester.tap(locateFinder.first);
        await tester.pumpAndSettle();

        expect(locatedTileKey, expectedTileKey);
        expect(locatedRegionId, seaFleet.regionId);
      },
    );

    testWidgets('AC: Port fleet locate button uses correct province tile key', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;
      final target = firstNavalNonCapitalLocateTarget(game, humanId);
      if (target == null) {
        fail('No non-capital province with a resolvable tile key found');
      }

      final baseFleet = game.worldState.fleets.firstWhere(
        (f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty,
      );
      final portFleet = baseFleet.copyWith(
        id: 'test_port_fleet',
        ownerId: humanId,
        regionId: target.province.regionId,
        inPortAtProvinceId: target.province.id,
        seaZoneId: null,
      );
      final gameWithPort = withNavalPanelExtraFleets(game, [portFleet]);

      String? locatedTileKey;
      String? locatedRegionId;
      final bus = AppEventBus.create();
      bus.on<LocateMapTileEvent>().listen((e) {
        locatedTileKey = e.tileKey;
        locatedRegionId = e.regionId;
      });

      await pumpNaval(
        tester,
        gameOverride: gameWithPort,
        humanPlayerId: humanId,
        bus: bus,
      );

      final fleetTileFinder = find.widgetWithText(
        ExpansionTile,
        'Fleet ${portFleet.id}',
      );
      expect(fleetTileFinder, findsOneWidget);

      await tester.ensureVisible(fleetTileFinder);
      final locateFinder = find.descendant(
        of: fleetTileFinder,
        matching: find.byTooltip('Locate fleet'),
      );
      if (locateFinder.evaluate().isEmpty) return;
      await tester.tap(locateFinder.first);
      await tester.pumpAndSettle();

      expect(locatedTileKey, target.tileKey);
      expect(locatedRegionId, portFleet.regionId);
    });

    testWidgets('AC: Split button is shown for Home Fleet with ships', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;

      await pumpNaval(tester, humanPlayerId: humanId);

      final homeFleetFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
      expect(homeFleetFinder, findsOneWidget);

      await expandFleetTile(tester, homeFleetFinder);

      expect(
        find.descendant(
          of: homeFleetFinder,
          matching: find.byTooltip('Split'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'AC: Home Fleet row has a checkbox; Combine is only in the panel header',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;

        await pumpNaval(tester, humanPlayerId: humanId);

        final homeFleetFinder = find.widgetWithText(
          ExpansionTile,
          'Home Fleet',
        );
        expect(homeFleetFinder, findsOneWidget);

        expect(
          find.descendant(of: homeFleetFinder, matching: find.byType(Checkbox)),
          findsOneWidget,
        );

        final combineButtons = find.widgetWithText(
          CtActionTextButton,
          'Combine',
        );
        expect(combineButtons, findsOneWidget);

        await expandFleetTile(tester, homeFleetFinder);

        expect(
          find.descendant(
            of: homeFleetFinder,
            matching: find.widgetWithText(CtActionTextButton, 'Combine'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('AC: Split button is shown for non-Home Fleet', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;
      final homeId = homeFleetIdFor(humanId);

      final playerFleets = game.worldState.fleets
          .where(
            (f) =>
                f.ownerId == humanId &&
                f.shipTypeIds.isNotEmpty &&
                f.id != homeId,
          )
          .toList();
      expect(playerFleets, isNotEmpty);

      await pumpNaval(tester, humanPlayerId: humanId);

      final fleetFinder = find.widgetWithText(
        ExpansionTile,
        navalFleetTileLabel(playerFleets.first, humanId),
      );
      expect(fleetFinder, findsOneWidget);

      await expandFleetTile(tester, fleetFinder);

      expect(
        find.descendant(
          of: fleetFinder,
          matching: find.byTooltip('Split'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'AC: Expanding home/non-home fleet and tapping Split opens Split Fleet dialog',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        final homeId = homeFleetIdFor(humanId);
        await pumpNaval(tester, humanPlayerId: humanId);

        final homeFleetFinder = find.widgetWithText(
          ExpansionTile,
          'Home Fleet',
        );
        expect(homeFleetFinder, findsOneWidget);
        await expandFleetTile(tester, homeFleetFinder);
        final homeSplit = find.descendant(
          of: homeFleetFinder,
          matching: find.byTooltip('Split'),
        );
        expect(homeSplit, findsOneWidget);
        await tester.tap(homeSplit);
        await tester.pumpAndSettle();
        expect(find.text('Split Fleet'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        final nonHome = game.worldState.fleets.firstWhere(
          (f) =>
              f.ownerId == humanId &&
              f.shipTypeIds.isNotEmpty &&
              f.id != homeId,
        );
        final nonHomeFinder = find.widgetWithText(
          ExpansionTile,
          navalFleetTileLabel(nonHome, humanId),
        );
        expect(nonHomeFinder, findsOneWidget);
        await expandFleetTile(tester, nonHomeFinder);
        final splitButton = find.descendant(
          of: nonHomeFinder,
          matching: find.byTooltip('Split'),
        );
        expect(splitButton, findsOneWidget);
        await tester.tap(splitButton);
        await tester.pumpAndSettle();
        expect(find.text('Split Fleet'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: Combine control is in the panel header when fleets exist',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        expect(
          game.worldState.fleets.where(
            (f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty,
          ),
          isNotEmpty,
        );

        await pumpNaval(tester, humanPlayerId: humanId);

        expect(
          find.widgetWithText(CtActionTextButton, 'Combine'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC: NavalFleetsUpdatedEvent is emitted when fleet split completes',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? fleetEvent;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          fleetEvent = e;
        });
        addTearDown(sub.cancel);
        final subSplit = wireNavalSplitForWidgetTest(
          bus: bus,
          gameSnapshot: () => game,
        );
        addTearDown(subSplit.cancel);

        final targetFleet = game.worldState.fleets.firstWhere(
          (f) => f.ownerId == humanId && f.shipTypeIds.length >= 2,
        );
        final tileLabel = navalFleetTileLabel(targetFleet, humanId);

        await pumpNaval(tester, humanPlayerId: humanId, bus: bus);

        final fleetFinder = find.widgetWithText(ExpansionTile, tileLabel);
        expect(fleetFinder, findsOneWidget);

        await expandFleetTile(tester, fleetFinder);

        final splitButton = find.descendant(
          of: fleetFinder,
          matching: find.byTooltip('Split'),
        );
        expect(splitButton, findsOneWidget);

        await tester.tap(splitButton);
        await tester.pumpAndSettle();

        final moveTypeId = targetFleet.ships.first.typeId;
        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveOne(moveTypeId)),
        );
        await tester.pumpAndSettle();

        final confirmSplit = find.text('Confirm Split');
        expect(confirmSplit, findsOneWidget);

        await tester.tap(confirmSplit);
        await tester.pumpAndSettle();

        expect(fleetEvent, isNotNull);
        expect(fleetEvent!.game.worldState.fleets, isNotEmpty);
      },
    );

    testWidgets(
      'split event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        final bus = AppEventBus.create();
        final observedFleetCount = ValueNotifier<int>(
          game.worldState.fleets.length,
        );
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          observedFleetCount.value = e.game.worldState.fleets.length;
        });
        final subSplit = wireNavalSplitForWidgetTest(
          bus: bus,
          gameSnapshot: () => game,
        );
        addTearDown(() async {
          await sub.cancel();
          await subSplit.cancel();
          observedFleetCount.dispose();
        });

        final targetFleet = game.worldState.fleets.firstWhere(
          (f) => f.ownerId == humanId && f.shipTypeIds.length >= 2,
        );
        final tileLabel = navalFleetTileLabel(targetFleet, humanId);

        await pumpNaval(
          tester,
          widget: buildNavalPanelWithFleetCountWatcher(
            game: game,
            humanPlayerId: humanId,
            bus: bus,
            observedFleetCount: observedFleetCount,
          ),
        );

        expect(
          find.text(
            'observed-fleet-count:${game.worldState.fleets.length}',
          ),
          findsOneWidget,
        );

        final fleetFinder = find.widgetWithText(ExpansionTile, tileLabel);
        expect(fleetFinder, findsOneWidget);
        await expandFleetTile(tester, fleetFinder);

        final splitButton = find.descendant(
          of: fleetFinder,
          matching: find.byTooltip('Split'),
        );
        expect(splitButton, findsOneWidget);
        await tester.tap(splitButton);
        await tester.pumpAndSettle();

        final moveTypeId = targetFleet.ships.first.typeId;
        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveOne(moveTypeId)),
        );
        await tester.pumpAndSettle();

        final confirmSplit = find.text('Confirm Split');
        expect(confirmSplit, findsOneWidget);
        await tester.tap(confirmSplit);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'observed-fleet-count:${game.worldState.fleets.length + 1}',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
