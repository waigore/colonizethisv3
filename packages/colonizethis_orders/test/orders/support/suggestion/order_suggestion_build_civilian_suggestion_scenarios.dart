// Table-driven civilian build suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../engine/order_engine_validate_build_civilian_test_support.dart';
import '../scenario_runner.dart';

List<String> _civilianUnitTypes(List<BuildUnitOrder> orders) => orders
    .where((o) => CivilianEconomyCatalog.byId.containsKey(o.unitType))
    .map((o) => o.unitType)
    .toList();

List<BuildUnitOrder> _suggestCivilianBuildsWithFlag({
  required Game game,
  required bool includeCivilianBuilds,
}) {
  final view = buildPlayerView(game, buildCivilianTopology, 'p1');
  return suggestBuildOrders(
    view,
    game,
    buildCivilianTopology,
    const Orders(),
    includeCivilianBuilds: includeCivilianBuilds,
  );
}

List<BuildUnitOrder> _suggestCivilianBuildsDefault({required Game game}) {
  final view = buildPlayerView(game, buildCivilianTopology, 'p1');
  return suggestBuildOrders(view, game, buildCivilianTopology, const Orders());
}
// dart format off

void osbcsRunIncludesAffordableWhenFlagTrue() {final game = buildCivilianValidationGame(treasury: 2000,paper: 2); final suggestions = _suggestCivilianBuildsWithFlag(game: game,includeCivilianBuilds: true,); final civilians = _civilianUnitTypes(suggestions); expect(civilians,containsAll(<String>[kUnitTypeBuilder,kUnitTypeEngineer,kUnitTypeExplorer,]),reason: 'Builder/Engineer/Explorer cost 1000 cash + 2 paper and are ' 'affordable with treasury 2000 + paper 2',);}

void osbcsRunDeterministicallySortedByUnitType() {final game = buildCivilianValidationGame(treasury: 2000,paper: 2); final suggestions = _suggestCivilianBuildsWithFlag(game: game,includeCivilianBuilds: true,); final unitTypes = suggestions.map((o) => o.unitType).toList(); final sorted = [...unitTypes]..sort(); expect(unitTypes,sorted);}

void osbcsRunDefaultOmitsCivilianCandidates() {final game = buildCivilianValidationGame(treasury: 2000,paper: 2); final defaulted = _suggestCivilianBuildsDefault(game: game); final explicitFalse = _suggestCivilianBuildsWithFlag(game: game,includeCivilianBuilds: false,); expect(_civilianUnitTypes(defaulted),isEmpty); expect(defaulted.map((o) => o.unitType).toList(),explicitFalse.map((o) => o.unitType).toList(),);}

void osbcsRunMerchantExcludedWithoutTech() {final game = buildCivilianValidationGame(treasury: 3000,paper: 4); final suggestions = _suggestCivilianBuildsWithFlag(game: game,includeCivilianBuilds: true,); expect(_civilianUnitTypes(suggestions),isNot(contains(kUnitTypeMerchant)));}

void osbcsRunMerchantIncludedWhenUnlocked() {final game = buildCivilianValidationGame(treasury: 3000,paper: 4,techUnlocked: const {kTechIdMerchantCompanies: true},); final suggestions = _suggestCivilianBuildsWithFlag(game: game,includeCivilianBuilds: true,); expect(_civilianUnitTypes(suggestions),contains(kUnitTypeMerchant));}

void osbcsRunIdenticalInputsIdenticalEnumeration() {final game = buildCivilianValidationGame(treasury: 3000,paper: 4); final first = _suggestCivilianBuildsWithFlag(game: game,includeCivilianBuilds: true,); final second = _suggestCivilianBuildsWithFlag(game: game,includeCivilianBuilds: true,); expect(first.map((o) => o.unitType).toList(),second.map((o) => o.unitType).toList(),);}

void osbcsRunNoCandidatesWhenTreasuryZero() {final game = buildCivilianValidationGame(treasury: 0,paper: 4); final suggestions = _suggestCivilianBuildsWithFlag(game: game,includeCivilianBuilds: true,); expect(_civilianUnitTypes(suggestions),isEmpty);}

void osbcsRunNoCandidatesWhenPaperBelowMinimum() {final game = buildCivilianValidationGame(treasury: 5000,paper: 1); final suggestions = _suggestCivilianBuildsWithFlag(game: game,includeCivilianBuilds: true,); expect(_civilianUnitTypes(suggestions),isEmpty);}

/// Scenarios for suggestBuildOrders civilian enumeration (Refs #3793).
List<RunnableScenario>
suggestBuildOrdersCivilianEnumerationScenarios() => [
  rs('AC1: includes affordable civilian candidates when includeCivilianBuilds is true', osbcsRunIncludesAffordableWhenFlagTrue, '#3793'),
  rs('AC1: emitted civilian candidates are deterministically sorted by unitType', osbcsRunDeterministicallySortedByUnitType, '#3793'),
  rs('AC1b: default (flag omitted) emits no civilian candidates and equals the explicit false call', osbcsRunDefaultOmitsCivilianCandidates, '#3793'),
  rs('AC5: Merchant excluded when merchant_companies is not unlocked', osbcsRunMerchantExcludedWithoutTech, '#3793'),
  rs('AC5: Merchant included when merchant_companies is unlocked and affordable', osbcsRunMerchantIncludedWhenUnlocked, '#3793'),
  rs('AC9: identical inputs produce identical civilian enumeration', osbcsRunIdenticalInputsIdenticalEnumeration, '#3793'),
  rs('AC12: no civilian candidates when treasury is zero', osbcsRunNoCandidatesWhenTreasuryZero, '#3793'),
  rs('AC12: no civilian candidates when paper is below the minimum cost', osbcsRunNoCandidatesWhenPaperBelowMinimum, '#3793'),
];
