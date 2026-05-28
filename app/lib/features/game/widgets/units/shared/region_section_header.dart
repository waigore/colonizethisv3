import 'package:flutter/material.dart';

import '../../../../../widgets/ct_section_label.dart';

/// Section title for a world region (Old World / New World) in units panels.
///
/// Implements `Refs #2866` S1–S3 region grouping via [CtSectionLabel] (#2859).
class RegionSectionHeader extends StatelessWidget {
  const RegionSectionHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: CtSectionLabel(label),
    );
  }
}
