/// Work-order cost and affordability UI helpers. SPEC/ui/civilian-units-panel.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/resource_icon.dart';
import 'civilian_units_panel_support_resolution.dart';
import 'civilian_units_panel_unit_row_pending.dart';

export 'work_order_afford_overlay_tooltips.dart';

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
