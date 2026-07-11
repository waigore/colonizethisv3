/// COLONIAL-lite scenario Game builders for orchestrator pins
/// (Refs #3941 / #3972).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart' show homeArmyIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_expand_scenarios.dart'
    show buildOrchestratorScenarioGame;
import 'domain_planner_orchestrator_quota_consts.dart';

/// COLONIAL-lite work-order / overture phasing fixture (builder + merchant).
Game buildOrchestratorColonialLiteWorkPhasingScenarioGame({
  required String id,
  required int turnNumber,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final provinceId in kGp1OwProvincesColonialLiteNearQuota)
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: kOrchestratorGp1NationId,
            ),
        ],
      ),
      newWorld: RegionData(
        provinces: const <Province>[
          Province(
            id: kOrchestratorColonialLiteNwGpProvince,
            regionId: 'newWorld',
            ownerId: kOrchestratorGp1NationId,
          ),
          Province(
            id: kOrchestratorColonialLiteNwTribeProvince,
            regionId: 'newWorld',
            ownerId: kOrchestratorTribeId,
          ),
        ],
        units: <Unit>[
          Unit(
            id: 'b_nw',
            type: kUnitTypeBuilder,
            ownerId: kOrchestratorGp1NationId,
            locationProvinceId: kOrchestratorColonialLiteNwGpProvince,
            tileKey: kOrchestratorColonialLiteNwGpTile,
          ),
          Unit(
            id: 'm_nw',
            type: kUnitTypeMerchant,
            ownerId: kOrchestratorGp1NationId,
            locationProvinceId: kOrchestratorColonialLiteNwTribeProvince,
            tileKey: kOrchestratorColonialLiteNwTribeTile,
          ),
        ],
      ),
      armies: <Army>[
        Army(
          id: homeArmyIdFor(kOrchestratorGp1NationId),
          ownerId: kOrchestratorGp1NationId,
          regionId: 'oldWorld',
          stationedProvinceId: kGp1OwProvincesColonialLiteNearQuota.first,
          regimentUnitIds: const <String>['u_gp1'],
          isHomeArmy: true,
        ),
      ],
      playerVisibilityByTile: const <String, Map<String, String>>{
        kOrchestratorGp1NationId: <String, String>{
          kOrchestratorColonialLiteNwGpTile: 'fullyVisible',
          kOrchestratorColonialLiteNwTribeTile: 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: const <String, Map<String, List<String>>>{
        'newWorld': <String, List<String>>{
          kOrchestratorColonialLiteNwGpProvince: <String>[
            kOrchestratorColonialLiteNwGpTile,
          ],
          kOrchestratorColonialLiteNwTribeProvince: <String>[
            kOrchestratorColonialLiteNwTribeTile,
          ],
        },
      },
      resourceByTileKey: const <String, String>{
        kOrchestratorColonialLiteNwGpTile: 'grain',
        kOrchestratorColonialLiteNwTribeTile: 'grain',
      },
    ),
    players: const <Player>[
      Player(
        id: kOrchestratorGp1NationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'henry',
      ),
    ],
    tribes: const <Tribe>[
      Tribe(id: kOrchestratorTribeId, displayName: 'T1'),
    ],
    minorNations: const <MinorNation>[],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorTribeId,
        state: RelationState.atPeace,
        score: 60,
      ),
    ],
    overtureStates: const <OvertureState>[
      OvertureState(
        gpId: kOrchestratorGp1NationId,
        targetId: kOrchestratorTribeId,
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

/// COLONIAL-lite NW `declareWar` suppression fixture (tribe-owned NW only).
Game buildOrchestratorColonialLiteDeclareWarScenarioGame({
  required String id,
  required List<String> gp1OwProvinces,
  int turnNumber = kObserverColonialLiteMinTurn,
}) {
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: gp1OwProvinces,
    turnNumber: turnNumber,
    newWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorTribeNwProvince,
        regionId: 'newWorld',
        ownerId: kOrchestratorTribeId,
      ),
    ],
    tribes: const <Tribe>[
      Tribe(id: kOrchestratorTribeId, displayName: 'T1'),
    ],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorTribeId,
        state: RelationState.atPeace,
        score: 0,
      ),
    ],
  );
}

/// COLONIAL-lite naval-allow fixture (tribe-owned NW, no fleets).
Game buildOrchestratorColonialLiteNavalAllowScenarioGame({
  required String id,
  required int turnNumber,
}) {
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: kGp1OwProvincesColonialLiteNearQuota,
    turnNumber: turnNumber,
    gp1LeaderKey: 'henry',
    newWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorTribeNwProvince,
        regionId: 'newWorld',
        ownerId: kOrchestratorTribeId,
      ),
    ],
    tribes: const <Tribe>[
      Tribe(id: kOrchestratorTribeId, displayName: 'T1'),
    ],
  );
}

/// COLONIAL-lite NW invasion army-move mixed-candidate fixture.
Game buildOrchestratorColonialLiteInvasionArmyMoveScenarioGame({
  required String id,
  required int turnNumber,
  required int gpOwProvinceCount,
}) {
  final gpOwProvinces = gp1OwProvincesForCount(gpOwProvinceCount);
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: gpOwProvinces,
    turnNumber: turnNumber,
    extraOldWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorColonialLiteInvasionOwMinorProvince,
        regionId: 'oldWorld',
        ownerId: kOrchestratorMinorId,
      ),
    ],
    newWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorTribeNwProvince,
        regionId: 'newWorld',
        ownerId: kOrchestratorTribeId,
      ),
    ],
    armies: <Army>[
      Army(
        id: homeArmyIdFor(kOrchestratorGp1NationId),
        ownerId: kOrchestratorGp1NationId,
        regionId: 'oldWorld',
        stationedProvinceId: kOrchestratorOwHomeProvince,
        regimentUnitIds: const <String>['u_home'],
        isHomeArmy: true,
      ),
      Army(
        id: kOrchestratorColonialLiteInvasionFieldArmyId,
        ownerId: kOrchestratorGp1NationId,
        regionId: 'oldWorld',
        stationedProvinceId: kOrchestratorOwHomeProvince,
        regimentUnitIds: const <String>['u_field'],
        isHomeArmy: false,
      ),
    ],
    tribes: const <Tribe>[
      Tribe(id: kOrchestratorTribeId, displayName: 'T1'),
    ],
    minorNations: const <MinorNation>[
      MinorNation(id: kOrchestratorMinorId, displayName: 'M1'),
    ],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorTribeId,
        state: RelationState.atWar,
        score: -20,
      ),
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorMinorId,
        state: RelationState.atWar,
        score: -20,
      ),
    ],
  );
}

