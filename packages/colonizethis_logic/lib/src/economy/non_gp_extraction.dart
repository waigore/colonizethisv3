import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../logging.dart';
import 'package:colonizethis_world/src/world/connectivity_resolver.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/tile_key_coordinates.dart';

/// Per-faction extraction for non-Great-Power factions (Minor Nations and
/// Tribes). Mirrors the per-tile formula in
/// [computeExtraction](resource_extractor.dart) with three documented
/// differences from the Great Power flow, normative in
/// `SPEC/game/extraction-and-improvements.md` § Non-Great-Power extraction:
///
///   1. Tech cap is fixed at [defaultExtractionCap] for every resource (Minors
///      and Tribes do not research tech).
///   2. Mineral resources (`iron`, `copper`, `tin`, `coal`, `silver`, `gold`,
///      `gems`, `diamonds`) are unconditionally excluded — Minors and Tribes
///      do not have Explorers and never prospect, so the Mineral Prospecting
///      Gate's prospected arm can never be satisfied.
///   3. Output is **land-only** — Minors are Old-World-only and Tribes are
///      New-World-only per `SPEC/game/factions.md`, so every owned tile is in
///      the same region as the faction's capital. No overseas bucket, no
///      sea-transport allocation, no naval-interception interaction. The
///      Great-Power-only capital-tile grain bonus is not added.
///
/// Output map is keyed by the minor/tribe `id`. Values are the per-commodity
/// extracted quantities for that turn. Per `SPEC/game/factions.md`, Minors and
/// Tribes have no `Player.stockpile`; the World Market phase consumes this map
/// as the source of system-authored auto-offers — see
/// `SPEC/game/world-market.md` § Minor and tribe auto-sell.
///
/// [connectivityByFactionId] is supplied by the caller (the non-GP
/// connectivity resolver, issue #2991 subtask C3, is intentionally separate so
/// extraction and connectivity remain decoupled). Tests may synthesize this
/// map with hand-built [ConnectivityResult] fixtures.
Map<String, Map<CommodityId, int>> computeNonGreatPowerExtraction({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, ConnectivityResult> connectivityByFactionId,
}) {
  if (game.minorNations.isEmpty && game.tribes.isEmpty) {
    return const <String, Map<CommodityId, int>>{};
  }
  if (tileMapByRegion.isEmpty) {
    return const <String, Map<CommodityId, int>>{};
  }
  logicLog.d(
    'non_gp_extraction compute start minors=${game.minorNations.length} '
    'tribes=${game.tribes.length}',
  );

  final provincesByFullId = <String, Province>{
    for (final p in allProvinces(game.worldState)) p.id: p,
  };
  final portTileKeys = game.worldState.portsByProvinceSeaboard.values.toSet();

  final out = <String, Map<CommodityId, int>>{};

  void runForFaction({
    required String factionId,
    required String? capitalProvinceId,
    required String? capitalRegionId,
  }) {
    if (capitalProvinceId == null || capitalRegionId == null) {
      return;
    }
    final cr = connectivityByFactionId[factionId];
    if (cr == null) {
      return;
    }
    final connected = cr.connected;
    if (connected.isEmpty) {
      return;
    }
    final pathTransportCap = cr.pathTransportCap;
    final roadRuleTiles = cr.connectedByRoadRule;

    final totals = <CommodityId, int>{};
    for (final tileKey in connected) {
      final contribution = _computeNonGpTileContribution(
        game: game,
        tileMapByRegion: tileMapByRegion,
        factionCapitalProvinceId: capitalProvinceId,
        factionCapitalRegionId: capitalRegionId,
        tileKey: tileKey,
        connectedTileKeys: connected,
        pathTransportCap: pathTransportCap,
        connectedByRoadRule: roadRuleTiles,
        portTileKeys: portTileKeys,
        provincesByFullId: provincesByFullId,
      );
      if (contribution == null) continue;
      totals[contribution.commodityId] =
          (totals[contribution.commodityId] ?? 0) + contribution.units;
    }
    if (totals.isNotEmpty) {
      out[factionId] = totals;
    }
  }

  for (final minor in game.minorNations) {
    runForFaction(
      factionId: minor.id,
      capitalProvinceId: minor.capitalProvinceId,
      capitalRegionId: minor.capitalTile?.regionId,
    );
  }
  for (final tribe in game.tribes) {
    runForFaction(
      factionId: tribe.id,
      capitalProvinceId: tribe.capitalProvinceId,
      capitalRegionId: tribe.capitalTile?.regionId,
    );
  }

  final totalUnits = out.values.fold<int>(
    0,
    (s, m) => s + m.values.fold(0, (a, b) => a + b),
  );
  logicLog.d(
    'non_gp_extraction compute end factions=${out.length} totalUnits=$totalUnits',
  );
  return out;
}

