import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../core/utils/currency_format.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/resource_icon.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../../../config/app_assets.dart';
import '../utils/commodity_ui_helpers.dart';
import 'train_dialog_chrome.dart';
import 'train_unit_dialog_helper.dart';

/// Train-at-capital dialog for naval (ship) units. Mirrors the civilian and
/// military train dialogs: a `remaining / total` resource bar, per-row cost
/// segments that turn red when a resource cannot cover one more ship, and a
/// danger-styled disabled `[+]` stepper for unaffordable rows. Ships are built
/// with `isMilitary: false` (their own unit category) and spawn into the
/// player's home fleet at the capital. SPEC/ui/train-naval-dialog.md.
class TrainNavalDialog extends StatefulWidget {
  const TrainNavalDialog({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.currentOrders,
    required this.bus,
  });

  /// SPEC/ui/train-naval-dialog.md — [UiScreenIds.trainNavalDialog].
  static const screenId = UiScreenIds.trainNavalDialog;

  final Game game;
  final String humanPlayerId;
  final Orders currentOrders;
  final AppEventBus bus;

  @override
  State<TrainNavalDialog> createState() => _TrainNavalDialogState();
}

class _TrainNavalDialogState extends State<TrainNavalDialog> {
  late Map<String, int> _counts;

  @override
  void initState() {
    super.initState();
    _counts = _initialCountsFromOrders();
  }

  Map<String, int> _initialCountsFromOrders() {
    return initialTrainDialogCountsFromOrders(
      unitTypeIds: ShipEconomyCatalog.byId.keys,
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
  int get _peasants => _player?.workerPool.peasants ?? 0;
  Map<String, bool> get _techUnlocked => trainDialogTechUnlocked(_player);

  int _stockpileQty(String commodityId) =>
      _player?.stockpile.quantityOf(commodityId) ?? 0;

  bool _isLocked(String shipType) {
    return trainDialogIsLocked(
      unitType: shipType,
      unlockingTechByUnitType: unlockingTechByShipId,
      techUnlocked: _techUnlocked,
    );
  }

  int _totalTreasuryCost() {
    var total = 0;
    for (final e in ShipEconomyCatalog.all) {
      total += (_counts[e.shipTypeId] ?? 0) * e.buildTreasuryCost;
    }
    return total;
  }

  int _totalPeasantCost() {
    var total = 0;
    for (final e in ShipEconomyCatalog.all) {
      total += (_counts[e.shipTypeId] ?? 0);
    }
    return total;
  }

  Map<String, int> _totalCommodityCosts() {
    final totals = <String, int>{};
    for (final e in ShipEconomyCatalog.all) {
      final count = _counts[e.shipTypeId] ?? 0;
      if (count <= 0) continue;
      for (final input in e.buildInputs.entries) {
        totals[input.key] = (totals[input.key] ?? 0) + (input.value * count);
      }
    }
    return totals;
  }

  bool _canAffordIncrement(String shipType) {
    final econ = ShipEconomyCatalog.byId[shipType];
    if (econ == null) return false;
    if (_isLocked(shipType)) return false;

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

  /// Treasury left after subtracting all currently committed ship costs.
  int _remainingTreasury() => _treasury - _totalTreasuryCost();

  /// Peasants left after subtracting all currently committed ship costs.
  int _remainingPeasants() => _peasants - _totalPeasantCost();

  /// Stockpile of [commodityId] left after subtracting committed costs.
  int _remainingCommodity(String commodityId, Map<String, int> committed) =>
      _stockpileQty(commodityId) - (committed[commodityId] ?? 0);

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

  void _increment(String shipType) {
    if (!_canAffordIncrement(shipType)) return;
    setState(() {
      _counts = incrementTrainDialogCount(_counts, shipType);
    });
  }

  void _decrement(String shipType) {
    if ((_counts[shipType] ?? 0) <= 0) return;
    setState(() {
      _counts = decrementTrainDialogCount(_counts, shipType);
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
      orderedUnitTypeIds: ShipEconomyCatalog.byId.keys,
      counts: _counts,
      capitalProvinceId: capital,
      isMilitary: false,
    );
    widget.bus.emit(TrainNavalBuildOrdersCommittedEvent(orders: orders));
  }

  String _techRequiredLabel(String shipType) {
    final techId = unlockingTechByShipId[shipType];
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
        padding: const EdgeInsets.fromLTRB(
          CtSpacing.l,
          CtSpacing.ml,
          CtSpacing.l,
          CtSpacing.l,
        ),
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
          title: l10n.trainNaval_title,
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
      _NavalResourceBar(
        treasury: _treasury,
        remainingTreasury: _remainingTreasury(),
        peasants: _peasants,
        remainingPeasants: _remainingPeasants(),
        stockpile: _player?.stockpile ?? const Stockpile(),
        committedCommodities: _totalCommodityCosts(),
        deficitHint: _deficitHint,
        l10n: l10n,
      ),
      const TrainDialogSectionDivider(),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final econ in ShipEconomyCatalog.all) _buildShipRow(econ),
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

  Widget _buildShipRow(ShipEconomyEntry econ) {
    final locked = _isLocked(econ.shipTypeId);
    final committed = _totalCommodityCosts();
    final insufficientCommodityIds = <String>{
      for (final input in econ.buildInputs.entries)
        if (!locked && _remainingCommodity(input.key, committed) < input.value)
          input.key,
    };
    return _ShipTypeRow(
      econ: econ,
      count: _counts[econ.shipTypeId] ?? 0,
      isLocked: locked,
      techRequiredLabel: _techRequiredLabel(econ.shipTypeId),
      canIncrement: _canAffordIncrement(econ.shipTypeId),
      canDecrement: (_counts[econ.shipTypeId] ?? 0) > 0,
      treasuryInsufficient:
          !locked && _remainingTreasury() < econ.buildTreasuryCost,
      peasantInsufficient: !locked && _remainingPeasants() < 1,
      insufficientCommodityIds: insufficientCommodityIds,
      onIncrement: () => _increment(econ.shipTypeId),
      onDecrement: () => _decrement(econ.shipTypeId),
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
            shipTypeDisplayName(econ.shipTypeId),
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
  /// flag that the remaining stockpile cannot cover one more of this ship.
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
