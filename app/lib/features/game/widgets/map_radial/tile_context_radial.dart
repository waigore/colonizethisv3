/// MAP30001 presentational radial. SPEC/ui/tile-context-radial.md (Refs #4440).
library;

import 'dart:math' as math;

import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tile_radial_catalog.dart';
import 'tile_radial_keys.dart';
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
    final spokeCount = wedges.length + 1;
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
              child: KeyedSubtree(
                key: kTileContextRadialKey,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: kTileRadialHubSize,
                        height: kTileRadialHubSize,
                        child: Padding(
                          padding: const EdgeInsets.all(CtSpacing.s),
                          child: Center(
                            child: Text(
                              placeLine,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: EditorialMonoclePalette.fg),
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < wedges.length; i++)
                      _spokeAt(
                        index: i,
                        spokeCount: spokeCount,
                        size: needed,
                        child: _TileRadialWedgeButton(
                          view: wedges[i],
                          onPressed: wedges[i].enabled
                              ? () => onWedge(wedges[i].action)
                              : null,
                        ),
                      ),
                    _spokeAt(
                      index: wedges.length,
                      spokeCount: spokeCount,
                      size: needed,
                      child: _TileRadialWedgeButton(
                        label: l10n.tileRadial_more,
                        tooltip: l10n.tileRadial_more,
                        enabled: true,
                        buttonKey: kTileRadialMoreKey,
                        onPressed: onMore,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spokeAt({
    required int index,
    required int spokeCount,
    required Size size,
    required Widget child,
  }) {
    final angle = -math.pi / 2 + (2 * math.pi * index / spokeCount);
    final cx = size.width / 2 + kTileRadialSpokeRadius * math.cos(angle);
    final cy = size.height / 2 + kTileRadialSpokeRadius * math.sin(angle);
    return Positioned(
      left: cx - kTileRadialWedgeMinSize / 2,
      top: cy - kTileRadialWedgeMinSize / 2,
      width: kTileRadialWedgeMinSize * 2.2,
      height: kTileRadialWedgeMinSize,
      child: child,
    );
  }
}

class _TileRadialWedgeButton extends StatelessWidget {
  const _TileRadialWedgeButton({
    this.view,
    this.label,
    this.tooltip,
    this.enabled,
    this.buttonKey,
    required this.onPressed,
  });

  final TileRadialSpokeView? view;
  final String? label;
  final String? tooltip;
  final bool? enabled;
  final Key? buttonKey;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = view?.label ?? label ?? '';
    final resolvedTooltip = view?.tooltip ?? tooltip ?? resolvedLabel;
    final isEnabled = view?.enabled ?? enabled ?? true;
    final Key? resolvedKey =
        buttonKey ?? (view == null ? null : tileRadialSpokeKey(view!.action));
    return Tooltip(
      message: resolvedTooltip,
      triggerMode: isEnabled
          ? TooltipTriggerMode.longPress
          : TooltipTriggerMode.tap,
      child: Material(
        color: isEnabled
            ? EditorialMonoclePalette.surfaceLite
            : EditorialMonoclePalette.surfaceLite.withValues(alpha: 0.55),
        child: InkWell(
          key: resolvedKey,
          onTap: isEnabled ? onPressed : null,
          child: SizedBox(
            height: kTileRadialWedgeMinSize,
            child: Center(
              child: Text(
                resolvedLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isEnabled
                      ? EditorialMonoclePalette.fg
                      : EditorialMonoclePalette.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
