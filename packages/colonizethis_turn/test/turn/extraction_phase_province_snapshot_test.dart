import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/phases/extraction_phase.dart';

Game _baseGame({
  TileMapState? tileState,
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
  group('runExtractionPhase display projection decoupling (Refs #4064)', () {
    test('normal path delivers stockpile without writing province Extraction map', () {
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
      final priorGrain = game.players.first.stockpile.quantityOf(
        CommodityCatalog.grain.id,
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

      expect(
        next.players.first.stockpile.quantityOf(CommodityCatalog.grain.id),
        greaterThan(priorGrain),
      );
      expect(
        next.toJson()['worldState'],
        isA<Map<Object?, Object?>>(),
      );
      final wsJson = Map<String, dynamic>.from(
        next.toJson()['worldState'] as Map<Object?, Object?>,
      );
      expect(
        wsJson.containsKey('lastTurnProvinceExtractionByProvinceId'),
        isFalse,
      );
    });

    test('scripted extractedByPlayerId still applies stockpile', () {
      final prior = _baseGame();
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

      expect(
        next.players.first.stockpile.quantityOf(CommodityCatalog.grain.id),
        priorGrain + 2,
      );
    });
  });
}
