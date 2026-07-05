/// Province and sea-zone tab content assembly for
/// [ProvinceSeaZoneDetailOverlay].

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
    final politicalObs = _buildSection(
      l10n.provinceOverlay_sectionPolitical,
      _obfuscatedBodyText(l10n.provinceOverlay_unknown),
    );
    final tileObs = _buildSection(
      l10n.provinceOverlay_sectionTile,
      _obfuscatedBodyText(l10n.provinceOverlay_unknown),
    );
    final obfuscatedSectionTitles = <String>[
      l10n.provinceOverlay_sectionPolitical,
      l10n.provinceOverlay_sectionTile,
      l10n.provinceOverlay_sectionEconomic,
      l10n.provinceOverlay_sectionMilitary,
      l10n.provinceOverlay_sectionCivilian,
      l10n.provinceOverlay_sectionNaval,
    ];
    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final title in obfuscatedSectionTitles)
          _buildSection(
            title,
            _obfuscatedBodyText(l10n.provinceOverlay_unknown),
          ),
      ],
    );
    final tabLabels = obfuscatedSectionTitles;
    final tabViews = [
      politicalObs,
      tileObs,
      _ObfuscatedSection(l10n: l10n),
      _ObfuscatedSection(l10n: l10n),
      _ObfuscatedSection(l10n: l10n),
      _ObfuscatedSection(l10n: l10n),
    ];
    return _OverlayContent(
      tabLabels: tabLabels,
      tabViews: tabViews,
      sections: sections,
    );
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
  final resourceByTile = game.worldState.resourceByTileKey;
  final tileState = game.worldState.tileState;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};

  final byResImproved =
      <String, List<({String tileKey, String terrain, String impBase})>>{};
  final byResImprovable = <String, List<({String tileKey, String terrain})>>{};
  for (final tk in tileKeys) {
    final res = resourceByTile[tk];
    if (tryParseTileKey(tk) == null) continue;
    if (!omniscientDetail && !prospected.contains(tk)) continue;
    final imp = tileState.improvementLevel(tk);
    final visLevel = omniscientDetail
        ? VisibilityLevel.fullyVisible
        : playerView.visibilityForTile(tk);
    if (!omniscientDetail && visLevel == VisibilityLevel.unknown) continue;
    final visibleRes = omniscientDetail
        ? res
        : resourceIdVisibleInPlayerView(playerView, tk, res);
    if (visibleRes == null) continue;
    final terrain = _economicTerrainTitleForTile(region, tk) ?? '—';
    if (imp > 0) {
      final impBase = _improvementBaseNameForPlayer(
        l10n: l10n,
        visLevel: visLevel,
        rawResourceId: res,
        visibleResourceId: visibleRes,
      );
      byResImproved.putIfAbsent(visibleRes, () => []).add((
        tileKey: tk,
        terrain: terrain,
        impBase: impBase,
      ));
    } else if (res != null && imp < 4) {
      byResImprovable.putIfAbsent(visibleRes, () => []).add((
        tileKey: tk,
        terrain: terrain,
      ));
    }
  }

  for (final list in byResImproved.values) {
    list.sort((a, b) => a.tileKey.compareTo(b.tileKey));
  }
  for (final list in byResImprovable.values) {
    list.sort((a, b) => a.tileKey.compareTo(b.tileKey));
  }

  final resourceKeysSorted = {
    ...byResImproved.keys,
    ...byResImprovable.keys,
  }.toList()..sort();

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
          resourceKeysSorted: resourceKeysSorted,
          byResImproved: byResImproved,
          byResImprovable: byResImprovable,
          onHighlightTile: onHighlightTile,
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

_OverlayContent _seaZoneContent({
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
    final politicalObs = _buildSection(
      l10n.provinceOverlay_sectionPolitical,
      _obfuscatedBodyText(l10n.provinceOverlay_unknown),
    );
    final navalObs = _buildSection(
      l10n.provinceOverlay_sectionNaval,
      _obfuscatedBodyText(l10n.provinceOverlay_unknown),
    );
    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [politicalObs, navalObs],
    );
    return _OverlayContent(
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
  final political = _buildSection(
    l10n.provinceOverlay_sectionPolitical,
    Text(
      l10n.provinceOverlay_seaZone(seaName),
      style: _fgBodyStyle(),
    ),
  );
  final naval = _buildNavalSection(
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
  return _OverlayContent(
    tabLabels: tabLabels,
    tabViews: tabViews,
    sections: sections,
  );
}
