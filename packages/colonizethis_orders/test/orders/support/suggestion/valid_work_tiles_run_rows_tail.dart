// Scenario run tear-offs for valid work tiles family (Refs #3949 wave 3).
import 'valid_work_tiles_expectation_shorthand.dart';
import 'valid_work_tiles_fixtures.dart';
import 'valid_work_tiles_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void
vwtRunSuggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral() {
  final ironFx = NwPartialRevealHomeTarget.tribeGrainIron(prospectedIron: true);
  vwtExpectPartialRevealSuggestions(
    fx: ironFx,
    game: ironFx.tribeConsulateGame('g1916p2'),
    workTarget: kWorkTargetProspect,
    expectNonEmpty: false,
  );
}

void
vwtRunSuggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy() {
  final purchaseFx = NwPartialRevealHomeTarget.minorPurchase();
  vwtExpectPartialRevealSuggestions(
    fx: purchaseFx,
    game: purchaseFx.minorPurchaseGame(
      'g1916pl1',
      overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
    ),
    workTarget: kWorkTargetPurchaseLand,
    expectNonEmpty: true,
    provinceId: purchaseFx.provTarget,
  );
}

void
vwtRunSuggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail() {
  final failPurchaseFx = NwPartialRevealHomeTarget.minorPurchase();
  vwtExpectPartialRevealSuggestions(
    fx: failPurchaseFx,
    game: failPurchaseFx.minorPurchaseGame('g1916pl2'),
    workTarget: kWorkTargetPurchaseLand,
    expectNonEmpty: false,
    provinceId: failPurchaseFx.provTarget,
  );
}
