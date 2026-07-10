// Compact civilian build suggestion assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../engine/order_engine_validate_build_civilian_test_support.dart';

/// Pins for [suggestBuildOrdersCivilianEnumerationScenarios] rows.
enum OrderSuggestionBuildCivilianSuggestionTarget {
  includesAffordableWhenFlagTrue,
  deterministicallySortedByUnitType,
  defaultOmitsCivilianCandidates,
  merchantExcludedWithoutTech,
  merchantIncludedWhenUnlocked,
  identicalInputsIdenticalEnumeration,
  noCandidatesWhenTreasuryZero,
  noCandidatesWhenPaperBelowMinimum,
}

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
  return suggestBuildOrders(
    view,
    game,
    buildCivilianTopology,
    const Orders(),
  );
}

void runOrderSuggestionBuildCivilianSuggestionExpectation(
  OrderSuggestionBuildCivilianSuggestionTarget target,
) {
  switch (target) {
    case OrderSuggestionBuildCivilianSuggestionTarget.includesAffordableWhenFlagTrue:
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

    case OrderSuggestionBuildCivilianSuggestionTarget
        .deterministicallySortedByUnitType:
      final game = buildCivilianValidationGame(treasury: 2000, paper: 2);
      final suggestions = _suggestCivilianBuildsWithFlag(
        game: game,
        includeCivilianBuilds: true,
      );
      final unitTypes = suggestions.map((o) => o.unitType).toList();
      final sorted = [...unitTypes]..sort();
      expect(unitTypes, sorted);

    case OrderSuggestionBuildCivilianSuggestionTarget
        .defaultOmitsCivilianCandidates:
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

    case OrderSuggestionBuildCivilianSuggestionTarget.merchantExcludedWithoutTech:
      final game = buildCivilianValidationGame(treasury: 3000, paper: 4);
      final suggestions = _suggestCivilianBuildsWithFlag(
        game: game,
        includeCivilianBuilds: true,
      );
      expect(_civilianUnitTypes(suggestions), isNot(contains(kUnitTypeMerchant)));

    case OrderSuggestionBuildCivilianSuggestionTarget.merchantIncludedWhenUnlocked:
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

    case OrderSuggestionBuildCivilianSuggestionTarget
        .identicalInputsIdenticalEnumeration:
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

    case OrderSuggestionBuildCivilianSuggestionTarget.noCandidatesWhenTreasuryZero:
      final game = buildCivilianValidationGame(treasury: 0, paper: 4);
      final suggestions = _suggestCivilianBuildsWithFlag(
        game: game,
        includeCivilianBuilds: true,
      );
      expect(_civilianUnitTypes(suggestions), isEmpty);

    case OrderSuggestionBuildCivilianSuggestionTarget
        .noCandidatesWhenPaperBelowMinimum:
      final game = buildCivilianValidationGame(treasury: 5000, paper: 1);
      final suggestions = _suggestCivilianBuildsWithFlag(
        game: game,
        includeCivilianBuilds: true,
      );
      expect(_civilianUnitTypes(suggestions), isEmpty);
  }
}
