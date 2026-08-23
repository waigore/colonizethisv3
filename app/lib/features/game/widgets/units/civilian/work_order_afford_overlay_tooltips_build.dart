/// Road / fort / port / railroad overlay work-order tooltips.
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'work_order_afford_preview_ui.dart'
    show formatWorkOrderMaterialCostSummary, workOrderAffordStatusLine;

String provinceOverlayBuildRoadTooltip({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required bool enabled,
  required bool hasMatchingUnits,
}) {
  if (!hasMatchingUnits) {
    return l10n.provinceOverlay_tileBuildRoadDisabledNoEngineerTooltip;
  }
  final preview = previewWorkOrderAffordAtTile(
    game: game,
    playerId: humanPlayerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetBuildRoad,
    targetTileKey: selectedTileKey,
  );
  if (!enabled &&
      preview.hasCostPreview &&
      !preview.canAfford &&
      preview.materialShortfalls.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildRoadDisabledMaterialsTooltip(
      workOrderAffordStatusLine(l10n: l10n, preview: preview),
    );
  }
  if (!enabled) {
    return l10n.provinceOverlay_tileBuildRoadDisabledTooltip;
  }
  if (enabled &&
      preview.materialCosts != null &&
      preview.materialCosts!.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildRoadTooltipWithCost(
      formatWorkOrderMaterialCostSummary(preview.materialCosts!),
    );
  }
  return l10n.provinceOverlay_tileBuildRoadTooltip;
}

String provinceOverlayBuildFortTooltip({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required bool enabled,
  required bool hasMatchingUnits,
}) {
  if (!hasMatchingUnits) {
    return l10n.provinceOverlay_tileBuildFortDisabledNoEngineerTooltip;
  }
  final preview = previewWorkOrderAffordAtTile(
    game: game,
    playerId: humanPlayerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetBuildFort,
    targetTileKey: selectedTileKey,
  );
  if (!enabled &&
      preview.hasCostPreview &&
      !preview.canAfford &&
      preview.materialShortfalls.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildFortDisabledMaterialsTooltip(
      workOrderAffordStatusLine(l10n: l10n, preview: preview),
    );
  }
  if (!enabled) {
    return l10n.provinceOverlay_tileBuildFortDisabledTooltip;
  }
  if (enabled &&
      preview.materialCosts != null &&
      preview.materialCosts!.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildFortTooltipWithCost(
      formatWorkOrderMaterialCostSummary(preview.materialCosts!),
    );
  }
  return l10n.provinceOverlay_tileBuildFortTooltip;
}

String provinceOverlayBuildPortTooltip({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required bool enabled,
  required bool hasMatchingUnits,
}) {
  if (!hasMatchingUnits) {
    return l10n.provinceOverlay_tileBuildPortDisabledNoEngineerTooltip;
  }
  final preview = previewWorkOrderAffordAtTile(
    game: game,
    playerId: humanPlayerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetBuildPort,
    targetTileKey: selectedTileKey,
  );
  if (!enabled &&
      preview.hasCostPreview &&
      !preview.canAfford &&
      preview.materialShortfalls.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildPortDisabledMaterialsTooltip(
      workOrderAffordStatusLine(l10n: l10n, preview: preview),
    );
  }
  if (!enabled) {
    return l10n.provinceOverlay_tileBuildPortDisabledTooltip;
  }
  if (enabled &&
      preview.materialCosts != null &&
      preview.materialCosts!.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildPortTooltipWithCost(
      formatWorkOrderMaterialCostSummary(preview.materialCosts!),
    );
  }
  return l10n.provinceOverlay_tileBuildPortTooltip;
}

String provinceOverlayBuildRailroadTooltip({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required bool enabled,
  required bool hasMatchingUnits,
}) {
  if (!hasMatchingUnits) {
    return l10n.provinceOverlay_tileBuildRailroadDisabledNoRailBuilderTooltip;
  }
  final preview = previewWorkOrderAffordAtTile(
    game: game,
    playerId: humanPlayerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetBuildRail,
    targetTileKey: selectedTileKey,
  );
  if (!enabled &&
      preview.hasCostPreview &&
      !preview.canAfford &&
      preview.materialShortfalls.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildRailroadDisabledMaterialsTooltip(
      workOrderAffordStatusLine(l10n: l10n, preview: preview),
    );
  }
  if (!enabled) {
    return l10n.provinceOverlay_tileBuildRailroadDisabledTooltip;
  }
  if (enabled &&
      preview.materialCosts != null &&
      preview.materialCosts!.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildRailroadTooltipWithCost(
      formatWorkOrderMaterialCostSummary(preview.materialCosts!),
    );
  }
  return l10n.provinceOverlay_tileBuildRailroadTooltip;
}
