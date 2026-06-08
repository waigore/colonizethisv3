import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_ai_contracts/src/ai/sim_game_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('defaultSimGameAi', () {
    test('with tileMapByRegion can emit build_rail for Rail Builder', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';

      TileMapResult railTileMap() => TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P1'],
        ],
        terrainGrid: [
          [TerrainType.plains],
        ],
      );

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      final game = Game(
        id: 'g-sim-rail',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [
              Unit(
                id: 'rail1',
                type: kUnitTypeRailBuilder,
                ownerId: 'p1',
                locationProvinceId: provinceId,
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: TileMapState().setRoadLevel(tileKey, 1),
          tileKeysByRegionAndProvince: {
            ow: {
              provinceId: [tileKey],
            },
          },
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fullyVisible'},
          },
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: provinceId,
            stockpile: Stockpile()
                .applyDelta(CommodityCatalog.lumber.id, 10)
                .applyDelta(CommodityCatalog.steel.id, 10),
            techUnlocked: const {kTechIdEarlySteamEngine: true},
          ),
        ],
        globalGameSeed: 11,
        aiSeedByGpId: const {'p1': 13},
      );

      final orders = defaultSimGameAi(
        game: game,
        player: game.players.single,
        topology: topology,
        baseSeed: 99,
        tileMapByRegion: {ow: railTileMap()},
      );
      final work = orders.workOrdersByPlayerId['p1'] ?? const [];
      expect(work.any((w) => w.target == kWorkTargetBuildRail), isTrue);
    });
  });
}
