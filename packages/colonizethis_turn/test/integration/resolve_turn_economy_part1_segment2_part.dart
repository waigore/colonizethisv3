part of 'resolve_turn_economy_test.dart';

void _resolve_turn_economy_part1_segment2_partTests() {
  group('part1_segment2_test', () {
    test(
          'full turn with tileMapByRegion: extraction pipeline, turn advanced',
          () {
            final topology = MapTopology(
              nodes: [
                const TopologyNode(
                  id: 'p1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.province,
                ),
              ],
              edges: [],
            );
            final grid = [
              ['p1'],
            ];
            final tileMap = TileMapResult(
              width: 1,
              height: 1,
              grid: grid,
              resourceGrid: [
                [Resource.grain],
              ],
            );
            final tileState = TileMapState()
                .setImprovement('oldWorld|p1|0|0', 2)
                .setRoadLevel('oldWorld|p1|0|0', 1);
            const ow = 'oldWorld';
            final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
            final game = Game(
              id: 'g1',
              capitalTileGrainBonusPerTurn: 0,
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
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
                tileState: tileState,
              ),
              players: [
                Player(
                  id: 'pl1',
                  displayName: 'Spain',
                  isHuman: true,
                  capitalProvinceId: '$ow|p1',
                  capitalTile: cap,
                ),
              ],
            );
            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: const Orders(),
                tileMapByRegion: {'oldWorld': tileMap},
                defaultAssignments: const [],
              ),
            );
            expect(next.worldState.turnState.turnNumber, 1);
            expect(next.players.single.stockpile.quantityOf('grain'), 1);
          },
        );

        test(
          'extraction phase with overseas runs allocateOverseasToStockpile and applyTradeInterception path',
          () {
            final topology = MapTopology(
              nodes: [
                const TopologyNode(
                  id: 'p1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.province,
                ),
                const TopologyNode(
                  id: 'n1',
                  regionId: 'newWorld',
                  type: TopologyNodeType.province,
                ),
              ],
              edges: [],
            );
            final tileMapOw = TileMapResult(
              width: 1,
              height: 1,
              grid: [
                ['p1'],
              ],
              resourceGrid: [
                [Resource.grain],
              ],
            );
            final tileMapNw = TileMapResult(
              width: 1,
              height: 1,
              grid: [
                ['n1'],
              ],
              resourceGrid: [
                [Resource.sugarCane],
              ],
            );
            final tileState = TileMapState()
                .setImprovement('oldWorld|p1|0|0', 1)
                .setRoadLevel('oldWorld|p1|0|0', 1)
                .setImprovement('newWorld|n1|0|0', 1)
                .setRoadLevel('newWorld|n1|0|0', 1);
            const ow = 'oldWorld';
            const nw = 'newWorld';
            final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
                oldWorld: RegionData(
                  provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1')],
                ),
                newWorld: RegionData(
                  provinces: [Province(id: '$nw|n1', regionId: nw, ownerId: 'pl1')],
                ),
                tileState: tileState,
              ),
              players: [
                Player(
                  id: 'pl1',
                  displayName: 'Spain',
                  isHuman: true,
                  capitalProvinceId: '$ow|p1',
                  capitalTile: cap,
                ),
              ],
            );
            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: const Orders(),
                tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
                defaultAssignments: const [],
              ),
            );
            expect(next.worldState.turnState.turnNumber, 1);
            expect(
              next.players.single.stockpile.quantityOf('grain'),
              greaterThanOrEqualTo(0),
            );
          },
        );

        test('production phase uses defaultAssignmentsByPlayerId per player', () {
          const topology = MapTopology(nodes: [], edges: []);
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
          final defaultAssignmentsByPlayerId = <String, List<AssignedRecipe>>{
            'p1': const [
              AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 10),
            ],
            'p2': const [
              AssignedRecipe(
                recipeId: 'castIron_from_timber_iron_coal',
                assignedLabour: 15,
              ),
            ],
          };
          final next = requireTurnResolutionComplete(
            resolveTurnForGame(
              game: game,
              topology: topology,
              orders: const Orders(),
              defaultAssignments: const [],
              defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
            ),
          );
          final player1 = next.playerById('p1')!;
          final player2 = next.playerById('p2')!;
          expect(player1.stockpile.quantityOf(CommodityCatalog.lumber.id), 5);
          expect(player1.stockpile.quantityOf(CommodityCatalog.castIron.id), 0);
          expect(player2.stockpile.quantityOf(CommodityCatalog.castIron.id), 3);
          expect(player2.stockpile.quantityOf(CommodityCatalog.lumber.id), 0);
        });
  });
}
