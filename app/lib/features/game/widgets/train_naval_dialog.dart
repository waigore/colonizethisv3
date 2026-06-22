import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../core/utils/currency_format.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/resource_icon.dart';
import '../utils/commodity_ui_helpers.dart';
import 'train_dialog_base.dart';
import 'train_dialog_chrome.dart';

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

class _TrainNavalDialogState extends TrainDialogBaseState<TrainNavalDialog> {
  @override
  Iterable<String> get unitTypeIds => ShipEconomyCatalog.byId.keys;

  @override
  bool get ordersAreMilitary => false;

  @override
  Map<String, String> get unlockingTechByUnitType => unlockingTechByShipId;

  @override
  String dialogTitle(AppLocalizations l10n) => l10n.trainNaval_title;

  @override
  void emitCommittedOrders(List<BuildUnitOrder> orders) {
    widget.bus.emit(TrainNavalBuildOrdersCommittedEvent(orders: orders));
  }

  int _totalTreasuryCost() {
    var total = 0;
    for (final e in ShipEconomyCatalog.all) {
      total += (counts[e.shipTypeId] ?? 0) * e.buildTreasuryCost;
    }
    return total;
  }

  int _totalPeasantCost() {
    var total = 0;
    for (final e in ShipEconomyCatalog.all) {
      total += (counts[e.shipTypeId] ?? 0);
    }
    return total;
  }

  Map<String, int> _totalCommodityCosts() {
    final totals = <String, int>{};
    for (final e in ShipEconomyCatalog.all) {
      final count = counts[e.shipTypeId] ?? 0;
      if (count <= 0) continue;
      for (final input in e.buildInputs.entries) {
        totals[input.key] = (totals[input.key] ?? 0) + (input.value * count);
      }
    }
    return totals;
  }

  @override
  bool canAffordIncrement(String shipType) {
    final econ = ShipEconomyCatalog.byId[shipType];
    if (econ == null) return false;
    if (isLocked(shipType)) return false;

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

  /// Treasury left after subtracting all currently committed ship costs.
  int _remainingTreasury() => treasury - _totalTreasuryCost();

  /// Peasants left after subtracting all currently committed ship costs.
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
    // `SPEC/ui/train-naval-dialog.md` § Deficit hint.
    return deficits.map((name) => '$name low').join(', ');
  }

  @override
  List<Widget> buildBody(AppLocalizations l10n) {
    return [
      const SizedBox(height: CtSpacing.ml),
      _NavalResourceBar(
        treasury: treasury,
        remainingTreasury: _remainingTreasury(),
        peasants: peasants,
        remainingPeasants: _remainingPeasants(),
        stockpile: player?.stockpile ?? const Stockpile(),
        committedCommodities: _totalCommodityCosts(),
        deficitHint: _deficitHint,
        l10n: l10n,
      ),
      const SizedBox(height: CtSpacing.ml),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final econ in ShipEconomyCatalog.all) _buildShipRow(econ),
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

  Widget _buildShipRow(ShipEconomyEntry econ) {
    final locked = isLocked(econ.shipTypeId);
    final committed = _totalCommodityCosts();
    final insufficientCommodityIds = <String>{
      for (final input in econ.buildInputs.entries)
        if (!locked && _remainingCommodity(input.key, committed) < input.value)
          input.key,
    };
    return _ShipTypeRow(
      econ: econ,
      count: counts[econ.shipTypeId] ?? 0,
      isLocked: locked,
      techRequiredLabel: techRequiredLabel(econ.shipTypeId),
      canIncrement: canAffordIncrement(econ.shipTypeId),
      canDecrement: (counts[econ.shipTypeId] ?? 0) > 0,
      treasuryInsufficient:
          !locked && _remainingTreasury() < econ.buildTreasuryCost,
      peasantInsufficient: !locked && _remainingPeasants() < 1,
      insufficientCommodityIds: insufficientCommodityIds,
      onIncrement: () => increment(econ.shipTypeId),
      onDecrement: () => decrement(econ.shipTypeId),
    );
  }
}

class _NavalResourceBar extends StatelessWidget {
  const _NavalResourceBar({
    required this.treasury,
    required this.remainingTreasury,
    required this.peasants,
    required this.remainingPeasants,
    required this.stockpile,
    required this.committedCommodities,
    required this.deficitHint,
    required this.l10n,
  });

  final int treasury;
  final int remainingTreasury;
  final int peasants;
  final int remainingPeasants;
  final Map<String, int> committedCommodities;
  final Stockpile stockpile;
  final String? deficitHint;
  final AppLocalizations l10n;

  /// Union of all commodities referenced by [ShipEconomyCatalog.buildInputs].
  /// SPEC/ui/train-naval-dialog.md § Resource bar.
  static const _navalCommodityIds = <String>[
    'lumber',
    'fabric',
    'castIron',
    'coal',
  ];

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
              for (final commodityId in _navalCommodityIds)
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
                _label(commodityId),
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

  String _label(String commodityId) {
    return CommodityCatalog.byId[commodityId]?.displayName ?? commodityId;
  }
}

class _ShipTypeRow extends StatelessWidget {
  const _ShipTypeRow({
    required this.econ,
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

  final ShipEconomyEntry econ;
  final int count;
  final bool isLocked;
  final String techRequiredLabel;
  final bool canIncrement;
  final bool canDecrement;

  /// Whether remaining treasury cannot cover one more of this ship.
  final bool treasuryInsufficient;

  /// Whether remaining peasants cannot cover one more of this ship.
  final bool peasantInsufficient;

  /// Commodity ids whose remaining stockpile cannot cover one more of this
  /// ship (each rendered in the danger colour).
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
            _buildStepper(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrainDialogUnitNameLine(
          name: shipTypeDisplayName(econ.shipTypeId),
          isLocked: isLocked,
        ),
        const SizedBox(height: 2),
        _buildCostWrap(l10n),
        ..._buildLockedHint(theme),
      ],
    );
  }

  Widget _buildCostWrap(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        TrainDialogInlineCost(
          icon: const Icon(Icons.payments_outlined, size: 14),
          label: econ.buildTreasuryCost.toString(),
          tooltipMessage: l10n.trainDialog_costTreasuryTooltip,
          isInsufficient: treasuryInsufficient,
        ),
        TrainDialogInlineCost(
          icon: const WorkerIcon(workerType: 'peasant', size: 14),
          label: 1.toString(),
          tooltipMessage: l10n.trainDialog_costPeasantsTooltip,
          isInsufficient: peasantInsufficient,
        ),
        for (final input in econ.buildInputs.entries)
          TrainDialogInlineCost(
            icon: ResourceIcon(commodityId: input.key, size: 14),
            label: input.value.toString(),
            tooltipMessage: commodityIconTooltip(l10n, input.key),
            isInsufficient: insufficientCommodityIds.contains(input.key),
          ),
      ],
    );
  }

  List<Widget> _buildLockedHint(ThemeData theme) {
    if (!isLocked) {
      return const [];
    }
    return [
      const SizedBox(height: 2),
      Text(
        techRequiredLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: EditorialMonoclePalette.muted,
        ),
      ),
    ];
  }

  Widget _buildStepper(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CtNinePatchButton(
          onPressed: isLocked || !canDecrement ? null : onDecrement,
          child: const Text('−'),
        ),
        CtGap.wm,
        SizedBox(
          width: 32,
          child: Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        CtGap.wm,
        CtNinePatchButton(
          onPressed: isLocked || !canIncrement ? null : onIncrement,
          dangerVariant: !isLocked && !canIncrement,
          child: const Text('+'),
        ),
      ],
    );
  }
}
