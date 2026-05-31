import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// Small preview of a Great Power’s default map / ownership RGB from GDD 09
/// (`greatPowerDefaultColorRgb`). Used beside nation names in pickers.
///
/// Unknown great-power ids fall back to [EditorialMonoclePalette.muted]
/// (Refs #2914 S4 — no raw `const Color(0x...)` literals in `app/lib/widgets/`).
class GpDefaultMapColorSwatch extends StatelessWidget {
  const GpDefaultMapColorSwatch({super.key, required this.greatPowerId});

  final String greatPowerId;

  @override
  Widget build(BuildContext context) {
    final rgb = greatPowerDefaultColorRgb[greatPowerId];
    final color = rgb != null
        ? Color.fromRGBO(rgb.$1, rgb.$2, rgb.$3, 1)
        : EditorialMonoclePalette.muted;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.45),
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
