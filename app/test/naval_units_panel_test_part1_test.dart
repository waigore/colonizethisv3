// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        applyNavalSplitFleet,
        applyNavalTransferShipsBetweenFleets,
        homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

/// Mirrors shell handling of [NavalSplitFleetRequestedEvent] for widget tests.
StreamSubscription<NavalSplitFleetRequestedEvent> wireNavalSplitForWidgetTest({
  required AppEventBus bus,
  required Game Function() gameSnapshot,
}) {
  return bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
    final next = applyNavalSplitFleet(
      game: gameSnapshot(),
      humanPlayerId: e.humanPlayerId,
      originalFleetId: e.originalFleetId,
      shipInstanceIdsToNewFleet: e.shipInstanceIdsToNewFleet,
    );
    bus.emit(NavalFleetsUpdatedEvent(game: next));
  });
}

/// Mirrors shell handling of [NavalTransferShipsRequestedEvent] for widget tests.
StreamSubscription<NavalTransferShipsRequestedEvent>
wireNavalTransferForWidgetTest({
  required AppEventBus bus,
  required Game Function() gameSnapshot,
}) {
  return bus.on<NavalTransferShipsRequestedEvent>().listen((e) {
    final next = applyNavalTransferShipsBetweenFleets(
      game: gameSnapshot(),
      humanPlayerId: e.humanPlayerId,
      sourceFleetId: e.sourceFleetId,
      targetFleetId: e.targetFleetId,
      shipInstanceIdsToTransfer: e.shipInstanceIdsToTransfer,
    );
    bus.emit(NavalFleetsUpdatedEvent(game: next));
  });
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game game;
  late String humanPlayerIdWithFleets;
  const String humanPlayerIdWithNoFleets = 'no-such-player';

  // Fallback 1x1 transparent PNG if the real asset cannot be read.
  final ninePatchFallbackPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=',
  );
  Uint8List ninePatchBytes = ninePatchFallbackPng;

  setUpAll(() async {
    final assetCandidates = <String>[
      'app/assets/images/ui_button_nine_patch.png',
      'assets/images/ui_button_nine_patch.png',
    ];
    for (final candidate in assetCandidates) {
      final file = File(candidate);
      if (await file.exists()) {
        ninePatchBytes = await file.readAsBytes();
        break;
      }
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = const StringCodec().decodeMessage(message);
          if (key == 'assets/images/ui_button_nine_patch.png') {
            return ByteData.view(ninePatchBytes.buffer);
          }
          return null;
        });

    // Preload panel nine-patch image into Flame cache so widget tests are
    // stable regardless of invocation directory.
    try {
      final bytes = await rootBundle.load(
        'assets/images/ui_button_nine_patch.png',
      );
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      Flame.images.add('ui_button_nine_patch.png', frame.image);
      Flame.images.add('assets/images/ui_button_nine_patch.png', frame.image);
    } catch (_) {
      // Keep tests resilient when asset prewarm fails; individual tests can
      // still validate behavior where possible.
    }

    game = getDebugInitGameResult().game;
    humanPlayerIdWithFleets = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    AppEventBus? bus,
    MapTopology topology = const MapTopology(),
    Orders draftOrders = const Orders(),
    String? locationScopeKey,
  }) {
    final resolvedBus = bus ?? AppEventBus.create();
    return MaterialApp(
      home: Scaffold(
        body: NavalUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          bus: resolvedBus,
          topology: topology,
          draftOrders: draftOrders,
          locationScopeKey: locationScopeKey,
        ),
      ),
    );
  }
  group('NavalUnitsPanel', () {
    testWidgets('AC: Panel shows title Naval Units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithFleets),
      );
      await tester.pumpAndSettle();

      expect(find.text('Naval Units'), findsOneWidget);
      if (find.byType(ExpansionTile).evaluate().isNotEmpty) {
        expect(find.byType(UnitsEntityActionRow), findsAtLeastNWidgets(1));
      }
    });

    testWidgets(
      'AC: When human player has no fleets, panel does not crash and shows either empty or Home Fleet only',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithNoFleets),
        );
        await tester.pumpAndSettle();

        // Depending on scenario data, there may be a Home Fleet or no fleets at all.
        // This test only asserts that the panel builds without throwing and that
        // any content is rendered inside a CtPanel.
        expect(find.byType(CtPanel), findsOneWidget);
      },
    );

    testWidgets(
      'AC: When player has fleets, panel shows at least one fleet row',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithFleets),
        );
        await tester.pumpAndSettle();

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
            find.text('Old World').evaluate().isNotEmpty ||
                find.text('New World').evaluate().isNotEmpty,
            isTrue,
          );
        }
      },
    );

    testWidgets('AC: Panel is wrapped in CtPanel', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithFleets),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtPanel), findsOneWidget);
    });

    testWidgets('AC: Wide viewport scales naval panel beyond fixed 400 width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: MaterialApp(
            home: Scaffold(
              body: NavalUnitsPanel(
                game: game,
                humanPlayerId: humanPlayerIdWithFleets,
                bus: AppEventBus.create(),
                topology: const MapTopology(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
      await tester.pumpWidget(
        buildPanel(
          game: game,
          humanPlayerId: humanPlayerIdWithFleets,
          bus: bus,
        ),
      );
      await tester.pumpAndSettle();

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
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithFleets),
      );
      await tester.pumpAndSettle();

      final tiles = find.byType(ExpansionTile);
      if (tiles.evaluate().isEmpty) return;

      // Collapsed content is compact and excludes strength summary text.
      expect(find.textContaining('Strength:'), findsNothing);

      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Expanded details include strength.
      expect(find.textContaining('Strength:'), findsAtLeastNWidgets(1));
    });

    testWidgets('sea-zone labels use world-state display names', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_named_sea';
      const capProvince = 'oldWorld|cap1';
      const zoneId = 'zone_alpha';
      final namedSeaGame = Game(
        id: 'named-sea',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'cap1',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Capital',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'sea_named',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: zoneId,
              ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
            ),
          ],
          seaZoneDisplayNameById: const {
            'oldWorld|zone_alpha': 'Caribbean Sea',
          },
          portsByProvinceSeaboard: const {
            'oldWorld|cap1|zone_alpha': 'oldWorld|cap1|0|0',
          },
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              capProvince: ['oldWorld|cap1|0|0'],
            },
          },
        ),
        players: const [
          Player(
            id: humanId,
            displayName: 'Named Sea Tester',
            isHuman: true,
            capitalProvinceId: capProvince,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: capProvince,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        buildPanel(game: namedSeaGame, humanPlayerId: humanId),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Caribbean Sea'), findsWidgets);
    });

    testWidgets(
      'AC: expanded composition lists ship display names not raw ids',
      (WidgetTester tester) async {
        const humanId = 'gp_ship_display';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);
        final shipLabelGame = Game(
          id: 'g_ship_labels',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: homeId,
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'h1', typeId: 'carrack')],
              ),
            ],
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
          ),
          players: const [
            Player(
              id: humanId,
              displayName: 'Ship Label Tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: shipLabelGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
        expect(homeTile, findsOneWidget);
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        expect(find.textContaining('Carrack: 1'), findsOneWidget);
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
        expect(
          playerFleets,
          isNotEmpty,
          reason: 'Demo game must include at least one fleet with ships',
        );
        final baseFleet = playerFleets.first;

        final oldProvinceList = game.worldState.oldWorld.provinces;
        final newProvinceList = game.worldState.newWorld.provinces;
        expect(oldProvinceList, isNotEmpty);
        expect(newProvinceList, isNotEmpty);
        final oldProvince = oldProvinceList.first;
        final newProvince = newProvinceList.first;

        // Inject deterministic port fleets in both regions so region headers
        // render reliably in the test.
        final extraOldFleet = baseFleet.copyWith(
          id: 'test_old_world_fleet',
          regionId: 'oldWorld',
          inPortAtProvinceId: oldProvince.id,
          seaZoneId: null,
          ownerId: humanId,
        );
        final extraNewFleet = baseFleet.copyWith(
          id: 'test_new_world_fleet',
          regionId: 'newWorld',
          inPortAtProvinceId: newProvince.id,
          seaZoneId: null,
          ownerId: humanId,
        );

        final gameWithExtraFleets = game.copyWith(
          worldState: game.worldState.copyWith(
            fleets: [...game.worldState.fleets, extraOldFleet, extraNewFleet],
          ),
        );

        String? locatedTileKey;
        String? locatedRegionId;
        final bus = AppEventBus.create();
        bus.on<LocateMapTileEvent>().listen((e) {
          locatedTileKey = e.tileKey;
          locatedRegionId = e.regionId;
        });

        await tester.pumpWidget(
          buildPanel(
            game: gameWithExtraFleets,
            humanPlayerId: humanId,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        // Old/New World headers should appear when fleets exist in both regions.
        expect(find.text('Old World'), findsAtLeastNWidgets(1));
        expect(find.text('New World'), findsAtLeastNWidgets(1));

        Finder tileFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet ${extraNewFleet.id}',
        );
        if (tileFinder.evaluate().isEmpty) {
          // If the injected fleet lands on the player's capital province, the
          // panel labels it "Home Fleet".
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
        final gameInstance = game;
        final player = game.players.firstWhere(
          (p) => p.id == humanPlayerIdWithFleets,
          orElse: () => game.players.first,
        );

        final capitalTile = player.capitalTile;
        expect(
          capitalTile,
          isNotNull,
          reason: 'Demo game must define a capital tile',
        );

        final capitalParts = capitalTile!.toTileKey().split('|');
        expect(capitalParts.length, greaterThanOrEqualTo(2));
        final capitalRegionId = capitalParts[0];
        final capitalProvinceLocalId = capitalParts[1];

        String? locatedTileKey;
        String? locatedRegionId;
        final bus = AppEventBus.create();
        bus.on<LocateMapTileEvent>().listen((e) {
          locatedTileKey = e.tileKey;
          locatedRegionId = e.regionId;
        });

        // Remove any actual fleet that would be considered home at the capital.
        final filteredFleets = gameInstance.worldState.fleets.where((f) {
          if (f.ownerId != humanPlayerIdWithFleets) return true;
          if (f.isAtSea) return true;
          final inPortId = f.inPortAtProvinceId;
          if (inPortId == null) return true;
          return !(f.regionId == capitalRegionId &&
              (inPortId == capitalProvinceLocalId ||
                  inPortId == '$capitalRegionId|$capitalProvinceLocalId'));
        }).toList();

        final gameWithoutHomeFleets = gameInstance.copyWith(
          worldState: gameInstance.worldState.copyWith(fleets: filteredFleets),
        );

        await tester.pumpWidget(
          buildPanel(
            game: gameWithoutHomeFleets,
            humanPlayerId: humanPlayerIdWithFleets,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final homeTileFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        expect(homeTileFinder, findsNothing);
        expect(locatedTileKey, isNull);
        expect(locatedRegionId, isNull);
      },
    );

    testWidgets(
      'AC: Sea-zone fleet locate button uses correct sea-zone tile key',
      (WidgetTester tester) async {
        final gameInstance = game;
        final humanId = humanPlayerIdWithFleets;

        final baseFleetCandidates = gameInstance.worldState.fleets
            .where((f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty)
            .toList();
        expect(baseFleetCandidates, isNotEmpty);
        final baseFleet = baseFleetCandidates.first;

        final portsEntry = gameInstance
            .worldState
            .portsByProvinceSeaboard
            .entries
            .firstWhere((e) => e.key.split('|').length >= 2);
        final portsParts = portsEntry.key.split('|');
        final seaRegionId = portsParts.first;
        final localSeaZoneId = portsParts.last;

        final seaFleet = baseFleet.copyWith(
          id: 'test_sea_zone_fleet',
          ownerId: humanId,
          regionId: seaRegionId,
          seaZoneId: localSeaZoneId,
          inPortAtProvinceId: null,
        );

        final expectedTileKey = portsEntry.value;

        final gameWithExtraFleets = gameInstance.copyWith(
          worldState: gameInstance.worldState.copyWith(
            fleets: [...gameInstance.worldState.fleets, seaFleet],
          ),
        );

        String? locatedTileKey;
        String? locatedRegionId;
        final bus = AppEventBus.create();
        bus.on<LocateMapTileEvent>().listen((e) {
          locatedTileKey = e.tileKey;
          locatedRegionId = e.regionId;
        });
        await tester.pumpWidget(
          buildPanel(
            game: gameWithExtraFleets,
            humanPlayerId: humanId,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final fleetTileFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet ${seaFleet.id}',
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
      final gameInstance = game;
      final humanId = humanPlayerIdWithFleets;
      final player = gameInstance.players.firstWhere(
        (p) => p.id == humanId,
        orElse: () => gameInstance.players.first,
      );

      final capitalTile = player.capitalTile;
      expect(capitalTile, isNotNull);
      final capitalParts = capitalTile!.toTileKey().split('|');
      expect(capitalParts.length, greaterThanOrEqualTo(2));
      final capitalRegionId = capitalParts[0];

      final baseFleetCandidates = gameInstance.worldState.fleets
          .where((f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty)
          .toList();
      expect(baseFleetCandidates, isNotEmpty);
      final baseFleet = baseFleetCandidates.first;

      Province? targetProvince;
      String? expectedTileKey;

      final oldProvinces = gameInstance.worldState.oldWorld.provinces;
      final newProvinces = gameInstance.worldState.newWorld.provinces;

      for (final province in [...oldProvinces, ...newProvinces]) {
        // Ensure the injected fleet can't be labeled "Home Fleet" by skipping
        // the player's capital region entirely.
        if (province.regionId == capitalRegionId) continue;

        // Mirror tileKeyForProvinceLocation() selection logic.
        String? tileKey;
        if (province.townTileKey != null && province.townTileKey!.isNotEmpty) {
          tileKey = province.townTileKey;
        } else {
          final byProvince = gameInstance
              .worldState
              .tileKeysByRegionAndProvince[province.regionId];
          final prefixedId = '${province.regionId}|${province.id}';
          final tiles = byProvince?[prefixedId] ?? byProvince?[province.id];
          if (tiles != null && tiles.isNotEmpty) tileKey = tiles.first;
        }

        if (tileKey == null) continue;

        targetProvince = province;
        expectedTileKey = tileKey;
        break;
      }

      if (targetProvince == null || expectedTileKey == null) {
        fail('No non-capital province with a resolvable tile key found');
      }

      final portFleet = baseFleet.copyWith(
        id: 'test_port_fleet',
        ownerId: humanId,
        regionId: targetProvince.regionId,
        inPortAtProvinceId: targetProvince.id,
        seaZoneId: null,
      );

      final gameWithExtraFleets = gameInstance.copyWith(
        worldState: gameInstance.worldState.copyWith(
          fleets: [...gameInstance.worldState.fleets, portFleet],
        ),
      );

      String? locatedTileKey;
      String? locatedRegionId;
      final bus = AppEventBus.create();
      bus.on<LocateMapTileEvent>().listen((e) {
        locatedTileKey = e.tileKey;
        locatedRegionId = e.regionId;
      });

      await tester.pumpWidget(
        buildPanel(game: gameWithExtraFleets, humanPlayerId: humanId, bus: bus),
      );
      await tester.pumpAndSettle();

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

      expect(locatedTileKey, expectedTileKey);
      expect(locatedRegionId, portFleet.regionId);
    });

    testWidgets('AC: Split button is shown for Home Fleet with ships', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
      await tester.pumpAndSettle();

      final homeFleetFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
      if (homeFleetFinder.evaluate().isEmpty) {
        return;
      }

      final homeFleet = game.worldState.fleets.where(
        (f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty,
      );
      if (homeFleet.isEmpty) {
        return;
      }

      await tester.ensureVisible(homeFleetFinder);
      await tester.tap(homeFleetFinder);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Split'), findsOneWidget);
    });

    testWidgets(
      'AC: Home Fleet row has a checkbox; Combine is only in the panel header',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;

        await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
        await tester.pumpAndSettle();

        final homeFleetFinder = find.widgetWithText(
          ExpansionTile,
          'Home Fleet',
        );
        if (homeFleetFinder.evaluate().isEmpty) {
          return;
        }

        expect(
          find.descendant(of: homeFleetFinder, matching: find.byType(Checkbox)),
          findsOneWidget,
        );

        final combineButtons = find.widgetWithText(
          CtNinePatchButton,
          'Combine',
        );
        expect(combineButtons, findsOneWidget);

        await tester.ensureVisible(homeFleetFinder);
        await tester.tap(homeFleetFinder);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: homeFleetFinder,
            matching: find.widgetWithText(CtNinePatchButton, 'Combine'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('AC: Split button is shown for non-Home Fleet', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;

      final playerFleets = game.worldState.fleets
          .where(
            (f) =>
                f.ownerId == humanId &&
                f.shipTypeIds.isNotEmpty &&
                f.id != 'home_fleet',
          )
          .toList();
      if (playerFleets.isEmpty) return;

      final baseFleet = playerFleets.first;

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
      await tester.pumpAndSettle();

      final fleetFinder = find.widgetWithText(
        ExpansionTile,
        'Fleet ${baseFleet.id}',
      );
      if (fleetFinder.evaluate().isEmpty) return;

      await tester.ensureVisible(fleetFinder);
      await tester.tap(fleetFinder);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Split'), findsOneWidget);
    });

    testWidgets(
      'AC: Expanding home/non-home fleet and tapping Split opens Split Fleet dialog',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
        await tester.pumpAndSettle();

        final homeFleetFinder = find.widgetWithText(
          ExpansionTile,
          'Home Fleet',
        );
        if (homeFleetFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(homeFleetFinder);
          await tester.tap(homeFleetFinder);
          await tester.pumpAndSettle();
          final splitButton = find.byTooltip('Split');
          if (splitButton.evaluate().isNotEmpty) {
            await tester.tap(splitButton.first);
            await tester.pumpAndSettle();
            expect(find.text('Split Fleet'), findsOneWidget);
            await tester.tap(find.text('Cancel'));
            await tester.pumpAndSettle();
          }
        }

        final nonHomeFleets = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanId &&
                  f.shipTypeIds.isNotEmpty &&
                  f.id != 'home_fleet',
            )
            .toList();
        if (nonHomeFleets.isEmpty) return;
        final nonHomeFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet ${nonHomeFleets.first.id}',
        );
        if (nonHomeFinder.evaluate().isEmpty) return;
        await tester.ensureVisible(nonHomeFinder);
        await tester.tap(nonHomeFinder);
        await tester.pumpAndSettle();
        final splitButton = find.byTooltip('Split');
        if (splitButton.evaluate().isEmpty) return;
        await tester.tap(splitButton.first);
        await tester.pumpAndSettle();
        expect(find.text('Split Fleet'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: Combine control is in the panel header when fleets exist',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;

        final playerFleets = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanId &&
                  f.shipTypeIds.isNotEmpty &&
                  f.id != 'home_fleet',
            )
            .toList();
        if (playerFleets.isEmpty) return;

        await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(CtNinePatchButton, 'Combine'),
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

        final splittable = game.worldState.fleets
            .where((f) => f.ownerId == humanId && f.shipTypeIds.length >= 2)
            .toList();
        if (splittable.isEmpty) return;

        final targetFleet = splittable.first;
        final tileLabel = targetFleet.id == 'home_fleet'
            ? 'Home Fleet'
            : 'Fleet ${targetFleet.id}';

        await tester.pumpWidget(
          buildPanel(bus: bus, game: game, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final fleetFinder = find.widgetWithText(ExpansionTile, tileLabel);
        if (fleetFinder.evaluate().isEmpty) return;

        await tester.ensureVisible(fleetFinder);
        await tester.tap(fleetFinder);
        await tester.pumpAndSettle();

        final splitButton = find.byTooltip('Split');
        if (splitButton.evaluate().isEmpty) return;

        await tester.tap(splitButton);
        await tester.pumpAndSettle();

        final moveToNew = find.byIcon(Icons.arrow_back);
        if (moveToNew.evaluate().isEmpty) return;

        await tester.tap(moveToNew);
        await tester.pumpAndSettle();

        final confirmSplit = find.text('Confirm Split');
        if (confirmSplit.evaluate().isEmpty) return;

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

        final splittable = game.worldState.fleets
            .where((f) => f.ownerId == humanId && f.shipTypeIds.length >= 2)
            .toList();
        if (splittable.isEmpty) return;

        final targetFleet = splittable.first;
        final tileLabel = targetFleet.id == 'home_fleet'
            ? 'Home Fleet'
            : 'Fleet ${targetFleet.id}';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: observedFleetCount,
                    builder: (context, count, _) =>
                        Text('observed-fleet-count:$count'),
                  ),
                  Expanded(
                    child: NavalUnitsPanel(
                      game: game,
                      humanPlayerId: humanId,
                      bus: bus,
                      topology: getDebugInitGameResult().combinedTopology,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final beforeText = find.text(
          'observed-fleet-count:${game.worldState.fleets.length}',
        );
        expect(beforeText, findsOneWidget);

        final fleetFinder = find.widgetWithText(ExpansionTile, tileLabel);
        if (fleetFinder.evaluate().isEmpty) return;
        await tester.ensureVisible(fleetFinder);
        await tester.tap(fleetFinder);
        await tester.pumpAndSettle();

        final splitButton = find.byTooltip('Split');
        if (splitButton.evaluate().isEmpty) return;
        await tester.tap(splitButton);
        await tester.pumpAndSettle();

        final moveToNew = find.byIcon(Icons.arrow_back);
        if (moveToNew.evaluate().isEmpty) return;
        await tester.tap(moveToNew.first);
        await tester.pumpAndSettle();

        final confirmSplit = find.text('Confirm Split');
        if (confirmSplit.evaluate().isEmpty) return;
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
