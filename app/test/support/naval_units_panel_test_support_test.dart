// Smoke tests for naval units-panel scaffolding (Refs #3730, #4048).
// SPEC: SPEC/ui/naval-units-panel.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';

import 'naval_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  test('scenario factories cover home/peers, merge-port, empty, draft, topology', () {
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
  });

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
}
