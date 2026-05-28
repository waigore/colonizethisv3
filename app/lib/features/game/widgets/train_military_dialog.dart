import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/resource_icon.dart';
import '../utils/commodity_ui_helpers.dart';
import 'train_unit_dialog_helper.dart';

class TrainMilitaryDialog extends StatefulWidget {
  const TrainMilitaryDialog({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.currentOrders,
    required this.bus,
  });

  /// SPEC/ui/train-military-dialog.md — [UiScreenIds.trainMilitaryDialog].
  static const screenId = UiScreenIds.trainMilitaryDialog;

  final Game game;
  final String humanPlayerId;
  final Orders currentOrders;
  final AppEventBus bus;

  @override
  State<TrainMilitaryDialog> createState() => _TrainMilitaryDialogState();
}

class _TrainMilitaryDialogState extends State<TrainMilitaryDialog> {
  late Map<String, int> _counts;

  @override
  void initState() {
    super.initState();
    _counts = _initialCountsFromOrders();
  }

  Map<String, int> _initialCountsFromOrders() {
    return initialTrainDialogCountsFromOrders(
      unitTypeIds: RegimentEconomyCatalog.byId.keys,
      currentOrders: widget.currentOrders,
      humanPlayerId: widget.humanPlayerId,
      capitalProvinceId: _player?.capitalProvinceId,
      isMilitary: true,
    );
  }

  Player? get _player {
    return trainDialogPlayerById(
      players: widget.game.players,
      playerId: widget.humanPlayerId,
    );
  }

  bool get _hasCapital => trainDialogHasCapital(_player);

  int get _treasury => trainDialogTreasury(_player);
  int get _peasants => _player?.workerPool.peasants ?? 0;
  Map<String, bool> get _techUnlocked => trainDialogTechUnlocked(_player);

  int _stockpileQty(String commodityId) =>
      _player?.stockpile.quantityOf(commodityId) ?? 0;

  bool _isLocked(String unitType) {
    return trainDialogIsLocked(
      unitType: unitType,
      unlockingTechByUnitType: unlockingTechByRegimentId,
      techUnlocked: _techUnlocked,
    );
  }

  int _totalTreasuryCost() {
    var total = 0;
    for (final e in RegimentEconomyCatalog.all) {
      total += (_counts[e.id] ?? 0) * e.buildTreasuryCost;
    }
    return total;
  }

  int _totalPeasantCost() {
    var total = 0;
    for (final e in RegimentEconomyCatalog.all) {
      total += (_counts[e.id] ?? 0);
    }
    return total;
  }

  Map<String, int> _totalCommodityCosts() {
    final totals = <String, int>{};
    for (final e in RegimentEconomyCatalog.all) {
      final count = _counts[e.id] ?? 0;
      if (count <= 0) continue;
      for (final input in e.buildInputs.entries) {
        totals[input.key] = (totals[input.key] ?? 0) + (input.value * count);
      }
    }
    return totals;
  }

  bool _canAffordIncrement(String unitType) {
    final econ = RegimentEconomyCatalog.byId[unitType];
    if (econ == null) return false;
    if (_isLocked(unitType)) return false;

    final newTreasury = _totalTreasuryCost() + econ.buildTreasuryCost;
    final newPeasants = _totalPeasantCost() + 1;
    if (newTreasury > _treasury) return false;
    if (newPeasants > _peasants) return false;

    final totals = _totalCommodityCosts();
    for (final input in econ.buildInputs.entries) {
      totals[input.key] = (totals[input.key] ?? 0) + input.value;
    }
    for (final e in totals.entries) {
      if (e.value > _stockpileQty(e.key)) return false;
    }
    return true;
  }

  String? get _deficitHint {
    final deficits = <String>[];
    if (_totalTreasuryCost() > _treasury) deficits.add('Treasury');
    if (_totalPeasantCost() > _peasants) deficits.add('Peasants');
    final totalComms = _totalCommodityCosts();
    for (final e in totalComms.entries) {
      if (e.value > _stockpileQty(e.key)) {
        deficits.add(commodityDisplayName(e.key));
      }
    }
    if (deficits.isEmpty) return null;
    if (deficits.length == 1) return '${deficits.first} low';
    if (deficits.length == 2) return '${deficits[0]} and ${deficits[1]} low';
    final head = deficits.sublist(0, deficits.length - 1).join(', ');
    return '$head and ${deficits.last} low';
  }

  void _increment(String unitType) {
    if (!_canAffordIncrement(unitType)) return;
    setState(() {
      _counts = incrementTrainDialogCount(_counts, unitType);
    });
  }

