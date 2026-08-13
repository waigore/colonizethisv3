// Labour / chrome helpers for ProductionPanel part2 (Refs #4352).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';
import 'package:flutter/material.dart';

import 'production_panel_test_support.dart';

Game productionPanelIsolatedGame(Player player, {required String id}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
}

Widget buildProductionPanelWithLabourCallbacks({
  required Player player,
  Orders currentOrders = const Orders(),
  bool canEditLabour = true,
}) {
  return buildProductionPanel(
    player: player,
    currentOrders: currentOrders,
    labourCallbacks: ProductionLabourCallbacks(
      onAppendRecruitOrder: (_) {},
      onPopLastRecruitOrder: (_) {},
      onDisband: (_) {},
    ),
    canEditLabour: canEditLabour,
    height: 700,
  );
}

Orders productionPanelFabricOfferOrders(Player player, {int quantity = 4}) {
  return Orders(
    tradeOrdersByPlayerId: {
      player.id: [
        TradeOrder(
          commodityId: CommodityCatalog.fabric.id,
          type: TradeOrderType.offer,
          quantity: quantity,
          priority: 5,
        ),
      ],
    },
  );
}
