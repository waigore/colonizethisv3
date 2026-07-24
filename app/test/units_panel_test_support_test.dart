// Smoke tests for military + naval units-panel scaffolding (Refs #3730, #4048, #4117).
// SPEC: SPEC/ui/military-units-panel.md, SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';

import 'support/military_units_panel_test_support.dart';
import 'support/naval_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  group('military units panel support', () {
    testWidgets('pumpMilitaryPanel hosts and settles MilitaryUnitsPanel', (
      WidgetTester tester,
    ) async {
      await pumpMilitaryPanel(
        tester,
        game: buildMilitaryPanelTestGame(),
        humanPlayerId: kPanelTestHumanPlayerId,
      );
      expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
    });

    testWidgets(
      'expandAllArmyExpansions expands every ExpansionTile without throwing',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildMilitaryPanel(
            game: buildMilitaryPanelTestGame(),
            humanPlayerId: kPanelTestHumanPlayerId,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ExpansionTile), findsAtLeastNWidgets(1));
        await expandFirstArmyExpansion(tester);
        await expandAllArmyExpansions(tester);
        expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
      },
    );

    test('buildMilitarySeaFleetDisplayGame seeds one fleet at the sea zone', () {
      final game = buildMilitarySeaFleetDisplayGame(
        id: 'sea_smoke',
        playerId: 'p_sea',
        shipTypeIds: const ['galleon'],
        mission: FleetMission.patrol,
        includeLisbonProvince: true,
      );
      expect(game.worldState.fleets, hasLength(1));
      expect(game.worldState.fleets.single.seaZoneId, 'atlantic');
      expect(game.worldState.oldWorld.provinces, hasLength(1));
    });

    test(
      'buildMilitarySeaFleetDisplayGame omits land province when not requested',
      () {
        final game = buildMilitarySeaFleetDisplayGame(
          id: 'sea_empty_land',
          playerId: 'p_sea',
          shipTypeIds: const ['fluyte'],
          mission: FleetMission.defend,
        );
        expect(game.worldState.oldWorld.provinces, isEmpty);
        expect(game.worldState.fleets.single.mission, FleetMission.defend);
      },
    );

    test(
      'buildMilitaryArmyAtLisbonDisplayGame wires regiment ids onto the army',
      () {
        const playerId = 'p_land';
        final game = buildMilitaryArmyAtLisbonDisplayGame(
          id: 'army_smoke',
          playerId: playerId,
          armyId: 'army_x',
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: playerId,
              locationProvinceId: 'oldWorld|lisbon',
            ),
            Unit(
              id: 'u2',
              type: 'musketeers',
              ownerId: playerId,
              locationProvinceId: 'oldWorld|lisbon',
            ),
          ],
        );
        expect(game.worldState.armies.single.regimentUnitIds, ['u1', 'u2']);
        expect(game.worldState.oldWorld.units, hasLength(2));
      },
    );

    test(
      'buildMilitaryProvinceTileLookupGame exposes tile keys without townTileKey',
      () {
        final game =
            buildMilitaryProvinceTileLookupGame(tileKey: 'oldWorld|p1|1|1');
        final province = game.worldState.oldWorld.provinces.single;
        expect(province.townTileKey, isNull);
        expect(
          game.worldState.tileKeysByRegionAndProvince['oldWorld']!['oldWorld|p1'],
          ['oldWorld|p1|1|1'],
        );
      },
    );

    test('buildUnitsPanelAdjacentOwProvincesTopology links the default OW pair', () {
      final topology = buildUnitsPanelAdjacentOwProvincesTopology();
      expect(topology.nodes, hasLength(2));
      expect(topology.edges.single.id1, 'oldWorld|p2');
      expect(topology.edges.single.id2, 'oldWorld|p3');
    });

    test('buildMilitaryTwoFieldArmiesAtProvinceGame seeds two non-home armies', () {
      final game = buildMilitaryTwoFieldArmiesAtProvinceGame(
        id: 'combine_smoke',
        playerId: 'gp_c',
      );
      expect(game.worldState.armies, hasLength(2));
      expect(game.worldState.armies.every((a) => !a.isHomeArmy), isTrue);
      expect(game.worldState.oldWorld.units, hasLength(2));
    });

    test(
      'buildMilitaryFieldArmyWithAdjacentOwnedGame omits tiles when visibility off',
      () {
        final game = buildMilitaryFieldArmyWithAdjacentOwnedGame(
          id: 'draft_smoke',
          playerId: 'gp_d',
          armyId: 'a1',
          regimentUnitIds: const ['u1'],
          includeTileKeysAndVisibility: false,
        );
        expect(game.worldState.tileKeysByRegionAndProvince, isEmpty);
        expect(game.worldState.playerVisibilityByTile, isEmpty);
        expect(game.worldState.oldWorld.provinces, hasLength(2));
      },
    );

    test('buildMilitaryCrossRegionOwnedMoveGame includes OW and NW owned ports', () {
      final game = buildMilitaryCrossRegionOwnedMoveGame(
        id: 'xr_smoke',
        playerId: 'gp_xr',
      );
      expect(game.worldState.oldWorld.provinces, hasLength(2));
      expect(game.worldState.newWorld.provinces, hasLength(1));
      expect(game.worldState.newWorld.provinces.single.displayName, 'New Port');
    });

    test(
      'buildMilitaryInvasionAdjacentHostileGame keeps empty diplomacy relations',
      () {
        final game = buildMilitaryInvasionAdjacentHostileGame(
          id: 'inv_smoke',
          playerId: 'gp_a',
          enemyId: 'gp_b',
        );
        expect(game.players, hasLength(2));
        expect(game.diplomacyRelations, isEmpty);
        expect(
          game.worldState.oldWorld.provinces
              .where((p) => p.ownerId == 'gp_b')
              .single
              .displayName,
          'Hostile',
        );
      },
    );

    testWidgets(
      'ArmySplitTestHarness renders the panel and applies a bus-driven split',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await pumpArmySplitHarness(
          tester,
          initialGame: buildMilitaryHomeArmyAtCapitalGame(
            id: 'g_military_support_smoke',
            playerId: kPanelTestHumanPlayerId,
            regimentIds: const ['r1', 'r2'],
          ),
          humanPlayerId: kPanelTestHumanPlayerId,
          bus: bus,
        );

        expect(find.byType(MilitaryUnitsPanel), findsOneWidget);

        bus.emit(
          ArmySplitRequestedEvent(
            humanPlayerId: kPanelTestHumanPlayerId,
            sourceArmyId: 'home_army',
            unitIdsToMove: const ['r2'],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Army army_1'), findsOneWidget);
      },
    );
  });

  group('naval units panel support', () {
    test(
      'scenario factories cover home/peers, merge-port, empty, draft, topology',
      () {
        const humanId = 'gp_home_peers';
        final peers = buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_home_peers',
          displayName: 'Peers',
          peerFleets: [
            Fleet(
              id: 'peer',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'z1',
              ships: const [ShipInstance(id: 'p1', typeId: 'fluyte')],
            ),
          ],
        );
        expect(peers.worldState.fleets, hasLength(2));
        expect(
          peers.worldState.fleets.any((f) => f.id == homeFleetIdFor(humanId)),
          isTrue,
        );

        final noCap = buildNavalPanelCapitalMergePortFleetsGame(
          humanId: 'gp_no_cap',
          gameId: 'g_no_cap',
          displayName: 'No Cap',
          playerHasCapital: false,
          fleets: [
            Fleet(
              id: 'mp1',
              ownerId: 'gp_no_cap',
              regionId: 'oldWorld',
              inPortAtProvinceId: 'oldWorld|mergeport',
              ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
            ),
          ],
        );
        expect(noCap.players.single.capitalProvinceId, isNull);
        expect(noCap.worldState.oldWorld.provinces, hasLength(1));

        final noMergeTiles = buildNavalPanelCapitalMergePortFleetsGame(
          humanId: 'gp_no_merge_tiles',
          gameId: 'g_no_merge_tiles',
          displayName: 'No Merge Tiles',
          includeMergePortTileKeys: false,
          fleets: [
            Fleet(
              id: 'mp1',
              ownerId: 'gp_no_merge_tiles',
              regionId: 'oldWorld',
              inPortAtProvinceId: 'oldWorld|mergeport',
              ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
            ),
          ],
        );
        final tiles =
            noMergeTiles.worldState.tileKeysByRegionAndProvince['oldWorld']!;
        expect(tiles.containsKey('oldWorld|cap1'), isTrue);
        expect(tiles.containsKey('oldWorld|mergeport'), isFalse);

        expect(
          buildNavalPanelCapitalHomeAndPeersGame(
            humanId: 'gp_home_mission',
            gameId: 'g_home_mission',
            displayName: 'Home Mission',
            homeMission: FleetMission.patrol,
            peerFleets: const [],
          ).worldState.fleets.single.mission,
          FleetMission.patrol,
        );

        final homeOnly = buildNavalPanelHomeFleetOnlyGame();
        expect(homeOnly.worldState.fleets, hasLength(1));
        expect(homeOnly.worldState.fleets.single.inPortAtProvinceId, isNotNull);
        expect(buildNavalPanelEmptyHumanGame().worldState.fleets, isEmpty);
        final draft = buildNavalPanelDraftMoveSubtitleGame();
        expect(
          draft.worldState.seaZoneDisplayNameById['oldWorld|sz1'],
          'Target Sea',
        );
        expect(
          buildNavalPanelBeachheadMissionGame().worldState.fleets.single.mission,
          FleetMission.beachhead,
        );
        expect(buildUnitsPanelCapitalAdjacentSeaTopology().edges, hasLength(1));
        expect(
          buildUnitsPanelCapitalAdjacentSeaTopology(includeEdge: false).edges,
          isEmpty,
        );
      },
    );

    test('withoutNavalPanelCapitalHomeFleets drops in-port capital fleets', () {
      final base = buildNavalPanelTestGame();
      final next = withoutNavalPanelCapitalHomeFleets(
        base,
        kPanelTestHumanPlayerId,
      );
      expect(
        next.worldState.fleets.any(
          (f) => f.id == homeFleetIdFor(kPanelTestHumanPlayerId),
        ),
        isFalse,
      );
      expect(next.worldState.fleets.any((f) => f.id == 'fleet_nh1'), isTrue);
    });

    test('withNavalPanelExtraFleets appends fleets', () {
      final base = buildNavalPanelTestGame();
      final next = withNavalPanelExtraFleets(base, [
        Fleet(
          id: 'extra',
          ownerId: kPanelTestHumanPlayerId,
          regionId: 'oldWorld',
          seaZoneId: 'sz9',
          ships: const [ShipInstance(id: 'e1', typeId: 'carrack')],
        ),
      ]);
      expect(next.worldState.fleets.length, base.worldState.fleets.length + 1);
      expect(next.worldState.fleets.any((f) => f.id == 'extra'), isTrue);
    });

    test('navalFleetTileLabel distinguishes home vs peer fleets', () {
      const humanId = 'gp_label';
      expect(
        navalFleetTileLabel(
          Fleet(
            id: homeFleetIdFor(humanId),
            ownerId: humanId,
            regionId: 'oldWorld',
            ships: const [],
          ),
          humanId,
        ),
        'Home Fleet',
      );
      expect(
        navalFleetTileLabel(
          Fleet(
            id: 'peer',
            ownerId: humanId,
            regionId: 'oldWorld',
            ships: const [],
          ),
          humanId,
        ),
        'Fleet peer',
      );
    });

    test(
      'wireNavalSplitForWidgetTest applies the split and re-emits the update',
      () async {
        final bus = AppEventBus.create();
        final game = buildNavalPanelTestGame();
        final originalFleetCount = game.worldState.fleets.length;
        final sub = wireNavalSplitForWidgetTest(
          bus: bus,
          gameSnapshot: () => game,
        );
        addTearDown(sub.cancel);

        final updated = bus.on<NavalFleetsUpdatedEvent>().first;
        bus.emit(
          NavalSplitFleetRequestedEvent(
            humanPlayerId: kPanelTestHumanPlayerId,
            originalFleetId: 'fleet_nh1',
            shipInstanceIdsToNewFleet: const ['n2'],
          ),
        );

        final event = await updated;
        expect(
          event.game.worldState.fleets.length,
          greaterThan(originalFleetCount),
        );
      },
    );

    test(
      'wireNavalTransferForWidgetTest moves the ship and re-emits the update',
      () async {
        final bus = AppEventBus.create();
        final game = buildNavalPanelTestGame();
        final homeFleetId = homeFleetIdFor(kPanelTestHumanPlayerId);
        final sub = wireNavalTransferForWidgetTest(
          bus: bus,
          gameSnapshot: () => game,
        );
        addTearDown(sub.cancel);

        final updated = bus.on<NavalFleetsUpdatedEvent>().first;
        bus.emit(
          NavalTransferShipsRequestedEvent(
            humanPlayerId: kPanelTestHumanPlayerId,
            sourceFleetId: 'fleet_nh1',
            targetFleetId: homeFleetId,
            shipInstanceIdsToTransfer: const ['n2'],
          ),
        );

        final event = await updated;
        final source = event.game.worldState.fleets.firstWhere(
          (f) => f.id == 'fleet_nh1',
        );
        expect(source.ships.length, 1);
      },
    );
  });
}
