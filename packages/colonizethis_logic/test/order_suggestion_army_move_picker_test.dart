import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/ai/simple_ai_heuristics.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('armyMovePickerDestinations', () {
    test('cached player-owned set matches default destination picker path', () {
      const gp = 'gp1';
      const cap = 'oldWorld|cap';
      const p1 = 'oldWorld|p1';
      const p2 = 'oldWorld|p2';
      const nw = 'newWorld|col';
      final game = Game(
        id: 'g_army_picker_dest_ids',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: gp,
                townTileKey: 'oldWorld|cap|0|0',
              ),
              Province(id: p1, regionId: 'oldWorld', ownerId: gp),
              Province(id: p2, regionId: 'oldWorld', ownerId: gp),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: nw, regionId: 'newWorld', ownerId: gp),
            ],
          ),
          armies: [
            Army(
              id: 'field_a',
              ownerId: gp,
              regionId: 'oldWorld',
              stationedProvinceId: p1,
              regimentUnitIds: const [],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: const {},
        ),
        players: [
          Player(
            id: gp,
            displayName: 'T',
            isHuman: true,
            capitalProvinceId: cap,
          ),
        ],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|cap',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'newWorld|col',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2'),
        ],
      );
      final army = game.worldState.armies.first;
      final uncached = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: gp,
        army: army,
        currentOrders: const Orders(),
      );
      final owned = <String>{
        for (final p in allProvinces(game.worldState))
          if (p.ownerId == gp) toFullProvinceId(p.regionId, p.id),
      };
      final cached = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: gp,
        army: army,
        currentOrders: const Orders(),
        playerOwnedFullProvinceIds: owned,
      );
      expect(cached, uncached);
    });

    test(
      'shared playerView and unitsById matches default armyMovePickerDestinations',
      () {
        const gp = 'gp1';
        const cap = 'oldWorld|cap';
        const p1 = 'oldWorld|p1';
        const p2 = 'oldWorld|p2';
        const nw = 'newWorld|col';
        final game = Game(
          id: 'g_army_picker_shared_view',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: cap,
                  regionId: 'oldWorld',
                  ownerId: gp,
                  townTileKey: 'oldWorld|cap|0|0',
                ),
                Province(id: p1, regionId: 'oldWorld', ownerId: gp),
                Province(id: p2, regionId: 'oldWorld', ownerId: gp),
              ],
              units: const [],
            ),
            newWorld: RegionData(
              provinces: [
                Province(id: nw, regionId: 'newWorld', ownerId: gp),
              ],
            ),
            armies: [
              Army(
                id: 'field_a',
                ownerId: gp,
                regionId: 'oldWorld',
                stationedProvinceId: p1,
                regimentUnitIds: const [],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: const {},
          ),
          players: [
            Player(
              id: gp,
              displayName: 'T',
              isHuman: true,
              capitalProvinceId: cap,
            ),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'oldWorld|cap',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'newWorld|col',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2'),
          ],
        );
        final army = game.worldState.armies.first;
        final baseline = armyMovePickerDestinations(
          game: game,
          topology: topology,
          playerId: gp,
          army: army,
          currentOrders: const Orders(),
        );
        final view = buildPlayerView(game, topology, gp);
        final unitsById = unitsByIdFromWorld(game.worldState);
        final withShared = armyMovePickerDestinations(
          game: game,
          topology: topology,
          playerId: gp,
          army: army,
          currentOrders: const Orders(),
          playerView: view,
          unitsById: unitsById,
        );
        expect(withShared, baseline);
      },
    );

    test(
      'shared factionMembership matches default armyMovePickerDestinations',
      () {
        const gp = 'gp1';
        const cap = 'oldWorld|cap';
        const p1 = 'oldWorld|p1';
        final game = Game(
          id: 'g_army_picker_shared_membership',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: cap,
                  regionId: 'oldWorld',
                  ownerId: gp,
                  townTileKey: 'oldWorld|cap|0|0',
                ),
                Province(id: p1, regionId: 'oldWorld', ownerId: gp),
              ],
              units: const [],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: 'field_a',
                ownerId: gp,
                regionId: 'oldWorld',
                stationedProvinceId: p1,
                regimentUnitIds: const [],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: const {},
          ),
          players: [
            Player(
              id: gp,
              displayName: 'T',
              isHuman: true,
              capitalProvinceId: cap,
            ),
          ],
        );
        final topology = const MapTopology(nodes: [], edges: []);
        final army = game.worldState.armies.first;
        final baseline = armyMovePickerDestinations(
          game: game,
          topology: topology,
          playerId: gp,
          army: army,
          currentOrders: const Orders(),
        );
        final membership = DiplomacyFactionMembership.from(game);
        final withShared = armyMovePickerDestinations(
          game: game,
          topology: topology,
          playerId: gp,
          army: army,
          currentOrders: const Orders(),
          factionMembership: membership,
        );
        expect(withShared, baseline);
      },
    );

    test(
      'sharedCandidateValidator matches default and skips forPlayer rebuild',
      () {
        const gp = 'gp1';
        const cap = 'oldWorld|cap';
        const p1 = 'oldWorld|p1';
        const p2 = 'oldWorld|p2';
        final game = Game(
          id: 'g_army_picker_shared_validator',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: cap,
                  regionId: 'oldWorld',
                  ownerId: gp,
                  townTileKey: 'oldWorld|cap|0|0',
                ),
                Province(id: p1, regionId: 'oldWorld', ownerId: gp),
                Province(id: p2, regionId: 'oldWorld', ownerId: gp),
              ],
              units: const [],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: 'field_a',
                ownerId: gp,
                regionId: 'oldWorld',
                stationedProvinceId: p1,
                regimentUnitIds: const [],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: const {},
          ),
          players: [
            Player(
              id: gp,
              displayName: 'T',
              isHuman: true,
              capitalProvinceId: cap,
            ),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'oldWorld|cap',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2'),
          ],
        );
        const orders = Orders();
        final army = game.worldState.armies.first;
        final baseline = armyMovePickerDestinations(
          game: game,
          topology: topology,
          playerId: gp,
          army: army,
          currentOrders: orders,
        );
        final view = buildPlayerView(game, topology, gp);
        final shared = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: gp,
          basePrefix: orders,
          view: view,
          unitsById: unitsByIdFromWorld(game.worldState),
        );
        resetIncrementalCandidateValidatorBuildCountForTests();
        final withSharedValidator = armyMovePickerDestinations(
          game: game,
          topology: topology,
          playerId: gp,
          army: army,
          currentOrders: orders,
          sharedCandidateValidator: shared,
        );
        expect(withSharedValidator, baseline);
        expect(
          incrementalCandidateValidatorBuildCountForTests,
          0,
          reason:
              'army picker must reuse supplied pass validator (Refs #2394)',
        );
      },
    );
  });

  group('generateOrdersWithSimpleHeuristics army moves', () {
    test('keeps at most one army move per army id', () {
      const gp = 'gp_ai';
      const cap = 'oldWorld|cap';
      const p1 = 'oldWorld|p1';
      const nw = 'newWorld|col';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|cap',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'newWorld|col',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g_heur',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: gp,
                townTileKey: 'oldWorld|cap|0|0',
              ),
              Province(id: p1, regionId: 'oldWorld', ownerId: gp),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: gp,
                locationProvinceId: p1,
                tileKey: 'oldWorld|p1|0|0',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: nw, regionId: 'newWorld', ownerId: gp),
            ],
          ),
          armies: [
            Army(
              id: homeArmyIdFor(gp),
              ownerId: gp,
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const [],
              isHomeArmy: true,
            ),
            Army(
              id: 'field_a',
              ownerId: gp,
              regionId: 'oldWorld',
              stationedProvinceId: p1,
              regimentUnitIds: const ['u1'],
              isHomeArmy: false,
            ),
          ],
          playerVisibilityByTile: {
            gp: {
              'oldWorld|cap|0|0': 'fullyVisible',
              'oldWorld|p1|0|0': 'fullyVisible',
              'newWorld|col|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              cap: ['oldWorld|cap|0|0'],
              p1: ['oldWorld|p1|0|0'],
            },
            'newWorld': {
              nw: ['newWorld|col|0|0'],
            },
          },
        ),
        players: [
          Player(
            id: gp,
            displayName: 'AI',
            isHuman: false,
            capitalProvinceId: cap,
          ),
        ],
        globalGameSeed: 1,
        aiSeedByGpId: const {gp: 42},
      );

      final orders = generateOrdersWithSimpleHeuristics(
        game,
        topology,
        gp,
        turnSeedForPlayer(game, gp, 1),
      );
      final list = orders.armyMoveOrdersByPlayerId[gp] ?? [];
      final perArmy = <String, int>{};
      for (final o in list) {
        perArmy[o.armyId] = (perArmy[o.armyId] ?? 0) + 1;
      }
      expect(perArmy.values.every((c) => c <= 1), isTrue);
    });
  });
}
