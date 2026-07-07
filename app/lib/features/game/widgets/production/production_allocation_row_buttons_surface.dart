part of 'production_allocation_row_buttons.dart';

/// Wraps an icon child in the dark editorial-monocle step-button chrome
/// (26 × 26 surface with [CtGradients.buttonGradient] inside a 1 px
/// `EditorialMonoclePalette.border` outline) and fades the entire surface
/// to [kProductionAllocationStepButtonDisabledOpacity] when disabled.
///
/// Shared by the Allocation subpanel's per-recipe ± / maximize / clear
/// controls **and** the Available subpanel's per-tier labour ± controls,
/// per `SPEC/ui/production-panel.md` § Allocation step buttons (R51 —
/// "Enabled tap / long-press semantics and the per-tier production tier
/// labour controls reuse the same step-button surface contract").
class ProductionStepButtonSurface extends StatelessWidget {
  const ProductionStepButtonSurface({
    super.key,
    required this.enabled,
    required this.iconAssetPath,
    required this.iconSize,
  });

  final bool enabled;
  final String iconAssetPath;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : kProductionAllocationStepButtonDisabledOpacity,
      child: SizedBox(
        width: kProductionAllocationStepButtonSize,
        height: kProductionAllocationStepButtonSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: CtGradients.buttonGradient,
            border: Border.all(
              color: EditorialMonoclePalette.border,
              width: 1,
            ),
          ),
          child: Center(
            child: StrictAssetIcon(
              assetPath: iconAssetPath,
              width: iconSize,
              height: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
