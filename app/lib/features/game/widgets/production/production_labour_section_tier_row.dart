// Per-tier Labour Controls row widgets (Refs #3878, #4432).
//
// Extracted from `production_labour_section.dart` to keep the host file
// under the repo code-review physical-line limit.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import 'production_labour_helpers.dart';
import 'production_labour_section_tier_row_controls.dart';
import 'production_labour_section_tier_row_gists.dart';

const kUiIconLabourIncrement = 'ui_icon_production_alloc_increment.png';
const kUiIconLabourDecrement = 'ui_icon_production_alloc_decrement.png';

class ProductionLabourTierRow extends StatelessWidget {
  const ProductionLabourTierRow({
    super.key,
    required this.data,
    required this.callbacks,
    required this.canEdit,
    required this.l10n,
    required this.theme,
  });

  final ProductionLabourTierRowData data;
  final ProductionLabourCallbacks callbacks;
  final bool canEdit;
  final AppLocalizations l10n;
  final ThemeData theme;

  String _tierName() {
    switch (data.tier) {
      case WorkerTier.peasant:
        return l10n.production_workers_peasants;
      case WorkerTier.apprentice:
        return l10n.production_workers_apprentices;
      case WorkerTier.journeyman:
        return l10n.production_workers_journeymen;
      case WorkerTier.master:
        return l10n.production_workers_masters;
    }
  }

  String _appendActionLabel() {
    final label = _tierName();
    return data.tier == WorkerTier.peasant
        ? l10n.production_labourRecruitTier(label)
        : l10n.production_labourTrainTier(label);
  }

  String _appendRefusalOrEmpty() {
    final reason = data.appendRefusalReason;
    if (!data.canAppend && reason != null && reason.isNotEmpty) {
      return reason;
    }
    return '';
  }

  String _appendTooltip() {
    final refusal = _appendRefusalOrEmpty();
    if (refusal.isNotEmpty) return refusal;
    return l10n.production_labourAppendEnabledTooltip(
      _appendActionLabel(),
      l10n.production_labourStaffsNextProduction,
    );
  }

  String _appendSemantics() {
    final refusal = _appendRefusalOrEmpty();
    if (refusal.isNotEmpty) return refusal;
    return _appendActionLabel();
  }

  Widget _buildQueuedSegment() {
    if (data.queuedCount <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        l10n.production_labourQueued(data.queuedCount),
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  List<Widget> _buildEditActions(String tierName) {
    final disbandLabel = l10n.production_labourDisband;
    final appendTooltip = _appendTooltip();
    return [
      ProductionLabourIconButton(
        key: ValueKey<String>('production_labour_minus_${data.tier.id}'),
        enabled: data.canPop,
        semanticLabel: l10n.production_labourDequeueTier(tierName),
        tooltip: l10n.production_labourDequeueTier(tierName),
        assetFileName: kUiIconLabourDecrement,
        onPressed: () => callbacks.onPopLastRecruitOrder(data.tier),
      ),
      ProductionLabourIconButton(
        key: ValueKey<String>('production_labour_plus_${data.tier.id}'),
        enabled: data.canAppend,
        semanticLabel: _appendSemantics(),
        tooltip: appendTooltip,
        assetFileName: kUiIconLabourIncrement,
        onPressed: () => callbacks.onAppendRecruitOrder(data.tier),
      ),
      if (data.tier != WorkerTier.peasant)
        ProductionLabourDisbandTierButton(
          tier: data.tier,
          enabled: data.canDisband,
          disbandLabel: disbandLabel,
          tooltip: l10n.production_labourDisbandTier(tierName),
          onDisband: callbacks.onDisband,
        )
      else
        ProductionLabourDisbandReservedSlot(label: disbandLabel),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tierName = _tierName();
    final requires = labourRequiresGist(
      tier: data.tier,
      techUnlocked: data.techUnlocked,
      l10n: l10n,
    );
    final segments = labourCostGistSegments(
      tier: data.tier,
      l10n: l10n,
      canAppend: data.canAppend,
      appendRefusalReason: data.appendRefusalReason,
      insufficientMaterialIds: data.insufficientMaterialIds,
    );
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tierName, style: theme.textTheme.bodySmall, softWrap: true),
              ProductionLabourTierCostGist(tier: data.tier, segments: segments),
              ProductionLabourTierUpkeepGist(tier: data.tier, l10n: l10n),
              if (requires != null)
                ProductionLabourTierRequiresGist(
                  tier: data.tier,
                  label: requires,
                ),
              _buildQueuedSegment(),
            ],
          ),
        ),
        if (canEdit) ..._buildEditActions(tierName),
      ],
    );
  }
}
