// Diplomatic appendability assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_api_impl_diplomatic_appendability_fixtures.dart';

/// Pins for [orderSuggestionApiImplDiplomaticAppendabilityScenarios] rows.
enum OrderSuggestionApiImplDiplomaticAppendabilityTarget {
  excludesTargetAlreadyInDraft,
  cumulativeListAppendableAndValidates,
  removingPendingRestoresSuggestions,
}

const _api = DefaultOrderSuggestionAPI();
const _gp1 = 'gp1';

void runOrderSuggestionApiImplDiplomaticAppendabilityExpectation(
  OrderSuggestionApiImplDiplomaticAppendabilityTarget target,
) {
  switch (target) {
    case OrderSuggestionApiImplDiplomaticAppendabilityTarget
        .excludesTargetAlreadyInDraft:
      final game = diplomaticAppendabilityTwoGpNeutralGame();
      final view = buildPlayerView(game, diplomaticAppendabilityEmptyTopology, _gp1);
      final withPending = Orders(
        diplomaticOrdersByPlayerId: {
          _gp1: [
            const DiplomaticOrder(
              type: DiplomaticOrderType.alliance,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final list = _api.suggestDiplomaticOrders(
        view,
        game,
        diplomaticAppendabilityEmptyTopology,
        withPending,
      );
      expect(list.where((o) => o.targetFactionId == 'gp2'), isEmpty);

    case OrderSuggestionApiImplDiplomaticAppendabilityTarget
        .cumulativeListAppendableAndValidates:
      final game = diplomaticAppendabilityTwoGpAlliedGame();
      final view = buildPlayerView(game, diplomaticAppendabilityEmptyTopology, _gp1);
      final suggestions = _api.suggestDiplomaticOrders(
        view,
        game,
        diplomaticAppendabilityEmptyTopology,
        const Orders(),
      );
      final byTarget = <String, List<DiplomaticOrderType>>{};
      for (final o in suggestions) {
        byTarget.putIfAbsent(o.targetFactionId, () => []).add(o.type);
      }
      for (final e in byTarget.entries) {
        final types = e.value;
        expect(
          types.toSet().length,
          types.length,
          reason: 'at most one suggestion per type per target ${e.key}',
        );
        final nonEconomic = types
            .where(
              (t) =>
                  t != DiplomaticOrderType.grantAid &&
                  t != DiplomaticOrderType.setSubsidy,
            )
            .length;
        expect(
          nonEconomic,
          lessThanOrEqualTo(1),
          reason:
              'at most one primary diplomatic suggestion per target ${e.key}',
        );
      }
      final eng = OrderEngine();
      for (final o in suggestions) {
        final addResult = eng.addDiplomaticOrderWithContext(
          game,
          diplomaticAppendabilityEmptyTopology,
          _gp1,
          o,
        );
        expect(
          addResult.isAccepted,
          isTrue,
          reason: '${o.type} ${o.targetFactionId} after prior suggestions',
        );
      }
      final validateResults = eng.validatePlayerOrdersWithContext(
        game,
        diplomaticAppendabilityEmptyTopology,
        _gp1,
      );
      expect(validateResults, isNotEmpty);
      expect(
        validateResults.every((r) => r.isAccepted),
        isTrue,
        reason: 'full merged diplomatic list validates',
      );

    case OrderSuggestionApiImplDiplomaticAppendabilityTarget
        .removingPendingRestoresSuggestions:
      final game = diplomaticAppendabilityTwoGpNeutralGame();
      final view = buildPlayerView(game, diplomaticAppendabilityEmptyTopology, _gp1);
      final pending = Orders(
        diplomaticOrdersByPlayerId: {
          _gp1: [
            const DiplomaticOrder(
              type: DiplomaticOrderType.alliance,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      expect(
        _api
            .suggestDiplomaticOrders(
              view,
              game,
              diplomaticAppendabilityEmptyTopology,
              pending,
            )
            .where((o) => o.targetFactionId == 'gp2'),
        isEmpty,
      );
      final afterClear = _api.suggestDiplomaticOrders(
        view,
        game,
        diplomaticAppendabilityEmptyTopology,
        const Orders(),
      );
      expect(afterClear.where((o) => o.targetFactionId == 'gp2'), isNotEmpty);
  }
}
