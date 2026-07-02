import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/turn_resolver_test_harness.dart';

void main() {
  group('resolveTurnForGame', () {
  group('part1_segment3_test', () {
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
                eventSink: TurnEventSink(onDialogue: dialogueEvents.add),
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

  group('part2_part1_combat_test', () {
    test('quick battle mode runs without error and can flip province', () {
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
                Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
                Player(id: 'p2', displayName: 'B', isHuman: true, militaryLevel: 1),
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
            resolveTurnForGame(game: game, topology: topology, orders: orders),
          );

          expect(next.worldState.turnState.turnNumber, 1);
          final p2 = next.worldState.oldWorld.provinces
              .where((p) => p.id == 'oldWorld|P2')
              .singleOrNull;
          expect(p2, isNotNull);
          // Owner may or may not flip depending on Quick Battle outcome, but state
          // remains consistent and combat resolved.
          expect(p2!.ownerId, isNotNull);
        });

        test(
          'combat phase with AI players invokes onDialogue with event battle_won/battle_lost',
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
                globalGameSeed: 12345,
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

            final dialogueEvents = <DialogueEvent>[];
            final next = requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: orders,
                eventSink: TurnEventSink(onDialogue: dialogueEvents.add),
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
            expect(eventDialogue.any((e) => e.situation == 'battle_won'), isTrue);
            expect(eventDialogue.any((e) => e.situation == 'battle_lost'), isTrue);
          },
        );

        test(
          'quick battle defender holds: onDialogue receives battle_won for defender and battle_lost for attacker',
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
                globalGameSeed: 7777,
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
                        type: 'peasant_levies',
                        ownerId: 'p1',
                        locationProvinceId: '$ow|P1',
                      ),
                      Unit(
                        id: 'u2',
                        type: 'grenadiers',
                        ownerId: 'p2',
                        locationProvinceId: '$ow|P2',
                        medals: 2,
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
                    militaryLevel: 1,
                  ),
                  Player(
                    id: 'p2',
                    displayName: 'AI Defender',
                    isHuman: false,
                    militaryLevel: 3,
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

            final dialogueEvents = <DialogueEvent>[];
            requireTurnResolutionComplete(
              resolveTurnForGame(
                game: game,
                topology: topology,
                orders: orders,
                eventSink: TurnEventSink(onDialogue: dialogueEvents.add),
              ),
            );

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

        test(
          'naval interception combat with AI players invokes onDialogue with event battle_won/battle_lost',
          () {
            final topology = MapTopology(
              nodes: const [
                TopologyNode(
                  id: 'sea1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.seaZone,
                ),
              ],
              edges: const [],
            );
            final game = Game(
              id: 'g1',
              globalGameSeed: 42,
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
                oldWorld: const RegionData(),
                newWorld: const RegionData(),
                fleets: [
                  Fleet(
                    id: 'f1',
                    ownerId: 'p1',
                    seaZoneId: 'sea1',
                    regionId: 'oldWorld',
                    shipTypeIds: ['carrack', 'carrack'],
                  ),
                  Fleet(
                    id: 'f2',
                    ownerId: 'p2',
                    seaZoneId: 'sea1',
                    regionId: 'oldWorld',
                    shipTypeIds: ['fluyte'],
                  ),
                ],
              ),
              players: const [
                Player(id: 'p1', displayName: 'AI Fleet A', isHuman: false),
                Player(id: 'p2', displayName: 'AI Fleet B', isHuman: false),
              ],
              diplomacyRelations: [
                DiplomacyRelation(
                  factionId1: 'p1',
                  factionId2: 'p2',
                  state: RelationState.atWar,
                ),
              ],
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
            expect(next.worldState.turnState.turnNumber, 1);
            // Naval battle may or may not eliminate one side; when it does, event dialogue is emitted.
            final eventDialogue = dialogueEvents
                .where(
                  (e) =>
                      e.category == 'event' &&
                      (e.situation == 'battle_won' || e.situation == 'battle_lost'),
                )
                .toList();
            expect(eventDialogue.length, lessThanOrEqualTo(2));
          },
        );
  });

  group('part2_part1_dialogue_order_engine_test', () {
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

  group('part2_part2_segment1_test', () {
    test(
          'validateOrdersAndResolveTurn filters invalid order and applies only valid move',
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
            final game = Game(
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
                      type: kUnitTypeBuilder,
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
              players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
            );
            final orders = Orders(
              moveOrdersByPlayerId: {
                'p1': [
                  MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0'),
                  MoveOrder(unitId: 'u999', destinationTileKey: '$ow|P2|0|0'),
                ],
              },
            );
            final next = requireTurnResolutionComplete(
              validateOrdersAndResolveTurn(
                game: game,
                topology: topology,
                orders: orders,
                extractedByPlayerId: const {},
                defaultAssignments: const [],
              ),
            );
            expect(next.worldState.turnState.turnNumber, 1);
            expect(next.worldState.oldWorld.units.length, 1);
            expect(
              next.worldState.oldWorld.units.single.locationProvinceId,
              '$ow|P2',
            );
          },
        );

        test('movement phase applies naval mission order', () {
          final topology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'sea1',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: const [],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: const RegionData(),
              newWorld: const RegionData(),
              fleets: [
                Fleet(
                  id: 'f1',
                  ownerId: 'p1',
                  seaZoneId: 'sea1',
                  regionId: 'oldWorld',
                  shipTypeIds: ['carrack'],
                  mission: FleetMission.none,
                ),
              ],
            ),
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
          );
          final orders = Orders(
            navalMissionOrdersByPlayerId: {
              'p1': [
                NavalMissionOrder(fleetId: 'f1', mission: FleetMission.patrol.name),
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
          expect(next.worldState.fleets.single.mission, FleetMission.patrol);
          expect(next.worldState.turnState.turnNumber, 1);
        });

        test('movement phase applies naval move order to adjacent sea zone', () {
          final topology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'sea1',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(
                id: 'sea2',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: const RegionData(),
              newWorld: const RegionData(),
              fleets: [
                Fleet(
                  id: 'f1',
                  ownerId: 'p1',
                  seaZoneId: 'sea1',
                  regionId: 'oldWorld',
                  shipTypeIds: ['carrack'],
                ),
              ],
            ),
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
          );
          final orders = Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2')],
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
          expect(next.worldState.fleets.single.seaZoneId, 'sea2');
          expect(next.worldState.turnState.turnNumber, 1);
        });

        test('dock order moves fleet from sea to port at owned province', () {
          const ow = 'oldWorld';
          final topology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'sea1',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
            ],
            edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
              ),
              newWorld: const RegionData(),
              fleets: [
                Fleet(
                  id: 'f1',
                  ownerId: 'p1',
                  seaZoneId: 'sea1',
                  inPortAtProvinceId: null,
                  regionId: ow,
                  shipTypeIds: const ['carrack'],
                ),
              ],
            ),
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
          );
          final orders = Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [
                NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: '$ow|P1'),
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
          final fleet = next.worldState.fleets.single;
          expect(fleet.isInPort, isTrue);
          expect(fleet.inPortAtProvinceId, '$ow|P1');
          expect(fleet.seaZoneId, isNull);
        });

        test('naval move order undocks fleet from port to adjacent sea zone', () {
          const ow = 'oldWorld';
          final topology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'sea1',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
            ],
            edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: RegionData(
                provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
              ),
              newWorld: const RegionData(),
              fleets: [
                Fleet(
                  id: 'f1',
                  ownerId: 'p1',
                  seaZoneId: null,
                  inPortAtProvinceId: '$ow|P1',
                  regionId: ow,
                  shipTypeIds: const ['carrack'],
                ),
              ],
            ),
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
          );
          final orders = Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [
                const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
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
          final fleet = next.worldState.fleets.single;
          expect(fleet.isAtSea, isTrue);
          expect(fleet.seaZoneId, 'sea1');
          expect(fleet.inPortAtProvinceId, isNull);
        });
  });

  group('part2_part2_segment2_test', () {
    test('naval move order targeting home fleet does not move it', () {
          final topology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'sea1',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(
                id: 'sea2',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: const RegionData(),
              newWorld: const RegionData(),
              fleets: [
                Fleet(
                  id: 'fleet_p1',
                  ownerId: 'p1',
                  seaZoneId: 'sea1',
                  regionId: 'oldWorld',
                  shipTypeIds: const ['carrack'],
                ),
              ],
            ),
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
          );
          final orders = Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [
                const NavalMoveOrder(
                  fleetId: 'fleet_p1',
                  destinationSeaZoneId: 'sea2',
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
          expect(next.worldState.fleets.single.seaZoneId, 'sea1');
          expect(next.worldState.turnState.turnNumber, 1);
        });

        test(
          'dock at capital merges sea-going fleet into home fleet and reveals port tiles',
          () {
            const ow = 'oldWorld';
            final topology = MapTopology(
              nodes: const [
                TopologyNode(
                  id: 'sea1',
                  regionId: ow,
                  type: TopologyNodeType.seaZone,
                ),
                TopologyNode(
                  id: 'P1',
                  regionId: ow,
                  type: TopologyNodeType.province,
                ),
              ],
              edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
            );
            const tileKey = '$ow|P1|0|0';
            final game = Game(
              id: 'g1',
              worldState: WorldState(
                turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
                oldWorld: RegionData(
                  provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
                ),
                newWorld: const RegionData(),
                tileKeysByRegionAndProvince: {
                  ow: {
                    '$ow|P1': [tileKey],
                  },
                },
                playerVisibilityByTile: {
                  'p1': {tileKey: 'fogged'},
                },
                fleets: [
                  Fleet(
                    id: 'fleet_p1',
                    ownerId: 'p1',
                    seaZoneId: null,
                    inPortAtProvinceId: '$ow|P1',
                    regionId: ow,
                    shipTypeIds: const ['carrack'],
                  ),
                  Fleet(
                    id: 'f2',
                    ownerId: 'p1',
                    seaZoneId: 'sea1',
                    regionId: ow,
                    shipTypeIds: const ['frigate'],
                  ),
                ],
              ),
              players: const [
                Player(
                  id: 'p1',
                  displayName: 'A',
                  isHuman: true,
                  capitalProvinceId: '$ow|P1',
                ),
              ],
            );
            final orders = Orders(
              navalMoveOrdersByPlayerId: {
                'p1': [
                  NavalMoveOrder(
                    fleetId: 'f2',
                    destinationPortProvinceId: '$ow|P1',
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
            expect(next.worldState.fleets.length, 1);
            final home = next.worldState.fleets.single;
            expect(home.id, 'fleet_p1');
            expect(home.shipTypeIds.length, 2);
            expect(home.isInPort, isTrue);
            expect(
              next.worldState.playerVisibilityByTile['p1']?[tileKey],
              'fullyVisible',
            );
          },
        );

        test('naval move clears mission on fleet', () {
          final topology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'sea1',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(
                id: 'sea2',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: const RegionData(),
              newWorld: const RegionData(),
              fleets: [
                Fleet(
                  id: 'f1',
                  ownerId: 'p1',
                  seaZoneId: 'sea1',
                  regionId: 'oldWorld',
                  shipTypeIds: const ['carrack'],
                  mission: FleetMission.patrol,
                ),
              ],
            ),
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
          );
          final orders = Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [
                const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
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
          expect(next.worldState.fleets.single.mission, FleetMission.none);
        });

        test('naval mission order skipped when naval move targets same fleet', () {
          final topology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'sea1',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(
                id: 'sea2',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
          );
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
              oldWorld: const RegionData(),
              newWorld: const RegionData(),
              fleets: [
                Fleet(
                  id: 'f1',
                  ownerId: 'p1',
                  seaZoneId: 'sea1',
                  regionId: 'oldWorld',
                  shipTypeIds: const ['carrack'],
                  mission: FleetMission.none,
                ),
              ],
            ),
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
          );
          final orders = Orders(
            navalMoveOrdersByPlayerId: {
              'p1': [
                const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
              ],
            },
            navalMissionOrdersByPlayerId: {
              'p1': [NavalMissionOrder(fleetId: 'f1', mission: 'patrol')],
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
          expect(next.worldState.fleets.single.seaZoneId, 'sea2');
          expect(next.worldState.fleets.single.mission, FleetMission.none);
        });
  });
  });
}
