/// Sea-zone tab content assembly for [ProvinceSeaZoneDetailOverlay].


import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';

import 'province_sea_zone_detail_overlay_civilian_naval_sections.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'sea_zone_name_resolver.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show kRegionOldWorld;

OverlayContent seaZoneContent({
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String seaZoneId,
  required String humanPlayerId,
  required Orders draftOrders,
}) {
  final regionId = prefixedIdRegionSegment(seaZoneId) ?? kRegionOldWorld;
  final localSeaZoneId = prefixedIdLocalSegment(seaZoneId);
  final fleets = game.worldState.fleets
      .where((f) => f.regionId == regionId && f.seaZoneId == localSeaZoneId)
      .toList();

  final isSeaZoneFullyUnrevealed =
      region.regionId == regionId &&
      !region.cells.any(
        (c) =>
            c.isSea &&
            c.regionCellId == localSeaZoneId &&
            c.visibility != TileVisibility.unrevealed,
      );
  if (isSeaZoneFullyUnrevealed) {
    final tabLabels = [
      l10n.provinceOverlay_sectionPolitical,
      l10n.provinceOverlay_sectionNaval,
    ];
    final politicalObs = buildOverlaySection(
      l10n.provinceOverlay_sectionPolitical,
      overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
    );
    final navalObs = buildOverlaySection(
      l10n.provinceOverlay_sectionNaval,
      overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
    );
    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [politicalObs, navalObs],
    );
    return OverlayContent(
      tabLabels: tabLabels,
      tabViews: [politicalObs, navalObs],
      sections: sections,
    );
  }

  final seaName = seaZoneDisplayName(
    game: game,
    regionId: regionId,
    seaZoneId: localSeaZoneId,
  );
  final political = buildOverlaySection(
    l10n.provinceOverlay_sectionPolitical,
    Text(
      l10n.provinceOverlay_seaZone(seaName),
      style: overlayFgBodyStyle(),
    ),
  );
  final naval = buildNavalSection(
    l10n: l10n,
    game: game,
    fleets: fleets,
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    pendingNavalPortProvinceId: null,
  );

  final tabLabels = [
    l10n.provinceOverlay_sectionPolitical,
    l10n.provinceOverlay_sectionNaval,
  ];
  final tabViews = [political, naval];
  final sections = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [political, naval],
  );
  return OverlayContent(
    tabLabels: tabLabels,
    tabViews: tabViews,
    sections: sections,
  );
}
