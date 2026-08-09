import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../turn_resolver_test_harness.dart';

void registerEconomyContinuedTests() {
  group('economy phases', () {
    group('economy phases continued', () {
      test(
        'full turn with tileMapByRegion: extraction pipeline, turn advanced',
        () {
          const ow = kRegionOldWorld;
          const tileKey = '$ow|p1|0|0';
          final game = Game(
            id: 'g1',
            capitalTileGrainBonusPerTurn: 0,
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(
                    id: '$ow|p1',
                    regionId: ow,
                    ownerId: 'pl1',
                    townDevelopmentLevel: 4,
                  ),
                ],
              ),
              newWorld: const RegionData(),
              tileState: TileMapState()
                  .setImprovement(tileKey, 2)
                  .setRoadLevel(tileKey, 1),
            ),
            players: [
              Player(
                id: 'pl1',
                displayName: 'Spain',
                isHuman: true,
                capitalProvinceId: '$ow|p1',
                capitalTile: CapitalTile(
                  regionId: ow,
                  provinceId: '$ow|p1',
                  x: 0,
                  y: 0,
                ),
              ),
            ],
          );
          final next = resolveTurnComplete(
            game: game,
            topology: turnTestOwSingleProvinceTopology(provinceLocalId: 'p1'),
            orders: const Orders(),
            tileMapByRegion: {
              kRegionOldWorld: turnTestResourceTileMap('p1', Resource.grain),
            },
          );
          expect(next.worldState.turnState.turnNumber, 1);
          expect(next.players.single.stockpile.quantityOf('grain'), 1);
        },
      );

      test(
        'extraction phase with overseas runs allocateOverseasToStockpile and applyTradeInterception path',
        () {
          const ow = kRegionOldWorld;
          const nw = kRegionNewWorld;
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                ],
              ),
              newWorld: RegionData(
                provinces: [
                  Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1'),
                ],
              ),
              tileState: TileMapState()
                  .setImprovement('$ow|p1|0|0', 1)
                  .setRoadLevel('$ow|p1|0|0', 1)
                  .setImprovement('$nw|n1|0|0', 1)
                  .setRoadLevel('$nw|n1|0|0', 1),
            ),
            players: [
              Player(
                id: 'pl1',
                displayName: 'Spain',
                isHuman: true,
                capitalProvinceId: '$ow|p1',
                capitalTile: CapitalTile(
                  regionId: ow,
                  provinceId: '$ow|p1',
                  x: 0,
                  y: 0,
                ),
              ),
            ],
          );
          final next = resolveTurnComplete(
            game: game,
            topology: turnTestOwNwCrossRegionTopology(
              owProvinceLocalId: 'p1',
              nwProvinceLocalId: 'n1',
            ),
            orders: const Orders(),
            tileMapByRegion: {
              kRegionOldWorld: turnTestResourceTileMap('p1', Resource.grain),
              kRegionNewWorld: turnTestResourceTileMap('n1', Resource.sugarCane),
            },
          );
          expect(next.worldState.turnState.turnNumber, 1);
          expect(
            next.players.single.stockpile.quantityOf('grain'),
            greaterThanOrEqualTo(0),
          );
        },
      );

      test('production phase uses defaultAssignmentsByPlayerId per player', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(provinces: [], units: []),
            newWorld: RegionData(provinces: [], units: []),
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: false,
              stockpile: const Stockpile()
                  .applyDelta(CommodityCatalog.grain.id, 20)
                  .applyDelta(CommodityCatalog.timber.id, 20)
                  .applyDelta(CommodityCatalog.iron.id, 0)
                  .applyDelta(CommodityCatalog.coal.id, 0),
              workerPool: const WorkerPool(peasants: 10),
            ),
            Player(
              id: 'p2',
              displayName: 'P2',
              isHuman: false,
              stockpile: const Stockpile()
                  .applyDelta(CommodityCatalog.grain.id, 20)
                  .applyDelta(CommodityCatalog.timber.id, 20)
                  .applyDelta(CommodityCatalog.iron.id, 20)
                  .applyDelta(CommodityCatalog.coal.id, 10),
              workerPool: const WorkerPool(peasants: 15),
            ),
          ],
        );
        final next = resolveTurnComplete(
          game: game,
          topology: const MapTopology(nodes: [], edges: []),
          orders: const Orders(),
          defaultAssignmentsByPlayerId: const {
            'p1': [
              AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 10),
            ],
            'p2': [
              AssignedRecipe(recipeId: 'castIron_from_iron', assignedLabour: 15),
            ],
          },
        );
        final player1 = next.playerById('p1')!;
        final player2 = next.playerById('p2')!;
        expect(player1.stockpile.quantityOf(CommodityCatalog.lumber.id), 5);
        expect(player1.stockpile.quantityOf(CommodityCatalog.castIron.id), 0);
        expect(player2.stockpile.quantityOf(CommodityCatalog.castIron.id), 7);
        expect(player2.stockpile.quantityOf(CommodityCatalog.lumber.id), 0);
      });
    });
  });
}
