// Treasury details teaching popover for the map gold HUD (Refs #4560).
//
// SPEC: SPEC/ui/empire-overview.md § Treasury teaching surface.

import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'treasury_committed_spend.dart';
import 'treasury_details_format.dart';
import 'treasury_details_panel.dart';

export 'treasury_details_format.dart';
export 'treasury_details_panel.dart';

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
