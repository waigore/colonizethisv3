import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'economy_resource_constants.dart';
import 'tile_extraction_pipeline.dart';
import 'tile_extraction_yield.dart';
import 'package:colonizethis_economy/src/logging.dart';

/// Shared per-faction / per-tile traversal helpers for the non-Great-Power
/// extraction flow. Both `computeNonGreatPowerExtraction`
/// (`non_gp_extraction.dart`) and `computeNonGreatPowerAutoOffers`
/// (`non_gp_auto_offers.dart`) compose these helpers so the faction and tile
/// loops are defined once. These symbols are library-internal (`src/`) and are
/// intentionally not re-exported from the package barrel.

/// Single-commodity contribution from one connected tile owned by a non-GP
/// faction. Returned by [forEachNonGpTileContribution] for each tile that
/// yields units.
class NonGpTileContribution {
  const NonGpTileContribution({
    required this.commodityId,
    required this.units,
  });

  final CommodityId commodityId;
  final int units;
}

/// Visits each minor nation and tribe that has a capital and non-empty
/// connectivity, invoking [onFaction] with the resolved capital ids and
/// [ConnectivityResult]. Shared by `computeNonGreatPowerExtraction` and
/// `computeNonGreatPowerAutoOffers` so the faction loop is not duplicated.
void forEachNonGpFaction({
  required Game game,
  required Map<String, ConnectivityResult> connectivityByFactionId,
  required void Function({
    required String factionId,
    required String capitalProvinceId,
    required String capitalRegionId,
    required ConnectivityResult connectivity,
  })
  onFaction,
}) {
  void visit({
    required String factionId,
    required String? capitalProvinceId,
    required String? capitalRegionId,
  }) {
    if (capitalProvinceId == null || capitalRegionId == null) return;
    final cr = connectivityByFactionId[factionId];
    if (cr == null || cr.connected.isEmpty) return;
    onFaction(
      factionId: factionId,
      capitalProvinceId: capitalProvinceId,
      capitalRegionId: capitalRegionId,
      connectivity: cr,
    );
  }

  for (final minor in game.minorNations) {
    visit(
      factionId: minor.id,
      capitalProvinceId: minor.capitalProvinceId,
      capitalRegionId: minor.capitalTile?.regionId,
    );
  }
  for (final tribe in game.tribes) {
    visit(
      factionId: tribe.id,
      capitalProvinceId: tribe.capitalProvinceId,
      capitalRegionId: tribe.capitalTile?.regionId,
    );
  }
}

/// Tile keys for a non-GP pass. Extraction preserves
/// [ConnectivityResult.connected] insertion order; auto-offers sort ascending
/// for deterministic offer lists.
Iterable<String> _nonGpTileKeysInPassOrder(
  Set<String> connected, {
  required bool sorted,
}) {
  if (sorted) {
    return connected.toList()..sort();
  }
  return connected;
}

/// Walks connected tiles for one non-GP faction and invokes [onContribution]
/// for each tile that yields units. Shared by extraction (aggregate totals)
/// and auto-offers (per-tile orders); [sortTileKeys] selects the pass ordering.
void forEachNonGpTileContribution({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String capitalProvinceId,
  required String capitalRegionId,
  required ConnectivityResult connectivity,
  required Set<String> portTileKeys,
  required Map<String, Province> provincesByFullId,
  required bool sortTileKeys,
  required void Function(String tileKey, NonGpTileContribution contribution)
  onContribution,
}) {
  final tileKeys = _nonGpTileKeysInPassOrder(
    connectivity.connected,
    sorted: sortTileKeys,
  );
  for (final tileKey in tileKeys) {
    final contribution = _computeNonGpTileContribution(
      game: game,
      tileMapByRegion: tileMapByRegion,
      factionCapitalProvinceId: capitalProvinceId,
      factionCapitalRegionId: capitalRegionId,
      tileKey: tileKey,
      connectedTileKeys: connectivity.connected,
      pathTransportCap: connectivity.pathTransportCap,
      connectedByRoadRule: connectivity.connectedByRoadRule,
      portTileKeys: portTileKeys,
      provincesByFullId: provincesByFullId,
    );
    if (contribution != null) {
      onContribution(tileKey, contribution);
    }
  }
}

