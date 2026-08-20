import 'package:colonizethis_logic/colonizethis_logic.dart'
    show NavalCombatResultEvent;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import 'naval_behavior_scenarios_cases.dart';

void main() {
  group('naval behavior scenarios', () {
    test(
      'scenario: sole mover is side1 (attacker) in naval event when opponent is not Patrol/Blockade '
      '(no interception roll; battle always proceeds)',
      () {
        NavalCombatResultEvent? navalEvent;
        final game = navalBehaviorBaseGame(
          fleets: [
            navalScenarioFleet(
              id: 'f_mover',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              shipTypeIds: const ['carrack', 'carrack'],
              mission: FleetMission.none,
            ),
            navalScenarioFleet(
              id: 'f_other',
              ownerId: 'p2',
              seaZoneId: 'sea1',
              shipTypeIds: const ['fluyte', 'fluyte'],
              mission: FleetMission.defend,
            ),
          ],
          relations: [navalAtWar('p1', 'p2')],
        );

        runNavalInterceptionCombatPhase(
          game,
          navalSea1Topology,
          {
            'p1': [
              const NavalMoveOrder(
                fleetId: 'f_mover',
                destinationSeaZoneId: 'sea1',
              ),
            ],
          },
          sink: TurnEventSink(
            onGameEvent: (e) {
              if (e is NavalCombatResultEvent) navalEvent = e;
            },
          ),
        );

        expect(navalEvent, isNotNull);
        final ev = navalEvent!;
        expect(ev.side1OwnerId, 'p1');
        expect(ev.side2OwnerId, 'p2');
        expect(ev.side1CasualtyCount, greaterThanOrEqualTo(0));
        expect(ev.side2CasualtyCount, greaterThanOrEqualTo(0));
        expect(
          ev.side1CasualtyCount,
          lessThanOrEqualTo(2),
        );
        expect(
          ev.side2CasualtyCount,
          lessThanOrEqualTo(2),
        );
      },
    );

    test('scenario: post-battle fleets preserve mission', () {
      final resolved = runNavalInterceptionCombatPhase(
        navalBehaviorBaseGame(
          fleets: [
            navalScenarioFleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              shipTypeIds: const ['carrack', 'carrack'],
              mission: FleetMission.patrol,
            ),
            navalScenarioFleet(
              id: 'f2',
              ownerId: 'p2',
              seaZoneId: 'sea1',
              shipTypeIds: const ['fluyte', 'fluyte'],
              mission: FleetMission.blockade,
            ),
          ],
          relations: [navalAtWar('p1', 'p2')],
        ),
        navalSea1Topology,
        const {},
      );

      final p1Fleets = resolved.worldState.fleets
          .where((f) => f.ownerId == 'p1')
          .toList();
      final p2Fleets = resolved.worldState.fleets
          .where((f) => f.ownerId == 'p2')
          .toList();
      if (p1Fleets.isNotEmpty) {
        expect(p1Fleets.first.mission, FleetMission.patrol);
      }
      if (p2Fleets.isNotEmpty) {
        expect(p2Fleets.first.mission, FleetMission.blockade);
      }
    });

    test('scenario: hostile adjacent sea zone is not used for retreat', () {
      final resolved = runNavalInterceptionCombatPhase(
        navalBehaviorBaseGame(
          fleets: [
            navalScenarioFleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              shipTypeIds: const ['carrack', 'carrack'],
              mission: FleetMission.patrol,
            ),
            navalScenarioFleet(
              id: 'f2',
              ownerId: 'p2',
              seaZoneId: 'sea1',
              shipTypeIds: const ['fluyte', 'fluyte'],
              mission: FleetMission.blockade,
            ),
            navalScenarioFleet(
              id: 'f3',
              ownerId: 'p3',
              seaZoneId: 'sea2',
              shipTypeIds: const ['carrack'],
              mission: FleetMission.patrol,
            ),
          ],
          relations: [
            navalAtWar('p1', 'p2'),
            navalAtWar('p1', 'p3'),
            navalAtWar('p2', 'p3'),
          ],
        ),
        navalSea123Topology,
        const {},
      );

      final retreatingOwnersInSea2 = resolved.worldState.fleets.where(
        (f) =>
            (f.ownerId == 'p1' || f.ownerId == 'p2') && f.seaZoneId == 'sea2',
      );
      expect(retreatingOwnersInSea2, isEmpty);
    });

    test(
      'scenario: no legal retreat destination keeps survivors in battle zone',
      () {
        final resolved = runNavalInterceptionCombatPhase(
          navalBehaviorBaseGame(
            fleets: [
              navalScenarioFleet(
                id: 'f1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                shipTypeIds: const ['carrack', 'carrack'],
                mission: FleetMission.patrol,
              ),
              navalScenarioFleet(
                id: 'f2',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                shipTypeIds: const ['fluyte', 'fluyte'],
                mission: FleetMission.blockade,
              ),
              navalScenarioFleet(
                id: 'f3',
                ownerId: 'p3',
                seaZoneId: 'sea2',
                shipTypeIds: const ['carrack'],
                mission: FleetMission.patrol,
              ),
            ],
            relations: [
              navalAtWar('p1', 'p2'),
              navalAtWar('p1', 'p3'),
              navalAtWar('p2', 'p3'),
            ],
          ),
          navalSea12Topology,
          const {},
        );

        final sideFleets = resolved.worldState.fleets.where(
          (f) => f.ownerId == 'p1' || f.ownerId == 'p2',
        );
        for (final fleet in sideFleets) {
          expect(fleet.seaZoneId, 'sea1');
        }
      },
    );
  });
}
