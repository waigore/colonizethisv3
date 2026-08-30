import 'dart:async';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Placement for HUD vs legend chrome-anchored popovers (Refs #4582).
enum ChromeAnchoredPopoverPlacement {
  /// Tab-bar indicators: right-align to the anchor, always below.
  rightAlignBelow,

  /// Map legends: left-align; prefer above when 160 px fits above the anchor.
  leftAlignPreferAbove,
}

/// Builds the 280 dp panel. [rebuild] remounts the overlay without dismissing
/// (treasury exact/compact).
typedef ChromeAnchoredPopoverPanelBuilder =
    Widget Function(VoidCallback dismiss, VoidCallback rebuild);

/// Shared OverlayEntry host for labour, cargo, treasury, and legend popovers.
Future<void> showChromeAnchoredPopover({
  required BuildContext context,
  required GlobalKey anchorKey,
  required double chromeBottomY,
  required ChromeAnchoredPopoverPlacement placement,
  required ChromeAnchoredPopoverPanelBuilder panelBuilder,
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

  void rebuild() {
    entry.markNeedsBuild();
  }

  entry = OverlayEntry(
    builder: (BuildContext _) {
      return _ChromeAnchoredPopoverOverlay(
        anchorTopLeft: anchorTopLeft,
        anchorSize: anchorSize,
        chromeBottomY: chromeBottomY,
        placement: placement,
        dismiss: dismiss,
        panel: panelBuilder(dismiss, rebuild),
      );
    },
  );

  overlay.insert(entry);
  return closed.future;
}

class _ChromeAnchoredPopoverOverlay extends StatelessWidget {
  const _ChromeAnchoredPopoverOverlay({
    required this.anchorTopLeft,
    required this.anchorSize,
    required this.chromeBottomY,
    required this.placement,
    required this.dismiss,
    required this.panel,
  });

  final Offset anchorTopLeft;
  final Size anchorSize;
  final double chromeBottomY;
  final ChromeAnchoredPopoverPlacement placement;
  final VoidCallback dismiss;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    const double panelMaxWidth = 280;
    final double panelWidth = panelMaxWidth.clamp(0, viewportWidth - 16);
    final ({double left, double top}) pos = _panelPosition(
      viewportWidth: viewportWidth,
      panelWidth: panelWidth,
    );

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
                  top: pos.top,
                  left: pos.left,
                  width: panelWidth,
                  child: Material(color: Colors.transparent, child: panel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({double left, double top}) _panelPosition({
    required double viewportWidth,
    required double panelWidth,
  }) {
    switch (placement) {
      case ChromeAnchoredPopoverPlacement.rightAlignBelow:
        final double anchorRight = anchorTopLeft.dx + anchorSize.width;
        double panelLeft = anchorRight - panelWidth;
        panelLeft = panelLeft.clamp(8, viewportWidth - panelWidth - 8);
        return (
          left: panelLeft,
          top: anchorTopLeft.dy + anchorSize.height + 4 - chromeBottomY,
        );
      case ChromeAnchoredPopoverPlacement.leftAlignPreferAbove:
        double panelLeft = anchorTopLeft.dx;
        panelLeft = panelLeft.clamp(8, viewportWidth - panelWidth - 8);
        const double panelEstimateHeight = 160;
        final double spaceAbove = anchorTopLeft.dy - chromeBottomY - 8;
        final bool placeAbove = spaceAbove >= panelEstimateHeight;
        final double panelTop = placeAbove
            ? (anchorTopLeft.dy - chromeBottomY - panelEstimateHeight - 4)
            : (anchorTopLeft.dy + anchorSize.height + 4 - chromeBottomY);
        return (left: panelLeft, top: panelTop.clamp(8, double.infinity));
    }
  }
}
