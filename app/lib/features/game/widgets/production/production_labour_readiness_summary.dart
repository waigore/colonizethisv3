import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import '../../../../widgets/ct_action_text_button.dart';
import 'commodity_ui_helpers.dart';
import 'production_available_grid.dart';

/// Labour readiness summary + optional details for Production Available panel.
/// SPEC/ui/production-panel.md § Labour readiness (Refs #4237).
class ProductionLabourReadinessSummary extends StatefulWidget {
  const ProductionLabourReadinessSummary({
    super.key,
    required this.snapshot,
    required this.l10n,
    required this.theme,
  });

  final LabourReadinessSnapshot snapshot;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  State<ProductionLabourReadinessSummary> createState() =>
      _ProductionLabourReadinessSummaryState();
}

class _ProductionLabourReadinessSummaryState
    extends State<ProductionLabourReadinessSummary> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final l10n = widget.l10n;
    final theme = widget.theme;
    final mutedStyle = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.muted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EffectiveLabourTotal(
          text: l10n.production_labourThisTurn(snapshot.effectiveLabour),
          theme: theme,
        ),
        if (!snapshot.isFullCapacity && snapshot.primaryCauseKind != null) ...[
          const SizedBox(height: 4),
          Text(
            _primaryReasonText(l10n, snapshot),
            style: mutedStyle,
            textAlign: TextAlign.right,
          ),
        ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: CtActionTextButton(
            key: const ValueKey<String>('production_labour_details_toggle'),
            onPressed: snapshot.isFullCapacity && !_hasDetailRows(snapshot)
                ? null
                : () => setState(() => _detailsExpanded = !_detailsExpanded),
            label: l10n.production_labourDetails,
          ),
        ),
        if (_detailsExpanded) ...[
          const SizedBox(height: 4),
          ..._buildDetailRows(l10n, mutedStyle, snapshot),
        ],
      ],
    );
  }

  bool _hasDetailRows(LabourReadinessSnapshot snapshot) {
    return snapshot.tierStatuses.any((t) => t.poolCount > 0);
  }

  String _primaryReasonText(
    AppLocalizations l10n,
    LabourReadinessSnapshot snapshot,
  ) {
    return switch (snapshot.primaryCauseKind) {
      LabourReadinessCauseKind.food =>
        snapshot.militaryOrNavyConsumesFoodBeforeWorkers
            ? l10n.production_labourReasonFoodWithMilitary
            : l10n.production_labourReasonFood,
      LabourReadinessCauseKind.luxury => l10n.production_labourReasonLuxury(
        commodityDisplayName(
          l10n,
          snapshot.primaryLuxuryCommodityId ?? '',
        ),
      ),
      null => '',
    };
  }

  List<Widget> _buildDetailRows(
    AppLocalizations l10n,
    TextStyle mutedStyle,
    LabourReadinessSnapshot snapshot,
  ) {
    final rows = <Widget>[];
    for (final tier in snapshot.tierStatuses) {
      if (tier.poolCount <= 0) continue;
      rows.add(
        Text(
          l10n.production_labourTierDetail(
            _tierLabel(l10n, tier.tier),
            tier.workingCount,
            tier.notWorkingCount,
          ),
          style: mutedStyle,
          textAlign: TextAlign.right,
        ),
      );
    }
    return rows;
  }

  String _tierLabel(AppLocalizations l10n, WorkerTierKey tier) {
    return switch (tier) {
      WorkerTierKey.peasant => l10n.production_workers_peasants,
      WorkerTierKey.apprentice => l10n.production_workers_apprentices,
      WorkerTierKey.journeyman => l10n.production_workers_journeymen,
      WorkerTierKey.master => l10n.production_workers_masters,
    };
  }
}
