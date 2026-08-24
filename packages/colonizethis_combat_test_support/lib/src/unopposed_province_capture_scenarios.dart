import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'scenario_runner.dart';

Game _gameWithMinorProvince({
  required String provinceId,
  required String minorOwnerId,
  required List<Unit> units,
  required List<DiplomacyRelation> relations,
}) => TestFixtures.minimalGame(
  id: 'g_unopposed',
  turnNumber: 5,
  players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
  oldWorld: RegionData(
    provinces: [
      Province(
        id: provinceId,
        regionId: kRegionOldWorld,
        ownerId: minorOwnerId,
      ),
    ],
    units: units,
  ),
  armies: [
    Army(
      id: 'army_gp1',
      ownerId: 'gp1',
      regionId: kRegionOldWorld,
      stationedProvinceId: provinceId,
      regimentUnitIds: const ['r1'],
    ),
  ],
  diplomacyRelations: relations,
);

List<RunnableScenario> unopposedProvinceCaptureScenarios() => [
  RunnableScenario(
    scenarioId: 'upc-captures-undefended',
    label: 'captures undefended minor province when GP army moved in at war',
    run: () {
      const provinceId = 'oldWorld|p22';
      final game = _gameWithMinorProvince(
        provinceId: provinceId,
        minorOwnerId: 'minor6',
        units: [
          Unit(
            id: 'r1',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: provinceId,
          ),
        ],
        relations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor6',
            state: RelationState.atWar,
          ),
        ],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: {
          'gp1': [
            ArmyMoveOrder(
              armyId: 'army_gp1',
              destinationProvinceId: provinceId,
            ),
          ],
        },
      );
      expect(
        applyUnopposedProvinceCaptures(
          game,
          orders,
        ).worldState.oldWorld.provinces.single.ownerId,
        'gp1',
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'upc-defender-units',
    label: 'skips when province owner still has combat units in province',
    run: () {
      const provinceId = 'oldWorld|p22';
      final game = _gameWithMinorProvince(
        provinceId: provinceId,
        minorOwnerId: 'minor6',
        units: [
          Unit(
            id: 'r1',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: provinceId,
          ),
          Unit(
            id: 'm1',
            type: 'peasant_levies',
            ownerId: 'minor6',
            locationProvinceId: provinceId,
          ),
        ],
        relations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor6',
            state: RelationState.atWar,
          ),
        ],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: {
          'gp1': [
            ArmyMoveOrder(
              armyId: 'army_gp1',
              destinationProvinceId: provinceId,
            ),
          ],
        },
      );
      expect(
        applyUnopposedProvinceCaptures(
          game,
          orders,
        ).worldState.oldWorld.provinces.single.ownerId,
        'minor6',
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'upc-peace',
    label: 'skips when attacker is not at war with province owner',
    run: () {
      const provinceId = 'oldWorld|p22';
      final game = _gameWithMinorProvince(
        provinceId: provinceId,
        minorOwnerId: 'minor6',
        units: [
          Unit(
            id: 'r1',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: provinceId,
          ),
        ],
        relations: const [],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: {
          'gp1': [
            ArmyMoveOrder(
              armyId: 'army_gp1',
              destinationProvinceId: provinceId,
            ),
          ],
        },
      );
      expect(
        applyUnopposedProvinceCaptures(
          game,
          orders,
        ).worldState.oldWorld.provinces.single.ownerId,
        'minor6',
      );
    },
  ),
];
