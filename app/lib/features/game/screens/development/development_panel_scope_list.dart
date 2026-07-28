import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_action_text_button.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../widgets/units/shared/region_section_header.dart';
import 'development_panel_keys.dart';

/// Province and purchased-land scope list for one region tab.
class DevelopmentPanelScopeList extends StatelessWidget {
  const DevelopmentPanelScopeList({
    super.key,
    required this.regionModel,
    required this.onShowTiles,
    required this.assignRowStateFor,
    required this.onAssign,
  });

  final DevelopmentPanelRegionModel regionModel;
  final void Function(Set<String> tileKeys) onShowTiles;
  final DevelopmentAssignRowState Function(
    String commodityId,
    Set<String> tileKeys,
  )
  assignRowStateFor;
  final void Function(DevelopmentImproveAssignCandidate candidate) onAssign;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const RegionSectionHeader(
          label: 'Your provinces',
          variant: RegionHeaderVariant.bottomBorderMuted,
        ),
        ...regionModel.ownedScopes.map(
          (scope) => _ScopeCard(
            scope: scope,
            onShowTiles: onShowTiles,
            assignRowStateFor: assignRowStateFor,
            onAssign: onAssign,
          ),
        ),
        const SizedBox(height: CtSpacing.m),
        const RegionSectionHeader(
          key: DevelopmentPanelKeys.purchasedSectionKey,
          label: 'Purchased land',
          variant: RegionHeaderVariant.bottomBorderMuted,
        ),
        if (regionModel.purchasedScopes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: CtSpacing.s),
            child: Text(
              '—',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.muted,
              ),
            ),
          )
        else
          ...regionModel.purchasedScopes.map(
            (scope) => _ScopeCard(
              scope: scope,
              onShowTiles: onShowTiles,
              assignRowStateFor: assignRowStateFor,
              onAssign: onAssign,
            ),
          ),
      ],
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.scope,
    required this.onShowTiles,
    required this.assignRowStateFor,
    required this.onAssign,
  });

  final DevelopmentPanelScopeRow scope;
  final void Function(Set<String> tileKeys) onShowTiles;
  final DevelopmentAssignRowState Function(
    String commodityId,
    Set<String> tileKeys,
  )
  assignRowStateFor;
  final void Function(DevelopmentImproveAssignCandidate candidate) onAssign;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      key: DevelopmentPanelKeys.scopeRowKey(scope.scopeKey),
      padding: const EdgeInsets.symmetric(vertical: CtSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scope.displayName,
            style: textTheme.titleSmall?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
          if (scope.isPurchasedLand && scope.provinceOwnerDisplayName != null)
            Text(
              'Owner: ${scope.provinceOwnerDisplayName}',
              style: textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.muted,
              ),
            ),
          const SizedBox(height: 4),
          if (!scope.hasImprovableResources)
            Text(
              'No improvable resources',
              style: textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.muted,
              ),
            )
          else
            ...scope.improvableCommodities.map(
              (row) => _ImprovableCommodityRow(
                scopeKey: scope.scopeKey,
                row: row,
                textTheme: textTheme,
                assignRowStateFor: assignRowStateFor,
                onShowTiles: onShowTiles,
                onAssign: onAssign,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImprovableCommodityRow extends StatelessWidget {
  const _ImprovableCommodityRow({
    required this.scopeKey,
    required this.row,
    required this.textTheme,
    required this.assignRowStateFor,
    required this.onShowTiles,
    required this.onAssign,
  });

  final String scopeKey;
  final DevelopmentImprovableCommodityRow row;
  final TextTheme textTheme;
  final DevelopmentAssignRowState Function(
    String commodityId,
    Set<String> tileKeys,
  )
  assignRowStateFor;
  final void Function(Set<String> tileKeys) onShowTiles;
  final void Function(DevelopmentImproveAssignCandidate candidate) onAssign;

  @override
  Widget build(BuildContext context) {
    final displayName =
        CommodityCatalog.all
            .firstWhere((c) => c.id == row.commodityId)
            .displayName ??
        row.commodityId;
    final tileKeys = row.tileKeys.toSet();
    final assignState = assignRowStateFor(row.commodityId, tileKeys);
    final assignTooltip = assignState.disabledReason;
    final assignButton = CtActionTextButton(
      key: DevelopmentPanelKeys.assignButtonKey(scopeKey, row.commodityId),
      label: 'Assign',
      onPressed: assignState.enabled && assignState.candidate != null
          ? () => onAssign(assignState.candidate!)
          : null,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${row.count} $displayName',
              style: textTheme.bodySmall,
            ),
          ),
          CtActionTextButton(
            key: DevelopmentPanelKeys.showButtonKey(scopeKey, row.commodityId),
            label: 'Show',
            onPressed: () => onShowTiles(tileKeys),
          ),
          const SizedBox(width: CtSpacing.s),
          if (assignTooltip != null && !assignState.enabled)
            Tooltip(message: assignTooltip, child: assignButton)
          else
            assignButton,
        ],
      ),
    );
  }
}
