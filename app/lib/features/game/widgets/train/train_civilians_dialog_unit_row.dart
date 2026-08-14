// Per-unit-type row for [TrainCiviliansDialog]. Refs #3878, #4366.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../widgets/ct_gap.dart';
import 'train_civilian_role_display.dart';
import 'train_dialog_chrome.dart';

/// One trainable civilian unit row with treasury + paper cost line.
class TrainCiviliansDialogUnitRow extends StatelessWidget {
  const TrainCiviliansDialogUnitRow({
    super.key,
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
            Expanded(child: _buildInfo(context, theme, paperQty)),
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

  Widget _buildInfo(BuildContext context, ThemeData theme, int paperQty) {
    final l10n = appL10n(context);
    final gist = TrainCivilianRoleDisplay.roleGist(l10n, econ.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrainDialogUnitNameLine(name: econ.id, isLocked: isLocked),
        if (gist.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            gist,
            style: TextStyle(
              fontSize: 10,
              color: EditorialMonoclePalette.muted,
            ),
          ),
        ],
        const SizedBox(height: 2),
        _buildCostLine(theme, paperQty),
        TrainDialogLockedHint(
          isLocked: isLocked,
          techRequiredLabel: techRequiredLabel,
        ),
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
}
