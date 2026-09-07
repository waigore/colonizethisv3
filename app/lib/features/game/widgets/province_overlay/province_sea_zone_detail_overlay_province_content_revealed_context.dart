import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show
        PlayerView,
        fleetsInPortAtProvince,
        kRegionNewWorld,
        provincePanelShowsFullTileDerivedIntel;

import 'package:colonizethis_app/core/utils/prefixed_id.dart';

import 'province_overlay_unit_partition.dart';
import 'province_sea_zone_detail_overlay_province_content_intel.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';

/// Derived overlay locals for revealed MAP20001 province content.
({
  String regionId,
  Province? province,
  List<Unit> military,
  List<Unit> civilian,
  int visibleCivilianCount,
  List<Fleet> fleetsInPort,
  bool showsFullIntel,
  ({
    Map<String, List<({String tileKey, String terrain, String impBase})>>
    byResImproved,
    Map<String, List<({String tileKey, String terrain})>> byResImprovable,
    List<String> resourceKeysSorted,
  })
  tileIntel,
})
resolveRevealedProvinceOverlayContext({
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
  required bool omniscientDetail,
}) {
  final regionId = prefixedIdRegionSegment(provinceId) ?? region.regionId;
  final province = findProvinceForSeaZoneOverlay(game, provinceId);
  final regionData = provinceId.startsWith(kRegionNewWorld)
      ? game.worldState.newWorld
      : game.worldState.oldWorld;
  final partitioned = partitionProvinceOverlayUnits(
    regionUnits: regionData.units,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
  );
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[provinceId] ??
      [];
  final showsFullIntel =
      omniscientDetail ||
      provincePanelShowsFullTileDerivedIntel(
        game: game,
        view: playerView,
        humanPlayerId: humanPlayerId,
        provinceId: provinceId,
        provinceTileKeys: tileKeys,
      );
  return (
    regionId: regionId,
    province: province,
    military: partitioned.military,
    civilian: partitioned.civilian,
    visibleCivilianCount: partitioned.visibleCivilianCount,
    fleetsInPort: fleetsInPortAtProvince(game.worldState, provinceId),
    showsFullIntel: showsFullIntel,
    tileIntel: aggregateProvinceTileIntel(
      l10n: l10n,
      game: game,
      region: region,
      provinceId: provinceId,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      tileKeys: tileKeys,
      omniscientDetail: omniscientDetail,
    ),
  );
}
