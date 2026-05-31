// Production panel Labour controls (per-tier recruit/train steppers +
// immediate disband). SPEC/ui/production-panel.md § Labour Controls,
// SPEC/game/workers-and-population.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/app_assets.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_danger_text_button.dart';
import 'production_allocation_row_buttons.dart';
import 'production_labour_helpers.dart';

const _uiIconLabourIncrement = 'ui_icon_production_alloc_increment.png';
const _uiIconLabourDecrement = 'ui_icon_production_alloc_decrement.png';

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

class _ProductionLabourTierRow extends StatelessWidget {
  const _ProductionLabourTierRow({
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

  String _tierLabelWithUnlockState() {
    final tierName = _tierName();
    final state = data.techUnlocked
        ? l10n.production_labourTierUnlocked
        : l10n.production_labourTierLocked;
    return l10n.production_labourTierLabel(tierName, state);
  }

  String _appendTooltip() {
    final label = _tierName();
    return data.tier == WorkerTier.peasant
        ? l10n.production_labourRecruitTier(label)
        : l10n.production_labourTrainTier(label);
  }

  Widget _buildQueuedSegment() {
    if (data.queuedCount <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        l10n.production_labourQueued(data.queuedCount),
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  List<Widget> _buildEditActions(String tierName) {
    return [
      _LabourIconButton(
        enabled: data.canPop,
        semanticLabel: l10n.production_labourDequeueTier(tierName),
        tooltip: l10n.production_labourDequeueTier(tierName),
        assetFileName: _uiIconLabourDecrement,
        onPressed: () => callbacks.onPopLastRecruitOrder(data.tier),
      ),
      _LabourIconButton(
        enabled: data.canAppend,
        semanticLabel: _appendTooltip(),
        tooltip: _appendTooltip(),
        assetFileName: _uiIconLabourIncrement,
        onPressed: () => callbacks.onAppendRecruitOrder(data.tier),
      ),
      if (data.tier != WorkerTier.peasant)
        _DisbandTierButton(
          tier: data.tier,
          enabled: data.canDisband,
          disbandLabel: l10n.production_labourDisband,
          tooltip: l10n.production_labourDisbandTier(tierName),
          onDisband: callbacks.onDisband,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tierName = _tierName();
    final tierLabel = _tierLabelWithUnlockState();
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: Text(
            tierLabel,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildQueuedSegment(),
        const Spacer(),
        if (canEdit) ..._buildEditActions(tierName),
      ],
    );
  }
}

class _DisbandTierButton extends StatelessWidget {
  const _DisbandTierButton({
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
      padding: const EdgeInsets.only(left: 6),
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
class _LabourIconButton extends StatelessWidget {
  const _LabourIconButton({
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
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: surface,
          ),
        ),
      ),
    );
  }
}
