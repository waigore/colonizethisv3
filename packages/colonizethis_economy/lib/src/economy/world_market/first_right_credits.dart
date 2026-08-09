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

import 'embassy_kickback_accumulation.dart';
import 'first_right_credit_records.dart';
import 'first_right_profit.dart';
import 'gp_treasury_credit_accumulator.dart';
import 'purchased_tile_index.dart';

export 'first_right_credit_records.dart';

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
    final sourceFactionId =
        attribution?.sourceFactionId ?? deal.sellerFactionId;

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
    accumulateEmbassyKickbacksForDeal(
      deal: deal,
      sourceFactionId: sourceFactionId,
      owningGpId: owningGpId,
      embassyGpRelationsFor: embassyGpRelationsFor,
      kickbackByGp: kickbackByGp,
    );
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
