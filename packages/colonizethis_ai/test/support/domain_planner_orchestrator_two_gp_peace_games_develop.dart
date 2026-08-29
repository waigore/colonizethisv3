/// DEVELOP two-GP peace orchestrator Game builder (Refs #2509 / #4602 Slice E).
library;

import 'package:colonizethis_logic/ai_api.dart' show homeArmyIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_quota_consts.dart';
import 'domain_planner_orchestrator_two_gp_peace_games.dart';

/// DEVELOP-phase two-GP wars Game for orchestrator peace pins (#2509 S10 DEVELOP).
Game buildOrchestratorDevelopTwoGpWarsScenarioGame() {
  return Game(
    id: 'g-2509-develop-two-gp-peace',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 140),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final id in kGp1OwProvincesAtQuota)
            Province(
              id: id,
              regionId: 'oldWorld',
              ownerId: kOrchestratorGp1NationId,
            ),
          const Province(
            id: _developGpAOwProvince,
            regionId: 'oldWorld',
            ownerId: kOrchestratorDevelopTwoGpAtWarGpAId,
          ),
          const Province(
            id: _developGpBOwProvince,
            regionId: 'oldWorld',
            ownerId: kOrchestratorDevelopTwoGpAtWarGpBId,
          ),
          const Province(
            id: _developMinorOwProvince,
            regionId: 'oldWorld',
            ownerId: kOrchestratorDevelopTwoGpAtWarMinorId,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: <Army>[
        Army(
          id: homeArmyIdFor(kOrchestratorGp1NationId),
          ownerId: kOrchestratorGp1NationId,
          regionId: 'oldWorld',
          stationedProvinceId: kGp1OwProvincesAtQuota.first,
          regimentUnitIds: const <String>['u_gp1'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(kOrchestratorDevelopTwoGpAtWarGpAId),
          ownerId: kOrchestratorDevelopTwoGpAtWarGpAId,
          regionId: 'oldWorld',
          stationedProvinceId: _developGpAOwProvince,
          regimentUnitIds: const <String>['u_gp2'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(kOrchestratorDevelopTwoGpAtWarGpBId),
          ownerId: kOrchestratorDevelopTwoGpAtWarGpBId,
          regionId: 'oldWorld',
          stationedProvinceId: _developGpBOwProvince,
          regimentUnitIds: const <String>['u_gp3'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: const <Player>[
      Player(
        id: kOrchestratorGp1NationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'victoria',
      ),
      Player(
        id: kOrchestratorDevelopTwoGpAtWarGpAId,
        displayName: 'GP2',
        isHuman: false,
      ),
      Player(
        id: kOrchestratorDevelopTwoGpAtWarGpBId,
        displayName: 'GP3',
        isHuman: false,
      ),
    ],
    minorNations: const <MinorNation>[
      MinorNation(
        id: kOrchestratorDevelopTwoGpAtWarMinorId,
        displayName: 'Minor1',
      ),
    ],
    tribes: const <Tribe>[],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorDevelopTwoGpAtWarGpAId,
        state: RelationState.atWar,
        score: 10,
      ),
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorDevelopTwoGpAtWarGpBId,
        state: RelationState.atWar,
        score: 10,
      ),
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorDevelopTwoGpAtWarMinorId,
        state: RelationState.atWar,
        score: 10,
      ),
    ],
  );
}
