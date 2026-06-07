import 'package:colonizethis_models/colonizethis_models.dart';

/// Price discovery for the world market phase.
///
/// SPEC/game/world-market.md § Price discovery,
/// SPEC/program/world-market-resolution.md § Price discovery.
///
/// All functions in this file are pure: deterministic for fixed inputs and
/// silent (no logger output) so they remain trivially callable inside hot
/// turn-resolution paths inside the 15-second budget.

/// Inputs for [PriceDiscovery.computeNextPrice].
///
/// `oldPrice` is the price valid for the *current* turn (deals clear at
/// `oldPrice`). `basePrice` is the commodity's `defaultMarketPrice` from
/// [`SPEC/game/resource-terrain-region-rules.md`](../../../../SPEC/game/resource-terrain-region-rules.md);
/// the price floor is `basePrice * priceFloorRatio`.
///
/// `newBidQuantity` and `newOfferQuantity` are sums of *newly-submitted*
/// quantities for the current turn (carry-forward unfilled orders are
/// excluded from price aggregation per `SPEC/game/world-market.md`).
typedef PriceDiscoveryInputs = ({
  double oldPrice,
  int basePrice,
  int newBidQuantity,
  int newOfferQuantity,
});

/// Pure pricing helpers and constants for the world market.
class PriceDiscovery {
  const PriceDiscovery._();

  /// Maximum price change magnitude per turn.
  /// SPEC/game/world-market.md § Price discovery: cap is ±20%.
  static const double maxDeltaPerTurn = 0.20;

  /// Coefficient applied to the supply/demand ratio.
  /// SPEC/game/world-market.md § Price discovery: `0.5 × (bid − offer) / volume`.
  static const double deltaCoefficient = 0.5;

  /// Floor as a fraction of `basePrice`.
  /// SPEC/game/world-market.md § Price discovery: floor at 30% of base.
  static const double priceFloorRatio = 0.30;

  /// Computes the next-turn market price for a single commodity.
  ///
  /// Returns `oldPrice` when total submitted volume is zero (price unchanged).
  /// Otherwise scales `oldPrice` by `(1 + cappedDelta)` and clamps the result
  /// at the price floor (`basePrice * priceFloorRatio`).
  static double computeNextPrice(PriceDiscoveryInputs inputs) {
    assert(inputs.newBidQuantity >= 0, 'newBidQuantity must be non-negative');
    assert(
      inputs.newOfferQuantity >= 0,
      'newOfferQuantity must be non-negative',
    );
    assert(inputs.basePrice >= 0, 'basePrice must be non-negative');
    assert(inputs.oldPrice >= 0, 'oldPrice must be non-negative');

    final volume = inputs.newBidQuantity + inputs.newOfferQuantity;
    final floor = inputs.basePrice.toDouble() * priceFloorRatio;

    if (volume == 0) {
      // No supply/demand signal — price unchanged. Defensive guard: if a
      // hand-constructed test state somehow holds an old price below the
      // floor, do not lower it further.
      return inputs.oldPrice;
    }

    final delta = inputs.newBidQuantity - inputs.newOfferQuantity;
    final rawDelta = deltaCoefficient * delta / volume;
    final cappedDelta = rawDelta.clamp(-maxDeltaPerTurn, maxDeltaPerTurn);
    final candidate = inputs.oldPrice * (1.0 + cappedDelta);
    return candidate >= floor ? candidate : floor;
  }

  /// Builds a [MarketActivity] record describing the resolved turn for a
  /// single commodity.
  ///
  /// `priceChangePercent` is `(newPrice / oldPrice) - 1`, reproducing the
  /// signed delta consistent with [computeNextPrice]'s capping. When
  /// `oldPrice <= 0` the percent is reported as `0.0` (defensive guard for
  /// hand-constructed test states; a real game seeds prices from
  /// `defaultMarketPrice`, all positive).
  static MarketActivity computeMarketActivity(
    PriceDiscoveryInputs inputs, {
    required int filledQuantity,
  }) {
    assert(filledQuantity >= 0, 'filledQuantity must be non-negative');

    final newPrice = computeNextPrice(inputs);
    final percent = inputs.oldPrice > 0
        ? (newPrice / inputs.oldPrice) - 1.0
        : 0.0;
    return MarketActivity(
      totalBidQuantity: inputs.newBidQuantity,
      totalOfferQuantity: inputs.newOfferQuantity,
      filledQuantity: filledQuantity,
      priceChangePercent: percent,
    );
  }
}
