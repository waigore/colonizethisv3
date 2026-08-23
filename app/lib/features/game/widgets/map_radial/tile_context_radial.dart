/// MAP30001 presentational radial. SPEC/ui/tile-context-radial.md (Refs #4440).
library;

import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tile_context_radial_chrome.dart';
import 'tile_radial_catalog.dart';
import 'tile_radial_layout.dart';
import 'tile_radial_spoke_view.dart';

/// Map-attached contextual radial for overlay Tile shortcuts.
class TileContextRadial extends StatelessWidget {
  const TileContextRadial({
    required this.placeLine,
    required this.wedges,
    required this.onWedge,
    required this.onMore,
    required this.onDismiss,
    this.anchor = Offset.zero,
    super.key,
  });

  static const screenId = UiScreenIds.tileContextRadial;

  final String placeLine;
  final List<TileRadialSpokeView> wedges;
  final ValueChanged<TileRadialCatalogAction> onWedge;
  final VoidCallback onMore;
  final VoidCallback onDismiss;
  final Offset anchor;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final viewport = MediaQuery.sizeOf(context);
    final needed = tileRadialNeededSize(actionWedgeCount: wedges.length);
    final topLeft = clampTileRadialTopLeft(
      viewport: viewport,
      anchor: anchor,
      size: needed,
    );
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): onDismiss,
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDismiss,
                onPanStart: (_) => onDismiss(),
              ),
            ),
            Positioned(
              left: topLeft.dx,
              top: topLeft.dy,
              width: needed.width,
              height: needed.height,
              child: TileRadialMenu(
                placeLine: placeLine,
                wedges: wedges,
                moreLabel: l10n.tileRadial_more,
                size: needed,
                onWedge: onWedge,
                onMore: onMore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
