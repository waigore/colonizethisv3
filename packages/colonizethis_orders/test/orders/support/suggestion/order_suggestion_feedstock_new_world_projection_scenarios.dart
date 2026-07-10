// Table-driven feedstock new-world projection scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/ai_api.dart'
    show feedstockExtractionResourceIdsForPlayer;
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_feedstock_new_world_projection_fixtures.dart';
// dart format off

void osfnwpRunSellerNwDeactivatesGate() {expect(feedstockExtractionResourceIdsForPlayer(feedstockNwProjectionGame(),feedstockNwProjectionSupplierId,),contains('iron'),); final game = feedstockNwProjectionGame(sellerNw: 1); expect(feedstockExtractionResourceIdsForPlayer(game,feedstockNwProjectionSupplierId,),isEmpty,reason: 'a below-quota seller owning a New World province is no longer a ' 'zero-NW lock-recovery seller, so the peer-supplier gate must empty',);}

List<RunnableScenario>
orderSuggestionFeedstockNewWorldProjectionScenarios() => [
  rs('seller owning a New World province deactivates the feedstock gate (projection-backed new-world count, Refs #3393)', osfnwpRunSellerNwDeactivatesGate),
];
