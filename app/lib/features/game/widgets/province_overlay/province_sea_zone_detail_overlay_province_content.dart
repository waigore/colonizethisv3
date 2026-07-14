/// Province tab content assembly for [ProvinceSeaZoneDetailOverlay].

part of 'province_sea_zone_detail_overlay.dart';

_OverlayContent _provinceContent({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
  required Orders draftOrders,
  String? selectedTileKey,
  void Function(String?)? onHighlightTile,
  required bool showProspectActionIcon,
  required bool prospectActionEnabled,
  VoidCallback? onProspectWithExplorerTap,
  required bool showExploreActionIcon,
  required bool exploreActionEnabled,
  VoidCallback? onExploreWithExplorerTap,
  required bool showBuildImprovementActionIcon,
  required bool buildImprovementActionEnabled,
  VoidCallback? onBuildImprovementTap,
  bool omniscientDetail = false,
  Map<String, int> townProductionBonusByCommodity = const {},
  ProvinceExtractionSnapshot? extractionSnapshot,
  Map<String, ProvinceImprovableCommodityCount> availableByCommodity =
      const {},
  void Function(Iterable<String>?)? onHighlightTiles,
}) {
  final regionId = prefixedIdRegionSegment(provinceId) ?? region.regionId;
  final localProvinceId = prefixedIdLocalSegment(provinceId);
  final isFullyUnrevealed =
      !omniscientDetail &&
      region.regionId == regionId &&
      !region.cells.any(
        (c) =>
            c.regionCellId == localProvinceId &&
            c.visibility != TileVisibility.unrevealed,
      );
  if (isFullyUnrevealed) {
    return _provinceContentUnrevealed(l10n: l10n);
  }
  final province = _findProvince(game, provinceId);
  final regionData = provinceId.startsWith(kRegionNewWorld)
      ? game.worldState.newWorld
      : game.worldState.oldWorld;
  final partitioned = partitionProvinceOverlayUnits(
    regionUnits: regionData.units,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
  );
  final military = partitioned.military;
  final civilian = partitioned.civilian;
  final visibleCivilianCount = partitioned.visibleCivilianCount;
  final fleetsInPort = fleetsInPortAtProvince(game.worldState, provinceId);
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
  final tileIntel = _aggregateProvinceTileIntel(
    l10n: l10n,
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    tileKeys: tileKeys,
    omniscientDetail: omniscientDetail,
  );

  final tileSection = _buildTileSection(
    context: context,
    l10n: l10n,
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    civilianCount: visibleCivilianCount,
    selectedTileKey: selectedTileKey,
    showProspectActionIcon: showProspectActionIcon,
    prospectActionEnabled: prospectActionEnabled,
    onProspectWithExplorerTap: onProspectWithExplorerTap,
    showExploreActionIcon: showExploreActionIcon,
    exploreActionEnabled: exploreActionEnabled,
    onExploreWithExplorerTap: onExploreWithExplorerTap,
    showBuildImprovementActionIcon: showBuildImprovementActionIcon,
    buildImprovementActionEnabled: buildImprovementActionEnabled,
    onBuildImprovementTap: onBuildImprovementTap,
  );
  final political = _buildPoliticalSection(
    l10n: l10n,
    name: province?.displayName ?? provinceId,
    ownerName: _ownerName(l10n, game, province?.ownerId),
    regionLabel: provinceOverlayRegionLabel(l10n, regionId),
    isCapital: provinceOverlayIsCapital(game, provinceId),
    townDevelopmentLevel: province?.townDevelopmentLevel ??
        kTownDevelopmentLevelMin,
  );
  final economic = showsFullIntel
      ? _buildEconomicSection(
          l10n: l10n,
          resourceKeysSorted: tileIntel.resourceKeysSorted,
          byResImproved: tileIntel.byResImproved,
          byResImprovable: tileIntel.byResImprovable,
          onHighlightTile: onHighlightTile,
          onHighlightTiles: onHighlightTiles,
          extractionSnapshot: extractionSnapshot,
          availableByCommodity: availableByCommodity,
          townProductionBonusByCommodity: townProductionBonusByCommodity,
        )
      : _buildSection(
          l10n.provinceOverlay_sectionEconomic,
          _obfuscatedBodyText(l10n.provinceOverlay_unknown),
        );
  final militarySection = showsFullIntel
      ? _buildMilitarySectionByOwner(
          l10n: l10n,
          game: game,
          military: military,
          humanPlayerId: humanPlayerId,
          provinceId: provinceId,
          draftOrders: draftOrders,
        )
      : _buildSection(
          l10n.provinceOverlay_sectionMilitary,
          _obfuscatedBodyText(l10n.provinceOverlay_unknown),
        );
  final civilianSection = showsFullIntel
      ? _buildCivilianSectionFiltered(
          l10n: l10n,
          game: game,
          civilian: civilian,
          humanPlayerId: humanPlayerId,
          playerView: playerView,
          draftOrders: draftOrders,
        )
      : _buildSection(
          l10n.provinceOverlay_sectionCivilian,
          _obfuscatedBodyText(l10n.provinceOverlay_unknown),
        );
  final naval = showsFullIntel
      ? _buildNavalSection(
          l10n: l10n,
          game: game,
          fleets: fleetsInPort,
          humanPlayerId: humanPlayerId,
          draftOrders: draftOrders,
          pendingNavalPortProvinceId: provinceId,
        )
      : _buildSection(
          l10n.provinceOverlay_sectionNaval,
          _obfuscatedBodyText(l10n.provinceOverlay_unknown),
        );

  final tabLabels = [
    l10n.provinceOverlay_sectionPolitical,
    l10n.provinceOverlay_sectionTile,
    l10n.provinceOverlay_sectionEconomic,
    l10n.provinceOverlay_sectionMilitary,
    l10n.provinceOverlay_sectionCivilian,
    l10n.provinceOverlay_sectionNaval,
  ];
  final tabViews = [
    political,
    tileSection,
    economic,
    militarySection,
    civilianSection,
    naval,
  ];
  final sections = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      political,
      tileSection,
      economic,
      militarySection,
      civilianSection,
      naval,
    ],
  );
  return _OverlayContent(
    tabLabels: tabLabels,
    tabViews: tabViews,
    sections: sections,
  );
}
