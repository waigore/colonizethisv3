/// MAP30001 radial chrome (hub, spokes, wedges). SPEC/ui/tile-context-radial.md.
library;

import 'dart:math' as math;

import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'tile_radial_catalog.dart';
import 'tile_radial_keys.dart';
import 'tile_radial_layout.dart';
import 'tile_radial_spoke_view.dart';

class TileRadialHub extends StatelessWidget {
  const TileRadialHub({super.key, required this.placeLine});

  final String placeLine;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EditorialMonoclePalette.fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget tileRadialSpokeAt({
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

class TileRadialWedgeButton extends StatelessWidget {
  const TileRadialWedgeButton({
    super.key,
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
            height: view?.caption == null
                ? kTileRadialWedgeMinSize
                : kTileRadialWedgeMinSize * 1.7,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
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
                  if (view?.caption != null && view!.caption!.isNotEmpty)
                    Text(
                      view!.caption!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: EditorialMonoclePalette.muted,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TileRadialMenu extends StatelessWidget {
  const TileRadialMenu({
    super.key,
    required this.placeLine,
    required this.wedges,
    required this.moreLabel,
    required this.size,
    required this.onWedge,
    required this.onMore,
  });

  final String placeLine;
  final List<TileRadialSpokeView> wedges;
  final String moreLabel;
  final Size size;
  final ValueChanged<TileRadialCatalogAction> onWedge;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final spokeCount = wedges.length + 1;
    return KeyedSubtree(
      key: kTileContextRadialKey,
      child: Stack(
        children: [
          TileRadialHub(placeLine: placeLine),
          for (var i = 0; i < wedges.length; i++)
            tileRadialSpokeAt(
              index: i,
              spokeCount: spokeCount,
              size: size,
              child: TileRadialWedgeButton(
                view: wedges[i],
                onPressed: wedges[i].enabled
                    ? () => onWedge(wedges[i].action)
                    : null,
              ),
            ),
          tileRadialSpokeAt(
            index: wedges.length,
            spokeCount: spokeCount,
            size: size,
            child: TileRadialWedgeButton(
              label: moreLabel,
              tooltip: moreLabel,
              enabled: true,
              buttonKey: kTileRadialMoreKey,
              onPressed: onMore,
            ),
          ),
        ],
      ),
    );
  }
}
