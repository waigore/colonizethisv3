/// Tile section builder for [ProvinceSeaZoneDetailOverlay].

part of 'province_sea_zone_detail_overlay.dart';

Widget _buildTileSection({
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
}) {
  if (selectedTileKey == null) {
    // SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
    // § Dark-theme Tile section placeholder body tokens (S5 follow-up).
    // The no-selection guidance prompt is placeholder copy, not live
    // world-state data, so it resolves to the muted token rather than
    // falling through `DefaultTextStyle` to the Material `bodyMedium`.
    return _buildSection(
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
    // SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
    // § Dark-theme Tile section placeholder body tokens (S5 follow-up).
    // Reuse the shared S9 em-dash helper so every `Text('—')` placeholder
    // surface in the overlay resolves to one muted token source.
    return _buildSection(
      l10n.provinceOverlay_sectionTile,
      _emptyBodyDashText(),
    );
  }
  final x = coords.x;
  final y = coords.y;
  final cell = region.cellAt(x, y);
  if (cell.visibility == TileVisibility.unrevealed) {
    return _buildSection(
      l10n.provinceOverlay_sectionTile,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _obfuscatedBodyText(l10n.provinceOverlay_tileCoordinatesUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileTerrainUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileResourceUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileProspectedUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileImprovementUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileRoadUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileCivilianUnitsUnknown),
        ],
      ),
    );
  }
  return _buildRevealedTileSection(
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
  );
}
