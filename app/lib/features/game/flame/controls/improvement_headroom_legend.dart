import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import '../region_map/region_map_component_shared_palette.dart'
    show RegionMapPalette, shouldShowImprovementLabels;
import 'improvement_headroom_legend_support.dart';

/// Stable key for the MAP10001 improvement-headroom legend chip (Refs #4408).
const Key kImprovementHeadroomLegendKey = Key('improvement_headroom_legend');

/// Whether the improvement-headroom teaching legend should paint on MAP10001.
bool shouldShowImprovementHeadroomLegend({
  required MapBaseLayerFlags flags,
  required String? viewingPlayerId,
}) {
  return shouldShowImprovementLabels(flags: flags) && viewingPlayerId != null;
}

/// Compact teaching chip for `{n} of {cap}` improvement marks.
///
/// SPEC: `SPEC/ui/empire-overview.md` § Improvement headroom legend;
/// `SPEC/ui/map-widget.md` § Improvement headroom.
class ImprovementHeadroomLegend extends StatelessWidget {
  const ImprovementHeadroomLegend({
    required this.narrow,
    required this.anchorKey,
    required this.chromeBottomY,
    super.key,
  });

  final bool narrow;
  final GlobalKey anchorKey;
  final double chromeBottomY;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = appL10n(context);
    return Material(
      key: kImprovementHeadroomLegendKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showImprovementHeadroomLegendPopover(
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
          label: l10n.mapImprovementHeadroom_legendSemantics,
          child: narrow
              ? const _MarkPair()
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _LegendRow(
                        muted: false,
                        label: l10n.mapImprovementHeadroom_legendHeadroom,
                        style: labelStyle,
                      ),
                      const SizedBox(height: CtSpacing.xs),
                      _LegendRow(
                        muted: true,
                        label: l10n.mapImprovementHeadroom_legendAtCap,
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

class _MarkPair extends StatelessWidget {
  const _MarkPair();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _MarkSwatch(muted: false, text: '1 of 2'),
        SizedBox(width: CtSpacing.xs),
        _MarkSwatch(muted: true, text: '1 of 1'),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.muted,
    required this.label,
    required this.style,
  });

  final bool muted;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _MarkSwatch(muted: muted, text: muted ? '1 of 1' : '1 of 2'),
        const SizedBox(width: CtSpacing.s),
        Flexible(child: Text(label, style: style)),
      ],
    );
  }
}

class _MarkSwatch extends StatelessWidget {
  const _MarkSwatch({required this.muted, required this.text});

  final bool muted;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: muted
            ? EditorialMonoclePalette.muted
            : RegionMapPalette.mapSelectionGold,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.0,
      ),
    );
  }
}
