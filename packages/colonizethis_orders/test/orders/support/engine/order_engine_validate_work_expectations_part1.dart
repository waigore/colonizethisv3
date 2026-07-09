part of 'order_engine_validate_work_expectations.dart';

void _rejectsSecondPendingWorkOrderForSameUnitInOneTurn() {
  const tileA = ValidateWorkOw.tileKey;
  const tileB = '${ValidateWorkOw.provinceId}|1|0';

  vwExpectDualWorkOrders(
    game: dualTilePendingWorkGame(),
    first: const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileA,
    ),
    second: const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileB,
    ),
    statuses: const [
      OrderValidationStatus.accepted,
      OrderValidationStatus.rejected,
    ],
    lastReasonContains: 'Only one work order per unit is allowed each turn',
  );
}

void _rejectsPurchaseLandWhenNoEmbassyWithMinor() {
  vwExpectPurchaseLandRejectedNoEmbassy();
}

void _rejectsPurchaseLandWhenAtWarWithFaction() {
  vwExpectPurchaseLandRejectedAtWar();
}

void _rejectsPurchaseLandWhenInsufficientTreasury() {
  vwExpectPurchaseLandRejectedInsufficientTreasury();
}

void _rejectsPurchaseLandWhenTileHasNoResource() {
  vwExpectPurchaseLandRejectedNoResource();
}

void _rejectsPurchaseLandWhenMineralTileNotProspected() {
  vwExpectPurchaseLandRejectedMineralNotProspected();
}

void
_acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource() {
  vwExpectPurchaseLandAcceptedEmbassy();
}

void
_rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity() {
  const tileKey = ValidateWorkOw.tileKey;
  vwExpectDualWorkOrders(
    game: builderEngineerSameTileExclusivityGame(),
    first: const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
    second: const WorkOrder(
      unitId: 'engineer1',
      target: kWorkTargetBuildRoad,
      targetTileKey: tileKey,
    ),
    statuses: const [
      OrderValidationStatus.accepted,
      OrderValidationStatus.rejected,
    ],
    lastReasonContains: 'Tile already has development or purchase work',
  );
}

void _acceptsPurchaseLandForMineralWhenProspected() {
  vwExpectPurchaseLandAcceptedMineralProspected();
}

void _rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP() {
  vwExpectPurchaseLandRejectedAlreadyPurchasedByOther();
}

void _rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer() {
  vwExpectPurchaseLandRejectedAlreadyOwnedBySelf();
}
