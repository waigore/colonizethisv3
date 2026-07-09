part of 'valid_work_tiles_expectations.dart';

void _suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral() {
  final fx = vwtTribeGrainIronFx(prospectedIron: true);
  expect(
    vwtSuggestProspect(
      vwtTribeConsulateGame(fx, id: 'g1916p2'),
      fx.topology(),
    ),
    isEmpty,
  );
}

void _suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy() {
  final fx = vwtMinorPurchaseFx();
  expect(
    vwtSuggestPurchaseLand(
      vwtMinorPurchaseGame(
        fx,
        id: 'g1916pl1',
        overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
      ),
      fx.topology(),
      fx.provTarget,
    ),
    isNotEmpty,
  );
}

void _suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail() {
  final fx = vwtMinorPurchaseFx();
  expect(
    vwtSuggestPurchaseLand(
      vwtMinorPurchaseGame(fx, id: 'g1916pl2'),
      fx.topology(),
      fx.provTarget,
    ),
    isEmpty,
  );
}
