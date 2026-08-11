// Shared base for the commodity-cost train-at-capital dialogs (military, naval).
// SPEC/ui/train-military-dialog.md, SPEC/ui/train-naval-dialog.md,
// SPEC/ui/components/train-dialog-chrome.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'train_dialog_base.dart';
import 'train_commodity_cost_dialog_base_costs.dart';
import 'train_commodity_cost_dialog_base_resource_bar.dart';
import 'train_commodity_cost_dialog_base_unit_row.dart';

/// A single trainable entry consumed by [CommodityCostTrainDialogState].
///
/// Adapts a concrete economy-catalog entry (e.g. `RegimentEconomy`,
/// `ShipEconomyEntry`) into the catalog-agnostic shape the shared
/// commodity-cost dialog needs: the [unitTypeId] used for stepper counts and
/// order materialization, the resolved roster [displayName], the cash
/// [buildTreasuryCost], and the per-commodity [buildInputs] consumed at build
/// time.
class CommodityCostUnitEntry {
  const CommodityCostUnitEntry({
    required this.unitTypeId,
    required this.displayName,
    required this.buildTreasuryCost,
    required this.buildInputs,
  });

  final String unitTypeId;
  final String displayName;
  final int buildTreasuryCost;
  final Map<String, int> buildInputs;
}

/// Optional per-row role and capability copy (naval train dialog).
class CommodityCostTrainDialogUnitRowExtras {
  const CommodityCostTrainDialogUnitRowExtras({
    required this.roleLabel,
    required this.capabilityLine,
  });

  final String roleLabel;
  final String capabilityLine;
}

/// Shared [TrainDialogBaseState] for the **commodity-cost** train dialogs
/// (military / naval), whose cost model is treasury + 1 peasant + commodity
/// inputs and whose presentation is a chip resource bar + per-unit cost rows.
///
/// Owns the cost math ([canAffordIncrement], the treasury / peasant / commodity
/// totals and remainders), the deficit hint, [buildBody], the commodity
/// resource bar, and the per-unit row — all of which were previously duplicated
/// byte-for-byte between `TrainMilitaryDialog` and `TrainNavalDialog`. Concrete
/// subclasses supply only the catalog adapter via [commodityCostEntries], the
/// presentation-ordered [resourceBarCommodityIds], the tech map
/// ([unlockingTechByUnitType]), the [dialogTitle], the [ordersAreMilitary]
/// flag, and the committed-orders event ([emitCommittedOrders]).
///
/// SPEC/ui/train-military-dialog.md, SPEC/ui/train-naval-dialog.md.
abstract class CommodityCostTrainDialogState<T extends TrainDialogBase>
    extends TrainDialogBaseState<T> {
  /// Ordered trainable entries (catalog order) for this dialog.
  List<CommodityCostUnitEntry> get commodityCostEntries;

  /// Presentation-ordered commodity ids rendered as chips on the resource bar.
  /// Not derivable from [commodityCostEntries] alone (it pins chip order and
  /// the goldens), so each subclass supplies it explicitly.
  List<String> get resourceBarCommodityIds;

  /// Optional per-row extras (naval role/capability gist). Military leaves null.
  @protected
  CommodityCostTrainDialogUnitRowExtras? unitRowExtrasFor(
    CommodityCostUnitEntry entry,
  ) =>
      null;

  /// Optional Military Counsel star on train rows (military dialog only).
  @protected
  Widget? counselStarFor(CommodityCostUnitEntry entry) => null;

  late final List<CommodityCostUnitEntry> _entries = commodityCostEntries;
  late final Map<String, CommodityCostUnitEntry> _entriesById = {
    for (final e in _entries) e.unitTypeId: e,
  };

  @override
  Iterable<String> get unitTypeIds => _entries.map((e) => e.unitTypeId);

  @override
  bool canAffordIncrement(String unitTypeId) {
    final econ = _entriesById[unitTypeId];
    if (econ == null) return false;
    if (isLocked(unitTypeId)) return false;

    final newTreasury = totalTreasuryCost() + econ.buildTreasuryCost;
    final newPeasants = totalPeasantCost() + 1;
    if (newTreasury > treasury) return false;
    if (newPeasants > peasants) return false;

    final totals = totalCommodityCosts();
    for (final input in econ.buildInputs.entries) {
      totals[input.key] = (totals[input.key] ?? 0) + input.value;
    }
    for (final e in totals.entries) {
      if (e.value > stockpileQty(e.key)) return false;
    }
    return true;
  }

  @override
  List<Widget> buildBody(AppLocalizations l10n) {
    return [
      const SizedBox(height: CtSpacing.ml),
      CommodityCostTrainDialogResourceBar(
        treasury: treasury,
        remainingTreasury: remainingTreasury(),
        peasants: peasants,
        remainingPeasants: remainingPeasants(),
        stockpile: player?.stockpile ?? const Stockpile(),
        committedCommodities: totalCommodityCosts(),
        commodityIds: resourceBarCommodityIds,
        deficitHint: commodityCostDeficitHint(l10n),
        l10n: l10n,
      ),
      const SizedBox(height: CtSpacing.ml),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final econ in _entries) _buildUnitRow(econ),
        ],
      ),
      const SizedBox(height: CtSpacing.ml),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CtNinePatchButton(
            onPressed: reset,
            child: Text(l10n.common_reset),
          ),
        ],
      ),
    ];
  }

  Widget _buildUnitRow(CommodityCostUnitEntry econ) {
    final locked = isLocked(econ.unitTypeId);
    final committed = totalCommodityCosts();
    final insufficientCommodityIds = <String>{
      for (final input in econ.buildInputs.entries)
        if (!locked && remainingCommodity(input.key, committed) < input.value)
          input.key,
    };
    final extras = unitRowExtrasFor(econ);
    return CommodityCostTrainDialogUnitRow(
      displayName: econ.displayName,
      buildTreasuryCost: econ.buildTreasuryCost,
      buildInputs: econ.buildInputs,
      count: counts[econ.unitTypeId] ?? 0,
      isLocked: locked,
      techRequiredLabel: techRequiredLabel(econ.unitTypeId),
      canIncrement: canAffordIncrement(econ.unitTypeId),
      canDecrement: (counts[econ.unitTypeId] ?? 0) > 0,
      treasuryInsufficient:
          !locked && remainingTreasury() < econ.buildTreasuryCost,
      peasantInsufficient: !locked && remainingPeasants() < 1,
      insufficientCommodityIds: insufficientCommodityIds,
      onIncrement: () => increment(econ.unitTypeId),
      onDecrement: () => decrement(econ.unitTypeId),
      roleLabel: extras?.roleLabel,
      capabilityLine: extras?.capabilityLine,
      counselStar: counselStarFor(econ),
    );
  }
}
