import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../../config/editorial_monocle_palette.dart';
import '../../../../../widgets/ct_spacing.dart';

/// Sub-header for a province or sea zone within a region in military/naval panels.
///
/// Matches the military/naval mockup `.province-label` / `.location-label`
/// chrome (`Refs #3514`): an indented body-font line in semi-bold
/// [EditorialMonoclePalette.fg] at `0.8` opacity. The displayed line content
/// (`name — region`) is unchanged (`Refs #2866` S2/S3) — only the visual
/// chrome is brought into mockup parity.
class LocationSectionHeader extends StatelessWidget {
  const LocationSectionHeader({
    super.key,
    required this.label,
    required this.regionLabel,
  });

  final String label;
  final String regionLabel;

  /// Foreground opacity for the location line (mockup `.province-label`
  /// `opacity:.8`).
  static const double labelOpacity = 0.8;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: CtSpacing.ml,
        top: CtSpacing.s,
        bottom: CtSpacing.xs,
      ),
      child: Text(
        appL10n(context).locationSection_headerLine(label, regionLabel),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: EditorialMonoclePalette.fg.withValues(alpha: labelOpacity),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
