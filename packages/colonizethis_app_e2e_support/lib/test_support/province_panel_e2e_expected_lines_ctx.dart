part of 'province_panel_e2e_expected_lines.dart';

const String _kRoadRailPrimitiveVersusRailGloss =
    'Basic land link for connectivity and yield caps. Railroads are transport level 4.';

String _roadRailSupplementaryLabel(int roadLevel) {
  return switch (roadLevel) {
    0 => 'none',
    1 => 'primitive road',
    2 => 'improved road',
    4 => 'port or railroad',
    _ => 'non-standard transport level',
  };
}

String _roadRailTransportLevelPrimaryLine(int transportLevel) {
  return 'Road / railroad: transport level $transportLevel';
}

class _ProvincePanelWideExpectedCtx {
  _ProvincePanelWideExpectedCtx({
    required this.game,
    required this.region,
    required this.provinceId,
    required this.humanPlayerId,
    required this.playerView,
    required this.draftOrders,
    required this.selectedTileKey,
    required this.regionId,
    required this.province,
    required this.military,
    required this.civilian,
    required this.visibleCivilianCount,
    required this.fleetsInPort,
    required this.resourceByTile,
    required this.tileState,
    required this.prospected,
    required this.byResImproved,
    required this.byResImprovable,
    required this.resourceKeysSorted,
    this.topology,
    this.tileMapByRegion,
  });

  final Game game;
  final RegionMapViewData region;
  final String provinceId;
  final String humanPlayerId;
  final PlayerView playerView;
  final Orders draftOrders;
  final String selectedTileKey;
  final String regionId;
  final Province? province;
  final List<Unit> military;
  final List<Unit> civilian;
  final int visibleCivilianCount;
  final List<Fleet> fleetsInPort;
  final Map<String, String> resourceByTile;
  final TileMapState tileState;
  final Set<String> prospected;
  final MapTopology? topology;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Map<String, List<({String tileKey, String terrain, String impBase})>>
  byResImproved;
  final Map<String, List<({String tileKey, String terrain})>> byResImprovable;
  final List<String> resourceKeysSorted;
}

_ProvincePanelWideExpectedCtx _buildProvincePanelWideExpectedCtx(
  CtE2eLastPanelSnapshot snap,
) {
  final game = snap.game;
  final region = snap.region;
  final provinceId = snap.displayId;
  final humanPlayerId = snap.humanPlayerId;
  final playerView = snap.playerView;
  final draftOrders = snap.draftOrders;
  final selectedTileKey = snap.selectedTileKey;

  final regionId = prefixedIdRegionSegment(provinceId) ?? region.regionId;
  final localProvinceId = prefixedIdLocalSegment(provinceId);
  final isFullyUnrevealed =
      region.regionId == regionId &&
      !region.cells.any(
        (c) =>
            c.regionCellId == localProvinceId &&
            c.visibility != TileVisibility.unrevealed,
      );
  if (isFullyUnrevealed) {
    throw StateError(
      'E2E expected a revealed capital province; got fully unrevealed $provinceId',
    );
  }

  final province = _findProvince(game, provinceId);
  final regionData = provinceId.startsWith('newWorld')
      ? game.worldState.newWorld
      : game.worldState.oldWorld;
  final units = regionData.units
      .where((u) => u.locationProvinceId == provinceId)
      .toList();
  final military = units.where((u) => isMilitaryUnit(u.type)).toList();
  final civilian = units.where((u) => !isMilitaryUnit(u.type)).toList();
  final visibleCivilianCount = civilian
      .where(
        (u) => foreignCivilianVisibleToPlayer(
          unit: u,
          viewerPlayerId: humanPlayerId,
          view: playerView,
        ),
      )
      .length;
  final fleetsInPort = fleetsInPortAtProvince(game.worldState, provinceId);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[provinceId] ??
      [];
  final resourceByTile = game.worldState.resourceByTileKey;
  final tileState = game.worldState.tileState;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};

  final byResImproved =
      <String, List<({String tileKey, String terrain, String impBase})>>{};
  final byResImprovable = <String, List<({String tileKey, String terrain})>>{};

  for (final tk in tileKeys) {
    final res = resourceByTile[tk];
    if (tryParseTileKey(tk) == null) continue;
    if (!prospected.contains(tk)) continue;
    final imp = tileState.improvementLevel(tk);
    final visLevel = playerView.visibilityForTile(tk);
    final visibleRes = resourceIdVisibleInPlayerView(playerView, tk, res);

    if (visibleRes == null) continue;

    final terrain = _economicTerrainTitleForTile(region, tk) ?? '—';
    if (imp > 0) {
      final impBase = _improvementBaseNameForPlayer(
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

  return _ProvincePanelWideExpectedCtx(
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    draftOrders: draftOrders,
    selectedTileKey: selectedTileKey,
    regionId: regionId,
    province: province,
    military: military,
    civilian: civilian,
    visibleCivilianCount: visibleCivilianCount,
    fleetsInPort: fleetsInPort,
    resourceByTile: resourceByTile,
    tileState: tileState,
    prospected: prospected,
    byResImproved: byResImproved,
    byResImprovable: byResImprovable,
    resourceKeysSorted: resourceKeysSorted,
    topology: snap.topology,
    tileMapByRegion: snap.tileMapByRegion,
  );
}

void _appendProvincePanelSection(
  List<String> out,
  String title,
  void Function() body,
) {
  // Section headers render via CtSectionLabel under the dark editorial-
  // monocle theme (Refs #2865 S4), which upper-cases the label per SPEC
  // SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme section
  // labels. The expected text mirror must therefore upper-case the title
  // before adding it to the snapshot output.
  out.add(title.toUpperCase());
  body();
}
