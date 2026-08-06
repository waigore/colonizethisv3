/// Work-order cost and affordability UI helpers. SPEC/ui/civilian-units-panel.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/resource_icon.dart';
import 'civilian_units_panel_support_resolution.dart';
import 'civilian_units_panel_unit_row_pending.dart';

String workOrderAffordCommodityLabel(String commodityId) {
  final commodity = CommodityCatalog.byId[commodityId];
  return commodity?.displayName ?? commodityId;
}

String formatWorkOrderMaterialCostSummary(Map<String, int> costs) {
  final parts = <String>[];
  for (final entry in sortedCivilianUnitsPanelMaterialCostEntries(costs)) {
    parts.add('${workOrderAffordCommodityLabel(entry.key)} ${entry.value}');
  }
  return parts.join(', ');
}

String workOrderAffordStatusLine({
  required AppLocalizations l10n,
  required WorkOrderAffordPreview preview,
}) {
  if (preview.treasuryShortfall != null) {
    return l10n.workOrderAfford_shortTreasury(preview.treasuryShortfall!);
  }
  if (preview.materialShortfalls.isNotEmpty) {
    final first = preview.materialShortfalls.first;
    return l10n.workOrderAfford_shortMaterial(
      workOrderAffordCommodityLabel(first.commodityId),
      first.quantity,
    );
  }
  if (preview.hasCostPreview) {
    return l10n.workOrderAfford_canAfford;
  }
  return '';
}

Widget buildWorkOrderAffordCostChips({
  required AppLocalizations l10n,
  required WorkOrderAffordPreview preview,
}) {
  final children = <Widget>[];
  final materialCosts = preview.materialCosts;
  if (materialCosts != null && materialCosts.isNotEmpty) {
    for (final entry in sortedCivilianUnitsPanelMaterialCostEntries(
      materialCosts,
    )) {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResourceIcon(commodityId: entry.key, size: 14),
            const SizedBox(width: 4),
            Text(entry.value.toString()),
          ],
        ),
      );
    }
  }
  if (preview.treasuryAmount != null) {
    children.add(
      Text(l10n.trainUnits_treasury(preview.treasuryAmount!.toString())),
    );
  }
  if (children.isEmpty) {
    return const SizedBox.shrink();
  }
  return Wrap(
    spacing: 8,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

Widget buildWorkOrderAffordStatusText({
  required AppLocalizations l10n,
  required WorkOrderAffordPreview preview,
  bool muted = false,
}) {
  final line = workOrderAffordStatusLine(l10n: l10n, preview: preview);
  if (line.isEmpty) {
    return const SizedBox.shrink();
  }
  return Text(
    line,
    style: TextStyle(
      color: muted ? EditorialMonoclePalette.muted : EditorialMonoclePalette.fg,
      fontSize: 12,
    ),
  );
}

WorkOrderAffordPreview? previewPendingCivilianWorkOrderAfford({
  required Game game,
  required CivilianUnitsPanelUnitRowPending pending,
}) {
  final order = pending.pendingWorkOrder;
  if (order == null) return null;
  return previewPendingWorkOrderAfford(
    game: game,
    playerId: pending.humanPlayerId,
    currentOrders: pending.currentOrders,
    pendingOrder: order,
  );
}

String provinceOverlayBuildImprovementTooltip({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required bool enabled,
  required bool hasBuilderUnits,
}) {
  if (!hasBuilderUnits) {
    return l10n.provinceOverlay_tileBuildImprovementDisabledNoBuilderTooltip;
  }
  final preview = previewWorkOrderAffordAtTile(
    game: game,
    playerId: humanPlayerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetBuildImprovement,
    targetTileKey: selectedTileKey,
  );
  if (!enabled &&
      preview.hasCostPreview &&
      !preview.canAfford &&
      preview.materialShortfalls.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildImprovementDisabledMaterialsTooltip(
      workOrderAffordStatusLine(l10n: l10n, preview: preview),
    );
  }
  if (enabled && preview.materialCosts != null && preview.materialCosts!.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildImprovementTooltipWithCost(
      formatWorkOrderMaterialCostSummary(preview.materialCosts!),
    );
  }
  return l10n.provinceOverlay_tileBuildImprovementTooltip;
}

String provinceOverlayBuildRoadTooltip({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required bool enabled,
  required bool hasEngineerUnits,
}) {
  if (!hasEngineerUnits) {
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
  if (enabled && preview.materialCosts != null && preview.materialCosts!.isNotEmpty) {
    return l10n.provinceOverlay_tileBuildRoadTooltipWithCost(
      formatWorkOrderMaterialCostSummary(preview.materialCosts!),
    );
  }
  return l10n.provinceOverlay_tileBuildRoadTooltip;
}

String provinceOverlayPurchaseLandTooltip({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required String provinceId,
  required bool enabled,
  required bool hasMerchantUnits,
}) {
  if (!hasMerchantUnits) {
    return l10n.provinceOverlay_tilePurchaseLandDisabledNoMerchantTooltip;
  }
  final province = game.worldState.tryGetProvince(provinceId);
  final ownerId = province?.ownerId;
  if (ownerId != null && ownerId.isNotEmpty && ownerId != humanPlayerId) {
    final rel = getRelation(game, humanPlayerId, ownerId);
    final overture = getOverture(game, humanPlayerId, ownerId);
    if (!enabled &&
        (rel?.atWar == true ||
            overture == null ||
            !overture.hasEmbassy)) {
      return l10n.provinceOverlay_tilePurchaseLandDisabledEmbassyTooltip;
    }
  }
  final preview = previewWorkOrderAffordAtTile(
    game: game,
    playerId: humanPlayerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetPurchaseLand,
    targetTileKey: selectedTileKey,
  );
  if (!enabled &&
      preview.hasCostPreview &&
      !preview.canAfford &&
      preview.treasuryShortfall != null) {
    return l10n.provinceOverlay_tilePurchaseLandDisabledTreasuryTooltip(
      preview.treasuryShortfall!,
    );
  }
  if (enabled && preview.treasuryAmount != null) {
    return l10n.provinceOverlay_tilePurchaseLandTooltipWithCost(
      preview.treasuryAmount!,
    );
  }
  return l10n.provinceOverlay_tilePurchaseLandTooltip;
}
