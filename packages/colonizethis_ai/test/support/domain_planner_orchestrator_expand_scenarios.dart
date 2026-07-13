/// EXPAND-family scenario Game builders for orchestrator pins
/// (Refs #3941 / #3972 / #3997).
library;

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_logic/ai_api.dart' show homeArmyIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_quota_consts.dart';

/// Shared EXPAND snapshot: gp1 below OW quota, at war with the OW minor
/// frontier used by [buildOrchestratorExpandMinorWarScenarioGame].
///
/// Used by domain-gates / phase-plan / trade-wiring / pending-cost pins
/// (Refs #3997 fixture consolidation).
AIWorldSnapshot buildOrchestratorExpandMinorWarAtWarSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String minorId = kOrchestratorMinorId,
  String owMinorProvince = kOrchestratorOwMinorProvince,
  int oldWorldProvincesOwned = 7,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: [minorId]),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: [owMinorProvince],
      adjacentOwnerFactionIdsSorted: [minorId],
    ),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: {
      minorId: DiplomacyRelation(
        factionId1: playerId,
        factionId2: minorId,
        state: RelationState.atWar,
        score: -100,
      ),
    },
  );
}

/// EXPAND below-quota snapshot with visible NW tribe acquisition targets.
///
/// Shared by NW `declareWar` / `establishOverture` suppression and COLONIAL
/// tribe declare-war EXPAND negative controls (Refs #3997).
///
/// When [tribePeaceRelationScore] is non-null, embeds an at-peace tribe
/// relation at that score; otherwise [relations] is empty.
AIWorldSnapshot buildOrchestratorExpandNwTribeTargetSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String tribeId = kOrchestratorTribeId,
  String tribeNwProvince = kOrchestratorTribeNwProvince,
  int oldWorldProvincesOwned = 7,
  int provincesToVictory = 24,
  int? tribePeaceRelationScore,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [tribeId],
      preferredColonialTargetFactionIdsSorted: [tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: tribePeaceRelationScore == null
        ? const <String, DiplomacyRelation>{}
        : <String, DiplomacyRelation>{
            tribeId: DiplomacyRelation(
              factionId1: playerId,
              factionId2: tribeId,
              state: RelationState.atPeace,
              score: tribePeaceRelationScore,
            ),
          },
  );
}

/// COLONIAL at-/past-quota snapshot with visible NW tribe acquisition targets.
///
/// Shared by NW suppression COLONIAL controls and COLONIAL tribe declare-war
/// positive pins (Refs #3997).
AIWorldSnapshot buildOrchestratorColonialNwTribeTargetSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String tribeId = kOrchestratorTribeId,
  String tribeNwProvince = kOrchestratorTribeNwProvince,
  int oldWorldProvincesOwned = 11,
  int provincesToVictory = 20,
  int newWorldProvincesOwned = 0,
  List<String> atWarWith = const <String>[],
  int? tribeRelationScore,
  RelationState tribeRelationState = RelationState.atPeace,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
    ),
    colonial: ColonialSummary(
      newWorldProvincesOwned: newWorldProvincesOwned,
      invadableNewWorldProvinceIdsSorted: [tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [tribeId],
      preferredColonialTargetFactionIdsSorted: [tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: tribeRelationScore == null
        ? const <String, DiplomacyRelation>{}
        : <String, DiplomacyRelation>{
            tribeId: DiplomacyRelation(
              factionId1: playerId,
              factionId2: tribeId,
              state: tribeRelationState,
              score: tribeRelationScore,
            ),
          },
  );
}

/// EXPAND below-quota snapshot with a GP-only invadable OW frontier.
AIWorldSnapshot buildOrchestratorExpandGpOnlyBlockerSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String blockerGpId = kOrchestratorBlockerGpId,
  List<String> invadableProvinceIdsSorted = kOrchestratorBlockerOwProvinces,
  int oldWorldProvincesOwned = 7,
  int provincesToVictory = 24,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
      adjacentOwnerFactionIdsSorted: <String>[blockerGpId],
    ),
    colonial: const ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: const <String, DiplomacyRelation>{},
  );
}

