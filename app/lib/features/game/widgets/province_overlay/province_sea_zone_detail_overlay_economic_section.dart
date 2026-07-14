part of 'province_sea_zone_detail_overlay.dart';

/// Shared empty-state body for Economic/Military/Civilian/Naval (S9 muted).
Widget _emptyBodyDashText() {
  return Text('—', style: TextStyle(color: EditorialMonoclePalette.muted));
}

Widget _buildEconomicSection({
  required AppLocalizations l10n,
  required List<String> resourceKeysSorted,
  required Map<String, List<({String tileKey, String terrain, String impBase})>>
  byResImproved,
  required Map<String, List<({String tileKey, String terrain})>>
  byResImprovable,
  void Function(String?)? onHighlightTile,
  void Function(Iterable<String>?)? onHighlightTiles,
  ProvinceExtractionSnapshot? extractionSnapshot,
  Map<String, ProvinceImprovableCommodityCount> availableByCommodity = const {},
  Map<String, int> townProductionBonusByCommodity = const {},
}) {
  final children = <Widget>[
    _extractionAvailableSubsection(
      heading: l10n.provinceOverlay_extractionHeading,
      child: _extractionCondensedLine(
        l10n: l10n,
        snapshot: extractionSnapshot,
        onHighlightTiles: onHighlightTiles,
      ),
    ),
    _extractionAvailableSubsection(
      heading: l10n.provinceOverlay_availableHeading,
      child: _availableCondensedLine(
        l10n: l10n,
        availableByCommodity: availableByCommodity,
        onHighlightTiles: onHighlightTiles,
      ),
    ),
  ];

  for (final resId in resourceKeysSorted) {
    final improved = byResImproved[resId] ?? const [];
    for (final row in improved) {
      children.add(
        _economicHoverRow(
          tileKey: row.tileKey,
          onHighlightTile: onHighlightTile,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResourceLabelInline(
                commodityId: resId,
                labelStyle: TextStyle(color: EditorialMonoclePalette.fg),
              ),
              const SizedBox(width: CtSpacing.m / 2),
              Expanded(
                child: Text(
                  l10n.province_economic_resourceRow(
                    row.terrain,
                    commodityDisplayName(l10n, resId),
                    l10n.province_economic_withImprovement(row.impBase),
                  ),
                  style: TextStyle(color: EditorialMonoclePalette.fg),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final improvable = byResImprovable[resId] ?? const [];
    for (final row in improvable) {
      children.add(
        _economicHoverRow(
          tileKey: row.tileKey,
          onHighlightTile: onHighlightTile,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResourceLabelInline(
                commodityId: resId,
                labelStyle: TextStyle(color: EditorialMonoclePalette.muted),
              ),
              const SizedBox(width: CtSpacing.m / 2),
              Expanded(
                child: Text(
                  l10n.province_economic_resourceRow(
                    row.terrain,
                    commodityDisplayName(l10n, resId),
                    l10n.province_economic_improvableSuffix,
                  ),
                  style: TextStyle(color: EditorialMonoclePalette.muted),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  children.add(
    Padding(
      padding: const EdgeInsets.only(top: CtSpacing.m / 2),
      child: Text(
        l10n.provinceOverlay_townProductionHeading,
        style: TextStyle(
          color: EditorialMonoclePalette.fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
  if (townProductionBonusByCommodity.isEmpty) {
    children.add(_emptyBodyDashText());
  } else {
    final commodityIds = townProductionBonusByCommodity.keys.toList()..sort();
    for (final commodityId in commodityIds) {
      final qty = townProductionBonusByCommodity[commodityId] ?? 0;
      if (qty <= 0) continue;
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: CtSpacing.m / 2),
          child: Row(
            children: [
              ResourceIcon(commodityId: commodityId, size: 20),
              const SizedBox(width: CtSpacing.m / 2),
              Text(
                l10n.provinceOverlay_townProductionQuantity(qty),
                style: TextStyle(color: EditorialMonoclePalette.fg),
              ),
            ],
          ),
        ),
      );
    }
  }

  return _buildSection(
    l10n.provinceOverlay_sectionEconomic,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
}
