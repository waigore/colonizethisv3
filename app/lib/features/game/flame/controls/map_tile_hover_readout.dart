import 'dart:math' as math;

import 'package:colonizethis_app/features/game/flame/controls/map_tile_hover_readout_copy.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Stable key for the MAP10001 owner/sight hover readout (Refs #4406).
const Key kMapTileHoverReadoutKey = Key('map_tile_hover_readout');

/// Compact dismiss-on-leave place / owner / sight chrome on MAP10001.
///
/// SPEC: `SPEC/ui/map-widget.md` § Hover; `SPEC/ui/empire-overview.md`
/// § Tile owner / sight hover readout.
class MapTileHoverReadout extends StatelessWidget {
  const MapTileHoverReadout({required this.copy, super.key});

  final MapTileHoverReadoutCopy copy;

  /// Preferred panel width; clamped to viewport minus 16 dp.
  static const double maxWidth = 260;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = appL10n(context);
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double panelWidth = math.min(
      MapTileHoverReadout.maxWidth,
      math.max(0, viewportWidth - 16),
    );
    final TextStyle style =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
          color: EditorialMonoclePalette.fg,
          fontSize: 11,
          height: 1.25,
        );
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.m),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: panelWidth),
            child: DecoratedBox(
              key: kMapTileHoverReadoutKey,
              decoration: BoxDecoration(
                color: EditorialMonoclePalette.surface.withValues(alpha: 0.92),
                border: Border.all(color: EditorialMonoclePalette.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(CtSpacing.m),
                child: Semantics(
                  container: true,
                  label: l10n.mapHover_semantics(copy.semanticsSummary),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(copy.placeLine, style: style),
                      Text(copy.identityLine, style: style),
                      Text(copy.sightLine, style: style),
                      if (copy.warpLine != null)
                        Text(copy.warpLine!, style: style),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
