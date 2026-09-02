/// Sea-zone tab content assembly for [ProvinceSeaZoneDetailOverlay].
library;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';

import '../../flame/map_state/province_naval_combine_overlay_controls.dart'
    show ProvinceNavalCombineOverlayControls;
import '../../flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import '../../flame/map_state/province_transfer_to_home_fleet_overlay_controls.dart'
    show ProvinceTransferToHomeFleetOverlayControls;
import 'province_overlay_wide_lazy_sections.dart';
import 'province_sea_zone_detail_overlay_civilian_naval_sections.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'sea_zone_name_resolver.dart';
import 'package:colonizethis_app/features/game/flame/controls/map_tile_sight.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show kRegionOldWorld;

OverlayContent seaZoneContent({
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String seaZoneId,
  required String humanPlayerId,
  required Orders draftOrders,
  String? selectedTileKey,
  ProvinceNavalMissionOverlayControls navalMission =
      ProvinceNavalMissionOverlayControls.hidden,
  ProvinceTransferToHomeFleetOverlayControls transferToHomeFleet =
      ProvinceTransferToHomeFleetOverlayControls.hidden,
  ProvinceNavalCombineOverlayControls navalCombine =
      ProvinceNavalCombineOverlayControls.hidden,
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
    return OverlayContent(
      tabLabels: tabLabels,
      lazyWideDeferredFromIndex: tabLabels.length,
      sectionSpecs: [
        OverlaySectionSpec(
          title: l10n.provinceOverlay_sectionPolitical,
          builder: () => politicalObs,
        ),
        OverlaySectionSpec(
          title: l10n.provinceOverlay_sectionNaval,
          builder: () => navalObs,
        ),
      ],
    );
  }

  final seaName = seaZoneDisplayName(
    game: game,
    regionId: regionId,
    seaZoneId: localSeaZoneId,
  );
  final sightPhrase = mapTileSightPhraseForSelectedTile(
    l10n: l10n,
    region: region,
    selectedTileKey: selectedTileKey,
  );
  final political = buildOverlaySection(
    l10n.provinceOverlay_sectionPolitical,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.provinceOverlay_seaZone(seaName),
          style: overlayFgBodyStyle(),
        ),
        if (sightPhrase != null)
          Text(
            l10n.provinceOverlay_sight(sightPhrase),
            style: overlayFgBodyStyle(),
          ),
      ],
    ),
  );
  final naval = buildNavalSection(
    l10n: l10n,
    game: game,
    fleets: fleets,
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    pendingNavalPortProvinceId: null,
    pendingNavalSeaZoneId: seaZoneId,
    navalMission: navalMission,
    transferToHomeFleet: transferToHomeFleet,
    navalCombine: navalCombine,
  );

  final tabLabels = [
    l10n.provinceOverlay_sectionPolitical,
    l10n.provinceOverlay_sectionNaval,
  ];
  return OverlayContent(
    tabLabels: tabLabels,
    lazyWideDeferredFromIndex: tabLabels.length,
    sectionSpecs: [
      OverlaySectionSpec(
        title: l10n.provinceOverlay_sectionPolitical,
        builder: () => political,
      ),
      OverlaySectionSpec(
        title: l10n.provinceOverlay_sectionNaval,
        builder: () => naval,
      ),
    ],
  );
}
