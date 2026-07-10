// Table-driven own-province prospect tile-cap scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_prospect_own_province_tile_cap_fixtures.dart';

void ospoptcRunFeedstockPastProbeCap() {
  final game = prospectOwnProvinceTileCapGame();
  final topology = prospectOwnProvinceTileCapTopology(game);
  final view = buildPlayerView(
    game,
    topology,
    prospectOwnProvinceTileCapPlayerId,
  );
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
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

List<RunnableScenario>
orderSuggestionProspectOwnProvinceTileCapScenarios() => const [
  RunnableScenario(
    label:
        'co-located Explorer still prospects feedstock iron when it sorts after four other accepted mineral tiles in the same province',
    run: ospoptcRunFeedstockPastProbeCap,
  ),
];
