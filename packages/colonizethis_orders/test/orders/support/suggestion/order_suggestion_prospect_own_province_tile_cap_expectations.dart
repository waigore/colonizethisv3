// Own-province prospect tile-cap assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_prospect_own_province_tile_cap_fixtures.dart';

enum OrderSuggestionProspectOwnProvinceTileCapTarget {
  feedstockPastProbeCap,
}

void runOrderSuggestionProspectOwnProvinceTileCapExpectation(
  OrderSuggestionProspectOwnProvinceTileCapTarget target,
) {
  switch (target) {
    case OrderSuggestionProspectOwnProvinceTileCapTarget.feedstockPastProbeCap:
      final game = prospectOwnProvinceTileCapGame();
      final topology = prospectOwnProvinceTileCapTopology(game);
      final view = buildPlayerView(
        game,
        topology,
        prospectOwnProvinceTileCapPlayerId,
      );
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final feedstockProspects = suggestions
          .where(
            (o) =>
                o.unitId == 'e1' &&
                o.target == kWorkTargetProspect &&
                o.targetTileKey == prospectOwnProvinceTileCapFeedstockTileKey,
          )
          .toList();
      expect(feedstockProspects, isNotEmpty);
  }
}
