/// Deal matching engine for the world market phase.
///
/// SPEC/game/world-market.md § Trade orders / Cargo / FTP,
/// SPEC/game/world-market-first-right-of-refusal.md § Rules,
/// SPEC/program/world-market-resolution.md § Deal matching engine.
///
/// The matcher is pure: deterministic for fixed inputs and silent (no logger
/// calls). It is safe to call inside the deterministic turn-resolution
/// pipeline under the 15-second turn-resolution budget per
/// `.cursor/rules/colonizethis-turn-resolution-budget.mdc`.
///
/// Matching / indexing live in standalone libraries with explicit imports
/// (Refs #3979); shared mutable pass state is [DealMatchSession].
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'deal_matcher_indexing.dart';
import 'deal_matcher_inputs.dart';
import 'deal_matcher_matching.dart';
import 'deal_matcher_session.dart';

export 'deal_matcher_inputs.dart';

/// Pure helpers and the canonical matching pass for the world market phase.
class DealMatcher {
  const DealMatcher._();

  /// Returns the canonical key for an unordered bilateral faction pair.
  ///
  /// FTP membership is symmetric — `pairKey('a', 'b') == pairKey('b', 'a')`.
  /// Callers populate `ftpPairKeys` with the result so the matcher does not
  /// need to query both orderings.
  static String pairKey(String a, String b) => DealMatchSession.pairKey(a, b);

  /// Runs a single matching pass over the supplied inputs.
  ///
  /// Returns the emitted [FilledDeal]s, the per-faction carry-forward orders
  /// (with `quantity` set to remaining units), and per-commodity activity
  /// totals. The matcher does not compute price change — the phase handler
  /// composes that separately via `PriceDiscovery.computeNextPrice` because
  /// only the handler knows which inputs are newly-submitted vs
  /// carry-forward (carry-forwards are excluded from the supply/demand
  /// signal per `SPEC/game/world-market.md` § Price discovery).
  static DealMatchResult matchDeals(DealMatchInputs inputs) {
    final commodityIds = collectMatchCommodityIds(
      inputs.offersByFactionId,
      inputs.bidsByFactionId,
    );
    if (commodityIds.isEmpty) {
      return DealMatchResult.empty;
    }

    final remainingCargo = <String, int>{
      for (final entry in inputs.tradeCapacityByFactionId.entries)
        entry.key: entry.value < 0 ? 0 : entry.value,
    };

    final remainingTreasury = <String, int>{
      for (final entry in inputs.treasuryBudgetByBuyerFactionId.entries)
        entry.key: entry.value < 0 ? 0 : entry.value,
    };

    final filled = <FilledDeal>[];
    final activity = <CommodityId, MarketActivity>{};
    final notesByCommodity = <CommodityId, List<MarketActivityNote>>{};

    final offerStatesByFaction = indexOrdersByFaction(inputs.offersByFactionId);
    final bidStatesByFaction = indexOrdersByFaction(inputs.bidsByFactionId);

    final offerStatesByCommodity = indexStatesByCommodity(offerStatesByFaction);
    final bidStatesByCommodity = indexStatesByCommodity(bidStatesByFaction);

    final session = DealMatchSession(
      remainingCargo: remainingCargo,
      remainingTreasury: remainingTreasury,
      filledOut: filled,
      boycottBlockedPairKeys: inputs.boycottBlockedPairKeys,
    );

    final purchasedTileIndex = inputs.purchasedTileIndex;
    final firstRightEnabled =
        purchasedTileIndex != null && purchasedTileIndex.isNotEmpty;

    for (final commodityId in commodityIds) {
      final commodityOffers =
          offerStatesByCommodity[commodityId] ?? const <MatchOrderState>[];
      final commodityBids =
          bidStatesByCommodity[commodityId] ?? const <MatchOrderState>[];

      final totalOfferQuantity = sumInputQuantity(commodityOffers);
      final totalBidQuantity = sumInputQuantity(commodityBids);
      var filledQuantity = 0;

      if (commodityOffers.isNotEmpty && commodityBids.isNotEmpty) {
        final price = inputs.pricesByCommodityId[commodityId] ?? 0.0;

        if (firstRightEnabled) {
          filledQuantity += runFirstRightMatching(
            session: session,
            commodityOffers: commodityOffers,
            commodityBids: commodityBids,
            commodityId: commodityId,
            pricePerUnit: price,
            purchasedTileIndex: purchasedTileIndex,
          );
        }

        final tiers = collectPriorityTiers(commodityOffers, commodityBids);

        for (final tier in tiers) {
          final tierOffers = commodityOffers
              .where((s) => s.order.priority == tier && s.remaining > 0)
              .toList();
          sortOffersLockRecoverySellersFirst(
            tierOffers,
            lockRecoverySellerPriorityIds: inputs.lockRecoverySellerPriorityIds,
            treasuryByFactionId: inputs.treasuryByFactionId,
          );
          final tierBids = commodityBids
              .where((s) => s.order.priority == tier && s.remaining > 0)
              .toList(growable: false);

          filledQuantity += runTierMatching(
            session: session,
            tierOffers: tierOffers,
            tierBids: tierBids,
            commodityId: commodityId,
            pricePerUnit: price,
            ftpPairKeys: inputs.ftpPairKeys,
            sellPriorityRelationByMinorTribeSeller:
                inputs.sellPriorityRelationByMinorTribeSeller,
          );
        }
      }

      for (final state in commodityBids) {
        if (!state.treasuryTruncated) continue;
        final commodityNotes = notesByCommodity.putIfAbsent(
          commodityId,
          () => <MarketActivityNote>[],
        );
        commodityNotes.add(
          MarketActivityNote(
            kind: MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
            factionId: state.factionId,
            commodityId: commodityId,
            quantity: state.order.quantity,
          ),
        );
      }

      if (totalOfferQuantity > 0 ||
          totalBidQuantity > 0 ||
          filledQuantity > 0) {
        final commodityNotes = notesByCommodity[commodityId];
        activity[commodityId] = MarketActivity(
          totalBidQuantity: totalBidQuantity,
          totalOfferQuantity: totalOfferQuantity,
          filledQuantity: filledQuantity,
          notes: commodityNotes == null
              ? const <MarketActivityNote>[]
              : List<MarketActivityNote>.unmodifiable(commodityNotes),
        );
      }
    }

    return DealMatchResult(
      filledDeals: List.unmodifiable(filled),
      unfilledOffersByFactionId: carryForwardByFaction(offerStatesByFaction),
      unfilledBidsByFactionId: carryForwardByFaction(bidStatesByFaction),
      activityByCommodityId: Map.unmodifiable(activity),
    );
  }
}
