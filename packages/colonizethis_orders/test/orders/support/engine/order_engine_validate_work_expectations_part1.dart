part of 'order_engine_validate_work_expectations.dart';

void _rejectsSecondPendingWorkOrderForSameUnitInOneTurn() {
  vwExpectSecondPendingWorkOrderRejected();
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
  vwExpectSameTileDevelopmentExclusivityRejected();
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
