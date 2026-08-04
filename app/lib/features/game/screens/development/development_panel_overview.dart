import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/commodity_display_name.dart';
import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/resource_icon.dart';
import '../../widgets/units/civilian/civilian_units_panel_support_resolution.dart';
import '../../widgets/units/shared/region_labels.dart';

/// Overview strip: extraction projection, idle civilian counts, shortage warning.
class DevelopmentPanelOverview extends StatelessWidget {
  const DevelopmentPanelOverview({
    super.key,
    required this.regionModel,
    this.materialShortageCommodityIds = const {},
    required this.provinceDisplayNamesById,
    required this.game,
    required this.humanPlayerId,
    required this.currentOrders,
  });

  final DevelopmentPanelRegionModel regionModel;
  final Set<String> materialShortageCommodityIds;
  final Map<String, String> provinceDisplayNamesById;
  final Game game;
  final String humanPlayerId;
  final Orders currentOrders;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CtSectionLabel(l10n.provinceOverlay_extractionHeading),
        const SizedBox(height: 4),
        _ExtractionStrip(
          l10n: l10n,
          textTheme: textTheme,
          landExtractionByCommodity: regionModel.landExtractionByCommodity,
        ),
        if (materialShortageCommodityIds.isNotEmpty)
          _ShortageWarning(
            l10n: l10n,
            textTheme: textTheme,
            materialShortageCommodityIds: materialShortageCommodityIds,
          ),
        const SizedBox(height: CtSpacing.m),
        Text(
          l10n.development_idleCivilians(
            regionModel.idleBuilderCount,
            regionModel.idleEngineerCount,
          ),
          style: textTheme.bodySmall?.copyWith(
            color: EditorialMonoclePalette.muted,
          ),
        ),
        if (regionModel.assignedCivilians.isNotEmpty) ...[
          const SizedBox(height: CtSpacing.m),
          CtSectionLabel(l10n.development_assignedCiviliansHeading),
          const SizedBox(height: 4),
          for (final row in regionModel.assignedCivilians)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _assignedCivilianLine(l10n, row),
                style: textTheme.bodySmall?.copyWith(
                  color: EditorialMonoclePalette.fg,
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _assignedCivilianLine(
    AppLocalizations l10n,
    DevelopmentAssignedCivilianRow row,
  ) {
    final workLabel =
        civilianUnitsPanelWorkTargetLabels[row.workTarget] ?? row.workTarget;
    final regionId = Unit.regionIdFromTileKey(row.targetTileKey);
    final provinceId = Unit.provinceIdFromTileKey(row.targetTileKey);
    var location = '';
    if (regionId != null && provinceId != null) {
      final prefixed = '$regionId|$provinceId';
      final name = provinceDisplayNamesById[prefixed] ?? prefixed;
      location = ' (${regionDisplayLabel(regionId)} — $name)';
    }
    if (row.isPending) {
      final unit = _unitForRow(row);
      if (unit == null) {
        return '${row.unitType}: $workLabel$location';
      }
      final pending = _pendingOrderForUnit(row.unitId);
      if (pending == null) {
        return '${row.unitType}: $workLabel$location';
      }
      final resolved = resolveCivilianUnitsPanelPendingAssignedResolution(
        game,
        unit,
        pending,
        provinceDisplayNamesById,
      );
      final turns = l10n.civilian_units_turns(resolved.totalTurns);
      return '${row.unitType}: ${resolved.mainLine} — $turns';
    }
    final progress = row.totalTurns != null && row.totalTurns! > 0
        ? l10n.civilian_units_turnProgress(
            (row.remainingTurns ?? 0).toString(),
            row.totalTurns.toString(),
          )
        : l10n.civilian_units_turns(
            (row.remainingTurns ?? 0) <= 0 ? 1 : row.remainingTurns!,
          );
    return '${row.unitType}: $workLabel$location — $progress';
  }

  Unit? _unitForRow(DevelopmentAssignedCivilianRow row) {
    for (final unit in [
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ]) {
      if (unit.id == row.unitId) return unit;
    }
    return null;
  }

  WorkOrder? _pendingOrderForUnit(String unitId) {
    for (final order
        in currentOrders.workOrdersByPlayerId[humanPlayerId] ?? const []) {
      if (order.unitId == unitId) return order;
    }
    return null;
  }
}

class _ExtractionStrip extends StatelessWidget {
  const _ExtractionStrip({
    required this.l10n,
    required this.textTheme,
    required this.landExtractionByCommodity,
  });

  final AppLocalizations l10n;
  final TextTheme textTheme;
  final Map<String, int> landExtractionByCommodity;

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[];
    for (final commodity in CommodityCatalog.all) {
      final qty = landExtractionByCommodity[commodity.id];
      if (qty == null || qty <= 0) continue;
      parts.add(
        Padding(
          padding: const EdgeInsets.only(right: CtSpacing.s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResourceIcon(commodityId: commodity.id, size: 14),
              const SizedBox(width: 4),
              Text(
                l10n.provinceOverlay_extractionQuantity(
                  qty,
                  commodityDisplayName(l10n, commodity.id),
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: EditorialMonoclePalette.fg,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (parts.isEmpty) {
      return Text(
        '—',
        style: textTheme.bodySmall?.copyWith(
          color: EditorialMonoclePalette.muted,
        ),
      );
    }
    return Wrap(children: parts);
  }
}

class _ShortageWarning extends StatelessWidget {
  const _ShortageWarning({
    required this.l10n,
    required this.textTheme,
    required this.materialShortageCommodityIds,
  });

  final AppLocalizations l10n;
  final TextTheme textTheme;
  final Set<String> materialShortageCommodityIds;

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[];
    for (final commodity in CommodityCatalog.all) {
      if (!materialShortageCommodityIds.contains(commodity.id)) continue;
      parts.add(
        Padding(
          padding: const EdgeInsets.only(right: CtSpacing.s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResourceIcon(commodityId: commodity.id, size: 14),
              const SizedBox(width: 4),
              Text(
                commodityDisplayName(l10n, commodity.id),
                style: textTheme.bodySmall?.copyWith(
                  color: EditorialMonoclePalette.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: CtSpacing.s),
        Text(
          l10n.development_materialsShortageForAssign,
          style: textTheme.bodySmall?.copyWith(
            color: EditorialMonoclePalette.accent,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(children: parts),
      ],
    );
  }
}
