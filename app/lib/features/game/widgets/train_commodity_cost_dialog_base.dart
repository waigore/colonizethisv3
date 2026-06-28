// Shared base for the commodity-cost train-at-capital dialogs (military, naval).
// SPEC/ui/train-military-dialog.md, SPEC/ui/train-naval-dialog.md,
// SPEC/ui/components/train-dialog-chrome.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../core/utils/currency_format.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/resource_icon.dart';
import '../utils/commodity_ui_helpers.dart';
import 'train_dialog_base.dart';
import 'train_dialog_chrome.dart';

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

/// Treasury / peasants / commodity chip resource bar shared by the military and
/// naval train dialogs (icon chips, not the civilian label/value entry bar).
class _CommodityCostResourceBar extends StatelessWidget {
  const _CommodityCostResourceBar({
    required this.treasury,
    required this.remainingTreasury,
    required this.peasants,
    required this.remainingPeasants,
    required this.stockpile,
    required this.committedCommodities,
    required this.commodityIds,
    required this.deficitHint,
    required this.l10n,
  });

  final int treasury;
  final int remainingTreasury;
  final int peasants;
  final int remainingPeasants;
  final Map<String, int> committedCommodities;
  final Stockpile stockpile;
  final List<String> commodityIds;
  final String? deficitHint;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrainDialogResourceBarBox(
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _buildTreasuryChip(),
              _buildPeasantsChip(),
              for (final commodityId in commodityIds)
                _buildCommodityChip(commodityId),
            ],
          ),
        ),
        ..._buildDeficitHint(context),
      ],
    );
  }

  Widget _buildTreasuryChip() {
    return TrainDialogResourceChip(
      child: Text(
        l10n.trainUnits_treasury(
          '${formatTreasuryCurrency(remainingTreasury)} / '
          '${formatTreasuryCurrency(treasury)}',
        ),
      ),
    );
  }

  Widget _buildPeasantsChip() {
    return TrainDialogResourceChip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WorkerIcon(workerType: 'peasant', size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.trainUnits_peasantsValue('$remainingPeasants / $peasants'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommodityChip(String commodityId) {
    return TrainDialogResourceChip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResourceIcon(commodityId: commodityId, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.trainMilitary_commodityValue(
                commodityDisplayName(commodityId),
                '${stockpile.quantityOf(commodityId) - (committedCommodities[commodityId] ?? 0)}'
                ' / ${stockpile.quantityOf(commodityId)}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeficitHint(BuildContext context) {
    if (deficitHint == null) return const [];
    return [
      const SizedBox(height: 4),
      Text(
        deficitHint!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: EditorialMonoclePalette.danger,
        ),
      ),
    ];
  }
}

/// A single commodity-cost trainable unit row (name over a cost wrap, with the
/// shared [TrainDialogStepper] on the right) shared by the military and naval
/// train dialogs.
class _CommodityCostUnitRow extends StatelessWidget {
  const _CommodityCostUnitRow({
    required this.displayName,
    required this.buildTreasuryCost,
    required this.buildInputs,
    required this.count,
    required this.isLocked,
    required this.techRequiredLabel,
    required this.canIncrement,
    required this.canDecrement,
    required this.treasuryInsufficient,
    required this.peasantInsufficient,
    required this.insufficientCommodityIds,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String displayName;
  final int buildTreasuryCost;
  final Map<String, int> buildInputs;
  final int count;
  final bool isLocked;
  final String techRequiredLabel;
  final bool canIncrement;
  final bool canDecrement;

  /// Whether remaining treasury cannot cover one more of this unit.
  final bool treasuryInsufficient;

  /// Whether remaining peasants cannot cover one more of this unit.
  final bool peasantInsufficient;

  /// Commodity ids whose remaining stockpile cannot cover one more of this
  /// unit (each rendered in the danger colour).
  final Set<String> insufficientCommodityIds;

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10n(context);
    return Opacity(
      opacity: isLocked ? kTrainDialogLockedOpacity : 1.0,
      child: TrainDialogUnitRowSurface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildInfo(theme, l10n)),
            CtGap.wm,
            TrainDialogStepper(
              count: count,
              isLocked: isLocked,
              canIncrement: canIncrement,
              canDecrement: canDecrement,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrainDialogUnitNameLine(name: displayName, isLocked: isLocked),
        const SizedBox(height: 2),
        _buildCostWrap(l10n),
        TrainDialogLockedHint(
          isLocked: isLocked,
          techRequiredLabel: techRequiredLabel,
        ),
      ],
    );
  }

  Widget _buildCostWrap(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        TrainDialogInlineCost(
          icon: const Icon(
            Icons.payments_outlined,
            size: kTrainDialogCostIconSize,
          ),
          label: buildTreasuryCost.toString(),
          tooltipMessage: l10n.trainDialog_costTreasuryTooltip,
          isInsufficient: treasuryInsufficient,
        ),
        TrainDialogInlineCost(
          icon: const WorkerIcon(
            workerType: 'peasant',
            size: kTrainDialogCostIconSize,
          ),
          label: 1.toString(),
          tooltipMessage: l10n.trainDialog_costPeasantsTooltip,
          isInsufficient: peasantInsufficient,
        ),
        for (final input in buildInputs.entries)
          TrainDialogInlineCost(
            icon: ResourceIcon(
              commodityId: input.key,
              size: kTrainDialogCostIconSize,
            ),
            label: input.value.toString(),
            tooltipMessage: commodityIconTooltip(l10n, input.key),
            isInsufficient: insufficientCommodityIds.contains(input.key),
          ),
      ],
    );
  }
}
