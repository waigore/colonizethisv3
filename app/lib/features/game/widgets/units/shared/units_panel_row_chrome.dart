import 'package:flutter/material.dart';

import '../../../../../config/editorial_monocle_palette.dart';
import '../../../../../widgets/ct_gradients.dart';
import '../../../../../widgets/ct_spacing.dart';

/// Dark editorial-monocle row surface for unit / army / fleet rows.
///
/// Implements `Refs #2866` shared row chrome: paints [CtGradients.rowGradient]
/// with a 1 px `--accent-dim` border. Hover is not modeled here (Flutter web
/// hover would require a [MouseRegion] parent); panel rows use the static
/// accent-dim border per the issue AC.
///
/// Default `margin` / `padding` resolve through [CtSpacing] tokens
/// (`SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens*, Refs #2914 S5):
/// the bottom margin uses [CtSpacing.s] (6 dp) and the inner padding uses
/// [CtSpacing.m] (8 dp horizontal) × [CtSpacing.s] (6 dp vertical). The
/// physical geometry is preserved end-to-end so this is a token-renaming
/// migration only.
class UnitsPanelRowChrome extends StatelessWidget {
  const UnitsPanelRowChrome({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: CtSpacing.s),
    this.padding = const EdgeInsets.symmetric(
      horizontal: CtSpacing.m,
      vertical: CtSpacing.s,
    ),
  });

  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;

  static const double _borderWidth = 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: CtGradients.rowGradient,
          border: Border.all(
            color: EditorialMonoclePalette.accentDim,
            width: _borderWidth,
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
