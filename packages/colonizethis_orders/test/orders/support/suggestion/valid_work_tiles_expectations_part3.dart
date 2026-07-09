part of 'valid_work_tiles_expectations.dart';

void _suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral() {
  vwtExpectProspectExcludedWhenIronProspected(
    vwtTribeGrainIronFx(prospectedIron: true),
  );
}

void _suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy() {
  vwtExpectMinorPurchaseLandIncludedWithEmbassy();
}

void _suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail() {
  vwtExpectMinorPurchaseLandExcludedWithoutEmbassy();
}
