// Train Civilians Dialog. SPEC/ui/train-civilians-dialog.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/app_assets.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../core/utils/currency_format.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'train_dialog_base.dart';
import 'train_dialog_chrome.dart';

class TrainCiviliansDialog extends TrainDialogBase {
  const TrainCiviliansDialog({
    super.key,
    required super.game,
    required super.humanPlayerId,
    required super.currentOrders,
    required super.bus,
  });

  /// SPEC/ui/train-civilians-dialog.md — [UiScreenIds.trainCiviliansDialog].
  static const screenId = UiScreenIds.trainCiviliansDialog;

  @override
  State<TrainCiviliansDialog> createState() => _TrainCiviliansDialogState();
}

class _TrainCiviliansDialogState
    extends TrainDialogBaseState<TrainCiviliansDialog> {
  @override
  Iterable<String> get unitTypeIds => CivilianEconomyCatalog.byId.keys;

  @override
  bool get ordersAreMilitary => false;

  @override
  Map<String, String> get unlockingTechByUnitType => unlockingTechByCivilianId;

  @override
  String dialogTitle(AppLocalizations l10n) => l10n.trainCivilians_title;

  @override
  void emitCommittedOrders(List<BuildUnitOrder> orders) {
    widget.bus.emit(TrainCivilianBuildOrdersCommittedEvent(orders: orders));
  }

  int get _paperStockpile => stockpileQty(CommodityCatalog.paper.id);

  int _totalTreasuryCost() {
    int total = 0;
    for (final e in CivilianEconomyCatalog.all) {
      total += (counts[e.id] ?? 0) * e.buildTreasuryCost;
    }
    return total;
  }

  int _totalPaperCost() {
    int total = 0;
    for (final e in CivilianEconomyCatalog.all) {
      final paperQty = e.buildInputs[CommodityCatalog.paper.id] ?? 0;
      total += (counts[e.id] ?? 0) * paperQty;
    }
    return total;
  }

  @override
  bool canAffordIncrement(String unitType) {
    final econ = CivilianEconomyCatalog.byId[unitType];
    if (econ == null) return false;
    final newTreasuryCost = _totalTreasuryCost() + econ.buildTreasuryCost;
    final newPaperCost =
        _totalPaperCost() + (econ.buildInputs[CommodityCatalog.paper.id] ?? 0);
    return newTreasuryCost <= treasury && newPaperCost <= _paperStockpile;
  }

  /// Treasury left after subtracting all currently committed unit costs.
  int _remainingTreasury() => treasury - _totalTreasuryCost();

  /// Paper left after subtracting all currently committed unit costs.
  int _remainingPaper() => _paperStockpile - _totalPaperCost();

  String? get _deficitHint {
    final treasuryDeficit = _totalTreasuryCost() > treasury;
    final paperDeficit = _totalPaperCost() > _paperStockpile;
    if (treasuryDeficit && paperDeficit) {
      return 'Treasury low and Paper low';
    }
    if (treasuryDeficit) return 'Treasury low';
    if (paperDeficit) return 'Paper low';
    return null;
  }

  @override
  List<Widget> buildBody(AppLocalizations l10n) {
    return [
      const TrainDialogSectionDivider(),
      TrainDialogResourceBar(
        entries: [
          TrainDialogResourceEntry(
            label: l10n.trainUnits_treasuryLabel,
            value:
                '${formatTreasuryCurrency(_remainingTreasury())} / '
                '${formatTreasuryCurrency(treasury)}',
          ),
          TrainDialogResourceEntry(
            label: l10n.trainUnits_paperLabel,
            value: '${_remainingPaper()} / $_paperStockpile',
          ),
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
              count: counts[econ.id] ?? 0,
              isLocked: isLocked(econ.id),
              techRequiredLabel: techRequiredLabel(econ.id),
              canIncrement: canAffordIncrement(econ.id),
              canDecrement: (counts[econ.id] ?? 0) > 0,
              treasuryInsufficient:
                  !isLocked(econ.id) &&
                  _remainingTreasury() < econ.buildTreasuryCost,
              paperInsufficient:
                  !isLocked(econ.id) &&
                  _remainingPaper() <
                      (econ.buildInputs[CommodityCatalog.paper.id] ?? 0),
              onIncrement: () => increment(econ.id),
              onDecrement: () => decrement(econ.id),
            ),
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
}

class _UnitTypeRow extends StatelessWidget {
  const _UnitTypeRow({
    required this.econ,
    required this.count,
    required this.isLocked,
    required this.techRequiredLabel,
    required this.canIncrement,
    required this.canDecrement,
    required this.treasuryInsufficient,
    required this.paperInsufficient,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CivilianEconomy econ;
  final int count;
  final bool isLocked;
  final String techRequiredLabel;
  final bool canIncrement;
  final bool canDecrement;

  /// Whether the remaining treasury cannot cover one more of this unit.
  final bool treasuryInsufficient;

  /// Whether the remaining paper cannot cover one more of this unit.
  final bool paperInsufficient;

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final paperQty = econ.buildInputs[CommodityCatalog.paper.id] ?? 0;
    final theme = Theme.of(context);

    return Opacity(
      opacity: isLocked ? kTrainDialogLockedOpacity : 1.0,
      child: TrainDialogUnitRowSurface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildInfo(theme, paperQty)),
            CtGap.wm,
            _buildStepper(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(ThemeData theme, int paperQty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                econ.id,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        _buildCostLine(theme, paperQty),
        ..._buildLockedHint(theme),
      ],
    );
  }

  /// Builds the `£X + N paper` cost line, colouring each resource segment
  /// in [EditorialMonoclePalette.danger] independently when that resource is
  /// insufficient for one more of this unit. Plain-text mirrors the
  /// `trainCivilians_costLine` l10n template (`{treasury} + {paper} paper`).
  Widget _buildCostLine(ThemeData theme, int paperQty) {
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final dangerStyle = TextStyle(color: EditorialMonoclePalette.danger);
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: formatTreasuryCurrency(econ.buildTreasuryCost),
            style: treasuryInsufficient ? dangerStyle : null,
          ),
          const TextSpan(text: ' + '),
          TextSpan(
            text: '$paperQty paper',
            style: paperInsufficient ? dangerStyle : null,
          ),
        ],
      ),
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
