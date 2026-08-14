/// Province overlay work-order tooltip strings. SPEC/ui/civilian-units-panel.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'work_order_afford_preview_ui.dart'
    show formatWorkOrderMaterialCostSummary, workOrderAffordStatusLine;

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
  if (enabled &&
      preview.materialCosts != null &&
      preview.materialCosts!.isNotEmpty) {
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
  required bool hasEngineerUnits,
}) {
  if (!hasEngineerUnits) {
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
  required bool hasEngineerUnits,
}) {
  if (!hasEngineerUnits) {
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
  required bool hasRailBuilderUnits,
}) {
  if (!hasRailBuilderUnits) {
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
        (rel?.atWar == true || overture == null || !overture.hasEmbassy)) {
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

String provinceOverlayPoliticalUpgradeTownTooltip({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String townTileKey,
  required bool enabled,
  required bool hasBuilderUnits,
}) {
  final player = game.playerById(humanPlayerId);
  if (player?.techUnlocked?[kTechIdNationalBureaucracy] != true) {
    return l10n.provinceOverlay_politicalUpgradeTownDisabledTechTooltip;
  }
  if (!hasBuilderUnits) {
    return l10n.provinceOverlay_politicalUpgradeTownDisabledNoBuilderTooltip;
  }
  final preview = previewWorkOrderAffordAtTile(
    game: game,
    playerId: humanPlayerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetUpgradeTown,
    targetTileKey: townTileKey,
  );
  if (!enabled &&
      preview.hasCostPreview &&
      !preview.canAfford &&
      preview.materialShortfalls.isNotEmpty) {
    return l10n.provinceOverlay_politicalUpgradeTownDisabledMaterialsTooltip(
      workOrderAffordStatusLine(l10n: l10n, preview: preview),
    );
  }
  if (!enabled) {
    return l10n.provinceOverlay_politicalUpgradeTownDisabledTooltip;
  }
  if (enabled &&
      preview.materialCosts != null &&
      preview.materialCosts!.isNotEmpty) {
    return l10n.provinceOverlay_politicalUpgradeTownTooltipWithCost(
      formatWorkOrderMaterialCostSummary(preview.materialCosts!),
    );
  }
  return l10n.provinceOverlay_politicalUpgradeTownTooltip;
}
