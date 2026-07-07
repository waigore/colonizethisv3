// Production panel Labour controls (per-tier recruit/train steppers +
// immediate disband). SPEC/ui/production-panel.md § Labour Controls,
// SPEC/game/workers-and-population.md.

library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_spacing.dart';
import '../chrome/ct_danger_text_button.dart';
import 'production_allocation_row_buttons.dart';
import 'production_labour_helpers.dart';

part 'production_labour_section_tier_row.dart';

/// Labour controls section appended to the Workers section of the
/// Available subpanel. Renders one row per worker tier with recruit/train
/// steppers and (for trained tiers) a disband button.
class ProductionLabourSection extends StatelessWidget {
  const ProductionLabourSection({
    super.key,
    required this.player,
    required this.currentOrders,
    required this.canEdit,
    required this.callbacks,
  });

  final Player player;
  final Orders currentOrders;
  final bool canEdit;
  final ProductionLabourCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10n(context);
    final rows = buildProductionLabourRowData(
      player: player,
      currentOrders: currentOrders,
      canEdit: canEdit,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            key: ValueKey<String>('production_labour_row_${row.tier.id}'),
            padding: const EdgeInsets.only(top: 4),
            child: _ProductionLabourTierRow(
              data: row,
              callbacks: callbacks,
              canEdit: canEdit,
              l10n: l10n,
              theme: theme,
            ),
          ),
      ],
    );
  }
}
