/// Tile section builder for [ProvinceSeaZoneDetailOverlay].

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_capital_link_preview.dart';
import 'province_sea_zone_detail_overlay_tile_section_labels.dart';
import 'province_sea_zone_detail_overlay_tile_section_revealed.dart';

Widget buildTileSection({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
  required int civilianCount,
  String? selectedTileKey,
  required bool showExploreActionIcon,
  required bool exploreActionEnabled,
  VoidCallback? onExploreWithExplorerTap,
  required bool showProspectActionIcon,
  required bool prospectActionEnabled,
  VoidCallback? onProspectWithExplorerTap,
  required bool showBuildImprovementActionIcon,
  required bool buildImprovementActionEnabled,
  VoidCallback? onBuildImprovementTap,
  ProvinceTileCapitalLinkPreview? tileCapitalLinkPreview,
}) {
  if (selectedTileKey == null) {
    return buildOverlaySection(
      l10n.provinceOverlay_sectionTile,
      Text(
        l10n.provinceOverlay_clickTileForDetails,
        style: TextStyle(color: EditorialMonoclePalette.muted),
      ),
    );
  }
  final coords = tryParseProvinceOverlayTileCoords(
    regionId: region.regionId,
    regionWidth: region.width,
    regionHeight: region.height,
    selectedTileKey: selectedTileKey,
  );
  if (coords == null) {
    return buildOverlaySection(
      l10n.provinceOverlay_sectionTile,
      overlayEmptyBodyDashText(),
    );
  }
  final x = coords.x;
  final y = coords.y;
  final cell = region.cellAt(x, y);
  if (cell.visibility == TileVisibility.unrevealed) {
    return buildOverlaySection(
      l10n.provinceOverlay_sectionTile,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          overlayObfuscatedBodyText(l10n.provinceOverlay_tileCoordinatesUnknown),
          overlayObfuscatedBodyText(l10n.provinceOverlay_tileTerrainUnknown),
          overlayObfuscatedBodyText(l10n.provinceOverlay_tileResourceUnknown),
          overlayObfuscatedBodyText(l10n.provinceOverlay_tileProspectedUnknown),
          overlayObfuscatedBodyText(l10n.provinceOverlay_tileImprovementUnknown),
          overlayObfuscatedBodyText(l10n.provinceOverlay_tileRoadUnknown),
          overlayObfuscatedBodyText(l10n.provinceOverlay_tileCivilianUnitsUnknown),
        ],
      ),
    );
  }
  return buildRevealedTileSection(
    context: context,
    l10n: l10n,
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    civilianCount: civilianCount,
    selectedTileKey: selectedTileKey,
    x: x,
    y: y,
    cell: cell,
    showExploreActionIcon: showExploreActionIcon,
    exploreActionEnabled: exploreActionEnabled,
    onExploreWithExplorerTap: onExploreWithExplorerTap,
    showProspectActionIcon: showProspectActionIcon,
    prospectActionEnabled: prospectActionEnabled,
    onProspectWithExplorerTap: onProspectWithExplorerTap,
    showBuildImprovementActionIcon: showBuildImprovementActionIcon,
    buildImprovementActionEnabled: buildImprovementActionEnabled,
    onBuildImprovementTap: onBuildImprovementTap,
    tileCapitalLinkPreview: tileCapitalLinkPreview,
  );
}
