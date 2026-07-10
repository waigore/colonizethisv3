// Scenario run tear-offs for order_suggestion_work_feedstock_priority (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        feedstockBootstrapBuildImprovementCastIronWaived,
        feedstockExtractionResourceIdsForPlayer;
import 'package:colonizethis_test/test.dart';
import 'order_suggestion_work_feedstock_priority_fixtures.dart';

void oswfpRunSupplierGateActiveIronNotLexFirstGrain() {
  final game = feedstockPriorityGame();
  expect(
    feedstockExtractionResourceIdsForPlayer(game, feedstockPrioritySupplierId),
    contains('iron'),
  );
  final improvements = feedstockPriorityBuildImprovementSuggestions(game);
  expect(improvements, isNotEmpty);
  expect(
    improvements.map((o) => o.targetTileKey),
    contains(feedstockPrioritySupplierIronTile),
    reason:
        'feedstock-priority ordering must surface the iron tile as a '
        'build_improvement suggestion',
  );
  expect(improvements.single.targetTileKey, feedstockPrioritySupplierIronTile);
}

void oswfpRunSupplierGateInactivePeerAtQuotaLexGrain() {
  final game = feedstockPriorityGame(
    sellerOw: kObserverConquestMinOwProvincesPerGp,
    supplierCastIron: 10,
  );
  expect(
    feedstockExtractionResourceIdsForPlayer(game, feedstockPrioritySupplierId),
    isEmpty,
  );
  final improvements = feedstockPriorityBuildImprovementSuggestions(game);
  expect(improvements, isNotEmpty);
  expect(improvements.single.targetTileKey, feedstockPrioritySupplierGrainTile);
}

void oswfpRunSupplierLumberOnlyCastIronWaiver() {
  final game = feedstockPriorityGame();
  expect(
    feedstockBootstrapBuildImprovementCastIronWaived(
      game,
      feedstockPrioritySupplierId,
      feedstockPrioritySupplierIronTile,
    ),
    isTrue,
  );
  final improvements = feedstockPriorityBuildImprovementSuggestions(game);
  expect(improvements.single.targetTileKey, feedstockPrioritySupplierIronTile);
}

void oswfpRunSuggestionOrderingDeterministicRepeatedPasses() {
  final game = feedstockPriorityGame();
  final first = feedstockPriorityBuildImprovementSuggestions(
    game,
  ).map((o) => o.targetTileKey).toList();
  final second = feedstockPriorityBuildImprovementSuggestions(
    game,
  ).map((o) => o.targetTileKey).toList();
  expect(first, equals(second));
  expect(first.single, feedstockPrioritySupplierIronTile);
}

void oswfpRunCoAvailSupplierHoldsTimberNotIronLeastHeldIron() {
  final game = feedstockCoAvailGame(
    supplierTimberHeld: 13,
    supplierIronHeld: 0,
  );
  expect(
    feedstockExtractionResourceIdsForPlayer(game, feedstockPrioritySupplierId),
    containsAll(<String>['timber', 'iron']),
  );
  final improvements = feedstockPriorityBuildImprovementSuggestions(game);
  expect(improvements, isNotEmpty);
  expect(
    improvements.single.targetTileKey,
    feedstockCoAvailIronTile,
    reason:
        'co-availability ordering must surface the missing co-feedstock '
        '(iron) ahead of the already-held timber tile',
  );
}

void oswfpRunCoAvailEqualFeedstockLexTimberNegativeControl() {
  final game = feedstockCoAvailGame(supplierTimberHeld: 0, supplierIronHeld: 0);
  final improvements = feedstockPriorityBuildImprovementSuggestions(game);
  expect(improvements, isNotEmpty);
  expect(improvements.single.targetTileKey, feedstockCoAvailTimberTile);
}

void oswfpRunCoAvailOrderingDeterministicRepeatedPasses() {
  final game = feedstockCoAvailGame(
    supplierTimberHeld: 13,
    supplierIronHeld: 0,
  );
  final first = feedstockPriorityBuildImprovementSuggestions(
    game,
  ).map((o) => o.targetTileKey).toList();
  final second = feedstockPriorityBuildImprovementSuggestions(
    game,
  ).map((o) => o.targetTileKey).toList();
  expect(first, equals(second));
  expect(first.single, feedstockCoAvailIronTile);
}
