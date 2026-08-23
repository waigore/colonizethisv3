/// Two-Great-Power peace orchestrator Game builders (Refs #2509 / #4291 Slice C).
library;

import 'package:colonizethis_logic/ai_api.dart' show homeArmyIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_quota_consts.dart';

export 'domain_planner_orchestrator_two_gp_peace_games_colonial.dart';

/// Blocker GP id for EXPAND two-GP peace orchestrator pins.
const String kOrchestratorExpandTwoGpBlockerId = 'gp2';

/// Non-blocker GP id for EXPAND two-GP peace orchestrator pins.
const String kOrchestratorExpandTwoGpNonBlockerId = 'gp3';

/// Invadable OW provinces owned by the EXPAND two-GP blocker GP.
const List<String> kOrchestratorExpandTwoGpBlockerInvadableProvinces = <String>[
  'oldWorld|gp2_0',
  'oldWorld|gp2_1',
  'oldWorld|gp2_2',
];

/// Non-invadable OW province owned by the EXPAND two-GP non-blocker GP.
const String kOrchestratorExpandTwoGpNonBlockerProvince = 'oldWorld|gp3_0';

/// At-war GP A for DEVELOP two-GP peace orchestrator pins.
const String kOrchestratorDevelopTwoGpAtWarGpAId = 'gp2';

/// At-war GP B for DEVELOP two-GP peace orchestrator pins.
const String kOrchestratorDevelopTwoGpAtWarGpBId = 'gp3';

/// At-war minor for DEVELOP two-GP peace negative-control pins.
const String kOrchestratorDevelopTwoGpAtWarMinorId = 'minor1';

const String _developGpAOwProvince = 'oldWorld|gp2_0';
const String _developGpBOwProvince = 'oldWorld|gp3_0';
const String _developMinorOwProvince = 'oldWorld|minor1_0';

/// Blocker GP id for COLONIAL two-GP peace orchestrator pins.
const String kOrchestratorColonialTwoGpBlockerId = 'gp2';

/// Non-blocker GP id for COLONIAL two-GP peace orchestrator pins.
const String kOrchestratorColonialTwoGpNonBlockerId = 'gp3';

/// Invadable NW provinces owned by the COLONIAL two-GP blocker GP.
const List<String> kOrchestratorColonialTwoGpBlockerNwProvinces = <String>[
  'newWorld|gp2_nw0',
  'newWorld|gp2_nw1',
];

/// Tribe-owned NW province in the COLONIAL two-GP invadable set.
const String kOrchestratorColonialTwoGpTribeNwProvince = 'newWorld|tribe1_nw0';

/// At-quota OW provinces owned by the COLONIAL two-GP non-blocker GP.
const List<String> kOrchestratorColonialTwoGpNonBlockerOwProvinces = <String>[
  'oldWorld|gp3_0',
  'oldWorld|gp3_1',
  'oldWorld|gp3_2',
  'oldWorld|gp3_3',
  'oldWorld|gp3_4',
  'oldWorld|gp3_5',
  'oldWorld|gp3_6',
  'oldWorld|gp3_7',
  'oldWorld|gp3_8',
  'oldWorld|gp3_9',
];

/// EXPAND-phase two-GP wars Game for orchestrator peace pins (#2509 S10 EXPAND).
Game buildOrchestratorExpandTwoGpWarsScenarioGame() {
  return Game(
    id: 'g-2509-expand-two-gp-peace',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final id in kGp1OwProvincesExpandTwoGp)
            Province(
              id: id,
              regionId: 'oldWorld',
              ownerId: kOrchestratorGp1NationId,
            ),
          for (final id in kOrchestratorExpandTwoGpBlockerInvadableProvinces)
            Province(
              id: id,
              regionId: 'oldWorld',
              ownerId: kOrchestratorExpandTwoGpBlockerId,
            ),
          const Province(
            id: kOrchestratorExpandTwoGpNonBlockerProvince,
            regionId: 'oldWorld',
            ownerId: kOrchestratorExpandTwoGpNonBlockerId,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: <Army>[
        Army(
          id: homeArmyIdFor(kOrchestratorGp1NationId),
          ownerId: kOrchestratorGp1NationId,
          regionId: 'oldWorld',
          stationedProvinceId: kGp1OwProvincesExpandTwoGp.first,
          regimentUnitIds: const <String>['u_gp1'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(kOrchestratorExpandTwoGpBlockerId),
          ownerId: kOrchestratorExpandTwoGpBlockerId,
          regionId: 'oldWorld',
          stationedProvinceId:
              kOrchestratorExpandTwoGpBlockerInvadableProvinces.first,
          regimentUnitIds: const <String>['u_gp2'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(kOrchestratorExpandTwoGpNonBlockerId),
          ownerId: kOrchestratorExpandTwoGpNonBlockerId,
          regionId: 'oldWorld',
          stationedProvinceId: kOrchestratorExpandTwoGpNonBlockerProvince,
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
        id: kOrchestratorExpandTwoGpBlockerId,
        displayName: 'GP2',
        isHuman: false,
      ),
      Player(
        id: kOrchestratorExpandTwoGpNonBlockerId,
        displayName: 'GP3',
        isHuman: false,
      ),
    ],
    minorNations: const <MinorNation>[],
    tribes: const <Tribe>[],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorExpandTwoGpBlockerId,
        state: RelationState.atWar,
        score: 10,
      ),
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorExpandTwoGpNonBlockerId,
        state: RelationState.atWar,
        score: 10,
      ),
    ],
  );
}

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
