// Preview fixtures for research slot-card goldens (Refs #3512 / #4734 Slice F).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_preview.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';

import 'golden_capture_harness.dart';

const String researchSlotCardGoldenTechId = kTechIdCropRotation;
const int researchSlotCardGoldenCost = 1800;
const int researchSlotCardGoldenCommitted = 600;

const ResearchSlotTurnPreview researchSlotCardGoldenMediumFunded =
    ResearchSlotTurnPreview(
  funding: ResearchFundingLevel.medium,
  committedProgress: researchSlotCardGoldenCommitted,
  cost: researchSlotCardGoldenCost,
  baseRpPerTurn: 300,
  industrialBonusRpPerTurn: 0,
  anticipatedRpPerTurn: 300,
  goldCostPerTurn: 150,
  goldSpentThisTurn: 150,
  debtBlocked: false,
);

const ResearchSlotTurnPreview researchSlotCardGoldenNoneFunding =
    ResearchSlotTurnPreview(
  funding: ResearchFundingLevel.none,
  committedProgress: researchSlotCardGoldenCommitted,
  cost: researchSlotCardGoldenCost,
  baseRpPerTurn: 0,
  industrialBonusRpPerTurn: 0,
  anticipatedRpPerTurn: 0,
  goldCostPerTurn: 0,
  goldSpentThisTurn: 0,
  debtBlocked: false,
);

const ResearchSlotTurnPreview researchSlotCardGoldenDebtBlocked =
    ResearchSlotTurnPreview(
  funding: ResearchFundingLevel.medium,
  committedProgress: researchSlotCardGoldenCommitted,
  cost: researchSlotCardGoldenCost,
  baseRpPerTurn: 300,
  industrialBonusRpPerTurn: 0,
  anticipatedRpPerTurn: 0,
  goldCostPerTurn: 150,
  goldSpentThisTurn: 0,
  debtBlocked: true,
);

const ResearchSlotTurnPreview researchSlotCardGoldenSpyInsightOne =
    ResearchSlotTurnPreview(
  funding: ResearchFundingLevel.medium,
  committedProgress: researchSlotCardGoldenCommitted,
  cost: researchSlotCardGoldenCost,
  baseRpPerTurn: 300,
  industrialBonusRpPerTurn: 0,
  anticipatedRpPerTurn: 345,
  goldCostPerTurn: 150,
  goldSpentThisTurn: 150,
  debtBlocked: false,
  spyInsightRpPerTurn: 45,
  spyInsightRivalCount: 1,
  spyInsightRivalNames: ['France'],
);

const ResearchSlotTurnPreview researchSlotCardGoldenCompletesNextTurn =
    ResearchSlotTurnPreview(
  funding: ResearchFundingLevel.medium,
  committedProgress: 1600,
  cost: researchSlotCardGoldenCost,
  baseRpPerTurn: 300,
  industrialBonusRpPerTurn: 0,
  anticipatedRpPerTurn: 300,
  goldCostPerTurn: 150,
  goldSpentThisTurn: 150,
  debtBlocked: false,
);

Future<void> pumpResearchSlotCardGoldenHost(
  WidgetTester tester, {
  required Key boundaryKey,
  required Widget child,
  Size surfaceSize = const Size(380, 360),
}) {
  return pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: surfaceSize,
    includeLocalizations: true,
    child: child,
  );
}

Widget researchSlotCardGoldenSlotCard({
  required ResearchFundingLevel funding,
  required ResearchSlotTurnPreview preview,
}) {
  return SizedBox(
    width: 340,
    child: ResearchSlotCard(
      slotIndex: 0,
      techId: researchSlotCardGoldenTechId,
      progress: preview.committedProgress,
      cost: preview.cost,
      canEdit: true,
      funding: funding,
      onFundingChanged: (_) {},
      onCancel: () {},
      onChooseTech: () {},
      turnPreview: preview,
    ),
  );
}
