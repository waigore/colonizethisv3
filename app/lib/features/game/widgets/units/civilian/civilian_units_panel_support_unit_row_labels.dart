/// Civilian unit row location and assignment labels. SPEC/ui/civilian-units-panel.md.
///
/// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/resource_icon.dart';
import '../shared/region_labels.dart';
import 'civilian_units_panel_support_resolution.dart';
import 'civilian_units_panel_support_unit_row.dart';

extension CivilianUnitRowLabels on CivilianUnitRow {
  String locationLabel() {
    final regionId = Unit.regionIdFromTileKey(projectedTileKey);
    final provinceId = Unit.provinceIdFromTileKey(projectedTileKey);
    if (regionId == null || provinceId == null) return '—';
    final prefixed = '$regionId|$provinceId';
    final name = provinceNames[prefixed] ?? prefixed;
    final regionLabel = regionDisplayLabel(regionId);
    return '$regionLabel — $name';
  }

  String assignedToLabelNonPending(AppLocalizations l10n) {
    if (unit.status != UnitStatus.working || unit.currentWork == null) {
      return '—';
    }
    final cw = unit.currentWork!;
    final workLabel = civilianWorkTargetLabels[cw.workTarget] ?? cw.workTarget;
    final regionId = Unit.regionIdFromTileKey(cw.tileKey);
    final provinceId = Unit.provinceIdFromTileKey(cw.tileKey);
    var location = '';
    if (regionId != null && provinceId != null) {
      final name =
          provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
      location = ' (${regionDisplayLabel(regionId)} — $name)';
    }
    final progress = cw.totalTurns > 0
        ? l10n.civilian_units_turnProgress(
            cw.remainingTurns.toString(),
            cw.totalTurns.toString(),
          )
        : l10n.civilian_units_turns(
            cw.remainingTurns <= 0 ? 1 : cw.remainingTurns,
          );
    return '$workLabel$location — $progress';
  }

  Widget buildAssignedToSubtitle(AppLocalizations l10n) {
    final pending = pendingWorkOrder;
    if (pending != null) {
      final r = resolvePendingAssignedResolution(
        game,
        unit,
        pending,
        provinceNames,
      );
      final turns = l10n.civilian_units_turns(r.totalTurns);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.civilian_units_assignedTo('${r.mainLine} — $turns')),
          if (r.materialCosts != null && r.materialCosts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in sortedMaterialCostEntries(r.materialCosts!))
                    CivilianAssignedCostChip(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ResourceIcon(commodityId: e.key, size: 14),
                          const SizedBox(width: 4),
                          Text(e.value.toString()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (r.treasuryAmount != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: CivilianAssignedCostChip(
                child: Text(
                  l10n.trainUnits_treasury(r.treasuryAmount!.toString()),
                ),
              ),
            ),
        ],
      );
    }
    return Text(
      l10n.civilian_units_assignedTo(assignedToLabelNonPending(l10n)),
    );
  }
}
