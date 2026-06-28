import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveTurnForGame', () {
    test('endOfTurn era transition invokes onDialogue with event era_change', () {
      // Turn 100 → year 1698 (earlyModern); turn 101 → 1700 (imperial). SPEC/ai/dialogue-and-mood.md.
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 100),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI One', isHuman: false),
          Player(id: 'gp2', displayName: 'AI Two', isHuman: false),
        ],
        turnTimeMapping: TurnTimeMapping.gdd01,
      );
      final dialogueEvents = <DialogueEvent>[];
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: const Orders(),
          eventSink: TurnEventSink(onDialogue: dialogueEvents.add),
        ),
      );
      expect(next.worldState.turnState.turnNumber, 101);
      final eraChange = dialogueEvents
          .where((e) => e.category == 'event' && e.situation == 'era_change')
          .toList();
      expect(eraChange.length, 2);
      for (final e in eraChange) {
        expect(e.era, 'imperial');
        expect(e.variables['previousEra'], 'earlyModern');
      }
    });

    test('combat emits capital_threatened when human attacks AI capital', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      const ow = 'oldWorld';
      final game = ensureMilitaryArmiesForGame(
        Game(
          id: 'g1',
          globalGameSeed: 42,
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'human'),
                Province(id: '$ow|P2', regionId: ow, ownerId: 'ai1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'human',
                  locationProvinceId: '$ow|P1',
                ),
                Unit(
                  id: 'u2',
                  type: 'peasant_levies',
                  ownerId: 'ai1',
                  locationProvinceId: '$ow|P2',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'human', displayName: 'Human', isHuman: true),
            Player(
              id: 'ai1',
              displayName: 'AI',
              isHuman: false,
              capitalProvinceId: '$ow|P2',
            ),
          ],
        ),
      );
      final dialogueEvents = <DialogueEvent>[];
      requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: Orders(
            armyMoveOrdersByPlayerId: {
              'human': [
                ArmyMoveOrder(
                  armyId: fieldArmyIdFor('human', '$ow|P1'),
                  destinationProvinceId: '$ow|P2',
                ),
              ],
            },
          ),
          eventSink: TurnEventSink(onDialogue: dialogueEvents.add),
        ),
      );
      expect(
        dialogueEvents.any(
          (e) => e.category == 'event' && e.situation == 'capital_threatened',
        ),
        isTrue,
      );
    });

    test(
      'combat emits attack_on_minor and attack_on_tribe reactive dialogue',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'N1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'N2',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'P1', id2: 'P2'),
            TopologyEdge(id1: 'N1', id2: 'N2'),
          ],
        );
        const ow = 'oldWorld';
        const nw = 'newWorld';
        final game = ensureMilitaryArmiesForGame(
          Game(
            id: 'g1',
            globalGameSeed: 99,
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: const [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'human'),
                  Province(id: '$ow|P2', regionId: ow, ownerId: 'mn1'),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: 'grenadiers',
                    ownerId: 'human',
                    locationProvinceId: '$ow|P1',
                  ),
                  Unit(
                    id: 'm1',
                    type: 'peasant_levies',
                    ownerId: 'mn1',
                    locationProvinceId: '$ow|P2',
                  ),
                ],
              ),
              newWorld: RegionData(
                provinces: const [
                  Province(id: '$nw|N1', regionId: nw, ownerId: 'human'),
                  Province(id: '$nw|N2', regionId: nw, ownerId: 'tr1'),
                ],
                units: [
                  Unit(
                    id: 'u2',
                    type: 'grenadiers',
                    ownerId: 'human',
                    locationProvinceId: '$nw|N1',
                  ),
                  Unit(
                    id: 't1',
                    type: 'peasant_levies',
                    ownerId: 'tr1',
                    locationProvinceId: '$nw|N2',
                  ),
                ],
              ),
            ),
            players: const [
              Player(id: 'human', displayName: 'Human', isHuman: true),
              Player(id: 'ai1', displayName: 'AI', isHuman: false),
            ],
            minorNations: const [MinorNation(id: 'mn1')],
            tribes: const [Tribe(id: 'tr1')],
            overtureStates: const [
              OvertureState(
                gpId: 'ai1',
                targetId: 'mn1',
                stage: OvertureStage.embassy,
              ),
              OvertureState(
                gpId: 'ai1',
                targetId: 'tr1',
                stage: OvertureStage.embassy,
              ),
            ],
          ),
        );
        final dialogueEvents = <DialogueEvent>[];
        requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: Orders(
              armyMoveOrdersByPlayerId: {
                'human': [
                  ArmyMoveOrder(
                    armyId: fieldArmyIdFor('human', '$ow|P1'),
                    destinationProvinceId: '$ow|P2',
                  ),
                  ArmyMoveOrder(
                    armyId: fieldArmyIdFor('human', '$nw|N1'),
                    destinationProvinceId: '$nw|N2',
                  ),
                ],
              },
            ),
            eventSink: TurnEventSink(onDialogue: dialogueEvents.add),
          ),
        );
        expect(
          dialogueEvents.any((e) => e.situation == 'attack_on_minor'),
          isTrue,
        );
        expect(
          dialogueEvents.any((e) => e.situation == 'attack_on_tribe'),
          isTrue,
        );
      },
    );

    test(
      'resolveTurnForGameFromOrderEngine integrates order engine output',
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
        final gameBase = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'p1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'oldWorld|P2|0|0': 'fullyVisible',
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
        );
        final game = ensureMilitaryArmiesForGame(gameBase);

        final engine = OrderEngine();
        engine.addArmyMoveOrder(
          'p1',
          ArmyMoveOrder(
            armyId: fieldArmyIdFor('p1', '$ow|P1'),
            destinationProvinceId: '$ow|P2',
          ),
        );

        final next = requireTurnResolutionComplete(
          resolveTurnForGameFromOrderEngine(
            game: game,
            topology: topology,
            orderEngine: engine,
          ),
        );

        expect(next.worldState.turnState.turnNumber, 1);
        expect(
          next.worldState.oldWorld.units.single.locationProvinceId,
          'oldWorld|P2',
        );
      },
    );
  });
}
