import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/games_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
import '../../widgets/production/production_commodity_breakdown_dialog.dart';
import '../../widgets/production/production_labour_disband_confirm.dart';
import '../../widgets/production/production_labour_helpers.dart';
import '../../widgets/production/production_panel.dart';

ProductionLabourCallbacks productionScreenLabourCallbacks({
  required bool canEdit,
  required String playerId,
  required WidgetRef shellRef,
  required Game displayGame,
  required BuildContext context,
}) {
  return ProductionLabourCallbacks(
    onAppendRecruitOrder: (tier) {
      if (!canEdit) return;
      final next = ordersWithAppendedRecruitWorkerOrder(
        currentOrders: shellRef.read(currentOrdersProvider),
        playerId: playerId,
        tier: tier,
      );
      shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
    },
    onPopLastRecruitOrder: (tier) {
      if (!canEdit) return;
      final next = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: shellRef.read(currentOrdersProvider),
        playerId: playerId,
        tier: tier,
      );
      shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
    },
    onDisband: (tier) {
      unawaited(
        confirmAndApplyImmediateLabourDisband(
          context: context,
          tier: tier,
          canEdit: canEdit,
          readGame: () => shellRef.read(currentGameProvider) ?? displayGame,
          writeGame: (nextGame) {
            shellRef.read(currentGameProvider.notifier).setGame(nextGame);
          },
          playerId: playerId,
        ),
      );
    },
  );
}

ProductionPanel buildProductionScreenPanel({
  required BuildContext context,
  required Game displayGame,
  required Player displayPlayer,
  required Map<String, int> desiredOutputByRecipe,
  required Map<String, int> netDeltasByCommodity,
  required LabourReadinessSnapshot labourReadiness,
  required ForceFeedingSnapshot forcesFeeding,
  required Orders currentOrders,
  required ProductionLabourCallbacks labourCallbacks,
  required bool canEdit,
  required WidgetRef shellRef,
  required MapTopology panelTopology,
  required Map<String, TileMapResult>? panelTileMaps,
  required Map<String, IndustryCounselRecommendation>
  starredProduceRecommendationsByRecipeId,
  required void Function({String? highlightRecommendationId}) openCounsel,
  required void Function(String commodityId) openTradeMarket,
}) {
  return ProductionPanel(
    game: displayGame,
    player: displayPlayer,
    desiredOutputByRecipe: desiredOutputByRecipe,
    netDeltasByCommodity: netDeltasByCommodity,
    labourReadiness: labourReadiness,
    forcesFeeding: forcesFeeding,
    currentOrders: currentOrders,
    labourCallbacks: labourCallbacks,
    canEditLabour: canEdit,
    onOpenCommodityBreakdown: canEdit
        ? () {
            showDialog<void>(
              context: context,
              barrierColor: EditorialMonoclePalette.dialogScrim,
              builder: (_) => ProductionCommodityBreakdownDialog(
                game: displayGame,
                player: displayPlayer,
                topology: panelTopology,
                tileMapByRegion: panelTileMaps,
                currentOrders: currentOrders,
              ),
            );
          }
        : null,
    onDesiredOutputChanged: (next) {
      if (!canEdit) return;
      shellRef.read(productionDesiredOutputProvider.notifier).replaceAll(next);
    },
    starredProduceRecommendationsByRecipeId:
        starredProduceRecommendationsByRecipeId,
    onOpenCounsel: openCounsel,
    onOpenTradeMarket: openTradeMarket,
  );
}
