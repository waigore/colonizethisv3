// Scenario run tear-offs for order_suggestion_helpers (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_helpers.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_helpers_fixtures.dart';

void oshRunDropsMoveWhenRelationAbsent() {
  final game = orderSuggestionHelpersGameWithMinorProvince(
    diplomacyRelations: const [],
  );
  const orders = [
    ArmyMoveOrder(
      armyId: 'a1',
      destinationProvinceId: '$orderSuggestionHelpersOw|P_minor',
    ),
  ];
  final out = filterArmyMoveOrdersByDiplomacy(
    game,
    orderSuggestionHelpersGpId,
    orders,
  );
  expect(out, isEmpty);
}

void oshRunKeepsMoveWhenAtWar() {
  final game = orderSuggestionHelpersGameWithMinorProvince(
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: orderSuggestionHelpersGpId,
        factionId2: orderSuggestionHelpersMinorId,
        state: RelationState.atWar,
      ),
    ],
  );
  const orders = [
    ArmyMoveOrder(
      armyId: 'a1',
      destinationProvinceId: '$orderSuggestionHelpersOw|P_minor',
    ),
  ];
  final out = filterArmyMoveOrdersByDiplomacy(
    game,
    orderSuggestionHelpersGpId,
    orders,
  );
  expect(out, orders);
}

void oshRunDropsMoveWhenAtPeace() {
  final game = orderSuggestionHelpersGameWithMinorProvince(
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: orderSuggestionHelpersGpId,
        factionId2: orderSuggestionHelpersMinorId,
        state: RelationState.atPeace,
      ),
    ],
  );
  const orders = [
    ArmyMoveOrder(
      armyId: 'a1',
      destinationProvinceId: '$orderSuggestionHelpersOw|P_minor',
    ),
  ];
  final out = filterArmyMoveOrdersByDiplomacy(
    game,
    orderSuggestionHelpersGpId,
    orders,
  );
  expect(out, isEmpty);
}

void oshRunKeepsReorderWithinOwnProvinces() {
  final game = orderSuggestionHelpersGameWithMinorProvince(
    diplomacyRelations: const [],
  );
  const orders = [
    ArmyMoveOrder(
      armyId: 'a1',
      destinationProvinceId: '$orderSuggestionHelpersOw|P_gp',
    ),
  ];
  final out = filterArmyMoveOrdersByDiplomacy(
    game,
    orderSuggestionHelpersGpId,
    orders,
  );
  expect(out, orders);
}

void oshRunKeepsMoveWhenDraftDeclaresWar() {
  final game = orderSuggestionHelpersGameWithMinorProvince(
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: orderSuggestionHelpersGpId,
        factionId2: orderSuggestionHelpersMinorId,
        state: RelationState.atPeace,
      ),
    ],
  );
  const armyOrders = [
    ArmyMoveOrder(
      armyId: 'a1',
      destinationProvinceId: '$orderSuggestionHelpersOw|P_minor',
    ),
  ];
  final draftOrders = Orders(
    diplomaticOrdersByPlayerId: {
      orderSuggestionHelpersGpId: [
        DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: orderSuggestionHelpersMinorId,
        ),
      ],
    },
  );
  final out = filterArmyMoveOrdersByDiplomacy(
    game,
    orderSuggestionHelpersGpId,
    armyOrders,
    draftOrders: draftOrders,
  );
  expect(out, armyOrders);
}
