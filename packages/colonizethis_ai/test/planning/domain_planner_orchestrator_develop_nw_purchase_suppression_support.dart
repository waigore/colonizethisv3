// Shared fixtures for DEVELOP-phase NW `purchase_land` orchestrator pins (Refs #2509).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_develop_nw_purchase_suppression_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';

const String kDevelopNwPurchaseSuppressionOrchestratorNationId =
    kDevelopNwPurchaseSuppressionNationId;
const String kDevelopNwPurchaseSuppressionOrchestratorNwTribeProvince =
    kDevelopNwPurchaseSuppressionNwTribeProvince;
const String kDevelopNwPurchaseSuppressionOrchestratorOwTile =
    kDevelopNwPurchaseSuppressionOwTile;
const String kDevelopNwPurchaseSuppressionOrchestratorNwOwnedTile =
    kDevelopNwPurchaseSuppressionNwOwnedTile;
const String kDevelopNwPurchaseSuppressionOrchestratorNwTribeTile =
    kDevelopNwPurchaseSuppressionNwTribeTile;

const FakeOrderSuggestionAPIForDomainPlannerTests
    kDevelopNwPurchaseSuppressionMixedRegionWorkApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [
    WorkOrder(
      unitId: 'b_ow',
      target: kWorkTargetBuildImprovement,
      targetTileKey: kDevelopNwPurchaseSuppressionOrchestratorOwTile,
    ),
    WorkOrder(
      unitId: 'b_nw',
      target: kWorkTargetBuildImprovement,
      targetTileKey: kDevelopNwPurchaseSuppressionOrchestratorNwOwnedTile,
    ),
    WorkOrder(
      unitId: 'm_nw',
      target: kWorkTargetPurchaseLand,
      targetTileKey: kDevelopNwPurchaseSuppressionOrchestratorNwTribeTile,
    ),
  ],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
);

const EconomyPlan kDevelopNwPurchaseSuppressionEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kDevelopNwPurchaseSuppressionAiConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);
