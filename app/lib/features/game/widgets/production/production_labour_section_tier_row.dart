// Per-tier Labour Controls row widgets (Refs #3878).
//
// Extracted from `production_labour_section.dart` to keep the host file
// under the repo code-review physical-line limit.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'production_labour_section.dart';

const _uiIconLabourIncrement = 'ui_icon_production_alloc_increment.png';
const _uiIconLabourDecrement = 'ui_icon_production_alloc_decrement.png';

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
      padding: const EdgeInsets.only(left: CtSpacing.m),
      child: Text(
        l10n.production_labourQueued(data.queuedCount),
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  List<Widget> _buildEditActions(String tierName) {
    final disbandLabel = l10n.production_labourDisband;
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
          disbandLabel: disbandLabel,
          tooltip: l10n.production_labourDisbandTier(tierName),
          onDisband: callbacks.onDisband,
        )
      else
        // Peasant rows have no visible Disband control but reserve the
        // same trailing slot width as trained rows so −/+ align across
        // all tier rows. SPEC/ui/production-panel.md § Labour Controls
        // (12-A) > Trailing alignment. Refs #2862 S8a / C4 / G5.
        _DisbandReservedSlot(label: disbandLabel),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tierName = _tierName();
    final tierLabel = _tierLabelWithUnlockState();
    // Expanded (not Flexible) on the leading tier-label slot so the slot
    // width is the same across rows. With Flexible.loose the label slot
    // collapses to the text's intrinsic width, which differs per tier
    // (e.g. "Peasants (unlocked)" vs "Apprentices (unlocked)") and
    // shifts the trailing action cluster horizontally — breaking the
    // trailing-alignment contract in SPEC/ui/production-panel.md
    // § Labour Controls (12-A) > Trailing alignment. With Expanded, the
    // label slot occupies all available pre-cluster space, the cluster
    // anchors flush to the row's right edge, and combined with the
    // reserved-Disband-slot on the peasant row the −/+ steppers sit at
    // the same screen-x across every tier row. Refs #2862 S8a / C4 / G5.
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Row(
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
            ],
          ),
        ),
        if (canEdit) ..._buildEditActions(tierName),
      ],
    );
  }
}
