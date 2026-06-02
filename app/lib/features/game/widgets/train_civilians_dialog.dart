// Train Civilians Dialog. SPEC/ui/train-civilians-dialog.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/app_assets.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'train_dialog_chrome.dart';
import 'train_unit_dialog_helper.dart';

class TrainCiviliansDialog extends StatefulWidget {
  const TrainCiviliansDialog({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.currentOrders,
    required this.bus,
  });

  /// SPEC/ui/train-civilians-dialog.md — [UiScreenIds.trainCiviliansDialog].
  static const screenId = UiScreenIds.trainCiviliansDialog;

  final Game game;
  final String humanPlayerId;
  final Orders currentOrders;
  final AppEventBus bus;

  @override
  State<TrainCiviliansDialog> createState() => _TrainCiviliansDialogState();
}

class _TrainCiviliansDialogState extends State<TrainCiviliansDialog> {
  late Map<String, int> _counts;

  @override
  void initState() {
    super.initState();
    _counts = _initialCountsFromOrders();
  }

  /// Counts pending train-at-capital civilian builds from [widget.currentOrders].
  Map<String, int> _initialCountsFromOrders() {
    return initialTrainDialogCountsFromOrders(
      unitTypeIds: CivilianEconomyCatalog.byId.keys,
      currentOrders: widget.currentOrders,
      humanPlayerId: widget.humanPlayerId,
      capitalProvinceId: _player?.capitalProvinceId,
      isMilitary: false,
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
  int get _paperStockpile => _player?.stockpile.quantityOf('paper') ?? 0;

  Map<String, bool> get _techUnlocked => trainDialogTechUnlocked(_player);

  bool _isLocked(String unitType) {
    return trainDialogIsLocked(
      unitType: unitType,
      unlockingTechByUnitType: unlockingTechByCivilianId,
      techUnlocked: _techUnlocked,
    );
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
      _counts = incrementTrainDialogCount(_counts, unitType);
    });
  }

  void _decrement(String unitType) {
    if (_counts[unitType] == null || _counts[unitType]! <= 0) return;
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
      orderedUnitTypeIds: CivilianEconomyCatalog.byId.keys,
      counts: _counts,
      capitalProvinceId: capital,
      isMilitary: false,
    );
    widget.bus.emit(TrainCivilianBuildOrdersCommittedEvent(orders: orders));
  }

  String _techRequiredLabel(String unitType) {
    final techId = unlockingTechByCivilianId[unitType];
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
      child: CtDialogShell(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: _buildDialogContent(context, l10n),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainDialogHeader(
          title: l10n.trainCivilians_title,
          onClose: () => Navigator.of(context).pop(),
        ),
        if (!_hasCapital) ...[
          const TrainDialogSectionDivider(),
          _buildNoCapitalMessage(context, l10n),
        ] else
          ..._buildBody(l10n),
      ],
    );
  }

  Widget _buildNoCapitalMessage(BuildContext context, AppLocalizations l10n) {
    return Text(
      l10n.trainUnits_noCapital,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: EditorialMonoclePalette.danger,
      ),
    );
  }

  List<Widget> _buildBody(AppLocalizations l10n) {
    return [
      const TrainDialogSectionDivider(),
      TrainDialogResourceBar(
        lines: [
          l10n.trainUnits_treasury(_formatTreasury(_treasury)),
          l10n.trainUnits_paper(_paperStockpile),
        ],
        deficitHint: _deficitHint,
      ),
      const TrainDialogSectionDivider(),
      Column(
        mainAxisSize: MainAxisSize.min,
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
      const TrainDialogSectionDivider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CtNinePatchButton(
            onPressed: _reset,
            child: Text(l10n.common_reset),
          ),
        ],
      ),
    ];
  }

  String _formatTreasury(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
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
      opacity: isLocked ? kTrainDialogLockedOpacity : 1.0,
      child: TrainDialogUnitRowSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme, paperQty),
            ..._buildLockedHint(theme),
            const SizedBox(height: 4),
            _buildStepper(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, int paperQty) {
    return Row(
      children: [
        if (isLocked)
          StrictAssetIcon(
            assetPath: '${kAppIconAssetPrefix}ui_icon_lock.png',
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
          appL10n(context).trainCivilians_costLine(
            _formatTreasury(econ.buildTreasuryCost),
            paperQty.toString(),
          ),
          style: theme.textTheme.bodyMedium,
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

  String _formatTreasury(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}
