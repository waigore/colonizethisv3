/// Row sizing, quantity, and price-display constants for Market rows (Refs #4352).
library;

import '../../../../config/app_constants.dart';

abstract final class TradeScreenMarketRowSizes {
  TradeScreenMarketRowSizes._();

  /// Logical-pixel side length of the leading `ResourceIcon` paint.
  static const double marketRowResourceIconSize = 20;

  /// Logical-pixel side length of the trailing treasury-coin glyph.
  static const double marketRowPriceCoinIconSize = 14;

  /// Fixed width of the trailing market-price column on row line 1.
  static const double marketRowPriceColumnWidth = 64;

  /// Horizontal gap between the treasury-coin glyph and the price text.
  static const double marketRowPriceColumnInnerGap = 4;

  /// Asset path of the treasury-coin glyph next to each Market row price.
  static const String marketRowPriceCoinAssetPath =
      '${kAppIconAssetPrefix}ui_icon_treasury_coin.png';

  /// Lower bound for the per-row quantity stepper when a trade order is staged.
  static const int marketRowQuantityMin = 1;

  /// Default starting quantity when the player first selects `Bid` or `Offer`.
  static const int marketRowQuantityDefault = 1;

  /// Default `TradeOrder.priority` for newly staged orders.
  // ignore: avoid-non-null-assertion
  static const int marketRowDefaultPriority = 1;

  /// Glyph in the quantity readout when no trade order is staged.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String marketRowQuantityIdleGlyph = '—';
}
