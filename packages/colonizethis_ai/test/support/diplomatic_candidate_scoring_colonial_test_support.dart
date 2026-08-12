// Shared Game fixtures for COLONIAL-phase diplomatic candidate scoring pins
// (Refs #4310 Slice C).

import 'package:colonizethis_logic/ai_api.dart' show homeArmyIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_quota_consts.dart';

/// Embassy overture from gp1 to the tribe — keeps the tribe a valid
/// declare-war target in COLONIAL (does **not** count toward
/// `_interventionRiskPenalty` because the GP is `overture.gpId == nationId`).
const OvertureState kDiplomaticCandidateScoringGp1TribeEmbassy = OvertureState(
  gpId: kOrchestratorGp1NationId,
  targetId: kOrchestratorTribeId,
  stage: OvertureStage.embassy,
);

/// Embassy overtures from gp2 / gp3 / gp4 to the tribe — three other GPs
/// trigger the maximum intervention-risk penalty
/// (`-(count * 8).clamp(0, 24)` = -24) in `_interventionRiskPenalty`.
const List<OvertureState> kDiplomaticCandidateScoringInterventionEmbassies =
    <OvertureState>[
  OvertureState(
    gpId: 'gp2',
    targetId: kOrchestratorTribeId,
    stage: OvertureStage.embassy,
  ),
  OvertureState(
    gpId: 'gp3',
    targetId: kOrchestratorTribeId,
    stage: OvertureStage.embassy,
  ),
  OvertureState(
    gpId: 'gp4',
    targetId: kOrchestratorTribeId,
    stage: OvertureStage.embassy,
  ),
];

/// Default embassy-only overture list for personality-divergence pins.
const List<OvertureState> kDiplomaticCandidateScoringPersonalityOvertures =
    <OvertureState>[kDiplomaticCandidateScoringGp1TribeEmbassy];

/// COLONIAL-phase Full AI scenario shared by diplomatic candidate scoring
/// pins.
///
/// One GP (`gp1`) at OW=11 (above quota), one tribe (`tribe1`) owning a
/// single sea-reachable NW province, peace + embassy already in place so
/// `declareWar` is a structurally valid scoring candidate. When
/// [includeBystanderGreatPowers] is true, `gp2` / `gp3` / `gp4` are present
/// so intervention-risk variants can attach embassy overtures to the tribe
/// without changing the OW / NW topology between fixtures.
Game diplomaticCandidateScoringColonialTribeScenarioGame({
  required String gameId,
  required List<OvertureState> overtureStates,
  bool includeBystanderGreatPowers = false,
  String homeArmyRegimentUnitId = 'u_gp1',
}) {
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 110),
      oldWorld: RegionData(
        provinces: [
          for (final id in kGp1OwProvincesAtQuota)
            Province(
              id: id,
              regionId: 'oldWorld',
              ownerId: kOrchestratorGp1NationId,
            ),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: kOrchestratorTribeNwProvince,
            regionId: 'newWorld',
            ownerId: kOrchestratorTribeId,
          ),
        ],
      ),
      armies: [
        Army(
          id: homeArmyIdFor(kOrchestratorGp1NationId),
          ownerId: kOrchestratorGp1NationId,
          regionId: 'oldWorld',
          stationedProvinceId: kGp1OwProvincesAtQuota.first,
          regimentUnitIds: [homeArmyRegimentUnitId],
          isHomeArmy: true,
        ),
      ],
    ),
    players: [
      const Player(
        id: kOrchestratorGp1NationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'victoria',
      ),
      if (includeBystanderGreatPowers) ...const <Player>[
        Player(
          id: 'gp2',
          displayName: 'GP2',
          isHuman: false,
          leaderKey: 'henry',
        ),
        Player(
          id: 'gp3',
          displayName: 'GP3',
          isHuman: false,
          leaderKey: 'napoleon',
        ),
        Player(
          id: 'gp4',
          displayName: 'GP4',
          isHuman: false,
          leaderKey: 'isabella',
        ),
      ],
    ],
    tribes: const [Tribe(id: kOrchestratorTribeId, displayName: 'T1')],
    minorNations: const [],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorTribeId,
        state: RelationState.atPeace,
        score: 30,
      ),
    ],
    overtureStates: overtureStates,
  );
}
