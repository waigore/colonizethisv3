import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../../config/editorial_monocle_palette.dart';

/// Sub-header for a province or sea zone within a region in military/naval panels.
///
/// Uses `--muted` for the location line (`Refs #2866` S2/S3).
class LocationSectionHeader extends StatelessWidget {
  const LocationSectionHeader({
    super.key,
    required this.label,
    required this.regionLabel,
  });

  final String label;
  final String regionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 2),
      child: Text(
        appL10n(context).locationSection_headerLine(label, regionLabel),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: EditorialMonoclePalette.muted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
