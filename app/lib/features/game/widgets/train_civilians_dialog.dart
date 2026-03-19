// Train Civilians Dialog. SPEC/ui/train-civilians-dialog.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

class TrainCiviliansDialog extends StatefulWidget {
  const TrainCiviliansDialog({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.currentOrders,
    required this.onOrdersChanged,
  });

  final Game game;
  final String humanPlayerId;
  final Orders currentOrders;
  final void Function(List<BuildUnitOrder> orders) onOrdersChanged;

  @override
  State<TrainCiviliansDialog> createState() => _TrainCiviliansDialogState();
}

class _TrainCiviliansDialogState extends State<TrainCiviliansDialog> {
  late Map<String, int> _counts;

  @override
  void initState() {
    super.initState();
    _counts = {for (final e in CivilianEconomyCatalog.all) e.id: 0};
  }

  Player? get _player {
    for (final p in widget.game.players) {
      if (p.id == widget.humanPlayerId) return p;
    }
    return null;
  }

  bool get _hasCapital => _player?.capitalProvinceId != null;

  int get _treasury => _player?.treasury ?? 0;
  int get _paperStockpile => _player?.stockpile.quantityOf('paper') ?? 0;

  Map<String, bool> get _techUnlocked => _player?.techUnlocked ?? const {};

  bool _isLocked(String unitType) {
    final techId = unlockingTechByCivilianId[unitType];
    if (techId == null) return false;
    return _techUnlocked[techId] != true;
  }

  int _totalTreasuryCost() {
    int total = 0;
    for (final e in CivilianEconomyCatalog.all) {
      total += _counts[e.id]! * e.buildTreasuryCost;
    }
    return total;
  }

  int _totalPaperCost() {
    int total = 0;
    for (final e in CivilianEconomyCatalog.all) {
      final paperQty = e.buildInputs[CommodityCatalog.paper.id] ?? 0;
      total += _counts[e.id]! * paperQty;
    }
    return total;
  }

  bool _canAffordIncrement(String unitType) {
    final econ = CivilianEconomyCatalog.byId[unitType];
    if (econ == null) return false;
    final newTreasuryCost = _totalTreasuryCost() + econ.buildTreasuryCost;
    final newPaperCost =
        _totalPaperCost() + (econ.buildInputs[CommodityCatalog.paper.id] ?? 0);
    return newTreasuryCost <= _treasury && newPaperCost <= _paperStockpile;
  }

  String? get _deficitHint {
    final treasuryDeficit = _totalTreasuryCost() > _treasury;
    final paperDeficit = _totalPaperCost() > _paperStockpile;
    if (treasuryDeficit && paperDeficit) {
      return 'Treasury and Paper low';
    }
    if (treasuryDeficit) return 'Treasury low';
    if (paperDeficit) return 'Paper low';
    return null;
  }

  void _increment(String unitType) {
    if (_isLocked(unitType)) return;
    if (!_canAffordIncrement(unitType)) return;
    setState(() {
      _counts[unitType] = (_counts[unitType] ?? 0) + 1;
    });
  }

  void _decrement(String unitType) {
    if (_counts[unitType] == null || _counts[unitType]! <= 0) return;
    setState(() {
      _counts[unitType] = _counts[unitType]! - 1;
    });
  }

  void _reset() {
    setState(() {
      for (final e in CivilianEconomyCatalog.all) {
        _counts[e.id] = 0;
      }
    });
  }

  void _applyOrders() {
    final orders = <BuildUnitOrder>[];
    final capital = _player?.capitalProvinceId;
    if (capital == null) return;
    for (final e in CivilianEconomyCatalog.all) {
      final count = _counts[e.id] ?? 0;
      for (var i = 0; i < count; i++) {
        orders.add(
          BuildUnitOrder(
            unitType: e.id,
            isMilitary: false,
            spawnProvinceId: capital,
          ),
        );
      }
    }
    widget.onOrdersChanged(orders);
  }

  String _techRequiredLabel(String unitType) {
    final techId = unlockingTechByCivilianId[unitType];
    if (techId == null) return '';
    return 'Requires: ${techDisplayName(techId)}';
  }

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Train Civilians',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _applyOrders();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (!_hasCapital)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No capital set — cannot train units',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            )
          else ...[
            _ResourceBar(
              treasury: _treasury,
              paperStockpile: _paperStockpile,
              deficitHint: _deficitHint,
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (final econ in CivilianEconomyCatalog.all)
                      _UnitTypeRow(
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
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CtNinePatchButton(
                    onPressed: _reset,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResourceBar extends StatelessWidget {
  const _ResourceBar({
    required this.treasury,
    required this.paperStockpile,
    required this.deficitHint,
  });

  final int treasury;
  final int paperStockpile;
  final String? deficitHint;

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Treasury: ${_formatNumber(treasury)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 16),
              Text(
                'Paper: $paperStockpile',
                style: Theme.of(context).textTheme.bodyMedium,
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
}

class _UnitTypeRow extends StatelessWidget {
  const _UnitTypeRow({
    required this.econ,
    required this.count,
    required this.isLocked,
    required this.techRequiredLabel,
    required this.canIncrement,
    required this.canDecrement,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CivilianEconomy econ;
  final int count;
  final bool isLocked;
  final String techRequiredLabel;
  final bool canIncrement;
  final bool canDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final paperQty = econ.buildInputs[CommodityCatalog.paper.id] ?? 0;
    final theme = Theme.of(context);

    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isLocked)
                  Image.asset(
                    'assets/images/ui_icon_lock.png',
                    width: 20,
                    height: 20,
                  ),
                if (isLocked) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    econ.id,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${_formatTreasury(econ.buildTreasuryCost)} + $paperQty Paper',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (isLocked) ...[
              const SizedBox(height: 2),
              Text(
                techRequiredLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
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
                    '$count',
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
            ),
          ],
        ),
      ),
    );
  }

  String _formatTreasury(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}
