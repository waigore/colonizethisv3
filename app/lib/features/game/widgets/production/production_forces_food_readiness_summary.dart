import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import '../../../../widgets/ct_action_text_button.dart';
import 'force_feeding_readiness_labels.dart';

/// Forces-food readiness summary + optional details for Production Available.
/// SPEC/ui/production-panel.md § Forces food readiness (Refs #4242).
class ProductionForcesFoodReadinessSummary extends StatefulWidget {
  const ProductionForcesFoodReadinessSummary({
    super.key,
    required this.snapshot,
    required this.l10n,
    required this.theme,
  });

  final ForceFeedingSnapshot snapshot;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  State<ProductionForcesFoodReadinessSummary> createState() =>
      _ProductionForcesFoodReadinessSummaryState();
}

class _ProductionForcesFoodReadinessSummaryState
    extends State<ProductionForcesFoodReadinessSummary> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    if (!snapshot.hasAnyForces) {
      return const SizedBox.shrink();
    }

    final l10n = widget.l10n;
    final theme = widget.theme;
    final mutedStyle = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.muted,
    );

    final defaultLines = <String>[
      if (snapshot.hasLandForces) landForceFeedingDefaultLine(l10n, snapshot),
      if (snapshot.hasNavalForces) navalForceFeedingDefaultLine(l10n, snapshot),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in defaultLines)
          Text(
            line,
            style: mutedStyle,
            textAlign: TextAlign.right,
          ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: CtActionTextButton(
            key: const ValueKey<String>('production_forces_food_details_toggle'),
            onPressed: () => setState(() => _detailsExpanded = !_detailsExpanded),
            label: l10n.production_forcesFoodDetails,
          ),
        ),
        if (_detailsExpanded) ...[
          const SizedBox(height: 4),
          if (snapshot.hasLandForces)
            Text(
              l10n.production_forcesFoodDetailsArmies(
                snapshot.fullyFedRegiments,
                snapshot.totalRegiments,
              ),
              style: mutedStyle,
              textAlign: TextAlign.right,
            ),
          if (snapshot.hasNavalForces)
            Text(
              l10n.production_forcesFoodDetailsFleets(
                snapshot.fullyFedShips,
                snapshot.totalShips,
              ),
              style: mutedStyle,
              textAlign: TextAlign.right,
            ),
          if (snapshot.forcesFoodDemand > 0)
            Text(
              l10n.production_forcesFoodDetailsDemand(
                snapshot.forcesFoodDemand,
              ),
              style: mutedStyle,
              textAlign: TextAlign.right,
            ),
          Text(
            l10n.production_forcesFoodDetailsPriority,
            style: mutedStyle,
            textAlign: TextAlign.right,
          ),
        ],
      ],
    );
  }
}
