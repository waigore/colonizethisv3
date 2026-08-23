/// COLONIAL two-GP peace orchestrator Game builder (Refs #2509 / #4602 Slice E).
library;

import 'package:colonizethis_logic/ai_api.dart' show homeArmyIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_quota_consts.dart';
import 'domain_planner_orchestrator_two_gp_peace_games.dart';

/// COLONIAL-phase two-GP wars Game for orchestrator peace pins (#2509 S10 COLONIAL).
Game buildOrchestratorColonialTwoGpWarsScenarioGame() {
  return Game(
    id: 'g-2509-colonial-two-gp-peace',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 110),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final id in kGp1OwProvincesAtQuota)
            Province(
              id: id,
              regionId: 'oldWorld',
              ownerId: kOrchestratorGp1NationId,
            ),
          for (final id in kOrchestratorColonialTwoGpNonBlockerOwProvinces)
            Province(
              id: id,
              regionId: 'oldWorld',
              ownerId: kOrchestratorColonialTwoGpNonBlockerId,
            ),
        ],
      ),
      newWorld: RegionData(
        provinces: <Province>[
          for (final id in kOrchestratorColonialTwoGpBlockerNwProvinces)
            Province(
              id: id,
              regionId: 'newWorld',
              ownerId: kOrchestratorColonialTwoGpBlockerId,
            ),
          const Province(
            id: kOrchestratorColonialTwoGpTribeNwProvince,
            regionId: 'newWorld',
            ownerId: 'tribe1',
          ),
        ],
      ),
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
          id: homeArmyIdFor(kOrchestratorColonialTwoGpBlockerId),
          ownerId: kOrchestratorColonialTwoGpBlockerId,
          regionId: 'newWorld',
          stationedProvinceId:
              kOrchestratorColonialTwoGpBlockerNwProvinces.first,
          regimentUnitIds: const <String>['u_gp2'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(kOrchestratorColonialTwoGpNonBlockerId),
          ownerId: kOrchestratorColonialTwoGpNonBlockerId,
          regionId: 'oldWorld',
          stationedProvinceId:
              kOrchestratorColonialTwoGpNonBlockerOwProvinces.first,
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
        id: kOrchestratorColonialTwoGpBlockerId,
        displayName: 'GP2',
        isHuman: false,
      ),
      Player(
        id: kOrchestratorColonialTwoGpNonBlockerId,
        displayName: 'GP3',
        isHuman: false,
      ),
    ],
    minorNations: const <MinorNation>[],
    tribes: const <Tribe>[Tribe(id: 'tribe1', displayName: 'T1')],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorColonialTwoGpBlockerId,
        state: RelationState.atWar,
        score: 10,
      ),
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorColonialTwoGpNonBlockerId,
        state: RelationState.atWar,
        score: 10,
      ),
    ],
  );
}
