// Scenario run tear-offs for order_suggestion_naval_validator_reuse (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_naval_validator_reuse_fixtures.dart';

const _emptyOrders = Orders();

void osnvrRunMoveAndMissionReuseOneValidator() {
  final game = navalValidatorReuseScenarioGame();
  final view = navalValidatorReuseViewFor(game);

  final shared = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: navalValidatorReuseTopology,
    playerId: 'gp1',
    basePrefix: _emptyOrders,
    resolution: orderResolutionContextFromView(view, game),
  );

  resetIncrementalCandidateValidatorBuildCountForTests();
  suggestNavalMoveOrders(
    view,
    game,
    navalValidatorReuseTopology,
    _emptyOrders,
    sharedCandidateValidator: shared,
  );
  suggestNavalMissionOrders(
    view,
    game,
    navalValidatorReuseTopology,
    _emptyOrders,
    sharedCandidateValidator: shared,
  );

  expect(
    incrementalCandidateValidatorBuildCountForTests,
    0,
    reason:
        'both naval families must reuse the supplied pass validator '
        '(Refs #2394)',
  );
}
