// Scenario run tear-offs for order_suggestion_api_impl_diplomatic_minor (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_api_impl_diplomatic_minor_fixtures.dart';

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();

List<DiplomaticOrder> _suggestFor(Game game) => _api.suggestDiplomaticOrders(
  diplomaticMinorApiImplViewFor(game),
  game,
  diplomaticMinorApiImplTopology,
  _emptyOrders,
);

void osaidmRunDoesNotSuggestForCompletelyUnknownFactions() {
  final list = _suggestFor(diplomaticMinorApiImplUnknownFactionGame());
  expect(list.any((o) => o.targetFactionId == 'minor1'), isFalse);
}

void osaidmRunReturnsEstablishOvertureWhenTreasurySuffices() {
  final list = _suggestFor(diplomaticMinorApiImplEstablishOvertureGame());
  final overture = list
      .where((o) => o.type == DiplomaticOrderType.establishOverture)
      .toList();
  expect(overture.any((o) => o.targetFactionId == 'minor1'), isTrue);
  expect(
    overture.any(
      (o) =>
          o.targetFactionId == 'minor1' &&
          o.overtureStage == OvertureStage.tradeConsulate,
    ),
    isTrue,
  );
}

void osaidmRunDoesNotSuggestAdvancedOvertureWithoutDiplomaticExpertise() {
  final list = _suggestFor(diplomaticMinorApiImplNoDiplomaticExpertiseGame());
  final overture = list
      .where((o) => o.type == DiplomaticOrderType.establishOverture)
      .where((o) => o.targetFactionId == 'minor1')
      .toList();
  expect(
    overture.any(
      (o) =>
          o.overtureStage == OvertureStage.tradeConsulate ||
          o.overtureStage == OvertureStage.embassy ||
          o.overtureStage == OvertureStage.nap,
    ),
    isFalse,
  );
}

void osaidmRunJoinEmpireOvertureSuggestsDeclareWar() {
  final list = _suggestFor(diplomaticMinorApiImplJoinEmpireDeclareWarGame());
  final toMinor1 = list.where((o) => o.targetFactionId == 'minor1').toList();
  expect(toMinor1, hasLength(1));
  expect(toMinor1.single.type, DiplomaticOrderType.declareWar);
}
