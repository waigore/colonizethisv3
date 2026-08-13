import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/ct_spacing.dart';

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
  void dismiss() {
    if (!closed.isCompleted) {
      closed.complete();
    }
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (BuildContext overlayContext) {
      final double viewportWidth = MediaQuery.sizeOf(overlayContext).width;
      const double panelMaxWidth = 280;
      final double panelWidth = panelMaxWidth.clamp(0, viewportWidth - 16);
      final double anchorLeft = anchorTopLeft.dx;
      double panelLeft = anchorLeft;
      panelLeft = panelLeft.clamp(8, viewportWidth - panelWidth - 8);
      // Prefer above the legend so the panel clears the corner controls /
      // narrow province sheet; fall back below if there is no room.
      const double panelEstimateHeight = 160;
      final double spaceAbove =
          anchorTopLeft.dy - chromeBottomY - 8;
      final bool placeAbove = spaceAbove >= panelEstimateHeight;
      final double panelTop = placeAbove
          ? (anchorTopLeft.dy - chromeBottomY - panelEstimateHeight - 4)
          : (anchorTopLeft.dy + anchorSize.height + 4 - chromeBottomY);

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
                        color: EditorialMonoclePalette.dialogScrim
                            .withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Positioned(
                    top: panelTop.clamp(8, double.infinity),
                    left: panelLeft,
                    width: panelWidth,
                    child: Material(
                      color: Colors.transparent,
                      child: ExtractionDiscLegendPanel(
                        l10n: l10n,
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
