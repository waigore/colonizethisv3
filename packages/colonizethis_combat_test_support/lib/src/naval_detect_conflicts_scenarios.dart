// Naval resolver scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_combat_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> detectNavalConflictsScenarios() => [
  RunnableScenario(
    scenarioId: 'ncr-empty-fleets',
    label: 'returns empty when no fleets',
    run: () {
      final game = navalTwoPlayerGame(
        diplomacyRelations: [navalDiplomacyRelation(RelationState.atWar)],
      );
      expect(detectNavalConflicts(game), isEmpty);
    },
  ),
  RunnableScenario(
    scenarioId: 'ncr-peace-same-zone',
    label: 'returns empty when two factions in same zone but at peace',
    run: () {
      final game = navalTwoPlayerGame(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['carrack'],
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['fluyte'],
          ),
        ],
        diplomacyRelations: [navalDiplomacyRelation(RelationState.atPeace)],
      );
      expect(detectNavalConflicts(game), isEmpty);
    },
  ),
  RunnableScenario(
    scenarioId: 'ncr-at-war-battle',
    label: 'returns one BattleContextSea when two at-war factions in same zone',
    run: () {
      final game = navalTwoPlayerGame(
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
        diplomacyRelations: [navalDiplomacyRelation(RelationState.atWar)],
      );
      final battles = detectNavalConflicts(game);
      expect(battles.length, 1);
      expect(battles[0].seaZoneId, 'sea1');
      expect(battles[0].side1.ownerId, 'p1');
      expect(battles[0].side1.shipTypeIds, ['carrack', 'carrack']);
      expect(battles[0].side1.ships.length, 2);
      expect(battles[0].side1.ships.map((s) => s.id).toSet().length, 2);
      expect(battles[0].side2.ownerId, 'p2');
      expect(battles[0].side2.shipTypeIds, ['fluyte']);
    },
  ),
];
