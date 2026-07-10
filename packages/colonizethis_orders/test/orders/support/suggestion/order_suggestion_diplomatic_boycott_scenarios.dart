// Table-driven diplomatic boycott suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_diplomatic_boycott_fixtures.dart';

const _api = DefaultOrderSuggestionAPI();

List<DiplomaticOrder> _suggestBoycottOrders(Game game) {
  final view = buildPlayerView(
    game,
    orderSuggestionDiplomaticBoycottEmptyTopology,
    'gp1',
  );
  return _api.suggestDiplomaticOrders(
    view,
    game,
    orderSuggestionDiplomaticBoycottEmptyTopology,
    const Orders(),
  );
}

void osdbRunEmitsBoycottTowardGpAtPeaceWhenIssuerHoldsColony() {
  final game = orderSuggestionDiplomaticBoycottTwoGpGame();
  final list = _suggestBoycottOrders(game);
  final boycotts = list.where(
    (o) => o.type == DiplomaticOrderType.boycott && o.targetFactionId == 'gp2',
  );
  expect(boycotts, hasLength(1));
  final eng = OrderEngine();
  expect(
    eng
        .addDiplomaticOrderWithContext(
          game,
          orderSuggestionDiplomaticBoycottEmptyTopology,
          'gp1',
          boycotts.single,
        )
        .isAccepted,
    isTrue,
  );
}

void osdbRunBoycottCoexistsWithSingleNonEconomicCandidateForSameGp() {
  final game = orderSuggestionDiplomaticBoycottTwoGpGame();
  final list = _suggestBoycottOrders(game);
  final toGp2 = list
      .where((o) => o.targetFactionId == 'gp2')
      .map((o) => o.type)
      .toSet();
  expect(toGp2, contains(DiplomaticOrderType.alliance));
  expect(toGp2, contains(DiplomaticOrderType.boycott));
}

void osdbRunDoesNotEmitBoycottWhenIssuerHoldsNoColony() {
  final game = orderSuggestionDiplomaticBoycottTwoGpGame(holdsColony: false);
  final list = _suggestBoycottOrders(game);
  expect(list.where((o) => o.type == DiplomaticOrderType.boycott), isEmpty);
}

void osdbRunDoesNotEmitDuplicateBoycottWhenOneAlreadyExists() {
  final game = orderSuggestionDiplomaticBoycottTwoGpGame(
    boycotts: const [
      BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 1),
    ],
  );
  final list = _suggestBoycottOrders(game);
  expect(list.where((o) => o.type == DiplomaticOrderType.boycott), isEmpty);
}

void osdbRunDoesNotEmitBoycottTowardMinorTribeTarget() {
  final game = orderSuggestionDiplomaticBoycottTwoGpGame(
    minors: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
  );
  final list = _suggestBoycottOrders(game);
  expect(
    list.where(
      (o) =>
          o.type == DiplomaticOrderType.boycott &&
          o.targetFactionId == 'minor1',
    ),
    isEmpty,
  );
}

void osdbRunDoesNotEmitBoycottWhenAtWarWithTargetGp() {
  final game = orderSuggestionDiplomaticBoycottTwoGpGame(
    state: RelationState.atWar,
    level: RelationLevel.hostile,
  );
  final list = _suggestBoycottOrders(game);
  expect(list.where((o) => o.type == DiplomaticOrderType.boycott), isEmpty);
}

List<RunnableScenario>
suggestDiplomaticOrdersBoycottCandidateScenarios() => const [
  RunnableScenario(
    label:
        'emits a boycott toward another GP at peace when the issuer holds a colony',
    run: osdbRunEmitsBoycottTowardGpAtPeaceWhenIssuerHoldsColony,
    refs: '#3758 R8',
  ),
  RunnableScenario(
    label:
        'boycott coexists with the single non-economic candidate for the same GP',
    run: osdbRunBoycottCoexistsWithSingleNonEconomicCandidateForSameGp,
    refs: '#3758 R8',
  ),
  RunnableScenario(
    label: 'does not emit a boycott when the issuer holds no colony',
    run: osdbRunDoesNotEmitBoycottWhenIssuerHoldsNoColony,
    refs: '#3758 R8',
  ),
  RunnableScenario(
    label: 'does not emit a duplicate boycott when one already exists',
    run: osdbRunDoesNotEmitDuplicateBoycottWhenOneAlreadyExists,
    refs: '#3758 R8',
  ),
  RunnableScenario(
    label: 'does not emit a boycott toward a Minor/Tribe target',
    run: osdbRunDoesNotEmitBoycottTowardMinorTribeTarget,
    refs: '#3758 R8',
  ),
  RunnableScenario(
    label: 'does not emit a boycott when at war with the target GP',
    run: osdbRunDoesNotEmitBoycottWhenAtWarWithTargetGp,
    refs: '#3758 R8',
  ),
];
