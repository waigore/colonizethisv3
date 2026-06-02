/// First-right-of-refusal profit computation for the world market.
///
/// SPEC: [SPEC/program/world-market-resolution.md § First right of refusal](
/// ../../../../../../SPEC/program/world-market-resolution.md) and
/// [SPEC/game/world-market.md § First right of refusal](
/// ../../../../../../SPEC/game/world-market.md). Authority: issue
/// [#2992](https://github.com/waigore/colonizethisv3/issues/2992) (D3).
///
/// When a Great Power has purchased a tile from a minor/tribe via the
/// `purchase_land` work order, that tile's commodity offers continue to
/// originate from the minor/tribe (auto-offered). When the owning GP does
/// **not** bid for that commodity and another GP buys those purchased-tile
/// commodities, the owning GP receives an "overseas profit" cut from the
/// sale proceeds based on its hidden relation score with the minor/tribe
/// that owns the underlying province.
///
/// The formula is intentionally a pure function so it can be invoked from
/// hot turn-resolution paths (deal matcher / phase handler) without
/// triggering logger calls or other side effects, keeping the function
/// safely callable inside the 15-second turn-resolution budget.
library;

/// Result of [computeFirstRightProfit] — the profit rate applied and the
/// resulting treasury credit for the owning GP.
class FirstRightProfit {
  const FirstRightProfit({
    required this.profitRate,
    required this.profitTreasury,
  });

  /// Zero-profit record. Used when no purchased-tile attribution applies,
  /// when the owning GP itself bid (no overseas profit), or when the
  /// relation score / fill / price collapses the formula to zero.
  static const FirstRightProfit zero = FirstRightProfit(
    profitRate: 0.0,
    profitTreasury: 0.0,
  );

  /// Profit rate applied this match — a pure function of `relationScore`,
  /// bounded to `[0.0, kMaxProfitRate]`. See [computeFirstRightProfitRate].
  final double profitRate;

  /// Treasury credit transferred to the owning GP for this filled deal,
  /// equal to `filledQuantity * pricePerUnit * profitRate`. The remainder
  /// of the buyer's payment is the minor/tribe treasury sink (no faction
  /// is credited) per `SPEC/game/world-market.md` Requirement 9.
  final double profitTreasury;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FirstRightProfit &&
        other.profitRate == profitRate &&
        other.profitTreasury == profitTreasury;
  }

  @override
  int get hashCode => Object.hash(profitRate, profitTreasury);

  @override
  String toString() =>
      'FirstRightProfit(rate: $profitRate, treasury: $profitTreasury)';
}

/// Maximum profit rate at the highest possible relation score (100).
/// Defined by `SPEC/game/world-market.md` § First right of refusal.
const double kFirstRightMaxProfitRate = 0.40;

/// Maximum relation score the formula expects (already clamped at the
/// diplomacy source per `SPEC/game/diplomacy.md` § Relation Model).
const int kFirstRightRelationScoreMax = 100;

/// Computes the overseas-profit rate `(relationScore / 100) * 0.40` and
/// clamps the result to `[0.0, kFirstRightMaxProfitRate]`.
///
/// `relationScore` is the 0–100 hidden relation score between the owning
/// GP and the minor/tribe that owns the underlying purchased province
/// (`SPEC/game/diplomacy.md` § Relation Model). The formula is bounded by
/// construction when `relationScore` is in `[0, 100]`; out-of-range
/// inputs are still clamped defensively because callers may have stale
/// state during refactors.
double computeFirstRightProfitRate(int relationScore) {
  if (relationScore <= 0) return 0.0;
  if (relationScore >= kFirstRightRelationScoreMax) {
    return kFirstRightMaxProfitRate;
  }
  return (relationScore / kFirstRightRelationScoreMax) *
      kFirstRightMaxProfitRate;
}

/// Computes the owning-GP overseas-profit credit for a single filled deal
/// attributed to a purchased tile when the owning GP did not bid.
///
/// Inputs:
/// - [relationScore] — owning GP's 0–100 hidden score with the minor/tribe
///   that owns the underlying purchased province.
/// - [filledQuantity] — units transferred for this deal (≥ 0). When
///   `filledQuantity == 0`, the result is `FirstRightProfit.zero`.
/// - [pricePerUnit] — clear price for this deal in treasury units (≥ 0.0).
///   When `pricePerUnit == 0.0`, the result is `FirstRightProfit.zero`.
///
/// Returns a [FirstRightProfit] holding both the applied rate and the
/// final treasury credit (`filledQuantity * pricePerUnit * profitRate`).
/// Negative inputs are clamped to zero defensively — callers should not
/// rely on negative-quantity behavior in production paths.
FirstRightProfit computeFirstRightProfit({
  required int relationScore,
  required int filledQuantity,
  required double pricePerUnit,
}) {
  if (filledQuantity <= 0 || pricePerUnit <= 0.0) {
    return FirstRightProfit.zero;
  }
  final rate = computeFirstRightProfitRate(relationScore);
  if (rate <= 0.0) return FirstRightProfit.zero;
  final treasury = filledQuantity * pricePerUnit * rate;
  return FirstRightProfit(profitRate: rate, profitTreasury: treasury);
}
