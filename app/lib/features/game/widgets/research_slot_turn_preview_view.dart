// Per-slot research turn-preview view for the GAME40001 Technology panel
// (Refs #3512): dual-segment progress bar (committed + anticipated), the
// monospace RP progress label, a green anticipated-RP delta that opens a
// breakdown dialog, and a treasury (gold) row with a signed per-turn delta.
//
// Split out of `technology_panel.dart` so that file stays under the
// `repo.game_widgets_file_size` cap.
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview.

import 'package:flutter/material.dart';

import '../../../config/app_assets.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_resource_cell.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../utils/research_slot_preview.dart';
import 'technology_slot_funding_toggles.dart';

/// Treasury-coin glyph shared with the trade screen / game tab-bar treasury
/// chip. SPEC/ui/technology-panel.md § Slot turn preview.
const String _kTreasuryCoinAsset = '${kAppIconAssetPrefix}ui_icon_treasury_coin.png';

/// Renders the committed/anticipated progress bar, RP progress label + delta,
/// and the treasury (gold) row for one assigned, editable research slot.
class ResearchSlotTurnPreviewView extends StatelessWidget {
  const ResearchSlotTurnPreviewView({
    super.key,
    required this.slotIndex,
    required this.preview,
  });

  final int slotIndex;
  final ResearchSlotTurnPreview preview;

  /// Stable test key for the green anticipated-RP delta control.
  static Key rpDeltaKey(int slotIndex) =>
      ValueKey<String>('techSlotRpDelta_$slotIndex');

  /// Stable test key for the treasury (gold) preview row.
  static Key goldRowKey(int slotIndex) =>
      ValueKey<String>('techSlotGoldRow_$slotIndex');

  /// Stable test key for the anticipated (segment B) progress fill.
  static Key anticipatedSegmentKey(int slotIndex) =>
      ValueKey<String>('techSlotAnticipatedSegment_$slotIndex');

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ResearchDualSegmentBar(
                committedFraction: preview.committedFraction,
                anticipatedFraction: preview.anticipatedFraction,
                anticipatedSegmentKey: anticipatedSegmentKey(slotIndex),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.technologyPanel_slotRpProgress(
                preview.committedProgress,
                preview.cost,
              ),
              style: _monoStyle(EditorialMonoclePalette.accentDim),
            ),
            if (preview.showsAnticipatedSegment) ...[
              const SizedBox(width: 6),
              _RpDeltaControl(
                key: rpDeltaKey(slotIndex),
                preview: preview,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        _GoldPreviewRow(
          key: goldRowKey(slotIndex),
          preview: preview,
        ),
      ],
    );
  }
}

TextStyle _monoStyle(Color color) => TextStyle(
  color: color,
  fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  fontSize: 10,
);

/// Green `+N RP` anticipated-delta chip that opens the breakdown dialog.
class _RpDeltaControl extends StatelessWidget {
  const _RpDeltaControl({super.key, required this.preview});

  final ResearchSlotTurnPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return InkWell(
      onTap: () => showResearchFundingBreakdownDialog(
        context: context,
        preview: preview,
      ),
      child: Text(
        l10n.technologyPanel_rpDeltaPreview(preview.anticipatedRpPerTurn),
        style: _monoStyle(EditorialMonoclePalette.success),
      ),
    );
  }
}

/// Treasury (gold) per-turn cost row with a signed delta. When the slot is
/// debt-blocked the per-turn cost is shown greyed with a zero delta (no spend
/// will occur). SPEC/ui/technology-panel.md § Slot turn preview.
class _GoldPreviewRow extends StatelessWidget {
  const _GoldPreviewRow({super.key, required this.preview});

  final ResearchSlotTurnPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    if (preview.isNoneFunding) {
      return const SizedBox.shrink();
    }
    final bool spends = preview.goldSpentThisTurn > 0;
    // Spending gold is a negative treasury delta (danger colour per
    // CtResourceCell rules); debt-blocked shows the cost greyed with no spend.
    final Color color = spends
        ? (CtResourceCell.deltaColor(-preview.goldSpentThisTurn) ??
              EditorialMonoclePalette.muted)
        : EditorialMonoclePalette.muted;
    final String label = spends
        ? l10n.technologyPanel_goldSpendPerTurn(preview.goldCostPerTurn)
        : l10n.technologyPanel_goldNoSpendPerTurn(preview.goldCostPerTurn);
    return Row(
      children: [
        StrictAssetIcon(
          assetPath: _kTreasuryCoinAsset,
          width: 14,
          height: 14,
        ),
        const SizedBox(width: 5),
        Text(label, style: _monoStyle(color)),
      ],
    );
  }
}

/// Dual-segment research progress bar: committed RP (segment A, `--accent`)
/// followed by anticipated RP this turn (segment B, a subtler `--accent` tint
/// animated on width). Mirrors the single-segment `CtProgressBar` geometry
/// (12 dp tall, 1 px `--accent-dim` border, `--surface` track).
class _ResearchDualSegmentBar extends StatelessWidget {
  const _ResearchDualSegmentBar({
    required this.committedFraction,
    required this.anticipatedFraction,
    required this.anticipatedSegmentKey,
  });