  void _decrement(String unitType) {
    if ((_counts[unitType] ?? 0) <= 0) return;
    setState(() {
      _counts = decrementTrainDialogCount(_counts, unitType);
    });
  }

  void _reset() {
    setState(() {
      _counts = resetTrainDialogCounts(_counts);
    });
  }

  void _applyOrders() {
    final capital = _player?.capitalProvinceId;
    if (capital == null) return;
    final orders = materializeTrainDialogOrdersFromCounts(
      orderedUnitTypeIds: RegimentEconomyCatalog.byId.keys,
      counts: _counts,
      capitalProvinceId: capital,
      isMilitary: true,
    );
    widget.bus.emit(TrainMilitaryBuildOrdersCommittedEvent(orders: orders));
  }

  String _techRequiredLabel(String unitType) {
    final techId = unlockingTechByRegimentId[unitType];
    if (techId == null) return '';
    return 'Requires: ${techDisplayName(techId)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _applyOrders();
        }
      },
      child: CtDialogShell(child: _buildDialogContent(context, l10n)),
    );
  }

  Widget _buildDialogContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, l10n),
        const Divider(height: 1),
        if (!_hasCapital)
          _buildNoCapitalMessage(context, l10n)
        else
          ..._buildBody(l10n),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.trainMilitary_title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCapitalMessage(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        l10n.trainUnits_noCapital,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  List<Widget> _buildBody(AppLocalizations l10n) {
    return [
      _MilitaryResourceBar(
        treasury: _treasury,
        peasants: _peasants,
        stockpile: _player?.stockpile ?? const Stockpile(),
        deficitHint: _deficitHint,
        l10n: l10n,
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final econ in RegimentEconomyCatalog.all)
              _RegimentRow(
                econ: econ,
                count: _counts[econ.id] ?? 0,
                isLocked: _isLocked(econ.id),
                techRequiredLabel: _techRequiredLabel(econ.id),
                canIncrement: _canAffordIncrement(econ.id),
                canDecrement: (_counts[econ.id] ?? 0) > 0,
                onIncrement: () => _increment(econ.id),
                onDecrement: () => _decrement(econ.id),
              ),
          ],
        ),
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CtNinePatchButton(
              onPressed: _reset,
              child: Text(l10n.common_reset),
            ),
          ],
        ),
      ),
    ];
  }
}

class _MilitaryResourceBar extends StatelessWidget {
  const _MilitaryResourceBar({
    required this.treasury,
    required this.peasants,
    required this.stockpile,
    required this.deficitHint,
    required this.l10n,
  });

  final int treasury;
  final int peasants;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _ResourceChip(child: Text(l10n.trainUnits_treasury('$treasury'))),
              _ResourceChip(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WorkerIcon(workerType: 'peasant', size: 14),
                    const SizedBox(width: 4),
                    Text(l10n.trainUnits_peasants(peasants)),
                  ],
                ),
              ),
              for (final commodityId in _militaryCommodityIds)
                _ResourceChip(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResourceIcon(commodityId: commodityId, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        l10n.trainMilitary_commodityAmount(
                          _label(commodityId),
                          stockpile.quantityOf(commodityId),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (deficitHint != null) ...[
            const SizedBox(height: 4),
            Text(
              deficitHint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _label(String commodityId) {
    return CommodityCatalog.byId[commodityId]?.displayName ?? commodityId;
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: child,
      ),
    );
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
    required this.onIncrement,
    required this.onDecrement,
  });

  final RegimentEconomy econ;
  final int count;
  final bool isLocked;
  final String techRequiredLabel;
  final bool canIncrement;
  final bool canDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 2),
            _buildCostWrap(),
            ..._buildLockedHint(theme),
            const SizedBox(height: 4),
            _buildStepper(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            regimentTypeDisplayName(econ.id),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          econ.buildTreasuryCost.toString(),
          style: theme.textTheme.bodyMedium,
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
        ),
        _InlineCost(
          icon: const WorkerIcon(workerType: 'peasant', size: 14),
          label: 1.toString(),
        ),
        for (final input in econ.buildInputs.entries)
          _InlineCost(
            icon: ResourceIcon(commodityId: input.key, size: 14),
            label: input.value.toString(),
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
          color: theme.colorScheme.error,
        ),
      ),
    ];
  }

  Widget _buildStepper(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CtNinePatchButton(
          onPressed: isLocked || !canDecrement ? null : onDecrement,
          child: const Text('−'),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(width: 8),
        CtNinePatchButton(
          onPressed: isLocked || !canIncrement ? null : onIncrement,
          child: const Text('+'),
        ),
      ],
    );
  }
}

class _InlineCost extends StatelessWidget {
  const _InlineCost({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
