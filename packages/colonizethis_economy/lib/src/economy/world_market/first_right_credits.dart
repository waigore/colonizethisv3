/// First-right-of-refusal **treasury-credit aggregation (D4)** for the
/// world market phase.
///
/// SPEC: [SPEC/game/world-market-first-right-of-refusal.md § Treasury
/// transfer (D4)](
/// ../../../../../../SPEC/game/world-market-first-right-of-refusal.md) and
/// [SPEC/program/world-market-resolution.md § First right of refusal](
/// ../../../../../../SPEC/program/world-market-resolution.md). Authority:
/// issue [#2992](https://github.com/waigore/colonizethisv3/issues/2992) (D4).
///
/// This helper closes the loop on the FRR design:
///
/// - **D1** ([purchased_tile_index.dart]) builds the per-tile attribution
///   index used by both the matcher and this helper.
/// - **D2** ([deal_matcher.dart]) emits `FilledDeal.sellerOriginTileKey`
///   for every offer-attributed deal, regardless of whether the buyer
///   was the owning GP or a different Great Power.
/// - **D3** ([first_right_profit.dart]) computes the per-deal profit
///   credit `filledQuantity * pricePerUnit * profitRate(relationScore)`.
/// - **D4** (this file) iterates the matcher's `List<FilledDeal>` and
///   aggregates the **overseas-profit credits** per **owning Great Power**
///   for the subset of deals where the buyer is **not** the owning GP
///   (the no-bid path per the GDD). The phase handler applies those
///   credits to player treasuries; the remainder of the buyer's payment
///   is the minor/tribe treasury sink per
///   `SPEC/game/world-market.md` Requirement 9.
///
/// The aggregation is intentionally a pure function:
///
/// - Deterministic for a fixed `(filledDeals, purchasedTileIndex,
///   relationScoreFor)` tuple, including iteration order of the result
///   map's entries (insertion order matches the first emission per
///   owning GP).
/// - No logger calls, no RNG, and no `Game` access — safe to call inside
///   the 15-second next-turn-resolution budget per
///   `SPEC/program/turn-resolution-phases.md` § Determinism.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'first_right_profit.dart';
import 'gp_treasury_credit_accumulator.dart';
import 'purchased_tile_index.dart';

/// Per-deal credit record produced by [computeFirstRightCredits].
///
/// Wraps the source [FilledDeal] together with the resolved owning GP
/// id, the source minor/tribe id, and the [FirstRightProfit] returned
/// by [computeFirstRightProfit]. Callers (phase handler, Deal Book UI)
/// consume either the per-deal records or the aggregated treasury map
/// on [FirstRightCreditsResult].
class FirstRightDealCredit {
  const FirstRightDealCredit({
    required this.deal,
    required this.owningGpId,
    required this.sourceFactionId,
    required this.relationScore,
    required this.profit,
  });

  /// The matcher-emitted deal that triggered the FRR overseas-profit
  /// credit. The deal's `buyerFactionId` is guaranteed to differ from
  /// [owningGpId] (the owning-GP-wins path is handled by D2 / FRR
  /// pre-pass matches, not by D4).
  final FilledDeal deal;

  /// Great Power id credited with the overseas profit cut for this
  /// deal. Always different from `deal.buyerFactionId` and from
  /// `deal.sellerFactionId`.
  final String owningGpId;

  /// Minor or tribe id that owns the underlying purchased province at
  /// resolution time. Used to look up the owning GP's hidden 0–100
  /// relation score via the caller-supplied `relationScoreFor`.
  final String sourceFactionId;

  /// Relation score sampled at credit-computation time (0–100, already
  /// clamped at the diplomacy source per `SPEC/game/diplomacy.md`
  /// § Relation Model).
  final num relationScore;

  /// Per-deal profit envelope produced by [computeFirstRightProfit].
  /// `profit.profitTreasury == 0.0` is a valid record — it preserves
  /// the audit trail when relation score is zero or `profitRate`
  /// clamps to zero defensively.
  final FirstRightProfit profit;

  /// Treasury units credited to [owningGpId] for this deal. Equal to
  /// `profit.profitTreasury`; exposed here as a convenience for the
  /// phase-handler aggregation loop.
  double get profitTreasury => profit.profitTreasury;

  @override
  String toString() =>
      'FirstRightDealCredit(deal: $deal, owningGp: $owningGpId, '
      'source: $sourceFactionId, relation: $relationScore, '
      'profit: $profit)';
}

/// Aggregated result of [computeFirstRightCredits].
///
/// [creditedDeals] preserves the matcher's emission order so callers can
/// reproduce per-deal audit trails (Deal Book UI, observer traces).
/// [treasuryCreditByGpId] aggregates the overseas-profit credits for
/// each owning GP; the phase handler applies these credits to player
/// treasuries (the remainder of the buyer's payment is the minor/tribe
/// sink per the GDD).
///
/// `treasuryCreditByGpId` is an unmodifiable map; insertion order of
/// its entries matches the order in which each owning GP first appears
/// in [creditedDeals].
class FirstRightCreditsResult {
  const FirstRightCreditsResult({
    required this.creditedDeals,
    required this.treasuryCreditByGpId,
    this.embassyKickbackByGpId = const <String, double>{},
    double? totalProfitTreasury,
    double? totalEmbassyKickback,
  }) : _totalProfitTreasury = totalProfitTreasury,
       _totalEmbassyKickback = totalEmbassyKickback;

