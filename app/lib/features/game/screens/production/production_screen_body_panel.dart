import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show
        economyPreviewInputs,
        forcesFeedingForPlayer,
        labourReadinessForPlayer,
        previewStockpileNetDeltaByCommodityForPlayer;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import '../../widgets/production/production_commodity_breakdown_dialog.dart';
import '../../widgets/production/production_labour_disband_confirm.dart';
import '../../widgets/production/production_labour_helpers.dart';
import '../../widgets/production/production_panel.dart';

/// Synchronous Production open-path prep when session cache overrides are active.
({
  Map<String, int> netDeltasByCommodity,
  LabourReadinessSnapshot labourReadiness,
  ForceFeedingSnapshot forcesFeeding,
}) buildProductionPanelOpenPathWithoutSessionCache({
  required Game displayGame,
  required Player displayPlayer,
  required MapTopology panelTopology,
  required Map<String, TileMapResult>? panelTileMaps,
  required Orders currentOrders,
  required Map<String, int> desiredOutputByRecipe,
}) {
  final netDeltasByCommodity = previewStockpileNetDeltaByCommodityForPlayer(
    game: displayGame,
    topology: panelTopology,
    playerId: displayPlayer.id,
    inputs: economyPreviewInputs(
      tileMapByRegion: panelTileMaps,
      currentOrders: currentOrders,
      defaultAssignmentsByPlayerId: {
        displayPlayer.id: assignedRecipesFromDesiredOutput(
          desiredOutputByRecipe,
        ),
      },
    ),
  );
  final regimentCounts = regimentTypeCountsForPlayer(
    displayGame.worldState,
    displayPlayer.id,
  );
  final shipCounts = shipTypeCountsForPlayer(
    displayGame.worldState,
    displayPlayer.id,
  );
  final foodCounts = MilitaryNavyFoodCounts(
    regimentCountsById: regimentCounts,
    shipCountsById: shipCounts,
  );
  final previewInputs = economyPreviewInputs(
    tileMapByRegion: panelTileMaps,
    currentOrders: currentOrders,
  );
  return (
    netDeltasByCommodity: netDeltasByCommodity,
    labourReadiness: labourReadinessForPlayer(
      game: displayGame,
      topology: panelTopology,
      playerId: displayPlayer.id,
      foodCounts: foodCounts,
      inputs: previewInputs,
    ),
    forcesFeeding: forcesFeedingForPlayer(
      game: displayGame,
      topology: panelTopology,
      playerId: displayPlayer.id,
      foodCounts: foodCounts,
      inputs: previewInputs,
    ),
  );
}

/// Callers read providers in `build` and pass narrow order/game accessors —
/// do not thread [WidgetRef] (`repo.app_widget_ref_parameter_smell`).
ProductionLabourCallbacks productionScreenLabourCallbacks({
  required bool canEdit,
  required String playerId,
  required Orders Function() readCurrentOrders,
  required void Function(Orders next) replaceCurrentOrders,
  required Game Function() readGame,
  required void Function(Game nextGame) writeGame,
  required BuildContext context,
}) {
  return ProductionLabourCallbacks(
    onAppendRecruitOrder: (tier) {
      if (!canEdit) return;
      final next = ordersWithAppendedRecruitWorkerOrder(
        currentOrders: readCurrentOrders(),
        playerId: playerId,
        tier: tier,
      );
      replaceCurrentOrders(next);
    },
    onPopLastRecruitOrder: (tier) {
      if (!canEdit) return;
      final next = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: readCurrentOrders(),
        playerId: playerId,
        tier: tier,
      );
      replaceCurrentOrders(next);
    },
    onDisband: (tier) {
      unawaited(
        confirmAndApplyImmediateLabourDisband(
          context: context,
          tier: tier,
          canEdit: canEdit,
          readGame: readGame,
          writeGame: writeGame,
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
  required void Function(Map<String, int> next) replaceDesiredOutput,
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
      replaceDesiredOutput(next);
    },
    starredProduceRecommendationsByRecipeId:
        starredProduceRecommendationsByRecipeId,
    onOpenCounsel: openCounsel,
    onOpenTradeMarket: openTradeMarket,
  );
}
