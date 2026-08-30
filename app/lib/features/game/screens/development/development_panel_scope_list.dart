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

enum _ScopeListEntryKind {
  ownedHeader,
  scopeCard,
  purchasedHeader,
  purchasedEmpty,
  sectionGap,
}

class _ScopeListEntry {
  const _ScopeListEntry._(this.kind, {this.scope});

  const _ScopeListEntry.ownedHeader() : this._(_ScopeListEntryKind.ownedHeader);

  const _ScopeListEntry.scopeCard(DevelopmentPanelScopeRow scope)
    : this._(_ScopeListEntryKind.scopeCard, scope: scope);

  const _ScopeListEntry.purchasedHeader()
    : this._(_ScopeListEntryKind.purchasedHeader);

  const _ScopeListEntry.purchasedEmpty()
    : this._(_ScopeListEntryKind.purchasedEmpty);

  const _ScopeListEntry.sectionGap() : this._(_ScopeListEntryKind.sectionGap);

  final _ScopeListEntryKind kind;
  final DevelopmentPanelScopeRow? scope;
}

List<_ScopeListEntry> _flattenScopeListEntries(
  DevelopmentPanelRegionModel regionModel,
) {
  return [
    const _ScopeListEntry.ownedHeader(),
    ...regionModel.ownedScopes.map(_ScopeListEntry.scopeCard),
    const _ScopeListEntry.sectionGap(),
    const _ScopeListEntry.purchasedHeader(),
    if (regionModel.purchasedScopes.isEmpty)
      const _ScopeListEntry.purchasedEmpty()
    else
      ...regionModel.purchasedScopes.map(_ScopeListEntry.scopeCard),
  ];
}

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
    final entries = _flattenScopeListEntries(regionModel);
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        switch (entry.kind) {
          case _ScopeListEntryKind.ownedHeader:
            return RegionSectionHeader(
              label: l10n.moveArmy_groupYourProvinces,
              variant: RegionHeaderVariant.bottomBorderMuted,
            );
          case _ScopeListEntryKind.scopeCard:
            return _ScopeCard(
              l10n: l10n,
              scope: entry.scope!,
              onShowTiles: onShowTiles,
              assignRowStateFor: assignRowStateFor,
              onAssign: onAssign,
              provinceDisplayNamesById: provinceDisplayNamesById,
              nextYieldGistForTile: nextYieldGistForTile,
            );
          case _ScopeListEntryKind.purchasedHeader:
            return RegionSectionHeader(
              key: DevelopmentPanelKeys.purchasedSectionKey,
              label: l10n.development_purchasedLand,
              variant: RegionHeaderVariant.bottomBorderMuted,
            );
          case _ScopeListEntryKind.purchasedEmpty:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: CtSpacing.s),
              child: Text(
                '—',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EditorialMonoclePalette.muted,
                ),
              ),
            );
          case _ScopeListEntryKind.sectionGap:
            return const SizedBox(height: CtSpacing.m);
        }
      },
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