  /// Empty result. Returned when the input deal list is empty, the
  /// purchased-tile index is empty, or no deal is FRR-eligible.
  static const FirstRightCreditsResult empty = FirstRightCreditsResult(
    creditedDeals: <FirstRightDealCredit>[],
    treasuryCreditByGpId: <String, double>{},
  );

  /// Precomputed grand total from the shared accumulator, when constructed via
  /// [computeFirstRightCredits]. `null` for hand-built results (for example the
  /// [empty] sentinel), which fall back to summing [treasuryCreditByGpId].
  final double? _totalProfitTreasury;

  /// Precomputed grand total of embassy kickbacks, when constructed via
  /// [computeFirstRightCredits]. `null` for hand-built results, which fall
  /// back to summing [embassyKickbackByGpId].
  final double? _totalEmbassyKickback;

  /// Per-deal credit records in matcher emission order (deals without
  /// a non-zero `profitTreasury` are still included so callers can
  /// surface every FRR-eligible deal in the Deal Book — see also
  /// `SPEC/game/world-market-first-right-of-refusal.md` § Rules).
  final List<FirstRightDealCredit> creditedDeals;

  /// Tile-owner full-share treasury credits to apply to owning GPs, keyed by
  /// GP id (#3753 R8.2 — full relation-linear share, no 40% cap). Only these
  /// credits are deducted from the seller's proceeds before the treasury
  /// sink (R8.4).
  final Map<String, double> treasuryCreditByGpId;

  /// Embassy-kickback treasury credits to apply to embassy-holding GPs that do
  /// **not** own the sourcing tile, keyed by GP id (#3753 R8.3 — 10% of the
  /// relation portion). Funded from the treasury-sink remainder, **not**
  /// deducted from the seller's proceeds (R8.4). Empty unless the caller
  /// supplies `embassyGpRelationsFor`.
  final Map<String, double> embassyKickbackByGpId;

  /// Convenience: total overseas-profit treasury credited across every
  /// owning GP for this aggregation. Phase handlers and observer
  /// traces use this for top-line economic accounting.
  ///
  /// O(1) when produced by [computeFirstRightCredits] (the
  /// [GpTreasuryCreditAccumulator] maintains the total incrementally); falls
  /// back to re-summing [treasuryCreditByGpId] for hand-built results.
  double get totalProfitTreasury {
    final cached = _totalProfitTreasury;
    if (cached != null) return cached;
    var total = 0.0;
    for (final amount in treasuryCreditByGpId.values) {
      total += amount;
    }
    return total;
  }

  /// Convenience: total embassy-kickback treasury credited across every
  /// embassy-holding non-owner GP for this aggregation (#3753 R8.3).
  double get totalEmbassyKickback {
    final cached = _totalEmbassyKickback;
    if (cached != null) return cached;
    var total = 0.0;
    for (final amount in embassyKickbackByGpId.values) {
      total += amount;
    }
    return total;
  }
}

