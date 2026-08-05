/// Status and assigned-to subtitles for civilian unit rows.
/// SPEC/ui/civilian-units-panel.md.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart'
    show isForeignProvinceForPlayer;
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../../widgets/resource_icon.dart';
import '../shared/region_labels.dart';
import 'civilian_units_panel_support_resolution.dart';
import 'civilian_units_panel_unit_row_pending.dart';
import 'work_order_afford_preview_ui.dart';

String? civilianUnitsPanelUnitRowSpyStatusLabel({
  required AppLocalizations l10n,
  required Game game,
  required Unit unit,
  required CivilianUnitsPanelUnitRowPending pending,
  required Map<String, String> provinceNames,
  required String? projectedTileKey,
  required String humanPlayerId,
}) {
  if (!pending.isSpy) return null;
  final pendingWork = pending.pendingWorkOrder;
  if (pendingWork?.target == kWorkTargetCounterSpy ||
      (unit.status == UnitStatus.working &&
          unit.currentWork?.workTarget == kWorkTargetCounterSpy)) {
    return l10n.civilian_units_spyStatus_counterEspionage;
  }
  if (pending.pendingMoveOrder != null) {
    return l10n.province_unitStatus_idle;
  }
  if (unit.status == UnitStatus.idle && unit.currentWork == null) {
    final tileKey = projectedTileKey;
    final regionId = Unit.regionIdFromTileKey(tileKey);
    final provinceFullId = Unit.provinceIdFromTileKey(tileKey);
    if (regionId != null && provinceFullId != null) {
      if (isForeignProvinceForPlayer(
        game: game,
        prefixedProvinceId: provinceFullId,
        humanPlayerId: humanPlayerId,
      )) {
        final name =
            provinceNames[provinceFullId] ??
            provinceNames['$regionId|${provinceFullId.split('|').last}'] ??
            provinceFullId;
        return l10n.civilian_units_spyStatus_holdingIntel(name);
      }
    }
    return l10n.civilian_units_spyStatus_reserve;
  }
  return null;
}

String civilianUnitsPanelUnitRowLocationLabel({
  required Map<String, String> provinceNames,
  required String? projectedTileKey,
}) {
  final regionId = Unit.regionIdFromTileKey(projectedTileKey);
  final provinceId = Unit.provinceIdFromTileKey(projectedTileKey);
  if (regionId == null || provinceId == null) return '—';
  final prefixed = '$regionId|$provinceId';
  final name = provinceNames[prefixed] ?? prefixed;
  final regionLabel = regionDisplayLabel(regionId);
  return '$regionLabel — $name';
}

String civilianUnitsPanelUnitRowAssignedToLabelNonPending({
  required AppLocalizations l10n,
  required Unit unit,
  required Map<String, String> provinceNames,
}) {
  if (unit.status != UnitStatus.working || unit.currentWork == null) {
    return '—';
  }
  final cw = unit.currentWork!;
  final workLabel =
      civilianUnitsPanelWorkTargetLabels[cw.workTarget] ?? cw.workTarget;
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

Widget buildCivilianUnitsPanelUnitRowAssignedToSubtitle({
  required AppLocalizations l10n,
  required Game game,
  required Unit unit,
  required CivilianUnitsPanelUnitRowPending pending,
  required Map<String, String> provinceNames,
}) {
  final pendingMove = pending.pendingMoveOrder;
  if (pendingMove != null) {
    final destTile = pendingMove.destinationTileKey;
    final regionId = Unit.regionIdFromTileKey(destTile);
    final provinceId = Unit.provinceIdFromTileKey(destTile);
    var location = destTile;
    if (regionId != null && provinceId != null) {
      final name =
          provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
      location = '${regionDisplayLabel(regionId)} — $name';
    }
    return Text(l10n.civilian_units_pendingRelocate(location));
  }
  final pendingWork = pending.pendingWorkOrder;
  if (pendingWork != null) {
    final r = resolveCivilianUnitsPanelPendingAssignedResolution(
      game,
      unit,
      pendingWork,
      provinceNames,
    );
    final pendingAfford = previewPendingCivilianWorkOrderAfford(
      game: game,
      pending: pending,
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
                for (final e in sortedCivilianUnitsPanelMaterialCostEntries(
                  r.materialCosts!,
                ))
                  CivilianUnitsPanelAssignedCostChip(
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
            child: CivilianUnitsPanelAssignedCostChip(
              child: Text(
                l10n.trainUnits_treasury(r.treasuryAmount!.toString()),
              ),
            ),
          ),
        if (pendingAfford != null &&
            pendingAfford.hasCostPreview &&
            !pendingAfford.canAfford)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: buildWorkOrderAffordStatusText(
              l10n: l10n,
              preview: pendingAfford,
              muted: true,
            ),
          ),
      ],
    );
  }
  return Text(
    l10n.civilian_units_assignedTo(
      civilianUnitsPanelUnitRowAssignedToLabelNonPending(
        l10n: l10n,
        unit: unit,
        provinceNames: provinceNames,
      ),
    ),
  );
}
