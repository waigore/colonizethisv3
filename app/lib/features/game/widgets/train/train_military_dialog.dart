import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../config/ui_screen_ids.dart';
import 'train_commodity_cost_dialog_base.dart';
import 'train_dialog_base.dart';
import 'train_military_regiment_role_display.dart';

class TrainMilitaryDialog extends TrainDialogBase {
  const TrainMilitaryDialog({
    super.key,
    required super.game,
    required super.humanPlayerId,
    required super.currentOrders,
    required super.bus,
  });

  /// SPEC/ui/train-military-dialog.md — [UiScreenIds.trainMilitaryDialog].
  static const screenId = UiScreenIds.trainMilitaryDialog;

  @override
  State<TrainMilitaryDialog> createState() => _TrainMilitaryDialogState();
}

class _TrainMilitaryDialogState
    extends CommodityCostTrainDialogState<TrainMilitaryDialog> {
  /// Presentation order of the military resource-bar commodity chips.
  /// SPEC/ui/train-military-dialog.md § Resource bar.
  static const _commodityIds = <String>[
    'fabric',
    'castIron',
    'lumber',
    'horses',
    'steel',
    'bronze',
  ];

  @override
  bool get ordersAreMilitary => true;

  @override
  Map<String, String> get unlockingTechByUnitType => unlockingTechByRegimentId;

  @override
  String dialogTitle(AppLocalizations l10n) => l10n.trainMilitary_title;

  @override
  List<String> get resourceBarCommodityIds => _commodityIds;

  @override
  CommodityCostTrainDialogUnitRowExtras? unitRowExtrasFor(
    CommodityCostUnitEntry entry,
  ) {
    final l10n = appL10n(context);
    final stats = regimentStatsById(entry.unitTypeId);
    if (stats == null) return null;
    final foodUpkeep =
        TrainMilitaryRegimentRoleDisplay.foodUpkeepForRegiment(entry.unitTypeId);
    return CommodityCostTrainDialogUnitRowExtras(
      roleLabel: TrainMilitaryRegimentRoleDisplay.categoryLabel(
        l10n,
        stats.category,
      ),
      capabilityLine: TrainMilitaryRegimentRoleDisplay.combatRoleGist(
        l10n,
        stats.category,
      ),
      ongoingCostLine: foodUpkeep == null
          ? null
          : TrainMilitaryRegimentRoleDisplay.foodUpkeepLine(l10n, foodUpkeep),
    );
  }

  @override
  List<CommodityCostUnitEntry> get commodityCostEntries => [
    for (final e in RegimentEconomyCatalog.all)
      CommodityCostUnitEntry(
        unitTypeId: e.id,
        displayName: regimentTypeDisplayName(e.id),
        buildTreasuryCost: e.buildTreasuryCost,
        buildInputs: e.buildInputs,
      ),
  ];

  @override
  void emitCommittedOrders(List<BuildUnitOrder> orders) {
    widget.bus.emit(TrainMilitaryBuildOrdersCommittedEvent(orders: orders));
  }
}
