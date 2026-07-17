// Smoke tests for the shared `NavalUnitsPanel` widget-test scaffolding.
//
// Verifies the consolidated helpers in `naval_units_panel_test_support.dart`
// (extracted from the five `naval_units_panel_part*_test.dart` files, Refs
// #3730) build the canonical panel host and bridge the split/transfer events
// the same way the running shell does, so the part files keep their behavior.
//
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

  testWidgets(
    'buildNavalPanel hosts NavalUnitsPanel inside a MaterialApp scaffold',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildNavalPanel(
          game: buildNavalPanelTestGame(),
          humanPlayerId: kPanelTestHumanPlayerId,
        ),
      );
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(NavalUnitsPanel), findsOneWidget);
    },
  );

  test(
    'buildNavalPanelHomeFleetOnlyGame keeps only the in-port home fleet',
    () {
      final game = buildNavalPanelHomeFleetOnlyGame();
      expect(game.worldState.fleets, hasLength(1));
      expect(game.worldState.fleets.single.inPortAtProvinceId, isNotNull);
    },
  );

  test(
    'buildNavalPanelCapitalHomeAndPeersGame adds home plus peer fleets',
    () {
      const humanId = 'gp_home_peers';
      final game = buildNavalPanelCapitalHomeAndPeersGame(
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
      expect(game.worldState.fleets, hasLength(2));
      expect(
        game.worldState.fleets.any((f) => f.id == homeFleetIdFor(humanId)),
        isTrue,
      );
      expect(game.worldState.fleets.any((f) => f.id == 'peer'), isTrue);
    },
  );

  test(
    'buildNavalPanelCapitalMergePortFleetsGame without capital omits capital player',
    () {
      const humanId = 'gp_no_cap';
      final game = buildNavalPanelCapitalMergePortFleetsGame(
        humanId: humanId,
        gameId: 'g_no_cap',
        displayName: 'No Cap',
        playerHasCapital: false,
        fleets: [
          Fleet(
            id: 'mp1',
            ownerId: humanId,
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|mergeport',
            ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
          ),
        ],
      );
      expect(game.players.single.capitalProvinceId, isNull);
      expect(game.worldState.oldWorld.provinces, hasLength(1));
      expect(game.worldState.fleets, hasLength(1));
    },
  );

  test(
    'buildNavalPanelCapitalMergePortFleetsGame can omit merge-port locate tiles',
    () {
      const humanId = 'gp_no_merge_tiles';
      final game = buildNavalPanelCapitalMergePortFleetsGame(
        humanId: humanId,
        gameId: 'g_no_merge_tiles',
        displayName: 'No Merge Tiles',
        includeMergePortTileKeys: false,
        fleets: [
          Fleet(
            id: 'mp1',
            ownerId: humanId,
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|mergeport',
            ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
          ),
        ],
      );
      final tiles = game.worldState.tileKeysByRegionAndProvince['oldWorld']!;
      expect(tiles.containsKey('oldWorld|cap1'), isTrue);
      expect(tiles.containsKey('oldWorld|mergeport'), isFalse);
    },
  );

  test(
    'buildNavalPanelCapitalHomeAndPeersGame can seed home mission',
    () {
      const humanId = 'gp_home_mission';
      final game = buildNavalPanelCapitalHomeAndPeersGame(
        humanId: humanId,
        gameId: 'g_home_mission',
        displayName: 'Home Mission',
        homeMission: FleetMission.patrol,
        peerFleets: const [],
      );
      final home = game.worldState.fleets.singleWhere(
        (f) => f.id == homeFleetIdFor(humanId),
      );
      expect(home.mission, FleetMission.patrol);
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

  test('buildNavalPanelDraftMoveSubtitleGame seeds target sea display name', () {
    final game = buildNavalPanelDraftMoveSubtitleGame();
    expect(
      game.worldState.seaZoneDisplayNameById['oldWorld|sz1'],
      'Target Sea',
    );
    expect(game.worldState.fleets.any((f) => f.id == 'f_at_sea'), isTrue);
  });

  test('buildNavalPanelEmptyHumanGame has no fleets', () {
    final game = buildNavalPanelEmptyHumanGame();
    expect(game.worldState.fleets, isEmpty);
  });

  test(
    'buildUnitsPanelCapitalAdjacentSeaTopology omits edge when requested',
    () {
      final withEdge = buildUnitsPanelCapitalAdjacentSeaTopology();
      final withoutEdge = buildUnitsPanelCapitalAdjacentSeaTopology(
        includeEdge: false,
      );
      expect(withEdge.edges, hasLength(1));
      expect(withoutEdge.edges, isEmpty);
    },
  );

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
