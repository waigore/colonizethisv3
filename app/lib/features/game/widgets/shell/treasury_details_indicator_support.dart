// Treasury details teaching popover for the map gold HUD (Refs #4560).
//
// SPEC: SPEC/ui/empire-overview.md § Treasury teaching surface.

import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/ct_spacing.dart';
import 'treasury_committed_spend.dart';

/// Stable key for widget tests that open the treasury details popover.
const Key kTreasuryDetailsPanelKey = Key('treasury_details_panel');

/// Formats treasury amounts for chip and popover Exact / Compact modes.
String formatTreasuryAmount(int value, {required bool showExact}) {
  if (showExact) {
    return NumberFormat.decimalPattern().format(value);
  }
  final compactRaw = NumberFormat.compact(locale: 'en_US').format(value);
  final compact = compactRaw.replaceAll('K', 'k');
  if (compact.contains('.') || !compact.endsWith('k')) {
    return compact;
  }
  return compact.replaceFirst('k', '.0k');
}

String? formatTreasuryDeltaLabel(int? delta) {
  if (delta == null || delta == 0) {
    return null;
  }
  if (delta > 0) {
    return '+$delta';
  }
  return '$delta';
}

/// Opens a dismissible floating panel anchored below the treasury indicator.
Future<void> showTreasuryDetailsPopover({
  required BuildContext context,
  required GlobalKey anchorKey,
  required double chromeBottomY,
  required AppLocalizations l10n,
  required int treasury,
  required int? projectedDelta,
  required List<TreasuryCommittedSpendLine> committedLines,
  required bool showExact,
  required ValueChanged<bool> onShowExactChanged,
}) {
  final RenderBox? renderBox =
      anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) {
    return Future<void>.value();
  }

  final OverlayState overlay = Overlay.of(context);
  final Offset anchorTopLeft = renderBox.localToGlobal(Offset.zero);
  final Size anchorSize = renderBox.size;
  final Completer<void> closed = Completer<void>();

  late OverlayEntry entry;
  var exact = showExact;

  void dismiss() {
    if (!closed.isCompleted) {
      closed.complete();
    }
    entry.remove();
  }

  void rebuild() {
    entry.markNeedsBuild();
  }

  entry = OverlayEntry(
    builder: (BuildContext overlayContext) {
      final double viewportWidth = MediaQuery.sizeOf(overlayContext).width;
      const double panelMaxWidth = 280;
      final double panelWidth = panelMaxWidth.clamp(0, viewportWidth - 16);
      final double anchorRight = anchorTopLeft.dx + anchorSize.width;
      double panelLeft = anchorRight - panelWidth;
      panelLeft = panelLeft.clamp(8, viewportWidth - panelWidth - 8);
      final double panelTop =
          anchorTopLeft.dy + anchorSize.height + 4 - chromeBottomY;

      return Positioned(
        top: chromeBottomY,
        left: 0,
        right: 0,
        bottom: 0,
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  dismiss();
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: dismiss,
                      behavior: HitTestBehavior.opaque,
                      child: ColoredBox(
                        color: EditorialMonoclePalette.dialogScrim.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: panelTop,
                    left: panelLeft,
                    width: panelWidth,
                    child: Material(
                      color: Colors.transparent,
                      child: TreasuryDetailsPanel(
                        l10n: l10n,
                        treasury: treasury,
                        projectedDelta: projectedDelta,
                        committedLines: committedLines,
                        showExact: exact,
                        onShowExactChanged: (bool next) {
                          exact = next;
                          onShowExactChanged(next);
                          rebuild();
                        },
                        onClose: dismiss,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  return closed.future;
}

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
    final String treasuryLabel = formatTreasuryAmount(
      treasury,
      showExact: showExact,
    );
    final String? deltaLabel = formatTreasuryDeltaLabel(projectedDelta);

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
                  child: Column(
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
                          style: rowStyle.copyWith(
                            color: EditorialMonoclePalette.accentDim,
                          ),
                        ),
                        for (final line in committedLines) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            _committedLineLabel(l10n, line, showExact),
                            style: rowStyle,
                          ),
                        ],
                      ],
                    ],
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
            Row(
              children: <Widget>[
                _FormatToggle(
                  key: exactFormatKey,
                  label: l10n.mapControls_treasury_details_formatExact,
                  selected: showExact,
                  onTap: () => onShowExactChanged(true),
                ),
                const SizedBox(width: CtSpacing.s),
                _FormatToggle(
                  key: compactFormatKey,
                  label: l10n.mapControls_treasury_details_formatCompact,
                  selected: !showExact,
                  onTap: () => onShowExactChanged(false),
                ),
              ],
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

class _FormatToggle extends StatelessWidget {
  const _FormatToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? EditorialMonoclePalette.bg
              : EditorialMonoclePalette.surface,
          border: Border.all(
            color: selected
                ? EditorialMonoclePalette.accent
                : EditorialMonoclePalette.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? EditorialMonoclePalette.accent
                  : EditorialMonoclePalette.muted,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
