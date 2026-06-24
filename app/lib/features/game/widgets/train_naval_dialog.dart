import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import 'train_commodity_cost_dialog_base.dart';
import 'train_dialog_base.dart';

/// Train-at-capital dialog for naval (ship) units. Mirrors the civilian and
/// military train dialogs: a `remaining / total` resource bar, per-row cost
/// segments that turn red when a resource cannot cover one more ship, and a
/// danger-styled disabled `[+]` stepper for unaffordable rows. Ships are built
/// with `isMilitary: false` (their own unit category) and spawn into the
/// player's home fleet at the capital. SPEC/ui/train-naval-dialog.md.
class TrainNavalDialog extends TrainDialogBase {
  const TrainNavalDialog({
    super.key,
    required super.game,
    required super.humanPlayerId,
    required super.currentOrders,
    required super.bus,
  });

  /// SPEC/ui/train-naval-dialog.md — [UiScreenIds.trainNavalDialog].
  static const screenId = UiScreenIds.trainNavalDialog;

  @override
  State<TrainNavalDialog> createState() => _TrainNavalDialogState();
}

class _TrainNavalDialogState
    extends CommodityCostTrainDialogState<TrainNavalDialog> {
  /// Union of all commodities referenced by [ShipEconomyCatalog.buildInputs],
  /// in presentation order. SPEC/ui/train-naval-dialog.md § Resource bar.
  static const _commodityIds = <String>[
    'lumber',
    'fabric',
    'castIron',
    'coal',
  ];

  @override
  bool get ordersAreMilitary => false;

  @override
  Map<String, String> get unlockingTechByUnitType => unlockingTechByShipId;

  @override
  String dialogTitle(AppLocalizations l10n) => l10n.trainNaval_title;

  @override
  List<String> get resourceBarCommodityIds => _commodityIds;

  @override
  List<CommodityCostUnitEntry> get commodityCostEntries => [
    for (final e in ShipEconomyCatalog.all)
      CommodityCostUnitEntry(
        unitTypeId: e.shipTypeId,
        displayName: shipTypeDisplayName(e.shipTypeId),
        buildTreasuryCost: e.buildTreasuryCost,
        buildInputs: e.buildInputs,
      ),
  ];

  @override
  void emitCommittedOrders(List<BuildUnitOrder> orders) {
    widget.bus.emit(TrainNavalBuildOrdersCommittedEvent(orders: orders));
  }
}
