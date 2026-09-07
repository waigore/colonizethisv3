import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../turn_resolver_test_harness.dart';

void registerCombatMovementAiTests() {
  group('combat movement', () {
    group('combat movement AI', () {
      test(
        'autoResolve combat with AI players invokes onDialogue with event battle_won/battle_lost',
        () {
          final topology = twoAdjacentOldWorldProvinceTopology();
          const ow = turnTestOldWorldRegionId;
          final game = adjacentOwP1P2Game(
            ensureMilitaryArmies: true,
            globalGameSeed: 999,
            defaultCombatMode: CombatMode.autoResolve,
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
          final next = resolveTurnComplete(
            game: game,
            topology: topology,
            orders: orders,
            eventSink: TurnEventSink(onDialogue: dialogueEvents.add),
          );

          expect(next.worldState.turnState.turnNumber, 1);
          final eventDialogue = dialogueEvents
              .where(
                (e) =>
                    e.category == 'event' &&
                    (e.situation == 'battle_won' ||
                        e.situation == 'battle_lost'),
              )
              .toList();
          expect(eventDialogue, isNotEmpty);
        },
      );
    });
  });
}
