import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'commodity_totals.dart';
import 'game_lookup_helpers.dart';
import 'non_gp_extraction_shared.dart';
import 'package:colonizethis_economy/src/logging.dart';

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
  economyLog.d(
    'non_gp_extraction compute start minors=${game.minorNations.length} '
    'tribes=${game.tribes.length}',
  );

  final provincesByFullId = buildProvinceIndex(game);
  final portTileKeys = collectPortTileKeys(game);

  final out = <String, Map<CommodityId, int>>{};

  forEachNonGpFaction(
    game: game,
    connectivityByFactionId: connectivityByFactionId,
    onFaction:
        ({
          required factionId,
          required capitalProvinceId,
          required capitalRegionId,
          required connectivity,
        }) {
          final totals = <CommodityId, int>{};
          forEachNonGpTileContribution(
            game: game,
            tileMapByRegion: tileMapByRegion,
            capitalProvinceId: capitalProvinceId,
            capitalRegionId: capitalRegionId,
            connectivity: connectivity,
            portTileKeys: portTileKeys,
            provincesByFullId: provincesByFullId,
            sortTileKeys: false,
            onContribution: (tileKey, contribution) {
              addUnits(totals, contribution.commodityId, contribution.units);
            },
          );
          if (totals.isNotEmpty) {
            out[factionId] = totals;
          }
        },
  );

  final totalUnits = sumNestedValues(out.values);
  economyLog.d(
    'non_gp_extraction compute end factions=${out.length} totalUnits=$totalUnits',
  );
  return out;
}
