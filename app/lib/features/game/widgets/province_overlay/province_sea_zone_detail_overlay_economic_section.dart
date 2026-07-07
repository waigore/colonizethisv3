
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
  Map<String, int> townProductionBonusByCommodity = const {},
}) {
  final children = <Widget>[];

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
                    resId,
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
                    resId,
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
