// Compact order suggestion helper assertions (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_helpers.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_helpers_fixtures.dart';

/// Pins for [filterArmyMoveOrdersByDiplomacyScenarios] rows.
enum OrderSuggestionHelpersTarget {
  dropsMoveWhenRelationAbsent,
  keepsMoveWhenAtWar,
  dropsMoveWhenAtPeace,
  keepsReorderWithinOwnProvinces,
  keepsMoveWhenDraftDeclaresWar,
}

void runOrderSuggestionHelpersExpectation(OrderSuggestionHelpersTarget target) {
  switch (target) {
    case OrderSuggestionHelpersTarget.dropsMoveWhenRelationAbsent:
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

    case OrderSuggestionHelpersTarget.keepsMoveWhenAtWar:
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

    case OrderSuggestionHelpersTarget.dropsMoveWhenAtPeace:
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

    case OrderSuggestionHelpersTarget.keepsReorderWithinOwnProvinces:
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

    case OrderSuggestionHelpersTarget.keepsMoveWhenDraftDeclaresWar:
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
}
