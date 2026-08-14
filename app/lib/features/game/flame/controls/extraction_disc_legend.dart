import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import '../region_map/region_map_component_shared_palette.dart'
    show RegionMapPalette, shouldShowExtractionUnitIndicators;
import 'extraction_disc_legend_support.dart';

/// Stable key for the MAP10001 extraction-disc legend chip (Refs #4367).
const Key kExtractionDiscLegendKey = Key('extraction_disc_legend');

/// Whether the extraction-disc teaching legend should paint on MAP10001.
///
/// Visible when the base layer includes resource icons **and** a viewing
/// player is present (normal play / player observe), including turn 1 with
/// zero discs painted. Hidden in terrain-only and global observe.
bool shouldShowExtractionDiscLegend({
  required MapBaseLayerFlags flags,
  required String? viewingPlayerId,
}) {
  return shouldShowExtractionUnitIndicators(flags: flags) &&
      viewingPlayerId != null;
}

/// Compact gold/brown legend teaching on-map extraction disc colours.
///
/// SPEC: `SPEC/ui/empire-overview.md` § Extraction disc legend;
/// `SPEC/ui/map-widget.md` § Per-tile extraction throughput indicators.
class ExtractionDiscLegend extends StatelessWidget {
  const ExtractionDiscLegend({
    required this.narrow,
    required this.anchorKey,
    required this.chromeBottomY,
    super.key,
  });

  /// When true, collapse to a two-disc chip without text labels.
  final bool narrow;

  /// Anchor for the details popover (typically this widget's [GlobalKey]).
  final GlobalKey anchorKey;

  /// Y of the bottom of shell chrome; popover scrim starts here.
  final double chromeBottomY;

  static const double discDiameter = 10;
  static const double wideMaxWidth = 220;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = appL10n(context);
    return Material(
      key: kExtractionDiscLegendKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showExtractionDiscLegendPopover(
            context: context,
            anchorKey: anchorKey,
            chromeBottomY: chromeBottomY,
            l10n: l10n,
          );
        },
        child: _LegendChipBody(narrow: narrow, l10n: l10n),
      ),
    );
  }
}

class _LegendChipBody extends StatelessWidget {
  const _LegendChipBody({required this.narrow, required this.l10n});

  final bool narrow;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
          color: EditorialMonoclePalette.muted,
          fontSize: 10,
          height: 1.2,
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface.withValues(alpha: 0.92),
        border: Border.all(color: EditorialMonoclePalette.border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: CtSpacing.s,
          vertical: narrow ? CtSpacing.xs : CtSpacing.s,
        ),
        child: Semantics(
          button: true,
          label: l10n.mapExtractionDisc_legendSemantics,
          child: narrow
              ? const _DiscPair()
              : ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ExtractionDiscLegend.wideMaxWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _LegendRow(
                        gold: true,
                        label: l10n.mapExtractionDisc_legendGold,
                        style: labelStyle,
                      ),
                      const SizedBox(height: CtSpacing.xs),
                      _LegendRow(
                        gold: false,
                        label: l10n.mapExtractionDisc_legendBrown,
                        style: labelStyle,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _DiscPair extends StatelessWidget {
  const _DiscPair();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ExtractionDiscSwatch(gold: true),
        SizedBox(width: CtSpacing.xs),
        _ExtractionDiscSwatch(gold: false),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.gold,
    required this.label,
    required this.style,
  });

  final bool gold;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ExtractionDiscSwatch(gold: gold),
        const SizedBox(width: CtSpacing.s),
        Flexible(child: Text(label, style: style)),
      ],
    );
  }
}

class _ExtractionDiscSwatch extends StatelessWidget {
  const _ExtractionDiscSwatch({required this.gold});

  final bool gold;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(
        ExtractionDiscLegend.discDiameter,
        ExtractionDiscLegend.discDiameter,
      ),
      painter: _DiscPainter(gold: gold),
    );
  }
}

class _DiscPainter extends CustomPainter {
  const _DiscPainter({required this.gold});

  final bool gold;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double stroke = RegionMapPalette.extractionDiscStrokeWidthPx;
    final double radius = (size.shortestSide / 2) - (stroke / 2);
    final Color fill = gold
        ? RegionMapPalette.mapSelectionGold
        : RegionMapPalette.extractionDiscBlockedBrown;
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = RegionMapPalette.extractionDiscStrokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DiscPainter oldDelegate) =>
      oldDelegate.gold != gold;
}
