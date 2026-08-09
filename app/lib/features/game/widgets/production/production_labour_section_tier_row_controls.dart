// Disband and stepper controls for per-tier Labour rows (Refs #3878).

import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import '../../../../widgets/ct_spacing.dart';
import 'production_allocation_row_buttons.dart';

class ProductionLabourDisbandTierButton extends StatelessWidget {
  const ProductionLabourDisbandTierButton({
    super.key,
    required this.tier,
    required this.enabled,
    required this.disbandLabel,
    required this.tooltip,
    required this.onDisband,
  });

  final WorkerTier tier;
  final bool enabled;
  final String disbandLabel;
  final String tooltip;
  final void Function(WorkerTier tier) onDisband;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: CtSpacing.s),
      child: CtDangerTextButton(
        key: ValueKey<String>('production_labour_disband_${tier.id}'),
        enabled: enabled,
        label: disbandLabel,
        semanticLabel: tooltip,
        tooltip: tooltip,
        onPressed: enabled ? () => onDisband(tier) : null,
      ),
    );
  }
}

/// Invisible Disband-shaped placeholder used by the peasant row to reserve
/// the same trailing slot width as trained rows so −/+ step buttons sit at
/// the same screen-x coordinates across every Labour row.
///
/// SPEC/ui/production-panel.md § Labour Controls (12-A) > Trailing
/// alignment (Refs #2862 S8a / C4 / G5). The reserved slot:
///
/// - Carries no widget key (so key-based finders for
///   `production_labour_disband_<tier>` skip it).
/// - Wraps the *enabled* [CtDangerTextButton] (with a no-op callback) in
///   [Opacity] 0.0 so the slot matches the exact rendered dimensions of a
///   trained-tier Disband button (including the Material / InkWell padded
///   tap-target inset on enabled buttons) but paints no visible pixels.
///   A disabled `CtDangerTextButton` would skip the Material / InkWell
///   wrapping and produce a narrower intrinsic width than the real
///   enabled Disband — that would mis-align the peasant row's −/+
///   steppers.
/// - Wraps the subtree in [ExcludeSemantics] + [IgnorePointer] so screen
///   readers do not announce a second "Disband" affordance on peasant
///   rows and pointer events are ignored.
class ProductionLabourDisbandReservedSlot extends StatelessWidget {
  const ProductionLabourDisbandReservedSlot({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: CtSpacing.s),
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.0,
            child: CtDangerTextButton(
              enabled: true,
              label: label,
              onPressed: _noop,
            ),
          ),
        ),
      ),
    );
  }

  static void _noop() {}
}

/// Per-tier `+` / `−` control for the Labour Controls section.
///
/// Renders the shared dark editorial-monocle 26 × 26 step-button surface
/// ([ProductionStepButtonSurface]) so the Available subpanel's per-tier
/// recruit/train controls reuse the same chrome as the Allocation
/// subpanel's per-recipe ± / maximize / clear controls — `SPEC/ui/production-panel.md`
/// § Allocation step buttons explicitly mandates this contract reuse
/// (`Refs #2862` § Labour Controls).
///
/// The surface fades to [kProductionAllocationStepButtonDisabledOpacity]
/// when [enabled] is false; tap gestures are gated by the same flag so
/// disabled controls never dispatch [onPressed].
class ProductionLabourIconButton extends StatelessWidget {
  const ProductionLabourIconButton({
    super.key,
    required this.enabled,
    required this.semanticLabel,
    required this.tooltip,
    required this.assetFileName,
    required this.onPressed,
  });

  static const double _iconSize = 15;

  final bool enabled;
  final String semanticLabel;
  final String tooltip;
  final String assetFileName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final path = '$kAppIconAssetPrefix$assetFileName';
    final surface = ProductionStepButtonSurface(
      enabled: enabled,
      iconAssetPath: path,
      iconSize: _iconSize,
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(onTap: enabled ? onPressed : null, child: surface),
        ),
      ),
    );
  }
}
