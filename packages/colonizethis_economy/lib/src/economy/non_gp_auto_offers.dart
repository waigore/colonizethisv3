import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_lookup_helpers.dart';
import 'non_gp_extraction_shared.dart';
import 'package:colonizethis_economy/src/logging.dart';

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
/// mineral exclusion already applied inside the shared tile-contribution
/// helper covers the metal/jewel riches (silver/gold/gems/diamonds) before they
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

  final provincesByFullId = buildProvinceIndex(game);
  final portTileKeys = collectPortTileKeys(game);
  final richesIds = richesCommodityIds.toSet();

  final out = <String, List<TradeOrder>>{};

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
          final orders = <TradeOrder>[];
          forEachNonGpTileContribution(
            game: game,
            tileMapByRegion: tileMapByRegion,
            capitalProvinceId: capitalProvinceId,
            capitalRegionId: capitalRegionId,
            connectivity: connectivity,
            portTileKeys: portTileKeys,
            provincesByFullId: provincesByFullId,
            sortTileKeys: true,
            onContribution: (tileKey, contribution) {
              if (richesIds.contains(contribution.commodityId)) return;
              orders.add(
                TradeOrder(
                  commodityId: contribution.commodityId,
                  type: TradeOrderType.offer,
                  quantity: contribution.units,
                  priority: 1,
                  originTileKey: tileKey,
                ),
              );
            },
          );
          if (orders.isNotEmpty) out[factionId] = orders;
        },
  );

  final totalOffers = out.values.fold<int>(0, (s, l) => s + l.length);
  economyLog.d(
    'non_gp_extraction auto-offers factions=${out.length} '
    'orders=$totalOffers',
  );
  return out;
}
