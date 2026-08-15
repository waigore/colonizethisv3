// Cost, upkeep, and Requires widgets for a Labour Controls tier row.
// SPEC/ui/production-panel.md § Labour Controls (12-A).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'production_labour_tier_gists.dart';

class ProductionLabourTierCostGist extends StatelessWidget {
  const ProductionLabourTierCostGist({
    super.key,
    required this.tier,
    required this.segments,
  });

  final WorkerTier tier;
  final List<LabourCostGistSegment> segments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.labelSmall?.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final dangerStyle = (baseStyle ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.danger,
    );
    final children = <InlineSpan>[];
    for (var i = 0; i < segments.length; i++) {
      if (i > 0) {
        children.add(TextSpan(text: ' + ', style: baseStyle));
      }
      final segment = segments[i];
      children.add(
        TextSpan(
          text: segment.text,
          style: segment.danger ? dangerStyle : baseStyle,
        ),
      );
    }
    return Text.rich(
      TextSpan(children: children),
      key: ValueKey<String>('production_labour_cost_${tier.id}'),
      softWrap: true,
    );
  }
}

class ProductionLabourTierUpkeepGist extends StatelessWidget {
  const ProductionLabourTierUpkeepGist({
    super.key,
    required this.tier,
    required this.l10n,
  });

  final WorkerTier tier;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      labourUpkeepGist(tier: tier, l10n: l10n),
      key: ValueKey<String>('production_labour_upkeep_${tier.id}'),
      style: theme.textTheme.labelSmall?.copyWith(
        color: EditorialMonoclePalette.muted,
      ),
      softWrap: true,
    );
  }
}

class ProductionLabourTierRequiresGist extends StatelessWidget {
  const ProductionLabourTierRequiresGist({
    super.key,
    required this.tier,
    required this.label,
  });

  final WorkerTier tier;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      key: ValueKey<String>('production_labour_requires_${tier.id}'),
      style: theme.textTheme.labelSmall?.copyWith(
        color: EditorialMonoclePalette.muted,
      ),
      softWrap: true,
    );
  }
}