/// DEVELOP past-quota snapshot with the same GP-only invadable frontier.
AIWorldSnapshot buildOrchestratorDevelopGpOnlyBlockerSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String blockerGpId = kOrchestratorBlockerGpId,
  List<String> invadableProvinceIdsSorted = kOrchestratorBlockerOwProvinces,
  int oldWorldProvincesOwned = 12,
  int provincesToVictory = 19,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
      adjacentOwnerFactionIdsSorted: <String>[blockerGpId],
    ),
    colonial: const ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: const <String, DiplomacyRelation>{},
  );
}

/// EXPAND below-quota snapshot with an adjacent invadable OW minor.
AIWorldSnapshot buildOrchestratorExpandAdjacentMinorSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String minorId = kOrchestratorAdjacentMinorId,
  String owMinorProvince = kOrchestratorAdjacentMinorOwProvince,
  int oldWorldProvincesOwned = 7,
  int provincesToVictory = 24,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
      invadableProvinceIdsSorted: <String>[owMinorProvince],
      adjacentOwnerFactionIdsSorted: <String>[minorId],
    ),
    colonial: const ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: const <String, DiplomacyRelation>{},
  );
}

/// DEVELOP past-quota snapshot with the same adjacent invadable OW minor.
AIWorldSnapshot buildOrchestratorDevelopAdjacentMinorSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String minorId = kOrchestratorAdjacentMinorId,
  String owMinorProvince = kOrchestratorAdjacentMinorOwProvince,
  int oldWorldProvincesOwned = 12,
  int provincesToVictory = 19,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
      invadableProvinceIdsSorted: <String>[owMinorProvince],
      adjacentOwnerFactionIdsSorted: <String>[minorId],
    ),
    colonial: const ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: const <String, DiplomacyRelation>{},
  );
}

/// Builds a minimal dual-region Game for orchestrator integration pins.
///
/// Callers supply any extra Old/New World provinces, diplomacy, armies, and
/// players; the helper always materializes GP1's OW provinces from
/// [gp1OwProvinces] with [gp1OwnerId].
Game buildOrchestratorScenarioGame({
  required String id,
  required List<String> gp1OwProvinces,
  String gp1OwnerId = kOrchestratorGp1NationId,
  int turnNumber = 110,
  List<Province> extraOldWorldProvinces = const <Province>[],
  List<Province> newWorldProvinces = const <Province>[],
  List<Army> armies = const <Army>[],
  List<Player> players = const <Player>[],
  List<Tribe> tribes = const <Tribe>[],
  List<MinorNation> minorNations = const <MinorNation>[],
  List<DiplomacyRelation> diplomacyRelations = const <DiplomacyRelation>[],
  List<OvertureState> overtureStates = const <OvertureState>[],
  String gp1LeaderKey = 'henry',
}) {
  final resolvedPlayers = players.isEmpty
      ? <Player>[
          Player(
            id: gp1OwnerId,
            displayName: 'GP1',
            isHuman: false,
            leaderKey: gp1LeaderKey,
          ),
        ]
      : players;
  final resolvedArmies = armies.isEmpty && gp1OwProvinces.isNotEmpty
      ? <Army>[
          Army(
            id: homeArmyIdFor(gp1OwnerId),
            ownerId: gp1OwnerId,
            regionId: 'oldWorld',
            stationedProvinceId: gp1OwProvinces.first,
            regimentUnitIds: const <String>['u_gp1'],
            isHomeArmy: true,
          ),
        ]
      : armies;
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final provinceId in gp1OwProvinces)
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: gp1OwnerId,
            ),
          ...extraOldWorldProvinces,
        ],
      ),
      newWorld: RegionData(provinces: newWorldProvinces),
      armies: resolvedArmies,
    ),
    players: resolvedPlayers,
    tribes: tribes,
    minorNations: minorNations,
    diplomacyRelations: diplomacyRelations,
    overtureStates: overtureStates,
  );
}

