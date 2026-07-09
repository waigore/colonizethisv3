// Compact diplomatic boycott suggestion assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_diplomatic_boycott_fixtures.dart';

/// Pins for [orderSuggestionDiplomaticBoycottScenarios] rows.
enum OrderSuggestionDiplomaticBoycottTarget {
  emitsBoycottTowardGpAtPeaceWhenIssuerHoldsColony,
  boycottCoexistsWithSingleNonEconomicCandidateForSameGp,
  doesNotEmitBoycottWhenIssuerHoldsNoColony,
  doesNotEmitDuplicateBoycottWhenOneAlreadyExists,
  doesNotEmitBoycottTowardMinorTribeTarget,
  doesNotEmitBoycottWhenAtWarWithTargetGp,
}

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

void runOrderSuggestionDiplomaticBoycottExpectation(
  OrderSuggestionDiplomaticBoycottTarget target,
) {
  switch (target) {
    case OrderSuggestionDiplomaticBoycottTarget
        .emitsBoycottTowardGpAtPeaceWhenIssuerHoldsColony:
      final game = orderSuggestionDiplomaticBoycottTwoGpGame();
      final list = _suggestBoycottOrders(game);
      final boycotts = list.where(
        (o) =>
            o.type == DiplomaticOrderType.boycott && o.targetFactionId == 'gp2',
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

    case OrderSuggestionDiplomaticBoycottTarget
        .boycottCoexistsWithSingleNonEconomicCandidateForSameGp:
      final game = orderSuggestionDiplomaticBoycottTwoGpGame();
      final list = _suggestBoycottOrders(game);
      final toGp2 = list
          .where((o) => o.targetFactionId == 'gp2')
          .map((o) => o.type)
          .toSet();
      expect(toGp2, contains(DiplomaticOrderType.alliance));
      expect(toGp2, contains(DiplomaticOrderType.boycott));

    case OrderSuggestionDiplomaticBoycottTarget
        .doesNotEmitBoycottWhenIssuerHoldsNoColony:
      final game = orderSuggestionDiplomaticBoycottTwoGpGame(holdsColony: false);
      final list = _suggestBoycottOrders(game);
      expect(list.where((o) => o.type == DiplomaticOrderType.boycott), isEmpty);

    case OrderSuggestionDiplomaticBoycottTarget
        .doesNotEmitDuplicateBoycottWhenOneAlreadyExists:
      final game = orderSuggestionDiplomaticBoycottTwoGpGame(
        boycotts: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 1),
        ],
      );
      final list = _suggestBoycottOrders(game);
      expect(list.where((o) => o.type == DiplomaticOrderType.boycott), isEmpty);

    case OrderSuggestionDiplomaticBoycottTarget
        .doesNotEmitBoycottTowardMinorTribeTarget:
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

    case OrderSuggestionDiplomaticBoycottTarget
        .doesNotEmitBoycottWhenAtWarWithTargetGp:
      final game = orderSuggestionDiplomaticBoycottTwoGpGame(
        state: RelationState.atWar,
        level: RelationLevel.hostile,
      );
      final list = _suggestBoycottOrders(game);
      expect(list.where((o) => o.type == DiplomaticOrderType.boycott), isEmpty);
  }
}
