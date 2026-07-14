import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/phases/extraction_phase.dart';

Game _baseGame({
  TileMapState? tileState,
  Map<String, ProvinceExtractionSnapshot> snapshots = const {},
  int capitalGrainBonus = 0,
  Map<String, bool>? techUnlocked,
}) {
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: 'oldWorld|p1',
          regionId: 'oldWorld',
          ownerId: 'pl1',
          townDevelopmentLevel: 4,
        ),
      ],
    ),
    newWorld: const RegionData(),
    tileState: tileState ?? const TileMapState(),
    lastTurnProvinceExtractionByProvinceId: snapshots,
  );
  return Game(
    id: 'g_snap',
    capitalTileGrainBonusPerTurn: capitalGrainBonus,
    worldState: world,
    players: [
      Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
        techUnlocked: techUnlocked,
      ),
    ],
  );
}

void main() {
  group('runExtractionPhase province Extraction snapshot (Refs #4002)', () {
    test('normal path writes last-turn province snapshot', () {
      const tk = 'oldWorld|p1|0|0';
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['p1'],
        ],
        resourceGrid: const [
          [Resource.grain],
        ],
      );
      final game = _baseGame(
        tileState: TileMapState().setImprovement(tk, 2).setRoadLevel(tk, 4),
        techUnlocked: const {kTechIdMoldboardPlow: true},
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );

      final next = runExtractionPhase(game, topology, {
        'oldWorld': tileMap,
      }, const {});

      final snap =
          next.worldState.lastTurnProvinceExtractionByProvinceId['oldWorld|p1'];
      expect(snap, isNotNull);
      expect(snap!.ownerId, 'pl1');
      final grain = snap.byCommodity['grain'];
      expect(grain, isNotNull);
      expect(grain!.effective, greaterThan(0));
      expect(grain.full, greaterThanOrEqualTo(grain.effective));
      expect(grain.tileKeys, contains(tk));
    });

    test('scripted extractedByPlayerId clears province snapshots', () {
      final prior = _baseGame(
        snapshots: const {
          'oldWorld|p1': ProvinceExtractionSnapshot(
            ownerId: 'pl1',
            byCommodity: {
              'grain': ProvinceExtractionCommodityTotals(effective: 3, full: 3),
            },
          ),
        },
      );
      final priorGrain = prior.players.first.stockpile.quantityOf(
        CommodityCatalog.grain.id,
      );

      final next = runExtractionPhase(
        prior,
        const MapTopology(nodes: [], edges: []),
        null,
        {
          'pl1': {CommodityCatalog.grain.id: 2},
        },
      );

      expect(next.worldState.lastTurnProvinceExtractionByProvinceId, isEmpty);
      expect(
        next.players.first.stockpile.quantityOf(CommodityCatalog.grain.id),
        priorGrain + 2,
      );
    });
  });
}