/// Minimal EXPAND game with gp1 below OW quota, an at-war OW minor, and a
/// non-home field army — shared by domain-gate / phase-plan / trade-wiring pins.
Game buildOrchestratorExpandMinorWarScenarioGame({required String id}) {
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: kGp1OwProvincesBelowQuota,
    turnNumber: 30,
    gp1LeaderKey: 'napoleon',
    extraOldWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorOwMinorProvince,
        regionId: 'oldWorld',
        ownerId: kOrchestratorMinorId,
      ),
    ],
    armies: const <Army>[
      Army(
        id: kOrchestratorFieldArmyId,
        ownerId: kOrchestratorGp1NationId,
        regionId: 'oldWorld',
        stationedProvinceId: kOrchestratorOwHomeProvince,
        regimentUnitIds: <String>['u_field'],
        isHomeArmy: false,
      ),
    ],
    minorNations: const <MinorNation>[
      MinorNation(id: kOrchestratorMinorId, displayName: 'Minor One'),
    ],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorMinorId,
        state: RelationState.atWar,
        score: -100,
      ),
    ],
  );
}

/// EXPAND/COLONIAL tribe declare-war fixture: parameterized gp1 OW holdings
/// plus one tribe-owned NW province visible for colonial acquisition.
Game buildOrchestratorGp1TribeNwScenarioGame({
  required String id,
  required List<String> gp1OwProvinces,
  int turnNumber = 110,
  List<DiplomacyRelation> diplomacyRelations = const <DiplomacyRelation>[],
  List<OvertureState> overtureStates = const <OvertureState>[],
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
    diplomacyRelations: diplomacyRelations,
    overtureStates: overtureStates,
  );
}

/// EXPAND adjacent invadable minor declare-war fixture.
Game buildOrchestratorExpandAdjacentMinorScenarioGame({
  required String id,
  required List<String> gp1OwProvinces,
  int turnNumber = 20,
}) {
  return buildOrchestratorScenarioGame(
    id: id,
    gp1OwProvinces: gp1OwProvinces,
    turnNumber: turnNumber,
    extraOldWorldProvinces: const <Province>[
      Province(
        id: kOrchestratorAdjacentMinorOwProvince,
        regionId: 'oldWorld',
        ownerId: kOrchestratorAdjacentMinorId,
      ),
    ],
    minorNations: const <MinorNation>[
      MinorNation(id: kOrchestratorAdjacentMinorId, displayName: 'M1'),
    ],
  );
}

/// EXPAND GP-only invadable frontier blocker declare-war fixture.
Game buildOrchestratorExpandGpOnlyBlockerScenarioGame({
  required String id,
  required List<String> gp1OwProvinces,
  int turnNumber = 60,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final provinceId in gp1OwProvinces)
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: kOrchestratorGp1NationId,
            ),
          for (final provinceId in kOrchestratorBlockerOwProvinces)
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: kOrchestratorBlockerGpId,
            ),
        ],
      ),
      newWorld: const RegionData(),
      armies: <Army>[
        Army(
          id: homeArmyIdFor(kOrchestratorGp1NationId),
          ownerId: kOrchestratorGp1NationId,
          regionId: 'oldWorld',
          stationedProvinceId: gp1OwProvinces.first,
          regimentUnitIds: const <String>['u_gp1'],
          isHomeArmy: true,
        ),
        Army(
          id: homeArmyIdFor(kOrchestratorBlockerGpId),
          ownerId: kOrchestratorBlockerGpId,
          regionId: 'oldWorld',
          stationedProvinceId: kOrchestratorBlockerOwProvinces.first,
          regimentUnitIds: const <String>['u_gp2'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: const <Player>[
      Player(
        id: kOrchestratorGp1NationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'henry',
      ),
      Player(id: kOrchestratorBlockerGpId, displayName: 'GP2', isHuman: false),
    ],
    minorNations: const <MinorNation>[],
    tribes: const <Tribe>[],
  );
}