/// Single-commodity contribution from one connected tile owned by a non-GP
/// faction. Returns null when the tile contributes no units (not connected,
/// invalid tile key, no resource, mineral resource excluded for non-GPs,
/// missing province row, or computed effective units `<= 0`).
///
/// Mirrors the per-tile branches of
/// [computeTileExtractionContributionForPlayer](resource_extractor.dart) with
/// the three documented non-GP simplifications (default tech cap, no
/// prospecting, no capital-tile grain bonus). The town-development-cap branch
/// (capital province; non-capital with connected port town) is preserved
/// byte-for-byte so that minors and tribes whose capital province has a
/// non-default town-development level are extracted with the same
/// town-development semantics as Great Powers.
NonGpTileContribution? _computeNonGpTileContribution({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String factionCapitalProvinceId,
  required String factionCapitalRegionId,
  required String tileKey,
  required Set<String> connectedTileKeys,
  required Map<String, int> pathTransportCap,
  required Set<String> connectedByRoadRule,
  required Set<String> portTileKeys,
  required Map<String, Province> provincesByFullId,
}) {
  if (!connectedTileKeys.contains(tileKey)) {
    return null;
  }

  final tileContext = resolveTileKeyExtractionContext(
    tileKey: tileKey,
    tileMapByRegion: tileMapByRegion,
    provincesByFullId: provincesByFullId,
    logContext: 'non_gp_extraction',
  );
  if (tileContext == null) {
    return null;
  }

  final commodityId = tileContext.commodityId;
  if (kMineralResourceIds.contains(commodityId)) {
    // Non-GP factions never prospect — exclude minerals unconditionally per
    // SPEC/game/extraction-and-improvements.md § Non-Great-Power extraction.
    return null;
  }

  final province = tileContext.province;
  final provinceId = tileContext.provinceId;

  final townDevelopmentCap = province.townDevelopmentLevel;
  final townTileKey = province.townTileKey;
  final townTileIsPort =
      townTileKey != null && portTileKeys.contains(townTileKey);

  // Non-GP tech cap is the package-wide default (1) for every resource: Minors
  // and Tribes do not research tech. The remaining production / transport /
  // town-development math is shared with the GP helper via
  // computeEffectiveTileYield so the two stay provably in lockstep.
  final isCapitalProvince = provinceId == factionCapitalProvinceId;
  final usesRoadRule = connectedByRoadRule.contains(tileKey);
  final effective = computeEffectiveTileYield(
    tileState: game.worldState.tileState,
    tileKey: tileKey,
    techCap: defaultExtractionCap,
    townDevelopmentCap: townDevelopmentCap,
    townTileIsPort: townTileIsPort,
    isCapitalProvince: isCapitalProvince,
    usesRoadRule: usesRoadRule,
    portTileKeys: portTileKeys,
    pathTransportCap: pathTransportCap,
  );
  if (effective <= 0) {
    return null;
  }
  // The faction-capital-region check is preserved for parity with the GP
  // helper; in current SPEC every owned non-GP tile is same-region, so this
  // branch is informational only — non-GP output is always land-only.
  final isLandRelativeToCapital =
      tileContext.regionId == factionCapitalRegionId;
  if (!isLandRelativeToCapital) {
    // Non-GP factions cannot own tiles outside their capital region under
    // current SPEC; emit a debug log and skip so this stays observable if a
    // future ruleset changes that invariant.
    economyLog.d(
      'non_gp_extraction skip overseas tile factionCapitalRegionId='
      '$factionCapitalRegionId tileRegionId=${tileContext.regionId} '
      'tileKey=$tileKey',
    );
    return null;
  }
  return NonGpTileContribution(
    commodityId: tileContext.commodityId,
    units: effective,
  );
}
