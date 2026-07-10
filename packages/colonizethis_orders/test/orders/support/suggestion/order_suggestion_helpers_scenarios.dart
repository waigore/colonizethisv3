// Table-driven order suggestion helper scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_helpers.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

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

/// Scenarios for filterArmyMoveOrdersByDiplomacy.
List<RunnableScenario> filterArmyMoveOrdersByDiplomacyScenarios() => const [
  RunnableScenario(
    label: 'drops move into minor-owned province when relation row is absent',
    run: oshRunDropsMoveWhenRelationAbsent,
    refs: '#2394',
  ),
  RunnableScenario(
    label: 'keeps move into minor province when at war (relation row present)',
    run: oshRunKeepsMoveWhenAtWar,
    refs: '#2394',
  ),
  RunnableScenario(
    label: 'drops move into minor province when explicitly at peace',
    run: oshRunDropsMoveWhenAtPeace,
    refs: '#2394',
  ),
  RunnableScenario(
    label: 'keeps reordering-only move within own provinces',
    run: oshRunKeepsReorderWithinOwnProvinces,
    refs: '#2394',
  ),
  RunnableScenario(
    label: 'keeps move into minor at peace when draft orders declare war',
    run: oshRunKeepsMoveWhenDraftDeclaresWar,
    refs: '#2394',
  ),
];
