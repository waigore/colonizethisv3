import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../core/utils/currency_format.dart';
import '../../../l10n/l10n.dart';
import '../../../config/app_assets.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/resource_icon.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../utils/commodity_ui_helpers.dart';
import 'train_dialog_base.dart';
import 'train_dialog_chrome.dart';

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
    extends TrainDialogBaseState<TrainMilitaryDialog> {
  @override
  Iterable<String> get unitTypeIds => RegimentEconomyCatalog.byId.keys;

  @override
  bool get ordersAreMilitary => true;

  @override
  Map<String, String> get unlockingTechByUnitType => unlockingTechByRegimentId;

  @override
  String dialogTitle(AppLocalizations l10n) => l10n.trainMilitary_title;

  @override
  void emitCommittedOrders(List<BuildUnitOrder> orders) {
    widget.bus.emit(TrainMilitaryBuildOrdersCommittedEvent(orders: orders));
  }

  int _totalTreasuryCost() {
    var total = 0;
    for (final e in RegimentEconomyCatalog.all) {
      total += (counts[e.id] ?? 0) * e.buildTreasuryCost;
    }
    return total;
  }

  int _totalPeasantCost() {
    var total = 0;
    for (final e in RegimentEconomyCatalog.all) {
      total += (counts[e.id] ?? 0);
    }
    return total;
  }

  Map<String, int> _totalCommodityCosts() {
    final totals = <String, int>{};
    for (final e in RegimentEconomyCatalog.all) {
      final count = counts[e.id] ?? 0;
      if (count <= 0) continue;
      for (final input in e.buildInputs.entries) {
        totals[input.key] = (totals[input.key] ?? 0) + (input.value * count);
      }
    }
    return totals;
  }

  @override
  bool canAffordIncrement(String unitType) {
    final econ = RegimentEconomyCatalog.byId[unitType];
    if (econ == null) return false;
    if (isLocked(unitType)) return false;

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

  /// Treasury left after subtracting all currently committed regiment costs.
  int _remainingTreasury() => treasury - _totalTreasuryCost();

  /// Peasants left after subtracting all currently committed regiment costs.
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
    if (deficits.length == 1) return '${deficits.first} low';
    if (deficits.length == 2) return '${deficits[0]} and ${deficits[1]} low';
    final head = deficits.sublist(0, deficits.length - 1).join(', ');
    return '$head and ${deficits.last} low';
  }

  @override
  List<Widget> buildBody(AppLocalizations l10n) {
    return [
      const TrainDialogSectionDivider(),
      _MilitaryResourceBar(
        treasury: treasury,
        remainingTreasury: _remainingTreasury(),
        peasants: peasants,
        remainingPeasants: _remainingPeasants(),
        stockpile: player?.stockpile ?? const Stockpile(),
        committedCommodities: _totalCommodityCosts(),
        deficitHint: _deficitHint,
        l10n: l10n,
      ),
      const TrainDialogSectionDivider(),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final econ in RegimentEconomyCatalog.all)
            _buildRegimentRow(econ),
        ],
      ),
      const TrainDialogSectionDivider(),
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

  Widget _buildRegimentRow(RegimentEconomy econ) {
    final locked = isLocked(econ.id);
    final committed = _totalCommodityCosts();
    final insufficientCommodityIds = <String>{
      for (final input in econ.buildInputs.entries)
        if (!locked && _remainingCommodity(input.key, committed) < input.value)
          input.key,
    };
    return _RegimentRow(
      econ: econ,
      count: counts[econ.id] ?? 0,
      isLocked: locked,
      techRequiredLabel: techRequiredLabel(econ.id),
      canIncrement: canAffordIncrement(econ.id),
      canDecrement: (counts[econ.id] ?? 0) > 0,
      treasuryInsufficient:
          !locked && _remainingTreasury() < econ.buildTreasuryCost,
      peasantInsufficient: !locked && _remainingPeasants() < 1,
      insufficientCommodityIds: insufficientCommodityIds,
      onIncrement: () => increment(econ.id),
      onDecrement: () => decrement(econ.id),
    );
  }
}

class _MilitaryResourceBar extends StatelessWidget {
  const _MilitaryResourceBar({
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

  static const _militaryCommodityIds = <String>[
    'fabric',
    'castIron',
    'lumber',
    'horses',
    'steel',
    'bronze',
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
              for (final commodityId in _militaryCommodityIds)
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

class _RegimentRow extends StatelessWidget {
  const _RegimentRow({
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

  final RegimentEconomy econ;
  final int count;
  final bool isLocked;
  final String techRequiredLabel;
  final bool canIncrement;
  final bool canDecrement;

  /// Whether remaining treasury cannot cover one more of this regiment.
  final bool treasuryInsufficient;

  /// Whether remaining peasants cannot cover one more of this regiment.
  final bool peasantInsufficient;

  /// Commodity ids whose remaining stockpile cannot cover one more of this
  /// regiment (each rendered in the danger colour).
  final Set<String> insufficientCommodityIds;

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: isLocked ? kTrainDialogLockedOpacity : 1.0,
      child: TrainDialogUnitRowSurface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildInfo(theme)),
            CtGap.wm,
            _buildStepper(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 2),
        _buildCostWrap(),
        ..._buildLockedHint(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        if (isLocked) ...[
          StrictAssetIcon(
            assetPath: '${kAppIconAssetPrefix}ui_icon_lock.png',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            regimentTypeDisplayName(econ.id),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _InlineCost(
          icon: const Icon(Icons.payments_outlined, size: 14),
          label: econ.buildTreasuryCost.toString(),
          isInsufficient: treasuryInsufficient,
        ),
        _InlineCost(
          icon: const WorkerIcon(workerType: 'peasant', size: 14),
          label: 1.toString(),
          isInsufficient: peasantInsufficient,
        ),
        for (final input in econ.buildInputs.entries)
          _InlineCost(
            icon: ResourceIcon(commodityId: input.key, size: 14),
            label: input.value.toString(),
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

class _InlineCost extends StatelessWidget {
  const _InlineCost({
    required this.icon,
    required this.label,
    this.isInsufficient = false,
  });

  final Widget icon;
  final String label;

  /// When `true`, the label renders in [EditorialMonoclePalette.danger] to
  /// flag that the remaining stockpile cannot cover one more of this unit.
  final bool isInsufficient;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall;
    final style = isInsufficient
        ? (baseStyle ?? const TextStyle()).copyWith(
            color: EditorialMonoclePalette.danger,
          )
        : baseStyle;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 3),
        Text(label, style: style),
      ],
    );
  }
}
