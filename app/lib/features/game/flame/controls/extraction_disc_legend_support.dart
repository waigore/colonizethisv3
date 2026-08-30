import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../widgets/shell/chrome_anchored_popover.dart';

/// Stable key for the extraction-disc legend details panel (Refs #4367).
const Key kExtractionDiscLegendPanelKey = Key('extraction_disc_legend_panel');

/// Opens a dismissible teaching panel anchored near the extraction legend.
///
/// Mirrors the cargo-hold details popover family: ×, outside tap, Esc.
Future<void> showExtractionDiscLegendPopover({
  required BuildContext context,
  required GlobalKey anchorKey,
  required double chromeBottomY,
  required AppLocalizations l10n,
}) {
  return showChromeAnchoredPopover(
    context: context,
    anchorKey: anchorKey,
    chromeBottomY: chromeBottomY,
    placement: ChromeAnchoredPopoverPlacement.leftAlignPreferAbove,
    panelBuilder: (VoidCallback dismiss, VoidCallback _) {
      return ExtractionDiscLegendPanel(l10n: l10n, onClose: dismiss);
    },
  );
}

/// Plain-language extraction disc breakdown for the legend popover.
class ExtractionDiscLegendPanel extends StatelessWidget {
  const ExtractionDiscLegendPanel({
    super.key,
    required this.l10n,
    required this.onClose,
  });

  final AppLocalizations l10n;
  final VoidCallback onClose;

  static const Key closeButtonKey = Key('extraction_disc_legend_close');

  @override
  Widget build(BuildContext context) {
    final TextStyle rowStyle =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: EditorialMonoclePalette.fg,
          fontSize: 11,
          height: 1.3,
        );
    final TextStyle counselStyle = rowStyle.copyWith(
      color: EditorialMonoclePalette.muted,
      fontStyle: FontStyle.italic,
    );

    return DecoratedBox(
      key: kExtractionDiscLegendPanelKey,
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
                      Text(l10n.mapExtractionDisc_detailsGold, style: rowStyle),
                      const SizedBox(height: CtSpacing.s),
                      Text(
                        l10n.mapExtractionDisc_detailsBrown,
                        style: rowStyle,
                      ),
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
            Text(l10n.mapExtractionDisc_detailsCounsel, style: counselStyle),
          ],
        ),
      ),
    );
  }
}
