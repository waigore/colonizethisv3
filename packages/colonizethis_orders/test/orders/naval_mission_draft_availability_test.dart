import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'support/validators/naval_order_validator_fixtures.dart';
import 'support/validators/naval_order_validator_test_support.dart';

const _gp1 = 'p1';
const _gp2 = 'p2';

Game _missionGame({
  required List<Province> provinces,
  required List<Fleet> fleets,
  List<DiplomacyRelation> diplomacy = const [],
}) {
  return navalOrderValidatorTestGame(
    fleets: fleets,
    oldWorldProvinces: provinces,
    players: const [
      Player(id: _gp1, displayName: 'P1', isHuman: true),
      Player(id: _gp2, displayName: 'P2', isHuman: true),
    ],
  ).copyWith(diplomacyRelations: diplomacy);
}

void main() {
  group('naval mission draft mutations', () {
    test('applyNavalMissionOrderForPlayer replaces prior mission for fleet', () {
      final after = applyNavalMissionOrderForPlayer(
        Orders(
          navalMissionOrdersByPlayerId: {
            _gp1: [
              NavalMissionOrder(
                fleetId: 'f1',
                mission: FleetMission.patrol.name,
              ),
            ],
          },
        ),
        _gp1,
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.defend.name,
        ),
      );
      expect(
        after.navalMissionOrdersByPlayerId[_gp1],
        equals([
          NavalMissionOrder(
            fleetId: 'f1',
            mission: FleetMission.defend.name,
          ),
        ]),
      );
    });

    test('applyNavalMissionOrderForPlayer removes naval move for same fleet', () {
      final after = applyNavalMissionOrderForPlayer(
        Orders(
          navalMoveOrdersByPlayerId: {
            _gp1: [
              const NavalMoveOrder(
                fleetId: 'f1',
                destinationSeaZoneId: 'sea2',
              ),
            ],
          },
          navalMissionOrdersByPlayerId: {
            _gp1: [
              NavalMissionOrder(
                fleetId: 'f2',
                mission: FleetMission.patrol.name,
              ),
            ],
          },
        ),
        _gp1,
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.patrol.name,
        ),
      );
      expect(after.navalMoveOrdersByPlayerId[_gp1], isEmpty);
      expect(
        after.navalMissionOrdersByPlayerId[_gp1]!.map((o) => o.fleetId).toList(),
        equals(['f2', 'f1']),
      );
    });

    test('removeNavalMissionOrderForPlayer drops pending mission only', () {
      final after = removeNavalMissionOrderForPlayer(
        Orders(
          navalMissionOrdersByPlayerId: {
            _gp1: [
              NavalMissionOrder(
                fleetId: 'f1',
                mission: FleetMission.patrol.name,
              ),
              NavalMissionOrder(
                fleetId: 'f2',
                mission: FleetMission.defend.name,
              ),
            ],
          },
        ),
        _gp1,
        'f1',
      );
      expect(
        after.navalMissionOrdersByPlayerId[_gp1]!.single.fleetId,
        'f2',
      );
    });
  });

  group('navalMissionAvailabilityForFleet', () {
    final topology = novSeaProvinceAdjacent(provinceLocalId: 'P1');

    test('at-sea non-home fleet offers patrol and defend', () {
      final game = _missionGame(
        provinces: [navalOrderValidatorTestOwnedProvince('P1')],
        fleets: [navalOrderValidatorTestFleetAtSea()],
      );
      final availability = navalMissionAvailabilityForFleet(
        game: game,
        topology: topology,
        playerId: _gp1,
        fleet: game.worldState.fleets.single,
        currentOrders: const Orders(),
      );
      expect(availability.baseGatesPass, isTrue);
      expect(
        availability.missions
            .where((o) => o.isEnabled)
            .map((o) => o.mission)
            .toList(),
        equals([
          FleetMission.patrol,
          FleetMission.defend,
        ]),
      );
    });

    test('blockade and beachhead enabled when adjacent war enemy exists', () {
      final game = _missionGame(
        provinces: [
          navalOrderValidatorTestOwnedProvince('P1'),
          navalOrderValidatorTestOwnedProvince('P2', ownerId: _gp2),
        ],
        fleets: [navalOrderValidatorTestFleetAtSea()],
        diplomacy: const [
          DiplomacyRelation(
            factionId1: _gp1,
            factionId2: _gp2,
            state: RelationState.atWar,
          ),
        ],
      );
      final topologyWithEnemy = navalOrderValidatorTestTopology(
        nodes: [
          navalOrderValidatorTestSeaNode('sea1'),
          navalOrderValidatorTestProvinceNode('P1'),
          navalOrderValidatorTestProvinceNode('P2'),
        ],
        edges: const [
          TopologyEdge(id1: 'sea1', id2: 'P1'),
          TopologyEdge(id1: 'sea1', id2: 'P2'),
        ],
      );
      final availability = navalMissionAvailabilityForFleet(
        game: game,
        topology: topologyWithEnemy,
        playerId: _gp1,
        fleet: game.worldState.fleets.single,
        currentOrders: const Orders(),
      );
      expect(
        availability.blockadeTargetProvinceIds,
        equals(['oldWorld|P2']),
      );
      expect(
        availability.missions.where((o) => o.isEnabled).map((o) => o.mission),
        containsAll([
          FleetMission.blockade,
          FleetMission.beachhead,
        ]),
      );
    });

    test('home fleet and in-port fleets have no assignable missions', () {
      final game = _missionGame(
        provinces: [navalOrderValidatorTestOwnedProvince('P1')],
        fleets: [
          navalOrderValidatorTestFleetAtSea(
            fleetId: homeFleetIdFor(_gp1),
          ),
          navalOrderValidatorTestFleetInPort(),
        ],
      );
      for (final fleet in game.worldState.fleets) {
        final availability = navalMissionAvailabilityForFleet(
          game: game,
          topology: topology,
          playerId: _gp1,
          fleet: fleet,
          currentOrders: const Orders(),
        );
        expect(availability.baseGatesPass, isFalse);
        expect(availability.missions, isEmpty);
      }
    });
  });
}
