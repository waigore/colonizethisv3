part of 'valid_work_tiles_expectations.dart';

void _suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral() {
  vwtExpectProspectExcludedWhenIronProspected(
    vwtTribeGrainIronFx(prospectedIron: true),
  );
}

void _suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy() {
  final fx = vwtMinorPurchaseFx();
  vwtExpectPurchaseLandIncluded(
    fx,
    gameId: 'g1916pl1',
    overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
  );
}

void _suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail() {
  vwtExpectPurchaseLandExcluded(
    vwtMinorPurchaseFx(),
    gameId: 'g1916pl2',
  );
}
