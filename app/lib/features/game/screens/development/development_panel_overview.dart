import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';

import '../../widgets/units/civilian/civilian_units_panel_support_resolution.dart';
import '../../widgets/units/shared/region_labels.dart';
import 'development_panel_overview_strips.dart';

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
        DevelopmentPanelExtractionStrip(
          l10n: l10n,
          textTheme: textTheme,
          landExtractionByCommodity: regionModel.landExtractionByCommodity,
        ),
        if (materialShortageCommodityIds.isNotEmpty)
          DevelopmentPanelShortageWarning(
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

  Unit? _unitForRow(DevelopmentAssignedCivilianRow row) =>
      game.worldState.tryGetUnitById(row.unitId);

  WorkOrder? _pendingOrderForUnit(String unitId) {
    for (final order
        in currentOrders.workOrdersByPlayerId[humanPlayerId] ?? const []) {
      if (order.unitId == unitId) return order;
    }
    return null;
  }
}
