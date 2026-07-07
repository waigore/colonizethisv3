/// Sea-zone tab content assembly for [ProvinceSeaZoneDetailOverlay].

part of 'province_sea_zone_detail_overlay.dart';

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
