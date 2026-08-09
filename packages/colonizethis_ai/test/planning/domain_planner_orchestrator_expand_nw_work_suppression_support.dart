// Shared fixtures for EXPAND-phase NW work filter pins (Refs #4104 Slice C).
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';

const String expandNwWorkSuppressionNationId = 'gp1';
const String expandNwWorkSuppressionFieldArmyId = 'field_a';
const String expandNwWorkSuppressionOwProvince = 'oldWorld|home';
const String expandNwWorkSuppressionOwMinorProvince = 'oldWorld|minor1';
const String expandNwWorkSuppressionNwOwnedProvince = 'newWorld|owned';
const String expandNwWorkSuppressionNwTribeProvince = 'newWorld|tribe';
const String expandNwWorkSuppressionOwTile = '$expandNwWorkSuppressionOwProvince|0|0';
const String expandNwWorkSuppressionNwOwnedTile = '$expandNwWorkSuppressionNwOwnedProvince|0|0';
const String expandNwWorkSuppressionNwTribeTile = '$expandNwWorkSuppressionNwTribeProvince|0|0';

/// Builds a game with one OW Builder, one NW Builder (in a GP-owned NW
/// province), and one NW Merchant (in a tribe-owned NW province). Each unit
/// sits on a deterministic tile so the candidate keys in the fake suggestion
/// API resolve unambiguously. Phase selection is driven entirely by the
/// snapshot the caller passes to `runDomainPlanners`.
Game expandNwWorkSuppressionScenarioGame() {
  return Game(
    id: 'g-2509-expand-nw-suppress',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
      oldWorld: RegionData(
        provinces: const [
          Province(id: expandNwWorkSuppressionOwProvince, regionId: 'oldWorld', ownerId: expandNwWorkSuppressionNationId),
          Province(
            id: expandNwWorkSuppressionOwMinorProvince,
            regionId: 'oldWorld',
            ownerId: 'minor1',
          ),
        ],
        units: [
          Unit(
            id: 'b_ow',
            type: kUnitTypeBuilder,
            ownerId: expandNwWorkSuppressionNationId,
            locationProvinceId: expandNwWorkSuppressionOwProvince,
            tileKey: expandNwWorkSuppressionOwTile,
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: const [
          Province(
            id: expandNwWorkSuppressionNwOwnedProvince,
            regionId: 'newWorld',
            ownerId: expandNwWorkSuppressionNationId,
          ),
          Province(
            id: expandNwWorkSuppressionNwTribeProvince,
            regionId: 'newWorld',
            ownerId: 'tribe1',
          ),
        ],
        units: [
          Unit(
            id: 'b_nw',
            type: kUnitTypeBuilder,
            ownerId: expandNwWorkSuppressionNationId,
            locationProvinceId: expandNwWorkSuppressionNwOwnedProvince,
            tileKey: expandNwWorkSuppressionNwOwnedTile,
          ),
          Unit(
            id: 'm_nw',
            type: kUnitTypeMerchant,
            ownerId: expandNwWorkSuppressionNationId,
            locationProvinceId: expandNwWorkSuppressionNwTribeProvince,
            tileKey: expandNwWorkSuppressionNwTribeTile,
          ),
        ],
      ),
      armies: const [
        Army(
          id: expandNwWorkSuppressionFieldArmyId,
          ownerId: expandNwWorkSuppressionNationId,
          regionId: 'oldWorld',
          stationedProvinceId: expandNwWorkSuppressionOwProvince,
          regimentUnitIds: [],
          isHomeArmy: false,
        ),
      ],
      playerVisibilityByTile: const {
        expandNwWorkSuppressionNationId: {
          expandNwWorkSuppressionOwTile: 'fullyVisible',
          expandNwWorkSuppressionNwOwnedTile: 'fullyVisible',
          expandNwWorkSuppressionNwTribeTile: 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          expandNwWorkSuppressionOwProvince: [expandNwWorkSuppressionOwTile],
        },
        'newWorld': {
          expandNwWorkSuppressionNwOwnedProvince: [expandNwWorkSuppressionNwOwnedTile],
          expandNwWorkSuppressionNwTribeProvince: [expandNwWorkSuppressionNwTribeTile],
        },
      },
      resourceByTileKey: const {
        expandNwWorkSuppressionOwTile: 'grain',
        expandNwWorkSuppressionNwOwnedTile: 'grain',
        expandNwWorkSuppressionNwTribeTile: 'grain',
      },
    ),
    players: const [
      Player(
        id: expandNwWorkSuppressionNationId,
        displayName: 'GP',
        isHuman: false,
        leaderKey: 'victoria',
      ),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: expandNwWorkSuppressionNationId,
        factionId2: 'tribe1',
        state: RelationState.atWar,
        score: 10,
      ),
      DiplomacyRelation(
        factionId1: expandNwWorkSuppressionNationId,
        factionId2: 'minor1',
        state: RelationState.atWar,
        score: 10,
      ),
    ],
  );
}

const FakeOrderSuggestionAPIForDomainPlannerTests expandNwWorkSuppressionMixedRegionWorkApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [
    WorkOrder(
      unitId: 'b_ow',
      target: kWorkTargetBuildImprovement,
      targetTileKey: expandNwWorkSuppressionOwTile,
    ),
    WorkOrder(
      unitId: 'b_nw',
      target: kWorkTargetBuildImprovement,
      targetTileKey: expandNwWorkSuppressionNwOwnedTile,
    ),
    WorkOrder(
      unitId: 'm_nw',
      target: kWorkTargetPurchaseLand,
      targetTileKey: expandNwWorkSuppressionNwTribeTile,
    ),
  ],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
);

const FakeOrderSuggestionAPIForDomainPlannerTests expandNwWorkSuppressionMixedOwNwArmyMoveApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  armyMove: [
    ArmyMoveOrder(
      armyId: expandNwWorkSuppressionFieldArmyId,
      destinationProvinceId: expandNwWorkSuppressionNwTribeProvince,
    ),
    ArmyMoveOrder(
      armyId: expandNwWorkSuppressionFieldArmyId,
      destinationProvinceId: expandNwWorkSuppressionOwMinorProvince,
    ),
  ],
);

const FakeOrderSuggestionAPIForDomainPlannerTests expandNwWorkSuppressionNwOnlyArmyMoveApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  armyMove: [
    ArmyMoveOrder(
      armyId: expandNwWorkSuppressionFieldArmyId,
      destinationProvinceId: expandNwWorkSuppressionNwTribeProvince,
    ),
  ],
);

const EconomyPlan expandNwWorkSuppressionEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig expandNwWorkSuppressionAiConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

const PhasePriorityWeights expandNwWorkSuppressionNwAcquisitionZeroExpand = PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);
