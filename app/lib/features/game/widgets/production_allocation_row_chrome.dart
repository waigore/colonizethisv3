import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../widgets/ct_gradients.dart';
import '../../../widgets/ct_spacing.dart';

/// Dark editorial-monocle row chrome for a production allocation row.
///
/// Implements `Refs #2862` S3 / requirement R13 (recipe rows: gradient
/// background + brass edge strips). Paints [CtGradients.rowGradient] inside
/// a 1 px `--accent-dim` border, mirroring the unit-panel row contract from
/// `Refs #2866` (`UnitsPanelRowChrome`) so the dark theme is consistent
/// across panel families. The brass edge separation between consecutive rows
/// is provided by `CtBrassDivider` paint above by the parent subpanel
/// (`_AllocationSubpanel`), not by this chrome.
///
/// SPEC: `SPEC/ui/production-panel.md` § Allocation row chrome.
class ProductionAllocationRowChrome extends StatelessWidget {
  const ProductionAllocationRowChrome({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: CtSpacing.m,
      vertical: CtSpacing.m,
    ),
  });

  final Widget child;
  final EdgeInsets padding;

  static const double borderWidth = 1;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: CtGradients.rowGradient,
        border: Border.all(
          color: EditorialMonoclePalette.accentDim,
          width: borderWidth,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
