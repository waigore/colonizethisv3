// Scenario run tear-offs for order_suggestion_build_civilian_suggestion (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../engine/order_engine_validate_build_civilian_test_support.dart';

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

void osbcsRunIncludesAffordableWhenFlagTrue() {
  final game = buildCivilianValidationGame(treasury: 2000, paper: 2);
  final suggestions = _suggestCivilianBuildsWithFlag(
    game: game,
    includeCivilianBuilds: true,
  );
  final civilians = _civilianUnitTypes(suggestions);
  expect(
    civilians,
    containsAll(<String>[
      kUnitTypeBuilder,
      kUnitTypeEngineer,
      kUnitTypeExplorer,
    ]),
    reason:
        'Builder/Engineer/Explorer cost 1000 cash + 2 paper and are '
        'affordable with treasury 2000 + paper 2',
  );
}

void osbcsRunDeterministicallySortedByUnitType() {
  final game = buildCivilianValidationGame(treasury: 2000, paper: 2);
  final suggestions = _suggestCivilianBuildsWithFlag(
    game: game,
    includeCivilianBuilds: true,
  );
  final unitTypes = suggestions.map((o) => o.unitType).toList();
  final sorted = [...unitTypes]..sort();
  expect(unitTypes, sorted);
}

void osbcsRunDefaultOmitsCivilianCandidates() {
  final game = buildCivilianValidationGame(treasury: 2000, paper: 2);
  final defaulted = _suggestCivilianBuildsDefault(game: game);
  final explicitFalse = _suggestCivilianBuildsWithFlag(
    game: game,
    includeCivilianBuilds: false,
  );
  expect(_civilianUnitTypes(defaulted), isEmpty);
  expect(
    defaulted.map((o) => o.unitType).toList(),
    explicitFalse.map((o) => o.unitType).toList(),
  );
}

void osbcsRunMerchantExcludedWithoutTech() {
  final game = buildCivilianValidationGame(treasury: 3000, paper: 4);
  final suggestions = _suggestCivilianBuildsWithFlag(
    game: game,
    includeCivilianBuilds: true,
  );
  expect(_civilianUnitTypes(suggestions), isNot(contains(kUnitTypeMerchant)));
}

void osbcsRunMerchantIncludedWhenUnlocked() {
  final game = buildCivilianValidationGame(
    treasury: 3000,
    paper: 4,
    techUnlocked: const {kTechIdMerchantCompanies: true},
  );
  final suggestions = _suggestCivilianBuildsWithFlag(
    game: game,
    includeCivilianBuilds: true,
  );
  expect(_civilianUnitTypes(suggestions), contains(kUnitTypeMerchant));
}

void osbcsRunIdenticalInputsIdenticalEnumeration() {
  final game = buildCivilianValidationGame(treasury: 3000, paper: 4);
  final first = _suggestCivilianBuildsWithFlag(
    game: game,
    includeCivilianBuilds: true,
  );
  final second = _suggestCivilianBuildsWithFlag(
    game: game,
    includeCivilianBuilds: true,
  );
  expect(
    first.map((o) => o.unitType).toList(),
    second.map((o) => o.unitType).toList(),
  );
}

void osbcsRunNoCandidatesWhenTreasuryZero() {
  final game = buildCivilianValidationGame(treasury: 0, paper: 4);
  final suggestions = _suggestCivilianBuildsWithFlag(
    game: game,
    includeCivilianBuilds: true,
  );
  expect(_civilianUnitTypes(suggestions), isEmpty);
}

void osbcsRunNoCandidatesWhenPaperBelowMinimum() {
  final game = buildCivilianValidationGame(treasury: 5000, paper: 1);
  final suggestions = _suggestCivilianBuildsWithFlag(
    game: game,
    includeCivilianBuilds: true,
  );
  expect(_civilianUnitTypes(suggestions), isEmpty);
}
