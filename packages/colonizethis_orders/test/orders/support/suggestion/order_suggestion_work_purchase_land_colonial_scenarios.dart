// Table-driven embassy-stage NW purchase_land colonial scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_colonial_acquisition_fixtures.dart';
import 'order_suggestion_work_purchase_land_colonial_fixtures.dart';

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();

void oswplcRunEmbassySurfacesPurchaseLand() {
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
}

void oswplcRunDeterministicAcrossRepeatedCalls() {
  final game = purchaseLandColonialScenarioGame();
  final view = purchaseLandColonialViewFor(game);

  List<String> orderKeys() => _api
      .suggestWorkOrders(view, game, colonialAcquisitionTopology, _emptyOrders)
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
}

void oswplcRunNoEmbassyOmitsPurchaseLand() {
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

List<RunnableScenario>
orderSuggestionWorkPurchaseLandColonialScenarios() => const [
  rs('embassy-stage NW tribe: suggestWorkOrders surfaces purchase_land for Merchant', oswplcRunEmbassySurfacesPurchaseLand, '#2509'),
  rs('embassy-stage NW tribe: suggestWorkOrders is deterministic for repeated calls', oswplcRunDeterministicAcrossRepeatedCalls, '#2509'),
  rs('no embassy with NW tribe: suggestWorkOrders omits purchase_land for Merchant', oswplcRunNoEmbassyOmitsPurchaseLand, '#2509'),
];
