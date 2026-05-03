import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_logic/src/turn/end_of_turn_resolver.dart';
import 'package:colonizethis_logic/src/turn/phases/extraction_phase.dart';
import 'package:colonizethis_logic/src/turn/turn_resolution_events.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

/// Regression for GitHub #2025 AC: after command-style canonical ownership
/// transfer, persistence round-trip and named turn-resolution hooks stay usable
/// (emitProvinceCapturedEvents, resolveConnectivity via extraction,
/// findMilitaryVictoryWinner, runEndOfTurnPhase distant/coastal fog passes).
void main() {
  group('Debug flip province (#2025) post-transfer turn downstream', () {
    const pid = '$kRegionOldWorld|p1';
    const tileKey = '$kRegionOldWorld|p1|1|1';

    Game gameBeforeFlip() {
      return TestFixtures.minimalGame(
        id: 'g-flip-downstream',
        turnNumber: 3,
        oldWorld: RegionData(
          provinces: [
            Province(
              id: pid,
              regionId: kRegionOldWorld,
              ownerId: 'ai_1',
              displayName: 'New Bordeaux',
            ),
          ],
          units: [
            Unit(
              id: 'r1',
              type: 'musketeers',
              ownerId: 'ai_1',
              locationProvinceId: pid,
            ),
          ],
        ),
        tileKeysByRegionAndProvince: const {
          kRegionOldWorld: {
            'p1': [tileKey],
          },
        },
        playerVisibilityByTile: {
          'human_1': {tileKey: VisibilityLevel.fogged.name},
          'ai_1': {tileKey: VisibilityLevel.fullyVisible.name},
        },
        players: const [
          Player(
            id: 'human_1',
            displayName: 'Human',
            isHuman: true,
            capitalProvinceId: pid,
            capitalTile: CapitalTile(
              regionId: kRegionOldWorld,
              provinceId: pid,
              x: 1,
              y: 1,
            ),
          ),
          Player(id: 'ai_1', displayName: 'AI', isHuman: false),
        ],
      );
    }

    Map<String, String?> ownershipSnapshot(Game g) {
      final m = <String, String?>{};
      for (final p in g.worldState.oldWorld.provinces) {
        m[p.id] = p.ownerId;
      }
      for (final p in g.worldState.newWorld.provinces) {
        m[p.id] = p.ownerId;
      }
      return m;
    }

    test(
      'canonical transfer JSON round-trip and downstream phase hooks stay coherent',
      () {
        final before = gameBeforeFlip();
        final previous = ownershipSnapshot(before);

        final out = applyCanonicalSingleProvinceOwnershipTransferWithResult(
          before,
          targetProvinceId: pid,
          oldOwnerId: 'ai_1',
          newOwnerId: 'human_1',
        );
        final flipped = out.game;

        final rt = Game.fromJson(flipped.toJson());
        expect(rt.worldState.oldWorld.provinces.single.ownerId, 'human_1');
        expect(
          rt.worldState.oldWorld.units.singleWhere((u) => u.id == 'r1').ownerId,
          'human_1',
        );

        final captured = <GameEvent>[];
        emitProvinceCapturedEvents(
          previous,
          flipped,
          before.worldState.turnState.turnNumber,
          null,
          captured.add,
          null,
        );
        expect(captured, hasLength(1));
        final pe = captured.single as ProvinceCapturedEvent;
        expect(pe.provinceId, pid);
        expect(pe.previousOwnerId, 'ai_1');
        expect(pe.newOwnerId, 'human_1');

        expect(findMilitaryVictoryWinner(flipped), isNull);

        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: kRegionOldWorld,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final grid = [
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ];
        final tileMap = TileMapResult(width: 3, height: 3, grid: grid);
        final afterExtract = runExtractionPhase(flipped, topology, {
          kRegionOldWorld: tileMap,
        }, const <String, Map<CommodityId, int>>{});
        expect(
          afterExtract.worldState.oldWorld.provinces.single.ownerId,
          'human_1',
        );

        final afterEot = runEndOfTurnPhase(
          flipped,
          topology: topology,
          onDialogue: null,
        );
        expect(afterEot.worldState.turnState.turnNumber, 4);
        expect(afterEot.worldState.turnState.phase, TurnPhase.orders);
        expect(afterEot.victory, isNull);
      },
    );
  });
}