/// Aggregates First Right of Refusal overseas-profit credits across a
/// matcher-emitted list of [FilledDeal]s.
///
/// For every deal whose `sellerOriginTileKey` resolves to a
/// purchased-tile attribution in [purchasedTileIndex] and whose
/// `buyerFactionId` is **different** from the attribution's owning GP,
/// this function:
///
/// 1. Resolves the owning GP id and the source minor/tribe id from the
///    [PurchasedTileAttribution].
/// 2. Calls [relationScoreFor] to read the owning GP's 0–100 hidden
///    relation score with the source faction at resolution time.
/// 3. Computes the per-deal credit via [computeFirstRightProfit]
///    (`relationScore`, `filledQuantity`, `pricePerUnit`).
/// 4. Adds the **full** relation-linear share (#3753 R8.2 — no 40% cap) to
///    the owning GP's running tile-owner credit in
///    [FirstRightCreditsResult.treasuryCreditByGpId] (insertion order
///    matches the first deal that mentions each owning GP).
///
/// For the **tile-owner full share** path: deals whose `sellerOriginTileKey`
/// is `null`, deals whose tile key does **not** resolve in the index, deals
/// where the buyer **is** the owning GP (including the FRR-match path emitted
/// by D2), and deals where `quantity <= 0` or `pricePerUnit <= 0` produce no
/// tile-owner credit — that path is strictly the **other-buyer** overseas
/// profit per the GDD. The separate **embassy-kickback** path (below) still
/// applies to those Minor/Tribe sales when [embassyGpRelationsFor] is given.
///
/// [relationScoreFor] receives `(owningGpId, sourceFactionId)` and
/// must return the owning GP's clamped 0–100 relation score with the
/// source faction. Callers typically wire this to
/// `getRelation(game, owningGpId, sourceFactionId)?.score ?? 0`.
///
/// [embassyGpRelationsFor] (optional, #3753 R8.3) receives a selling
/// `sourceFactionId` and returns the GPs that hold an Embassy with that
/// Minor/Tribe mapped to their clamped 0–100 relation score. When supplied,
/// every embassy-holding GP that does **not** own the sourcing tile is
/// credited a kickback of `Q × P × (relation / 100) × 0.10` on each
/// Minor/Tribe sale (including sales with **no** purchased-tile attribution,
/// R8.6). The tile owner is excluded from the kickback (R8.5) but still
/// receives its full tile-owner share. When `null`, no kickbacks are
/// produced (legacy behavior).
///
/// Returns [FirstRightCreditsResult.empty] when [filledDeals] is empty, or
/// when both [purchasedTileIndex] is `null` / empty **and**
/// [embassyGpRelationsFor] is `null` (nothing to credit).
FirstRightCreditsResult computeFirstRightCredits({
  required Iterable<FilledDeal> filledDeals,
  required PurchasedTileIndex? purchasedTileIndex,
  required num Function(String owningGpId, String sourceFactionId)
  relationScoreFor,
  Map<String, num> Function(String sourceFactionId)? embassyGpRelationsFor,
}) {
  final hasTileIndex =
      purchasedTileIndex != null && purchasedTileIndex.isNotEmpty;
  if (!hasTileIndex && embassyGpRelationsFor == null) {
    return FirstRightCreditsResult.empty;
  }
  final dealsList = filledDeals is List<FilledDeal>
      ? filledDeals
      : filledDeals.toList(growable: false);
  if (dealsList.isEmpty) return FirstRightCreditsResult.empty;

  final creditedDeals = <FirstRightDealCredit>[];
  final treasuryByGp = GpTreasuryCreditAccumulator<double>(0.0);
  final kickbackByGp = GpTreasuryCreditAccumulator<double>(0.0);

  for (final deal in dealsList) {
    if (deal.quantity <= 0 || deal.pricePerUnit <= 0.0) continue;

    final tileKey = deal.sellerOriginTileKey;
    final attribution = (hasTileIndex && tileKey != null && tileKey.isNotEmpty)
        ? purchasedTileIndex.attributionForTileKey(tileKey)
        : null;
    final owningGpId = attribution?.owningGpId ?? '';
    // Source Minor/Tribe: the purchased-tile attribution when present,
    // otherwise the deal's seller faction (R8.6 — kickbacks still apply to
    // unattributed Minor/Tribe sales).
    final sourceFactionId = attribution?.sourceFactionId ?? deal.sellerFactionId;

    // Tile-owner full share (R8.2): only when the buyer is not the owner.
    if (attribution != null &&
        owningGpId.isNotEmpty &&
        deal.buyerFactionId != owningGpId) {
      final relationScore = relationScoreFor(owningGpId, sourceFactionId);
      final profit = computeFirstRightProfit(
        relationScore: relationScore,
        filledQuantity: deal.quantity,
        pricePerUnit: deal.pricePerUnit,
      );
      creditedDeals.add(
        FirstRightDealCredit(
          deal: deal,
          owningGpId: owningGpId,
          sourceFactionId: sourceFactionId,
          relationScore: relationScore,
          profit: profit,
        ),
      );
      if (profit.profitTreasury > 0.0) {
        treasuryByGp.add(owningGpId, profit.profitTreasury);
      } else {
        treasuryByGp.ensure(owningGpId);
      }
    }

    // Embassy kickbacks (R8.3): every embassy-holding GP except the tile
    // owner. Deterministic in the callback's iteration order.
    if (embassyGpRelationsFor != null && sourceFactionId.isNotEmpty) {
      final embassyRelations = embassyGpRelationsFor(sourceFactionId);
      for (final entry in embassyRelations.entries) {
        final gpId = entry.key;
        if (gpId.isEmpty || gpId == owningGpId) continue;
        final kickback = computeEmbassyKickback(
          relationScore: entry.value,
          filledQuantity: deal.quantity,
          pricePerUnit: deal.pricePerUnit,
        );
        if (kickback > 0.0) {
          kickbackByGp.add(gpId, kickback);
        }
      }
    }
  }

  if (creditedDeals.isEmpty && kickbackByGp.isEmpty) {
    return FirstRightCreditsResult.empty;
  }
  return FirstRightCreditsResult(
    creditedDeals: List.unmodifiable(creditedDeals),
    treasuryCreditByGpId: treasuryByGp.view,
    embassyKickbackByGpId: kickbackByGp.view,
    totalProfitTreasury: treasuryByGp.total,
    totalEmbassyKickback: kickbackByGp.total,
  );
}
