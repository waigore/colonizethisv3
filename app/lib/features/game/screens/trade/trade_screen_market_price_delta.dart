// Last-turn Market price-delta helpers (Refs #4345).
//
// SPEC/ui/trade-screen.md § Market tab — last-turn price move;
// SPEC/game/world-market.md § Price discovery.

/// Reconstructs the last-turn signed coin delta from the published integer
/// price and `MarketActivity.priceChangePercent`.
///
/// Returns `null` when there is no displayable non-zero move (missing
/// price, percent `0`, percent `≤ −1`, or reconstructed delta `0`).
int? marketPriceDeltaCoins({
  required int? currentPrice,
  required double priceChangePercent,
}) {
  if (currentPrice == null) return null;
  if (priceChangePercent == 0.0) return null;
  if (priceChangePercent <= -1.0) return null;
  final int previous = (currentPrice / (1.0 + priceChangePercent)).round();
  final int delta = currentPrice - previous;
  if (delta == 0) return null;
  return delta;
}

/// Formats a non-zero coin delta as `+£N` / `−£N` (unicode minus U+2212).
String formatMarketPriceDelta(int delta) {
  if (delta > 0) return '+£$delta';
  return '\u2212£${delta.abs()}';
}
