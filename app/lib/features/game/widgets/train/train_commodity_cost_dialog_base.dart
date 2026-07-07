// Shared base for the commodity-cost train-at-capital dialogs (military, naval).
// SPEC/ui/train-military-dialog.md, SPEC/ui/train-naval-dialog.md,
// SPEC/ui/components/train-dialog-chrome.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/resource_icon.dart';
import '../production/commodity_ui_helpers.dart';
import 'train_dialog_base.dart';
import 'train_dialog_chrome.dart';

part 'train_commodity_cost_dialog_base_widgets.dart';

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

  late final List<CommodityCostUnitEntry> _entries = commodityCostEntries;
  late final Map<String, CommodityCostUnitEntry> _entriesById = {
    for (final e in _entries) e.unitTypeId: e,
  };

  @override
  Iterable<String> get unitTypeIds => _entries.map((e) => e.unitTypeId);

  int _totalTreasuryCost() {
    var total = 0;
    for (final e in _entries) {
      total += (counts[e.unitTypeId] ?? 0) * e.buildTreasuryCost;
    }
    return total;
  }

  int _totalPeasantCost() {
    var total = 0;
    for (final e in _entries) {
      total += counts[e.unitTypeId] ?? 0;
    }
    return total;
  }

  Map<String, int> _totalCommodityCosts() {
    final totals = <String, int>{};
    for (final e in _entries) {
      final count = counts[e.unitTypeId] ?? 0;
      if (count <= 0) continue;
      for (final input in e.buildInputs.entries) {
        totals[input.key] = (totals[input.key] ?? 0) + (input.value * count);
      }
    }
    return totals;
  }

  @override
  bool canAffordIncrement(String unitTypeId) {
    final econ = _entriesById[unitTypeId];
    if (econ == null) return false;
    if (isLocked(unitTypeId)) return false;

    final newTreasury = _totalTreasuryCost() + econ.buildTreasuryCost;
    final newPeasants = _totalPeasantCost() + 1;
    if (newTreasury > treasury) return false;
    if (newPeasants > peasants) return false;

    final totals = _totalCommodityCosts();
    for (final input in econ.buildInputs.entries) {
      totals[input.key] = (totals[input.key] ?? 0) + input.value;
    }
    for (final e in totals.entries) {
      if (e.value > stockpileQty(e.key)) return false;
    }
    return true;
  }

  /// Treasury left after subtracting all currently committed unit costs.
  int _remainingTreasury() => treasury - _totalTreasuryCost();

  /// Peasants left after subtracting all currently committed unit costs.
  int _remainingPeasants() => peasants - _totalPeasantCost();

  /// Stockpile of [commodityId] left after subtracting committed costs.
  int _remainingCommodity(String commodityId, Map<String, int> committed) =>
      stockpileQty(commodityId) - (committed[commodityId] ?? 0);

  String? get _deficitHint {
    final deficits = <String>[];
    if (_totalTreasuryCost() > treasury) deficits.add('Treasury');
    if (_totalPeasantCost() > peasants) deficits.add('Peasants');
    final totalComms = _totalCommodityCosts();
    for (final e in totalComms.entries) {
      if (e.value > stockpileQty(e.key)) {
        deficits.add(commodityDisplayName(e.key));
      }
    }
    if (deficits.isEmpty) return null;
    // Per-clause `{Name} low` joined with `", "` per
    // `SPEC/ui/train-military-dialog.md` / `SPEC/ui/train-naval-dialog.md`
    // § Deficit hint.
    return deficits.map((name) => '$name low').join(', ');
  }

  @override
  List<Widget> buildBody(AppLocalizations l10n) {
    return [
      const SizedBox(height: CtSpacing.ml),
      _CommodityCostResourceBar(
        treasury: treasury,
        remainingTreasury: _remainingTreasury(),
        peasants: peasants,
        remainingPeasants: _remainingPeasants(),
        stockpile: player?.stockpile ?? const Stockpile(),
        committedCommodities: _totalCommodityCosts(),
        commodityIds: resourceBarCommodityIds,
        deficitHint: _deficitHint,
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
    final committed = _totalCommodityCosts();
    final insufficientCommodityIds = <String>{
      for (final input in econ.buildInputs.entries)
        if (!locked && _remainingCommodity(input.key, committed) < input.value)
          input.key,
    };
    return _CommodityCostUnitRow(
      displayName: econ.displayName,
      buildTreasuryCost: econ.buildTreasuryCost,
      buildInputs: econ.buildInputs,
      count: counts[econ.unitTypeId] ?? 0,
      isLocked: locked,
      techRequiredLabel: techRequiredLabel(econ.unitTypeId),
      canIncrement: canAffordIncrement(econ.unitTypeId),
      canDecrement: (counts[econ.unitTypeId] ?? 0) > 0,
      treasuryInsufficient:
          !locked && _remainingTreasury() < econ.buildTreasuryCost,
      peasantInsufficient: !locked && _remainingPeasants() < 1,
      insufficientCommodityIds: insufficientCommodityIds,
      onIncrement: () => increment(econ.unitTypeId),
      onDecrement: () => decrement(econ.unitTypeId),
    );
  }
}
