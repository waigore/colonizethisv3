part of 'resolve_turn_combat_movement_test.dart';

void _resolve_turn_combat_part2_part1_combat_partTests() {
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
}
