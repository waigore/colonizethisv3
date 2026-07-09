// Embassy-stage NW purchase_land colonial assertions (Refs #2509, #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_colonial_acquisition_fixtures.dart';
import 'order_suggestion_work_purchase_land_colonial_fixtures.dart';

/// Pins for [orderSuggestionWorkPurchaseLandColonialScenarios] rows.
enum OrderSuggestionWorkPurchaseLandColonialTarget {
  embassySurfacesPurchaseLand,
  deterministicAcrossRepeatedCalls,
  noEmbassyOmitsPurchaseLand,
}

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();

void runOrderSuggestionWorkPurchaseLandColonialExpectation(
  OrderSuggestionWorkPurchaseLandColonialTarget target,
) {
  switch (target) {
    case OrderSuggestionWorkPurchaseLandColonialTarget
        .embassySurfacesPurchaseLand:
      final game = purchaseLandColonialScenarioGame();
      final view = purchaseLandColonialViewFor(game);
      final orders = _api.suggestWorkOrders(
        view,
        game,
        colonialAcquisitionTopology,
        _emptyOrders,
      );
      final purchaseLandForMerchant = orders.where(
        (o) =>
            o.unitId == purchaseLandColonialMerchantId &&
            o.target == kWorkTargetPurchaseLand &&
            o.targetTileKey == purchaseLandColonialColonyTileKey,
      );
      expect(
        purchaseLandForMerchant,
        isNotEmpty,
        reason:
            'AC must-have #2: suggested orders must include a '
            '`purchase_land` WorkOrder toward the embassy-stage NW tribe '
            'tile when the validator preconditions (embassy + at peace + '
            'treasury + resource) all hold. Future tuning must not '
            'silently drop the candidate from the merchant suggestion '
            'pipeline.',
      );

    case OrderSuggestionWorkPurchaseLandColonialTarget
        .deterministicAcrossRepeatedCalls:
      final game = purchaseLandColonialScenarioGame();
      final view = purchaseLandColonialViewFor(game);

      List<String> orderKeys() => _api
          .suggestWorkOrders(
            view,
            game,
            colonialAcquisitionTopology,
            _emptyOrders,
          )
          .map(purchaseLandColonialWorkOrderKey)
          .toList();

      final first = orderKeys();
      final second = orderKeys();

      expect(
        second,
        equals(first),
        reason:
            'AC: deterministic for fixed seed — suggestWorkOrders must '
            'return the same candidate set across repeated calls on '
            'identical inputs (per the determinism pattern shared with '
            '`order_suggestion_colonial_acquisition_join_empire_or_war_test.dart`).',
      );
      expect(
        first,
        contains(
          '$purchaseLandColonialMerchantId:$kWorkTargetPurchaseLand:$purchaseLandColonialColonyTileKey',
        ),
        reason:
            'deterministic purchase_land candidate must appear in the '
            'logic suggestion API output for the embassy-stage scenario.',
      );

    case OrderSuggestionWorkPurchaseLandColonialTarget.noEmbassyOmitsPurchaseLand:
      final game = purchaseLandColonialScenarioGame(withEmbassy: false);
      final view = purchaseLandColonialViewFor(game);
      final orders = _api.suggestWorkOrders(
        view,
        game,
        colonialAcquisitionTopology,
        _emptyOrders,
      );
      final purchaseLandForMerchant = orders.where(
        (o) =>
            o.unitId == purchaseLandColonialMerchantId &&
            o.target == kWorkTargetPurchaseLand,
      );
      expect(
        purchaseLandForMerchant,
        isEmpty,
        reason:
            'Negative pin: without embassy, the candidate validator '
            '(`precheckPurchaseLand`) rejects the order, so '
            'suggestWorkOrders must not surface it. Confirms the embassy '
            'precondition is enforced at the suggestion layer (not only '
            'at order validation time).',
      );
  }
}
