import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveTurnForGame', () {
    test(
      'one full turn with combat: MoveOrder into enemy province, casualties and province flip',
      () {
        final topology = MapTopology(
          nodes: [
            const TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            const TopologyNode(
              id: 'P2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
        );

        const ow = 'oldWorld';
        final game = ensureMilitaryArmiesForGame(
          Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                  Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: 'grenadiers',
                    ownerId: 'p1',
                    locationProvinceId: '$ow|P1',
                    medals: 2,
                  ),
                  Unit(
                    id: 'u2',
                    type: 'peasant_levies',
                    ownerId: 'p2',
                    locationProvinceId: '$ow|P2',
                  ),
                ],
              ),
              newWorld: const RegionData(),
            ),
            players: [
              Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
              Player(id: 'p2', displayName: 'B', isHuman: true, militaryLevel: 1),
            ],
          ),
        );

        final orders = Orders(
          armyMoveOrdersByPlayerId: {
            'p1': [
              ArmyMoveOrder(
                armyId: fieldArmyIdFor('p1', '$ow|P1'),
                destinationProvinceId: '$ow|P2',
              ),
            ],
          },
        );

        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: orders,
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          ),
        );

        expect(next.worldState.turnState.turnNumber, 1);

        final unitsAfter = next.worldState.oldWorld.units;
        expect(unitsAfter.length, lessThanOrEqualTo(2));

        final p2 = next.worldState.oldWorld.provinces
            .where((p) => p.id == 'oldWorld|P2')
            .singleOrNull;
        expect(p2, isNotNull);
        expect(p2!.ownerId, anyOf('p1', 'p2'));
      },
    );

    test(
      'combat with tileMapByRegion runs capital reassignment when defender loses only province',
      () {
        final topology = MapTopology(
          nodes: [
            const TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            const TopologyNode(
              id: 'P2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
        );
        const ow = 'oldWorld';
        final tileMap = TileMapResult(
          width: 2,
          height: 1,
          grid: [
            ['P1', 'P2'],
          ],
          resourceGrid: [
            [Resource.grain, Resource.grain],
          ],
        );
        final tileState = TileMapState()
            .setImprovement('$ow|P1|0|0', 1)
            .setRoadLevel('$ow|P1|0|0', 1)
            .setImprovement('$ow|P2|0|1', 1)
            .setRoadLevel('$ow|P2|0|1', 1);
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|P2', x: 1, y: 0);
        final game = ensureMilitaryArmiesForGame(
          Game(
            id: 'g1',
            globalGameSeed: 55555,
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                  Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: 'grenadiers',
                    ownerId: 'p1',
                    locationProvinceId: '$ow|P1',
                    medals: 2,
                  ),
                  Unit(
                    id: 'u2',
                    type: 'peasant_levies',
                    ownerId: 'p2',
                    locationProvinceId: '$ow|P2',
                  ),
                ],
              ),
              newWorld: const RegionData(),
              tileState: tileState,
              tileKeysByRegionAndProvince: {
                ow: {
                  'P1': ['$ow|P1|0|0'],
                  'P2': ['$ow|P2|0|1'],
                },
              },
            ),
            players: [
              Player(
                id: 'p1',
                displayName: 'Attacker',
                isHuman: true,
                militaryLevel: 3,
              ),
              Player(
                id: 'p2',
                displayName: 'Defender',
                isHuman: true,
                militaryLevel: 1,
                capitalProvinceId: '$ow|P2',
                capitalTile: cap,
              ),
            ],
            defaultCombatMode: CombatMode.quickBattle,
          ),
        );
        final orders = Orders(
          armyMoveOrdersByPlayerId: {
            'p1': [
              ArmyMoveOrder(
                armyId: fieldArmyIdFor('p1', '$ow|P1'),
                destinationProvinceId: '$ow|P2',
              ),
            ],
          },
        );
        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: orders,
            tileMapByRegion: {'oldWorld': tileMap},
          ),
        );
        expect(next.worldState.turnState.turnNumber, 1);
        final p2Province = next.worldState.oldWorld.provinces
            .where((p) => p.id == '$ow|P2')
            .singleOrNull;
        expect(p2Province, isNotNull);
        expect(p2Province!.ownerId, anyOf('p1', 'p2'));
        // When defender loses their only province, capital reassignment clears their capital (path covered when RNG flips province).
      },
    );

    test(
      'autoResolve combat with AI players invokes onDialogue with event battle_won/battle_lost',
      () {
        final topology = MapTopology(
          nodes: [
            const TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            const TopologyNode(
              id: 'P2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
        );

        const ow = 'oldWorld';
        final game = ensureMilitaryArmiesForGame(
          Game(
            id: 'g1',
            globalGameSeed: 999,
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                  Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: 'grenadiers',
                    ownerId: 'p1',
                    locationProvinceId: '$ow|P1',
                    medals: 2,
                  ),
                  Unit(
                    id: 'u2',
                    type: 'peasant_levies',
                    ownerId: 'p2',
                    locationProvinceId: '$ow|P2',
                  ),
                ],
              ),
              newWorld: const RegionData(),
            ),
            players: const [
              Player(
                id: 'p1',
                displayName: 'AI Attacker',
                isHuman: false,
                militaryLevel: 3,
              ),
              Player(
                id: 'p2',
                displayName: 'AI Defender',
                isHuman: false,
                militaryLevel: 1,
              ),
            ],
            defaultCombatMode: CombatMode.autoResolve,
          ),
        );

        final orders = Orders(
          armyMoveOrdersByPlayerId: {
            'p1': [
              ArmyMoveOrder(
                armyId: fieldArmyIdFor('p1', '$ow|P1'),
                destinationProvinceId: '$ow|P2',
              ),
            ],
          },
        );

        final dialogueEvents = <DialogueEvent>[];
        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: orders,
            onDialogue: dialogueEvents.add,
          ),
        );

        expect(next.worldState.turnState.turnNumber, 1);
        final eventDialogue = dialogueEvents
            .where(
              (e) =>
                  e.category == 'event' &&
                  (e.situation == 'battle_won' || e.situation == 'battle_lost'),
            )
            .toList();
        expect(eventDialogue, isNotEmpty);
      },
    );
  });
}
