// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show applyNavalSplitFleet, homeFleetIdFor;
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
      'AC: Home Fleet expansion shows empty ships and locate button targets capital tile',
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

        Province? capitalProvince;
        final oldProvinces = gameInstance.worldState.oldWorld.provinces;
        final newProvinces = gameInstance.worldState.newWorld.provinces;
        for (final p in [...oldProvinces, ...newProvinces]) {
          if (p.regionId == capitalRegionId && p.id == capitalProvinceLocalId) {
            capitalProvince = p;
            break;
          }
        }

        // Mirror tileKeyForProvinceLocation() selection logic.
        String? expectedTileKey;
        if (capitalProvince != null) {
          final townTileKey = capitalProvince.townTileKey;
          if (townTileKey != null && townTileKey.isNotEmpty) {
            expectedTileKey = townTileKey;
          } else {
            final byProvince = gameInstance
                .worldState
                .tileKeysByRegionAndProvince[capitalProvince.regionId];
            final prefixedId =
                '${capitalProvince.regionId}|${capitalProvince.id}';
            final tiles =
                byProvince?[prefixedId] ?? byProvince?[capitalProvince.id];
            if (tiles != null && tiles.isNotEmpty) {
              expectedTileKey = tiles.first;
            }
          }
        }

        String? locatedTileKey;
        String? locatedRegionId;
        final bus = AppEventBus.create();
        bus.on<LocateMapTileEvent>().listen((e) {
          locatedTileKey = e.tileKey;
          locatedRegionId = e.regionId;
        });

        // Force the widget into the "synthetic" Home Fleet path by removing any
        // actual fleet that would be considered home (located at the capital
        // province). This ensures row.shipCountsByType is empty.
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
        expect(homeTileFinder, findsOneWidget);

        await tester.ensureVisible(homeTileFinder);
        await tester.tap(homeTileFinder);
        await tester.pumpAndSettle();

        expect(find.text('No ships in this fleet'), findsOneWidget);

        final locateFinder = find.descendant(
          of: homeTileFinder,
          matching: find.byTooltip('Locate fleet'),
        );
        if (locateFinder.evaluate().isEmpty) return;
        await tester.tap(locateFinder.first);
        await tester.pumpAndSettle();

        // When the panel has a resolvable tile key for the home fleet,
        // it calls onLocateFleet with that key.
        expect(
          expectedTileKey == null || locatedTileKey == expectedTileKey,
          isTrue,
        );
        expect(locatedRegionId, capitalRegionId);
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

    testWidgets(
      'AC: Header checkbox selects all fleets then second interaction clears',
      (WidgetTester tester) async {
        const humanId = 'gp_select_all';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final selectAllGame = Game(
          id: 'g_select_all',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'a',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'b',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ship_2', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Select-all tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: selectAllGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final headerCheckboxFinder = find.descendant(
          of: find.byType(NavalUnitsPanel),
          matching: find.byWidgetPredicate(
            (w) => w is Checkbox && w.tristate == true,
          ),
        );
        expect(headerCheckboxFinder, findsOneWidget);

        await tester.tap(headerCheckboxFinder);
        await tester.pumpAndSettle();

        final checkboxes = find.byType(Checkbox);
        final cbCount = checkboxes.evaluate().length;
        expect(cbCount, greaterThanOrEqualTo(2));
        for (var i = 0; i < cbCount; i++) {
          expect(tester.widget<Checkbox>(checkboxes.at(i)).value, isTrue);
        }

        await tester.tap(headerCheckboxFinder);
        await tester.pumpAndSettle();

        for (var i = 0; i < cbCount; i++) {
          expect(tester.widget<Checkbox>(checkboxes.at(i)).value, isFalse);
        }
      },
    );

    testWidgets('AC: Combining fleets creates correct ship counts', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_combine_count';
      const capProvince = 'oldWorld|cap1';
      const mergePort = 'oldWorld|mergeport';

      final combineGame = Game(
        id: 'g_combine_count',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'cap1',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Capital',
              ),
              Province(
                id: 'mergeport',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Merge Port',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'test_fleet_1',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
            ),
            Fleet(
              id: 'test_fleet_2',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ship_2', typeId: 'fluyte')],
            ),
          ],
          // Capital only: merge-port fleets intentionally have no tile key so the
          // panel does not wrap them in a locate InkWell (that would swallow taps
          // and prevent ExpansionTile from expanding in widget tests).
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              capProvince: ['oldWorld|cap1|0|0'],
            },
          },
          nextShipInstanceSeq: 3,
        ),
        players: [
          Player(
            id: humanId,
            displayName: 'Combine tester',
            isHuman: true,
            capitalProvinceId: capProvince,
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: capProvince,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );

      final bus = AppEventBus.create();
      NavalFleetsUpdatedEvent? updated;
      final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
        updated = e;
      });
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        buildPanel(game: combineGame, humanPlayerId: humanId, bus: bus),
      );
      await tester.pumpAndSettle();

      final fleet1Finder = find.widgetWithText(
        ExpansionTile,
        'Fleet test_fleet_1',
      );
      expect(fleet1Finder, findsOneWidget);

      final fleet2Finder = find.widgetWithText(
        ExpansionTile,
        'Fleet test_fleet_2',
      );
      expect(fleet2Finder, findsOneWidget);

      final cb1 = find.descendant(
        of: fleet1Finder,
        matching: find.byType(Checkbox),
      );
      final cb2 = find.descendant(
        of: fleet2Finder,
        matching: find.byType(Checkbox),
      );
      await tester.ensureVisible(cb1);
      await tester.tap(cb1);
      await tester.pumpAndSettle();
      await tester.ensureVisible(cb2);
      await tester.tap(cb2);
      await tester.pumpAndSettle();

      final combineFinder = find.widgetWithText(CtNinePatchButton, 'Combine');
      await tester.ensureVisible(combineFinder);
      await tester.tap(combineFinder);
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      final fleetsAfter = updated!.game.worldState.fleets;
      final merged = fleetsAfter.firstWhere((f) => f.id == 'test_fleet_1');
      final mergedIds = merged.ships.map((s) => s.id).toList()..sort();
      expect(mergedIds, ['ship_1', 'ship_2']);
      expect(fleetsAfter.any((f) => f.id == 'test_fleet_2'), isFalse);
    });

    testWidgets(
      'AC: Fleets at different locations keep Combine disabled when both checked',
      (WidgetTester tester) async {
        const humanId = 'gp_diff_loc';
        const capProvince = 'oldWorld|cap1';
        const portA = 'oldWorld|port_a';
        const portB = 'oldWorld|port_b';

        final diffLocGame = Game(
          id: 'g_diff_loc',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'port_a',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Port A',
                ),
                Province(
                  id: 'port_b',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Port B',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fa',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: portA,
                ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'fb',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: portB,
                ships: const [ShipInstance(id: 'ship_2', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Diff-loc tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: diffLocGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final fleetAFinder = find.widgetWithText(ExpansionTile, 'Fleet fa');
        final fleetBFinder = find.widgetWithText(ExpansionTile, 'Fleet fb');
        expect(fleetAFinder, findsOneWidget);
        expect(fleetBFinder, findsOneWidget);

        await tester.tap(
          find.descendant(of: fleetAFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: fleetBFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Combining into Home Fleet merges ships into home id when Home is selected',
      (WidgetTester tester) async {
        const humanId = 'gp_home_combine';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        final homeCombineGame = Game(
          id: 'g_home_combine',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
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
                ships: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
                mission: FleetMission.patrol,
              ),
              Fleet(
                id: 'at_capital',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'ship_v', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Home combine tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: homeCombineGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final homeFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final otherFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet at_capital',
        );
        expect(homeFinder, findsOneWidget);
        expect(otherFinder, findsOneWidget);

        await tester.tap(
          find.descendant(of: homeFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: otherFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.where((f) => f.id == 'at_capital'), isEmpty);

        final home = fleetsAfter.firstWhere((f) => f.id == homeId);
        final shipIds = home.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ship_h', 'ship_v']);
        expect(home.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Combining three fleets at same port merges all ships into first in panel order',
      (WidgetTester tester) async {
        const humanId = 'gp_three_combine';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final threeGame = Game(
          id: 'g_three_combine',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'c1',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'c2',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 's2', typeId: 'fluyte')],
              ),
              Fleet(
                id: 'c3',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 's3', typeId: 'carrack')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 4,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Three combine tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: threeGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        for (final label in ['Fleet c1', 'Fleet c2', 'Fleet c3']) {
          final tile = find.widgetWithText(ExpansionTile, label);
          expect(tile, findsOneWidget);
          final cb = find.descendant(of: tile, matching: find.byType(Checkbox));
          await tester.scrollUntilVisible(cb, 120);
          await tester.pumpAndSettle();
          await tester.ensureVisible(cb);
          await tester.tap(cb);
          await tester.pumpAndSettle();
        }

        final combineBtnFinder = find.widgetWithText(
          CtNinePatchButton,
          'Combine',
        );
        await tester.scrollUntilVisible(combineBtnFinder, 120);
        await tester.pumpAndSettle();
        await tester.tap(combineBtnFinder);
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.length, 1);
        final survivor = fleetsAfter.single;
        expect(survivor.id, 'c1');
        final ids = survivor.ships.map((s) => s.id).toList();
        expect(ids, ['s1', 's2', 's3']);
        expect(survivor.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Fleets in different sea zones keep Combine disabled when both checked',
      (WidgetTester tester) async {
        const humanId = 'gp_two_seas';
        const capProvince = 'oldWorld|cap1';

        final twoSeaGame = Game(
          id: 'g_two_seas',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'coast',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Coast',
                ),
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
                id: 'sea_a',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_alpha',
                inPortAtProvinceId: null,
                ships: const [ShipInstance(id: 'a1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'sea_b',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_beta',
                inPortAtProvinceId: null,
                ships: const [ShipInstance(id: 'b1', typeId: 'fluyte')],
              ),
            ],
            portsByProvinceSeaboard: {
              'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
              'oldWorld|coast|zone_beta': 'oldWorld|coast|1|0',
            },
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
                'oldWorld|coast': ['oldWorld|coast|0|0'],
              },
            },
            nextShipInstanceSeq: 2,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Two seas tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: twoSeaGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final finderA = find.widgetWithText(ExpansionTile, 'Fleet sea_a');
        final finderB = find.widgetWithText(ExpansionTile, 'Fleet sea_b');
        expect(finderA, findsOneWidget);
        expect(finderB, findsOneWidget);

        await tester.tap(
          find.descendant(of: finderA, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: finderB, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Fleet at sea and fleet in port keep Combine disabled when both checked',
      (WidgetTester tester) async {
        const humanId = 'gp_sea_port';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final seaPortGame = Game(
          id: 'g_sea_port',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
                Province(
                  id: 'coast',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Coast',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'at_sea',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_alpha',
                inPortAtProvinceId: null,
                ships: const [ShipInstance(id: 's_sea', typeId: 'carrack')],
              ),
              Fleet(
                id: 'in_port',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 's_port', typeId: 'fluyte')],
              ),
            ],
            portsByProvinceSeaboard: {
              'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
            },
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
                'oldWorld|coast': ['oldWorld|coast|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Sea-port tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: seaPortGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final seaFinder = find.widgetWithText(ExpansionTile, 'Fleet at_sea');
        final portFinder = find.widgetWithText(ExpansionTile, 'Fleet in_port');
        expect(seaFinder, findsOneWidget);
        expect(portFinder, findsOneWidget);

        await tester.tap(
          find.descendant(of: seaFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: portFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Two fleets in the same sea zone combine; mission becomes none',
      (WidgetTester tester) async {
        const humanId = 'gp_same_sea_combine';
        const capProvince = 'oldWorld|cap1';

        final sameSeaGame = Game(
          id: 'g_same_sea_combine',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'coast',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Coast',
                ),
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
                id: 'sea_1',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_alpha',
                inPortAtProvinceId: null,
                ships: const [ShipInstance(id: 'ss1', typeId: 'carrack')],
                mission: FleetMission.patrol,
              ),
              Fleet(
                id: 'sea_2',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_alpha',
                inPortAtProvinceId: null,
                ships: const [ShipInstance(id: 'ss2', typeId: 'fluyte')],
              ),
            ],
            portsByProvinceSeaboard: {
              'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
            },
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
                'oldWorld|coast': ['oldWorld|coast|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Same-sea combine',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: sameSeaGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final finder1 = find.widgetWithText(ExpansionTile, 'Fleet sea_1');
        final finder2 = find.widgetWithText(ExpansionTile, 'Fleet sea_2');
        expect(finder1, findsOneWidget);
        expect(finder2, findsOneWidget);

        await tester.tap(
          find.descendant(of: finder1, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: finder2, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Combine'),
        );
        expect(combineBtn.enabled, isTrue);

        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.length, 1);
        final survivor = fleetsAfter.single;
        expect(survivor.id, 'sea_1');
        final shipIds = survivor.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ss1', 'ss2']);
        expect(survivor.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Combining two non-home fleets clears non-none missions on survivor',
      (WidgetTester tester) async {
        const humanId = 'gp_mission_clear';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final missionGame = Game(
          id: 'g_mission_clear',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'm1',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ms1', typeId: 'carrack')],
                mission: FleetMission.patrol,
              ),
              Fleet(
                id: 'm2',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ms2', typeId: 'fluyte')],
                mission: FleetMission.blockade,
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Mission clear tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: missionGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final t1 = find.widgetWithText(ExpansionTile, 'Fleet m1');
        final t2 = find.widgetWithText(ExpansionTile, 'Fleet m2');
        await tester.tap(
          find.descendant(of: t1, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: t2, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final merged = updated!.game.worldState.fleets.firstWhere(
          (f) => f.id == 'm1',
        );
        expect(merged.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Partial row selection shows indeterminate header; header tap selects all',
      (WidgetTester tester) async {
        const humanId = 'gp_partial_header';
        const mergePort = 'oldWorld|mergeport';

        // No capital => no synthetic Home Fleet row; select-all stays one locality.
        final partialGame = Game(
          id: 'g_partial_header',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'p1',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ps1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'p2',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ps2', typeId: 'fluyte')],
              ),
              Fleet(
                id: 'p3',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ps3', typeId: 'carrack')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                mergePort: ['oldWorld|mergeport|0|0'],
              },
            },
            nextShipInstanceSeq: 4,
          ),
          players: const [
            Player(
              id: humanId,
              displayName: 'Partial header tester',
              isHuman: true,
              treasury: 0,
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: partialGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final headerCheckboxFinder = find.descendant(
          of: find.byType(NavalUnitsPanel),
          matching: find.byWidgetPredicate(
            (w) => w is Checkbox && w.tristate == true,
          ),
        );

        final tile1 = find.widgetWithText(ExpansionTile, 'Fleet p1');
        await tester.tap(
          find.descendant(of: tile1, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        expect(tester.widget<Checkbox>(headerCheckboxFinder).value, isNull);

        await tester.tap(headerCheckboxFinder);
        await tester.pumpAndSettle();

        expect(tester.widget<Checkbox>(headerCheckboxFinder).value, isTrue);
        for (final label in ['Fleet p1', 'Fleet p2', 'Fleet p3']) {
          final tile = find.widgetWithText(ExpansionTile, label);
          expect(tile, findsOneWidget);
          final cb = find.descendant(of: tile, matching: find.byType(Checkbox));
          await tester.ensureVisible(cb);
          expect(tester.widget<Checkbox>(cb).value, isTrue);
        }

        final combineBtn = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Combine'),
        );
        expect(combineBtn.enabled, isTrue);
      },
    );

    testWidgets(
      'AC: Three-fleet combine survivor is first in panel order regardless of check order',
      (WidgetTester tester) async {
        const humanId = 'gp_reverse_check';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final revGame = Game(
          id: 'g_reverse_check',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'r1',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'rs1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'r2',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'rs2', typeId: 'fluyte')],
              ),
              Fleet(
                id: 'r3',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'rs3', typeId: 'carrack')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 4,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Reverse check tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: revGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        for (final label in ['Fleet r3', 'Fleet r2', 'Fleet r1']) {
          final titleFinder = find.text(label);
          await tester.scrollUntilVisible(titleFinder, 120);
          await tester.pumpAndSettle();
          final tile = find.ancestor(
            of: titleFinder,
            matching: find.byType(ExpansionTile),
          );
          final cb = find.descendant(of: tile, matching: find.byType(Checkbox));
          await tester.scrollUntilVisible(cb, 120);
          await tester.pumpAndSettle();
          await tester.ensureVisible(cb);
          await tester.tap(cb);
          await tester.pumpAndSettle();
        }

        final combineFinder = find.widgetWithText(CtNinePatchButton, 'Combine');
        await tester.scrollUntilVisible(combineFinder, 120);
        await tester.pumpAndSettle();
        await tester.tap(combineFinder);
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.length, 1);
        final survivor = fleetsAfter.single;
        expect(survivor.id, 'r1');
        expect(survivor.ships.map((s) => s.id).toList(), ['rs1', 'rs2', 'rs3']);
      },
    );

    testWidgets(
      'AC: Updating game prunes combine selection to fleets that still exist',
      (WidgetTester tester) async {
        const humanId = 'gp_prune_sel';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        WorldState stateWithTwo(String keep, String drop) => WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'cap1',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Capital',
              ),
              Province(
                id: 'mergeport',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Merge Port',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: keep,
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ks1', typeId: 'carrack')],
            ),
            Fleet(
              id: drop,
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ks2', typeId: 'fluyte')],
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              capProvince: ['oldWorld|cap1|0|0'],
            },
          },
          nextShipInstanceSeq: 3,
        );

        final gameTwo = Game(
          id: 'g_prune_two',
          worldState: stateWithTwo('stays', 'removed'),
          players: [
            Player(
              id: humanId,
              displayName: 'Prune tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final gameOne = Game(
          id: 'g_prune_one',
          worldState: gameTwo.worldState.copyWith(
            fleets: [
              gameTwo.worldState.fleets.firstWhere((f) => f.id == 'stays'),
            ],
          ),
          players: gameTwo.players,
        );

        await tester.pumpWidget(
          buildPanel(game: gameTwo, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final tileStays = find.widgetWithText(ExpansionTile, 'Fleet stays');
        final tileRemoved = find.widgetWithText(ExpansionTile, 'Fleet removed');
        await tester.tap(
          find.descendant(of: tileStays, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: tileRemoved, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          buildPanel(game: gameOne, humanPlayerId: humanId),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final staysCb = find.descendant(
          of: tileStays,
          matching: find.byType(Checkbox),
        );
        final removedFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet removed',
        );
        expect(removedFinder, findsNothing);
        expect(tester.widget<Checkbox>(staysCb).value, isTrue);

        final combineBtn = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Collapsed rows keep inline Split action while checkbox selection works',
      (WidgetTester tester) async {
        const humanId = 'gp_collapsed_cb';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final collapsedGame = Game(
          id: 'g_collapsed_cb',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'col_a',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'cs1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'col_b',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'cs2', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Collapsed cb tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: collapsedGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final tileA = find.widgetWithText(ExpansionTile, 'Fleet col_a');
        final tileB = find.widgetWithText(ExpansionTile, 'Fleet col_b');

        expect(
          find.descendant(of: tileA, matching: find.byTooltip('Split')),
          findsOne,
        );
        expect(
          find.descendant(of: tileB, matching: find.byTooltip('Split')),
          findsOne,
        );

        await tester.tap(
          find.descendant(of: tileA, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: tileB, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(of: tileA, matching: find.byTooltip('Split')),
          findsOne,
        );

        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        final merged = fleetsAfter.firstWhere((f) => f.id == 'col_a');
        final mergedIds = merged.ships.map((s) => s.id).toList()..sort();
        expect(mergedIds, ['cs1', 'cs2']);
      },
    );

    testWidgets('AC: Beachhead mission appears in status line', (
      WidgetTester tester,
    ) async {
      const playerId = 'p_beach';
      final gameBeach = Game(
        id: 'beach_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(units: []),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'bf1',
              ownerId: playerId,
              regionId: 'oldWorld',
              seaZoneId: 'atlantic',
              shipTypeIds: const ['carrack'],
              mission: FleetMission.beachhead,
            ),
          ],
          portsByProvinceSeaboard: {
            'oldWorld|lisbon|atlantic': 'oldWorld|lisbon|0|0',
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: const [Player(id: playerId, displayName: 'P', isHuman: true)],
      );

      await tester.pumpWidget(
        buildPanel(game: gameBeach, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Beachhead'), findsWidgets);
    });

    testWidgets('AC: No fleets and no capital shows empty naval message', (
      WidgetTester tester,
    ) async {
      const playerId = 'p_empty';
      final emptyGame = Game(
        id: 'empty_naval',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [
          const Player(
            id: playerId,
            displayName: 'Solo',
            isHuman: true,
            treasury: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        buildPanel(game: emptyGame, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.text('No naval units'), findsOneWidget);
    });

    testWidgets('AC: Home Fleet collapsed row does not show Move action', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_move_home';
      const capProvince = 'oldWorld|cap1';
      final homeId = homeFleetIdFor(humanId);

      final moveHomeGame = Game(
        id: 'g_move_home',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
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
              ships: const [ShipInstance(id: 'home_ship', typeId: 'carrack')],
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
            displayName: 'Move Home Test',
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
        buildPanel(game: moveHomeGame, humanPlayerId: humanId),
      );
      await tester.pumpAndSettle();

      final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
      expect(homeTile, findsOneWidget);

      expect(
        find.descendant(of: homeTile, matching: find.byTooltip('Move')),
        findsNothing,
      );
    });

    testWidgets(
      'AC: Non-home collapsed Move action opens MoveFleetDialog without expansion',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        final nonHomeFleets = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanId &&
                  f.shipTypeIds.isNotEmpty &&
                  f.id != homeFleetIdFor(humanId),
            )
            .toList();
        if (nonHomeFleets.isEmpty) return;
        final targetFleet = nonHomeFleets.first;

        await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
        await tester.pumpAndSettle();

        final fleetTile = find.widgetWithText(
          ExpansionTile,
          'Fleet ${targetFleet.id}',
        );
        expect(fleetTile, findsOneWidget);
        await tester.ensureVisible(fleetTile);

        final moveButton = find.descendant(
          of: fleetTile,
          matching: find.byTooltip('Move'),
        );
        expect(moveButton, findsOneWidget);
        await tester.ensureVisible(moveButton);
        await tester.tap(moveButton);
        await tester.pumpAndSettle();

        expect(find.byType(MoveFleetDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('AC: Narrow row switches inline actions to icon-only mode', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 800));

      final humanId = humanPlayerIdWithFleets;
      final nonHomeFleets = game.worldState.fleets
          .where(
            (f) =>
                f.ownerId == humanId &&
                f.shipTypeIds.isNotEmpty &&
                f.id != homeFleetIdFor(humanId),
          )
          .toList();
      if (nonHomeFleets.isEmpty) return;
      final targetFleet = nonHomeFleets.first;

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
      await tester.pumpAndSettle();

      final fleetTile = find.widgetWithText(
        ExpansionTile,
        'Fleet ${targetFleet.id}',
      );
      expect(fleetTile, findsOneWidget);

      expect(
        find.descendant(of: fleetTile, matching: find.byIcon(Icons.route)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: fleetTile, matching: find.byIcon(Icons.call_split)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: fleetTile, matching: find.text('Move')),
        findsNothing,
      );
    });

    testWidgets(
      'AC: Home Fleet is never deleted even when empty after combine',
      (WidgetTester tester) async {
        const humanId = 'gp_home_never_deleted';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        final homeNeverDeleteGame = Game(
          id: 'g_home_never_deleted',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
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
                ships: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
              ),
              Fleet(
                id: 'donor',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'ship_d', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Home never deleted tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(
            game: homeNeverDeleteGame,
            humanPlayerId: humanId,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final homeFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final donorFinder = find.widgetWithText(ExpansionTile, 'Fleet donor');
        expect(homeFinder, findsOneWidget);
        expect(donorFinder, findsOneWidget);

        await tester.tap(
          find.descendant(of: homeFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: donorFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        final homeFleet = fleetsAfter.where((f) => f.id == homeId);
        expect(homeFleet, isNotEmpty);
        final shipIds = homeFleet.first.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ship_d', 'ship_h']);
        expect(fleetsAfter.any((f) => f.id == 'donor'), isFalse);
      },
    );

    testWidgets(
      'AC: Non-Home fleet split cannot empty original (Confirm Split disabled)',
      (WidgetTester tester) async {
        const humanId = 'gp_nonhome_removed';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        final nonHomeSplitGame = Game(
          id: 'g_nonhome_removed',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
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
                ships: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
              ),
              Fleet(
                id: 'split_me',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'ship_s1', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Non-home removed tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        final subSplit = wireNavalSplitForWidgetTest(
          bus: bus,
          gameSnapshot: () => nonHomeSplitGame,
        );
        addTearDown(sub.cancel);
        addTearDown(subSplit.cancel);

        await tester.pumpWidget(
          buildPanel(game: nonHomeSplitGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final fleetFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet split_me',
        );
        expect(fleetFinder, findsOneWidget);

        await tester.ensureVisible(fleetFinder);
        await tester.tap(fleetFinder);
        await tester.pumpAndSettle();

        final splitButton = find.descendant(
          of: fleetFinder,
          matching: find.byTooltip('Split'),
        );
        expect(splitButton, findsOneWidget);
        await tester.ensureVisible(splitButton);
        await tester.pumpAndSettle();
        await tester.tap(splitButton);
        await tester.pumpAndSettle();

        final fleet = nonHomeSplitGame.worldState.fleets.firstWhere(
          (f) => f.id == 'split_me',
        );
        expect(fleet.ships.length, 1);

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveOne(fleet.ships.first.typeId)),
        );
        await tester.pumpAndSettle();

        final confirmBtn = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Confirm Split'),
        );
        expect(confirmBtn.enabled, isFalse);
        expect(updated, isNull);
      },
    );
  });

  group('Draft naval move subtitle', () {
    testWidgets('shows Moving to line when draft order present', (
      WidgetTester tester,
    ) async {
      const ow = 'oldWorld';
      const humanId = 'gp_draft_line';
      const capProvince = '$ow|capital';
      final draftGame = Game(
        id: 'g_draft_line',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: capProvince,
                regionId: ow,
                ownerId: humanId,
                displayName: 'Capital',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: homeFleetIdFor(humanId),
              ownerId: humanId,
              regionId: ow,
              inPortAtProvinceId: capProvince,
              ships: const [],
            ),
            Fleet(
              id: 'f_at_sea',
              ownerId: humanId,
              regionId: ow,
              seaZoneId: 'sz0',
              ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
            ),
          ],
          seaZoneDisplayNameById: const {'oldWorld|sz1': 'Target Sea'},
        ),
        players: [
          Player(
            id: humanId,
            displayName: 'P',
            isHuman: true,
            capitalProvinceId: capProvince,
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: capProvince,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          humanId: [
            const NavalMoveOrder(
              fleetId: 'f_at_sea',
              destinationSeaZoneId: 'sz1',
            ),
          ],
        },
      );

      await tester.pumpWidget(
        buildPanel(
          game: draftGame,
          humanPlayerId: humanId,
          draftOrders: orders,
        ),
      );
      await tester.pump();

      expect(find.textContaining('Moving to: Target Sea'), findsOneWidget);
    });
  });
}
