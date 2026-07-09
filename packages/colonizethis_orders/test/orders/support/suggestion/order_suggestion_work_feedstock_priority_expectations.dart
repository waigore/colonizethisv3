// Compact feedstock-priority build_improvement suggestion assertions (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        feedstockBootstrapBuildImprovementCastIronWaived,
        feedstockExtractionResourceIdsForPlayer;
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_work_feedstock_priority_fixtures.dart';

/// Pins for [orderSuggestionWorkFeedstockPriorityScenarios] rows.
enum OrderSuggestionWorkFeedstockPriorityTarget {
  supplierGateActiveIronNotLexFirstGrain,
  supplierGateInactivePeerAtQuotaLexGrain,
  supplierLumberOnlyCastIronWaiver,
  suggestionOrderingDeterministicRepeatedPasses,
  coAvailSupplierHoldsTimberNotIronLeastHeldIron,
  coAvailEqualFeedstockLexTimberNegativeControl,
  coAvailOrderingDeterministicRepeatedPasses,
}

void runOrderSuggestionWorkFeedstockPriorityExpectation(
  OrderSuggestionWorkFeedstockPriorityTarget target,
) {
  switch (target) {
    case OrderSuggestionWorkFeedstockPriorityTarget
        .supplierGateActiveIronNotLexFirstGrain:
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

    case OrderSuggestionWorkFeedstockPriorityTarget
        .supplierGateInactivePeerAtQuotaLexGrain:
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

    case OrderSuggestionWorkFeedstockPriorityTarget
        .supplierLumberOnlyCastIronWaiver:
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

    case OrderSuggestionWorkFeedstockPriorityTarget
        .suggestionOrderingDeterministicRepeatedPasses:
      final game = feedstockPriorityGame();
      final first = feedstockPriorityBuildImprovementSuggestions(game)
          .map((o) => o.targetTileKey)
          .toList();
      final second = feedstockPriorityBuildImprovementSuggestions(game)
          .map((o) => o.targetTileKey)
          .toList();
      expect(first, equals(second));
      expect(first.single, feedstockPrioritySupplierIronTile);

    case OrderSuggestionWorkFeedstockPriorityTarget
        .coAvailSupplierHoldsTimberNotIronLeastHeldIron:
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

    case OrderSuggestionWorkFeedstockPriorityTarget
        .coAvailEqualFeedstockLexTimberNegativeControl:
      final game = feedstockCoAvailGame(
        supplierTimberHeld: 0,
        supplierIronHeld: 0,
      );
      final improvements = feedstockPriorityBuildImprovementSuggestions(game);
      expect(improvements, isNotEmpty);
      expect(improvements.single.targetTileKey, feedstockCoAvailTimberTile);

    case OrderSuggestionWorkFeedstockPriorityTarget
        .coAvailOrderingDeterministicRepeatedPasses:
      final game = feedstockCoAvailGame(
        supplierTimberHeld: 13,
        supplierIronHeld: 0,
      );
      final first = feedstockPriorityBuildImprovementSuggestions(game)
          .map((o) => o.targetTileKey)
          .toList();
      final second = feedstockPriorityBuildImprovementSuggestions(game)
          .map((o) => o.targetTileKey)
          .toList();
      expect(first, equals(second));
      expect(first.single, feedstockCoAvailIronTile);
  }
}
