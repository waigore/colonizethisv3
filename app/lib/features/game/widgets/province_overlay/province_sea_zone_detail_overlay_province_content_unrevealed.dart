/// Fully unrevealed province tab assembly for [ProvinceSeaZoneDetailOverlay].
library;

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'province_overlay_wide_lazy_sections.dart';
import 'province_sea_zone_detail_overlay_support.dart';

bool provinceContentIsFullyUnrevealed({
  required RegionMapViewData region,
  required String provinceId,
  required bool omniscientDetail,
}) {
  final regionId = prefixedIdRegionSegment(provinceId) ?? region.regionId;
  final localProvinceId = prefixedIdLocalSegment(provinceId);
  return !omniscientDetail &&
      region.regionId == regionId &&
      !region.cells.any(
        (c) =>
            c.regionCellId == localProvinceId &&
            c.visibility != TileVisibility.unrevealed,
      );
}

OverlayContent provinceContentUnrevealed({required AppLocalizations l10n}) {
  Widget obfuscatedSection(String title) => buildOverlaySection(
    title,
    overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
  );

  final obfuscatedSectionTitles = <String>[
    l10n.provinceOverlay_sectionPolitical,
    l10n.provinceOverlay_sectionTile,
    l10n.provinceOverlay_sectionEconomic,
    l10n.provinceOverlay_sectionMilitary,
    l10n.provinceOverlay_sectionCivilian,
    l10n.provinceOverlay_sectionNaval,
  ];
  return OverlayContent(
    tabLabels: obfuscatedSectionTitles,
    sectionSpecs: [
      for (final title in obfuscatedSectionTitles)
        OverlaySectionSpec(
          title: title,
          builder: () => obfuscatedSection(title),
        ),
    ],
  );
}
