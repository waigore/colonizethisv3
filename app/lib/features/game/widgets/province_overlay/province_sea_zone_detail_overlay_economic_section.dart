part of 'province_sea_zone_detail_overlay.dart';

/// Shared empty-state placeholder body used by the Economic, Military,
/// Civilian, and Naval sections when their content list is empty.
///
/// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
/// § Style / implementation — Dark-theme empty-state body tokens (S9).
///
/// `EditorialMonoclePalette.muted` is a runtime OKLCH→`Color` getter, so
/// the [TextStyle] cannot be `const`; the helper centralizes the token
/// so every empty surface stays in sync (mirroring the obfuscated
/// `???` helper's single-source pattern).
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

Widget _extractionAvailableSubsection({
  required String heading,
  required Widget child,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: CtSpacing.m / 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          heading,
          style: TextStyle(
            color: EditorialMonoclePalette.fg,
            fontWeight: FontWeight.bold,
          ),
        ),
        child,
      ],
    ),
  );
}

Widget _extractionCondensedLine({
  required AppLocalizations l10n,
  required ProvinceExtractionSnapshot? snapshot,
  void Function(Iterable<String>?)? onHighlightTiles,
}) {
  if (snapshot == null || snapshot.byCommodity.isEmpty) {
    return _emptyBodyDashText();
  }
  final segments = <Widget>[];
  for (final commodity in CommodityCatalog.all) {
    final totals = snapshot.byCommodity[commodity.id];
    if (totals == null) continue;
    if (totals.effective == 0 && totals.full == 0) continue;
    final name = commodityDisplayName(l10n, commodity.id);
    final qtyText = totals.effective < totals.full
        ? l10n.provinceOverlay_extractionQuantityPartial(
            totals.effective,
            totals.full,
            name,
          )
        : l10n.provinceOverlay_extractionQuantity(totals.effective, name);
    if (segments.isNotEmpty) {
      segments.add(
        Text(', ', style: TextStyle(color: EditorialMonoclePalette.fg)),
      );
    }
    segments.add(
      _commodityHoverSegment(
        tileKeys: totals.tileKeys,
        onHighlightTiles: onHighlightTiles,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResourceIcon(commodityId: commodity.id, size: 20),
            const SizedBox(width: CtSpacing.m / 4),
            Text(qtyText, style: TextStyle(color: EditorialMonoclePalette.fg)),
          ],
        ),
      ),
    );
  }
  if (segments.isEmpty) return _emptyBodyDashText();
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: segments,
  );
}

Widget _availableCondensedLine({
  required AppLocalizations l10n,
  required Map<String, ProvinceImprovableCommodityCount> availableByCommodity,
  void Function(Iterable<String>?)? onHighlightTiles,
}) {
  if (availableByCommodity.isEmpty) return _emptyBodyDashText();
  final segments = <Widget>[];
  for (final commodity in CommodityCatalog.all) {
    final entry = availableByCommodity[commodity.id];
    if (entry == null || entry.count <= 0) continue;
    final name = commodityDisplayName(l10n, commodity.id);
    final qtyText = l10n.provinceOverlay_availableTileCount(entry.count, name);
    if (segments.isNotEmpty) {
      segments.add(
        Text(', ', style: TextStyle(color: EditorialMonoclePalette.fg)),
      );
    }
    segments.add(
      _commodityHoverSegment(
        tileKeys: entry.tileKeys,
        onHighlightTiles: onHighlightTiles,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResourceIcon(commodityId: commodity.id, size: 20),
            const SizedBox(width: CtSpacing.m / 4),
            Text(qtyText, style: TextStyle(color: EditorialMonoclePalette.fg)),
          ],
        ),
      ),
    );
  }
  if (segments.isEmpty) return _emptyBodyDashText();
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: segments,
  );
}

Widget _commodityHoverSegment({
  required List<String> tileKeys,
  required void Function(Iterable<String>?)? onHighlightTiles,
  required Widget child,
}) {
  if (onHighlightTiles == null || tileKeys.isEmpty) return child;
  return MouseRegion(
    onEnter: (_) => onHighlightTiles(tileKeys),
    onExit: (_) => onHighlightTiles(null),
    child: child,
  );
}
