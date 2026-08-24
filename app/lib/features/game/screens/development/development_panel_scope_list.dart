import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show DevelopmentPanelRegionModel, DevelopmentPanelScopeRow;
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show DevelopmentAssignRowState, DevelopmentImproveAssignCandidate;
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';

import '../../widgets/units/shared/region_section_header.dart';
import 'development_panel_keys.dart';
import 'development_panel_scope_commodity_rows.dart';

/// Province and purchased-land scope list for one region tab.
class DevelopmentPanelScopeList extends StatelessWidget {
  const DevelopmentPanelScopeList({
    super.key,
    required this.regionModel,
    required this.onShowTiles,
    required this.assignRowStateFor,
    required this.onAssign,
    required this.provinceDisplayNamesById,
    this.nextYieldGistForTile,
  });

  final DevelopmentPanelRegionModel regionModel;
  final void Function(Set<String> tileKeys, {String? selectedTileKey})
  onShowTiles;
  final DevelopmentAssignRowState Function(String scopeKey, String commodityId)
  assignRowStateFor;
  final void Function(DevelopmentImproveAssignCandidate candidate) onAssign;
  final Map<String, String> provinceDisplayNamesById;
  final String? Function(String tileKey)? nextYieldGistForTile;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return ListView(
      children: [
        RegionSectionHeader(
          label: l10n.moveArmy_groupYourProvinces,
          variant: RegionHeaderVariant.bottomBorderMuted,
        ),
        ...regionModel.ownedScopes.map(
          (scope) => _ScopeCard(
            l10n: l10n,
            scope: scope,
            onShowTiles: onShowTiles,
            assignRowStateFor: assignRowStateFor,
            onAssign: onAssign,
            provinceDisplayNamesById: provinceDisplayNamesById,
            nextYieldGistForTile: nextYieldGistForTile,
          ),
        ),
        const SizedBox(height: CtSpacing.m),
        RegionSectionHeader(
          key: DevelopmentPanelKeys.purchasedSectionKey,
          label: l10n.development_purchasedLand,
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
              l10n: l10n,
              scope: scope,
              onShowTiles: onShowTiles,
              assignRowStateFor: assignRowStateFor,
              onAssign: onAssign,
              provinceDisplayNamesById: provinceDisplayNamesById,
              nextYieldGistForTile: nextYieldGistForTile,
            ),
          ),
      ],
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.l10n,
    required this.scope,
    required this.onShowTiles,
    required this.assignRowStateFor,
    required this.onAssign,
    required this.provinceDisplayNamesById,
    this.nextYieldGistForTile,
  });

  final AppLocalizations l10n;

  final DevelopmentPanelScopeRow scope;
  final void Function(Set<String> tileKeys, {String? selectedTileKey})
  onShowTiles;
  final DevelopmentAssignRowState Function(String scopeKey, String commodityId)
  assignRowStateFor;
  final void Function(DevelopmentImproveAssignCandidate candidate) onAssign;
  final Map<String, String> provinceDisplayNamesById;
  final String? Function(String tileKey)? nextYieldGistForTile;

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
              l10n.provinceOverlay_owner(scope.provinceOwnerDisplayName!),
              style: textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.muted,
              ),
            ),
          const SizedBox(height: 4),
          if (!scope.hasImprovableResources)
            Text(
              l10n.development_noImprovableResources,
              style: textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.muted,
              ),
            )
          else
            ...scope.improvableCommodities.map(
              (row) => DevelopmentImprovableCommodityRowView(
                l10n: l10n,
                scopeKey: scope.scopeKey,
                row: row,
                textTheme: textTheme,
                assignRowStateFor: assignRowStateFor,
                onShowTiles: onShowTiles,
                onAssign: onAssign,
                provinceDisplayNamesById: provinceDisplayNamesById,
                nextYieldGistForTile: nextYieldGistForTile,
              ),
            ),
        ],
      ),
    );
  }
}
