import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../widgets/shell/chrome_anchored_popover.dart';

/// Stable key for the improvement-headroom legend details panel (Refs #4408).
const Key kImprovementHeadroomLegendPanelKey = Key(
  'improvement_headroom_legend_panel',
);

/// Opens a dismissible teaching panel anchored near the improvement legend.
Future<void> showImprovementHeadroomLegendPopover({
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
      return ImprovementHeadroomLegendPanel(l10n: l10n, onClose: dismiss);
    },
  );
}

/// Plain-language improvement-mark breakdown for the legend popover.
class ImprovementHeadroomLegendPanel extends StatelessWidget {
  const ImprovementHeadroomLegendPanel({
    super.key,
    required this.l10n,
    required this.onClose,
  });

  final AppLocalizations l10n;
  final VoidCallback onClose;

  static const Key closeButtonKey = Key('improvement_headroom_legend_close');

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: kImprovementHeadroomLegendPanelKey,
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border.all(color: EditorialMonoclePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.m),
        child: _ImprovementHeadroomLegendPanelBody(
          l10n: l10n,
          onClose: onClose,
        ),
      ),
    );
  }
}

class _ImprovementHeadroomLegendPanelBody extends StatelessWidget {
  const _ImprovementHeadroomLegendPanelBody({
    required this.l10n,
    required this.onClose,
  });

  final AppLocalizations l10n;
  final VoidCallback onClose;

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

    return Column(
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
                    l10n.mapImprovementHeadroom_detailsMeaning,
                    style: rowStyle,
                  ),
                  const SizedBox(height: CtSpacing.s),
                  Text(
                    l10n.mapImprovementHeadroom_detailsMuted,
                    style: rowStyle,
                  ),
                ],
              ),
            ),
            CtIconAction(
              key: ImprovementHeadroomLegendPanel.closeButtonKey,
              icon: Icons.close,
              tooltip: l10n.common_close,
              semanticLabel: l10n.common_close,
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: CtSpacing.s),
        Text(l10n.mapImprovementHeadroom_detailsCounsel, style: counselStyle),
      ],
    );
  }
}
