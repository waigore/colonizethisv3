// Treasury details teaching panel for the map gold HUD (Refs #4560).
//
// SPEC: SPEC/ui/empire-overview.md § Treasury teaching surface.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/ct_spacing.dart';
import 'treasury_committed_spend.dart';
import 'treasury_details_format.dart';
import 'treasury_details_format_toggles.dart';

/// Plain-language treasury forecast breakdown surfaced on player tap.
class TreasuryDetailsPanel extends StatelessWidget {
  const TreasuryDetailsPanel({
    super.key,
    required this.l10n,
    required this.treasury,
    required this.projectedDelta,
    required this.committedLines,
    required this.showExact,
    required this.onShowExactChanged,
    required this.onClose,
  });

  final AppLocalizations l10n;
  final int treasury;
  final int? projectedDelta;
  final List<TreasuryCommittedSpendLine> committedLines;
  final bool showExact;
  final ValueChanged<bool> onShowExactChanged;
  final VoidCallback onClose;

  static const Key closeButtonKey = Key('treasury_details_close');
  static const Key exactFormatKey = Key('treasury_details_format_exact');
  static const Key compactFormatKey = Key('treasury_details_format_compact');

  @override
  Widget build(BuildContext context) {
    final TextStyle rowStyle = _treasuryDetailsRowStyle(context);
    final TextStyle counselStyle = rowStyle.copyWith(
      color: EditorialMonoclePalette.muted,
      fontStyle: FontStyle.italic,
    );

    return DecoratedBox(
      key: kTreasuryDetailsPanelKey,
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border.all(color: EditorialMonoclePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _TreasuryDetailsRows(
                    l10n: l10n,
                    treasury: treasury,
                    projectedDelta: projectedDelta,
                    committedLines: committedLines,
                    showExact: showExact,
                    rowStyle: rowStyle,
                  ),
                ),
                CtIconAction(
                  key: closeButtonKey,
                  icon: Icons.close,
                  tooltip: l10n.common_close,
                  semanticLabel: l10n.common_close,
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: CtSpacing.s),
            TreasuryFormatToggles(
              l10n: l10n,
              showExact: showExact,
              onShowExactChanged: onShowExactChanged,
              exactFormatKey: exactFormatKey,
              compactFormatKey: compactFormatKey,
            ),
            const SizedBox(height: CtSpacing.s),
            Text(
              l10n.mapControls_treasury_details_counsel,
              style: counselStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _TreasuryDetailsRows extends StatelessWidget {
  const _TreasuryDetailsRows({
    required this.l10n,
    required this.treasury,
    required this.projectedDelta,
    required this.committedLines,
    required this.showExact,
    required this.rowStyle,
  });

  final AppLocalizations l10n;
  final int treasury;
  final int? projectedDelta;
  final List<TreasuryCommittedSpendLine> committedLines;
  final bool showExact;
  final TextStyle rowStyle;

  @override
  Widget build(BuildContext context) {
    final String treasuryLabel = formatTreasuryAmount(
      treasury,
      showExact: showExact,
    );
    final String? deltaLabel = formatTreasuryDeltaLabel(projectedDelta);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.mapControls_treasury_details_current(treasuryLabel),
          style: rowStyle,
        ),
        if (deltaLabel != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            l10n.mapControls_treasury_details_forecast(deltaLabel),
            style: rowStyle,
          ),
        ],
        if (committedLines.isNotEmpty) ...<Widget>[
          const SizedBox(height: CtSpacing.s),
          Text(
            l10n.mapControls_treasury_details_committedHeading,
            style: rowStyle.copyWith(color: EditorialMonoclePalette.accentDim),
          ),
          for (final line in committedLines) ...<Widget>[
            const SizedBox(height: 4),
            Text(_committedLineLabel(l10n, line, showExact), style: rowStyle),
          ],
        ],
      ],
    );
  }
}

String _committedLineLabel(
  AppLocalizations l10n,
  TreasuryCommittedSpendLine line,
  bool showExact,
) {
  final String amount = formatTreasuryAmount(line.amount, showExact: showExact);
  return switch (line.family) {
    TreasuryCommittedSpendFamily.research =>
      l10n.mapControls_treasury_details_line_research(amount),
    TreasuryCommittedSpendFamily.marketBids =>
      l10n.mapControls_treasury_details_line_marketBids(amount),
    TreasuryCommittedSpendFamily.grantAid =>
      l10n.mapControls_treasury_details_line_grantAid(amount),
    TreasuryCommittedSpendFamily.overtures =>
      l10n.mapControls_treasury_details_line_overtures(amount),
    TreasuryCommittedSpendFamily.recruitWorkers =>
      l10n.mapControls_treasury_details_line_recruitWorkers(amount),
    TreasuryCommittedSpendFamily.trainUnits =>
      l10n.mapControls_treasury_details_line_trainUnits(amount),
    TreasuryCommittedSpendFamily.purchaseLand =>
      l10n.mapControls_treasury_details_line_purchaseLand(amount),
  };
}

TextStyle _treasuryDetailsRowStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  return (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
    color: EditorialMonoclePalette.fg,
    fontSize: 11,
    height: 1.3,
  );
}