/// Generates priority-1 `TradeOrder` auto-offers for every connected developed
/// non-Great-Power tile that produces a non-riches commodity, per
/// `SPEC/program/world-market-resolution.md` § Step A Gather (Step A.2) and
/// `SPEC/game/world-market.md` § Minor and tribe auto-sell.
///
/// One [TradeOrder] is emitted per contributing tile (not aggregated across
/// tiles for the same commodity) so the offer carries an
/// `originTileKey` and FRR (`#2992` D2/D4) can attribute purchased-tile flows
/// per `SPEC/game/world-market-first-right-of-refusal.md`. Each emitted order
/// uses `type = TradeOrderType.offer`, `priority = 1`, `quantity` equal to the
/// per-tile units the GP-parity extraction formula yields, and the source
/// tile key.
///
/// Commodities in `richesCommodityIds` are filtered out per
/// `SPEC/game/world-market.md` Requirement 11 (riches do not trade). The
/// mineral exclusion already applied inside [computeNonGreatPowerExtraction]
/// covers the metal/jewel riches (silver/gold/gems/diamonds) before they
/// reach this stage; the explicit riches filter here additionally suppresses
/// non-mineral riches (spices) for which no prospecting precondition exists.
///
/// Output map keys are minor/tribe faction ids. Factions with no qualifying
/// auto-offer are omitted (no empty list values). Per-faction order list is
/// ordered by `(tileKey ascending, commodityId)` so identical inputs produce
/// identical outputs across runs (Refs `colonizethis-turn-resolution-budget`
/// determinism contract).
Map<String, List<TradeOrder>> computeNonGreatPowerAutoOffers({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, ConnectivityResult> connectivityByFactionId,
}) {
  if (game.minorNations.isEmpty && game.tribes.isEmpty) {
    return const <String, List<TradeOrder>>{};
  }
  if (tileMapByRegion.isEmpty) {
    return const <String, List<TradeOrder>>{};
  }

  final provincesByFullId = <String, Province>{
    for (final p in allProvinces(game.worldState)) p.id: p,
  };
  final portTileKeys = game.worldState.portsByProvinceSeaboard.values.toSet();
  final richesIds = richesCommodityIds.toSet();

  final out = <String, List<TradeOrder>>{};

  void runForFaction({
    required String factionId,
    required String? capitalProvinceId,
    required String? capitalRegionId,
  }) {
    if (capitalProvinceId == null || capitalRegionId == null) return;
    final cr = connectivityByFactionId[factionId];
    if (cr == null) return;
    final connected = cr.connected;
    if (connected.isEmpty) return;
    final orders = <TradeOrder>[];
    final sortedTileKeys = connected.toList()..sort();
    for (final tileKey in sortedTileKeys) {
      final contribution = _computeNonGpTileContribution(
        game: game,
        tileMapByRegion: tileMapByRegion,
        factionCapitalProvinceId: capitalProvinceId,
        factionCapitalRegionId: capitalRegionId,
        tileKey: tileKey,
        connectedTileKeys: connected,
        pathTransportCap: cr.pathTransportCap,
        connectedByRoadRule: cr.connectedByRoadRule,
        portTileKeys: portTileKeys,
        provincesByFullId: provincesByFullId,
      );
      if (contribution == null) continue;
      if (richesIds.contains(contribution.commodityId)) continue;
      orders.add(
        TradeOrder(
          commodityId: contribution.commodityId,
          type: TradeOrderType.offer,
          quantity: contribution.units,
          priority: 1,
          originTileKey: tileKey,
        ),
      );
    }
    if (orders.isNotEmpty) out[factionId] = orders;
  }

  for (final minor in game.minorNations) {
    runForFaction(
      factionId: minor.id,
      capitalProvinceId: minor.capitalProvinceId,
      capitalRegionId: minor.capitalTile?.regionId,
    );
  }
  for (final tribe in game.tribes) {
    runForFaction(
      factionId: tribe.id,
      capitalProvinceId: tribe.capitalProvinceId,
      capitalRegionId: tribe.capitalTile?.regionId,
    );
  }

  final totalOffers = out.values.fold<int>(0, (s, l) => s + l.length);
  logicLog.d(
    'non_gp_extraction auto-offers factions=${out.length} '
    'orders=$totalOffers',
  );
  return out;
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
_NonGpTileContribution? _computeNonGpTileContribution({
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
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return null;
  if (coords.x < 0 || coords.y < 0) return null;

  final map = tileMapByRegion[coords.regionId];
  if (map == null) return null;

  final resource = map.resourceAt(coords.x, coords.y);
  if (resource == null) return null;

  // Resource enum name is the canonical commodity id; matches the existing
  // GP-side `_resourceToCommodityId` switch (see resource_extractor.dart) and
  // `kMineralResourceIds` membership check in constants.dart.
  final CommodityId commodityId = resource.name;

  if (kMineralResourceIds.contains(commodityId)) {
    // Non-GP factions never prospect — exclude minerals unconditionally per
    // SPEC/game/extraction-and-improvements.md § Non-Great-Power extraction.
    return null;
  }

  final provinceId = '${coords.regionId}|${coords.provinceLocalId}';
  final province = provincesByFullId[provinceId];
  if (province == null) {
    final msg =
        'non_gp_extraction province missing tileKey=$tileKey '
        'provinceId=$provinceId (region-scoped lookup failed; '
        'SPEC/game/world-model-identity.md)';
    logicLog.e(msg, error: StateError(msg), stackTrace: StackTrace.current);
    return null;
  }

  final townDevelopmentCap = province.townDevelopmentLevel;
  final townTileKey = province.townTileKey;
  final townTileIsPort =
      townTileKey != null && portTileKeys.contains(townTileKey);

  final improvementLevel = game.worldState.tileState
      .improvementLevel(tileKey)
      .clamp(0, 4);
  final roadLevel = game.worldState.tileState.roadLevel(tileKey);
  final isPort = portTileKeys.contains(tileKey);
  final tileTransportLevel = isPort ? 4 : (roadLevel > 0 ? roadLevel : 0);
  final pathCap = pathTransportCap[tileKey] ?? tileTransportLevel;

  // Non-GP tech cap is the package-wide default (1) for every resource: Minors
  // and Tribes do not research tech.
  const techCap = defaultExtractionCap;
  final production = (improvementLevel < techCap ? improvementLevel : techCap)
      .clamp(0, 4);
  var effective = (production < pathCap ? production : pathCap).clamp(0, 4);

  final isCapitalProvince = provinceId == factionCapitalProvinceId;
  final usesRoadRule = connectedByRoadRule.contains(tileKey);
  if (isCapitalProvince) {
    effective =
        (effective < townDevelopmentCap ? effective : townDevelopmentCap).clamp(
          0,
          4,
        );
  } else if (!usesRoadRule && townTileIsPort) {
    // Town rule only (non-capital) with connected port town applies town cap;
    // mirrors the GP branch in resource_extractor.dart.
    effective =
        (effective < townDevelopmentCap ? effective : townDevelopmentCap).clamp(
          0,
          4,
        );
  }
  if (effective <= 0) {
    return null;
  }
  // The faction-capital-region check is preserved for parity with the GP
  // helper; in current SPEC every owned non-GP tile is same-region, so this
  // branch is informational only — non-GP output is always land-only.
  final isLandRelativeToCapital = coords.regionId == factionCapitalRegionId;
  if (!isLandRelativeToCapital) {
    // Non-GP factions cannot own tiles outside their capital region under
    // current SPEC; emit a debug log and skip so this stays observable if a
    // future ruleset changes that invariant.
    logicLog.d(
      'non_gp_extraction skip overseas tile factionCapitalRegionId='
      '$factionCapitalRegionId tileRegionId=${coords.regionId} '
      'tileKey=$tileKey',
    );
    return null;
  }
  return _NonGpTileContribution(commodityId: commodityId, units: effective);
}

class _NonGpTileContribution {
  const _NonGpTileContribution({required this.commodityId, required this.units});

  final CommodityId commodityId;
  final int units;
}
