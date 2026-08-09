/// Per-deal and aggregated result types for FRR treasury-credit aggregation (D4).
///
/// SPEC: [SPEC/game/world-market-first-right-of-refusal.md § Treasury transfer (D4)](
/// ../../../../../../SPEC/game/world-market-first-right-of-refusal.md). Authority:
/// issue [#2992](https://github.com/waigore/colonizethisv3/issues/2992) (D4);
/// phase-8 type extraction Refs #4299.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'first_right_profit.dart';
import 'gp_treasury_credit_rollup.dart';

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
  FirstRightCreditsResult({
    required this.creditedDeals,
    required Map<String, double> treasuryCreditByGpId,
    Map<String, double> embassyKickbackByGpId = const <String, double>{},
    double? totalProfitTreasury,
    double? totalEmbassyKickback,
  }) : _profitRollup = GpTreasuryCreditRollup<double>(
         treasuryCreditByGpId: treasuryCreditByGpId,
         cachedGrandTotal: totalProfitTreasury,
       ),
       _kickbackRollup = GpTreasuryCreditRollup<double>(
         treasuryCreditByGpId: embassyKickbackByGpId,
         cachedGrandTotal: totalEmbassyKickback,
       );

  /// Empty result. Returned when the input deal list is empty, the
  /// purchased-tile index is empty, or no deal is FRR-eligible.
  static final FirstRightCreditsResult empty = FirstRightCreditsResult(
    creditedDeals: <FirstRightDealCredit>[],
    treasuryCreditByGpId: <String, double>{},
  );

  final GpTreasuryCreditRollup<double> _profitRollup;
  final GpTreasuryCreditRollup<double> _kickbackRollup;

  /// Per-deal credit records in matcher emission order (deals without
  /// a non-zero `profitTreasury` are still included so callers can
  /// surface every FRR-eligible deal in the Deal Book — see also
  /// `SPEC/game/world-market-first-right-of-refusal.md` § Rules).
  final List<FirstRightDealCredit> creditedDeals;

  /// Tile-owner full-share treasury credits to apply to owning GPs, keyed by
  /// GP id (#3753 R8.2 — full relation-linear share, no 40% cap). Only these
  /// credits are deducted from the seller's proceeds before the treasury
  /// sink (R8.4).
  Map<String, double> get treasuryCreditByGpId =>
      _profitRollup.treasuryCreditByGpId;

  /// Embassy-kickback treasury credits to apply to embassy-holding GPs that do
  /// **not** own the sourcing tile, keyed by GP id (#3753 R8.3 — 10% of the
  /// relation portion). Funded from the treasury-sink remainder, **not**
  /// deducted from the seller's proceeds (R8.4). Empty unless the caller
  /// supplies `embassyGpRelationsFor`.
  Map<String, double> get embassyKickbackByGpId =>
      _kickbackRollup.treasuryCreditByGpId;

  /// Convenience: total overseas-profit treasury credited across every
  /// owning GP for this aggregation. Phase handlers and observer
  /// traces use this for top-line economic accounting.
  ///
  /// O(1) when produced by [computeFirstRightCredits] (the
  /// [GpTreasuryCreditAccumulator] maintains the total incrementally); falls
  /// back to re-summing [treasuryCreditByGpId] for hand-built results.
  double get totalProfitTreasury => _profitRollup.grandTotal(0.0);

  /// Convenience: total embassy-kickback treasury credited across every
  /// embassy-holding non-owner GP for this aggregation (#3753 R8.3).
  double get totalEmbassyKickback => _kickbackRollup.grandTotal(0.0);
}