  final double committedFraction;
  final double anticipatedFraction;
  final Key anticipatedSegmentKey;

  static const double height = 12;
  static const double borderWidth = 1;
  static const Duration animationDuration = Duration(milliseconds: 120);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double trackWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
        final double innerWidth =
            (trackWidth - 2 * borderWidth).clamp(0.0, trackWidth);
        final double committedWidth =
            (innerWidth * committedFraction.clamp(0.0, 1.0)).clamp(
          0.0,
          innerWidth,
        );
        final double anticipatedWidth =
            (innerWidth * anticipatedFraction.clamp(0.0, 1.0)).clamp(
          0.0,
          innerWidth - committedWidth,
        );
        return SizedBox(
          height: height,
          width: trackWidth,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              const _DualSegmentTrack(),
              _DualSegmentFill(
                committedWidth: committedWidth,
                anticipatedWidth: anticipatedWidth,
                anticipatedSegmentKey: anticipatedSegmentKey,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Static track (surface fill + `--accent-dim` border) behind both segments.
class _DualSegmentTrack extends StatelessWidget {
  const _DualSegmentTrack();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border.all(
          color: EditorialMonoclePalette.accentDim,
          width: _ResearchDualSegmentBar.borderWidth,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Committed (segment A) + anticipated (segment B, animated) fill row, inset by
/// the track border so the segments sit inside the 1 px frame.
class _DualSegmentFill extends StatelessWidget {
  const _DualSegmentFill({
    required this.committedWidth,
    required this.anticipatedWidth,
    required this.anticipatedSegmentKey,
  });

  final double committedWidth;
  final double anticipatedWidth;
  final Key anticipatedSegmentKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_ResearchDualSegmentBar.borderWidth),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (committedWidth > 0)
              SizedBox(
                width: committedWidth,
                height: double.infinity,
                child: ColoredBox(color: EditorialMonoclePalette.accent),
              ),
            if (anticipatedWidth > 0)
              AnimatedContainer(
                key: anticipatedSegmentKey,
                duration: _ResearchDualSegmentBar.animationDuration,
                curve: Curves.easeOut,
                width: anticipatedWidth,
                height: double.infinity,
                color:
                    EditorialMonoclePalette.accent.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}

/// Opens the research-funding breakdown dialog explaining the anticipated RP
/// (base funding RP, the +20% industrial bonus when applicable, the effective
/// total, the treasury cost, and a debt-block note when the spend is blocked).
///
/// SPEC/ui/technology-panel.md § Slot turn preview.
void showResearchFundingBreakdownDialog({
  required BuildContext context,
  required ResearchSlotTurnPreview preview,
}) {
  showDialog<void>(
    context: context,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (ctx) => ResearchFundingBreakdownDialog(preview: preview),
  );
}

/// Read-only research-funding breakdown modal. SPEC/ui/technology-panel.md
/// § Slot turn preview.
@visibleForTesting
class ResearchFundingBreakdownDialog extends StatelessWidget {
  const ResearchFundingBreakdownDialog({super.key, required this.preview});

  final ResearchSlotTurnPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return CtDialogShell(
      maxWidth: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.technologyPanel_rpBreakdownTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: EditorialMonoclePalette.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CtSpacing.m),
          _BreakdownRow(
            label: l10n.technologyPanel_rpBreakdownBaseLabel(
              fundingLevelLabel(l10n, preview.funding),
            ),
            value: l10n.technologyPanel_rpValue(preview.baseRpPerTurn),
          ),
          if (preview.hasIndustrialBonus)
            _BreakdownRow(
              label: l10n.technologyPanel_rpBreakdownIndustrialLabel,
              value: l10n.technologyPanel_rpValue(
                preview.industrialBonusRpPerTurn,
              ),
            ),
          _BreakdownRow(
            label: l10n.technologyPanel_rpBreakdownEffectiveLabel,
            value: l10n.technologyPanel_rpValue(preview.effectiveRpPerTurn),
            emphasised: true,
          ),
          _BreakdownRow(
            label: l10n.technologyPanel_rpBreakdownTreasuryLabel,
            value: l10n.technologyPanel_goldValue(preview.goldCostPerTurn),
          ),
          if (preview.debtBlocked) ...[
            const SizedBox(height: CtSpacing.s),
            Text(
              l10n.technologyPanel_rpBreakdownDebtBlocked,
              style: theme.textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.danger,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: CtSpacing.ml),
          CtNinePatchButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = emphasised
        ? EditorialMonoclePalette.fg
        : EditorialMonoclePalette.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: emphasised ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: CtSpacing.m),
          Text(
            value,
            style: _monoStyle(
              emphasised
                  ? EditorialMonoclePalette.accentBright
                  : EditorialMonoclePalette.accentDim,
            ).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
