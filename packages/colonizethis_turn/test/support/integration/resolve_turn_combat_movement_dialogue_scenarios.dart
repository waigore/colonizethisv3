import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../turn_resolver_test_harness.dart';

void registerCombatMovementDialogueTests() {
  group('combat movement', () {
    group('combat movement dialogue', () {
      test(
        'endOfTurn era transition invokes onDialogue with event era_change',
        () {
          final dialogueEvents = <DialogueEvent>[];
          final next = resolveTurnComplete(
            game: Game(
              id: 'g1',
              worldState: const WorldState(
                turnState: TurnState(phase: TurnPhase.orders, turnNumber: 100),
                oldWorld: RegionData(),
                newWorld: RegionData(),
              ),
              players: const [
                Player(id: 'gp1', displayName: 'AI One', isHuman: false),
                Player(id: 'gp2', displayName: 'AI Two', isHuman: false),
              ],
              turnTimeMapping: TurnTimeMapping.gdd01,
            ),
            topology: turnTestOwSingleProvinceTopology(),
            orders: const Orders(),
            eventSink: TurnEventSink(onDialogue: dialogueEvents.add),
          );
          expect(next.worldState.turnState.turnNumber, 101);
          final eraChange = dialogueEvents
              .where(
                (e) => e.category == 'event' && e.situation == 'era_change',
              )
              .toList();
          expect(eraChange.length, 2);
          for (final e in eraChange) {
            expect(e.era, 'imperial');
            expect(e.variables['previousEra'], 'earlyModern');
          }
        },
      );

      test('combat emits capital_threatened when human attacks AI capital', () {
        final topology = twoAdjacentOldWorldProvinceTopology();
        const ow = turnTestOldWorldRegionId;
        final game = adjacentOwP1P2Game(
          ensureMilitaryArmies: true,
          globalGameSeed: 42,
          province1OwnerId: 'human',
          province2OwnerId: 'ai1',
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
          players: const [
            Player(id: 'human', displayName: 'Human', isHuman: true),
            Player(
              id: 'ai1',
              displayName: 'AI',
              isHuman: false,
              capitalProvinceId: '$ow|P2',
            ),
          ],
        );
        final dialogueEvents = <DialogueEvent>[];
        resolveTurnComplete(
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
          const ow = kRegionOldWorld;
          const nw = kRegionNewWorld;
          final game = turnTestOwNwMinorTribeAttackGame();
          final dialogueEvents = <DialogueEvent>[];
          resolveTurnComplete(
            game: game,
            topology: turnTestOwNwMinorTribeAttackTopology(),
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
          final topology = twoAdjacentOldWorldProvinceTopology();

          const ow = turnTestOldWorldRegionId;
          final game = adjacentOwP1P2Game(
            ensureMilitaryArmies: true,
            province1OwnerId: 'p1',
            province2OwnerId: 'p1',
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
            ],
            playerVisibilityByTile: const {
              'p1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'oldWorld|P2|0|0': 'fullyVisible',
              },
            },
            players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
          );

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
  });
}
