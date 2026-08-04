
import 'package:colonizethis_models/colonizethis_models.dart'
    show ProvinceExtractionSnapshot;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../production/commodity_ui_helpers.dart';
import 'province_sea_zone_detail_overlay_economic_condensed.dart';
import 'province_sea_zone_detail_overlay_sections_economic_labels.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart' show ProvinceImprovableCommodityCount;

Widget buildEconomicSection({
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
    extractionAvailableSubsection(
      heading: l10n.provinceOverlay_extractionHeading,
      child: extractionCondensedLine(
        l10n: l10n,
        snapshot: extractionSnapshot,
        onHighlightTiles: onHighlightTiles,
      ),
    ),
    extractionAvailableSubsection(
      heading: l10n.provinceOverlay_availableHeading,
      child: availableCondensedLine(
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
        economicHoverRow(
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
        economicHoverRow(
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
    children.add(overlayEmptyBodyDashText());
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

  return buildOverlaySection(
    l10n.provinceOverlay_sectionEconomic,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
}
