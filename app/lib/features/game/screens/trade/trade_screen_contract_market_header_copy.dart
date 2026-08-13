/// Market header indicator keys and copy literals (Refs #4352).
library;

import 'package:flutter/material.dart';

abstract final class TradeScreenMarketHeaderCopy {
  TradeScreenMarketHeaderCopy._();

  static const Key marketBidGoodsIndicatorKey =
      ValueKey<String>('tradeScreenMarketBidGoodsIndicator');

  static const Key marketBidTypeWarningKey =
      ValueKey<String>('tradeScreenMarketBidTypeWarning');

  static const Key marketBidGoodsTooltipKey =
      ValueKey<String>('tradeScreenMarketBidGoodsTooltip');

  static const Key marketBidTypeCapGoldenKey =
      ValueKey<String>('tradeScreenMarketBidTypeCapGolden');

  static const Key marketBidBudgetIndicatorKey =
      ValueKey<String>('tradeScreenMarketBidBudgetIndicator');

  static const Key marketBidBudgetWarningKey =
      ValueKey<String>('tradeScreenMarketBidBudgetWarning');

  static const Key marketBidBudgetTooltipKey =
      ValueKey<String>('tradeScreenMarketBidBudgetTooltip');

  static const Key marketCargoIndicatorKey =
      ValueKey<String>('tradeScreenMarketCargoIndicator');

  static const Key marketCargoWarningKey =
      ValueKey<String>('tradeScreenMarketCargoWarning');

  static const Key marketCargoTooltipKey =
      ValueKey<String>('tradeScreenMarketCargoTooltip');

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidGoodsIndicatorPrefix = 'Bid goods:';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidTypeLimitWarningText =
      'Bid commodity limit reached — remove a bid, or research Trade Fairs '
      'to raise your limit.';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidTypeLimitTooltipCopyCap3 =
      'You may bid on up to three distinct commodities each turn; research '
      'Trade Fairs to raise the limit to six.';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidTypeLimitTooltipCopyCap6 =
      'Trade Fairs lets you bid on up to six distinct commodities each turn.';

  static String bidTypeLimitTooltipForCap(int cap) {
    if (cap >= 6) return bidTypeLimitTooltipCopyCap6;
    return bidTypeLimitTooltipCopyCap3;
  }

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String cargoLimitTooltipCopy =
      'Staged bids share your trade cargo capacity and cannot exceed your '
      'remaining cargo this turn.';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidChipBidTypeCapSemanticLabel =
      'Bid disabled — commodity limit reached';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String cargoIndicatorPrefix = 'Cargo remaining:';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String cargoLimitWarningText =
      'Cargo limit reached — increase your fleet capacity or reduce bids.';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidBudgetIndicatorPrefix = 'Bid budget:';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidBudgetLimitWarningText =
      'Treasury bid limit reached — free gold or reduce other spending '
      'before bidding more.';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidBudgetLimitTooltipCopy =
      'Bids spend from treasury after other staged orders; expected income '
      'does not increase this budget.';
}
