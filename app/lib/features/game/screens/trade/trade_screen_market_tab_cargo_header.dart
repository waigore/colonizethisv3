// Market-tab header strip: bid-goods indicator, cargo telemetry, and cap
// warnings. Split from `trade_screen_market_tab.dart` to keep the host
// `build` body under the repo file-size target (Refs #3878, #4170).

/// Persistent header above the Market commodity list (Refs #2993 E5c,
/// #4170 bid-type slots, #4186 inline limit tooltips). Renders live
/// bid-goods usage, cargo remaining, and saturation warnings. Shared by
/// the editable and observe-mode bodies so telemetry stays live even when
/// row controls are dimmed.

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../widgets/ct_icon_action.dart';
import 'trade_screen_contract_market.dart';

/// Per-side hit padding so the help [CtIconAction] meets
/// [kMinTouchTargetSize] (18 + 2×13 = 44 dp).
const double _limitHelpHitPadding = 13;

class MarketTabHeaderStrip extends StatelessWidget {
  const MarketTabHeaderStrip({
    required this.stagedDistinctBidCount,
    required this.bidTypeCap,
    required this.clampedRemaining,
    required this.cargoWarningVisible,
    required this.bidBudgetTotal,
    required this.bidBudgetRemaining,
    required this.bidBudgetWarningVisible,
    required this.bidGoodsIndicatorStyle,
    required this.bidTypeWarningStyle,
    required this.cargoIndicatorStyle,
    required this.cargoWarningStyle,
    required this.bidBudgetIndicatorStyle,
    required this.bidBudgetWarningStyle,
  });

  final int stagedDistinctBidCount;
  final int bidTypeCap;
  final int clampedRemaining;
  final bool cargoWarningVisible;
  final int bidBudgetTotal;
  final int bidBudgetRemaining;
  final bool bidBudgetWarningVisible;
  final TextStyle bidGoodsIndicatorStyle;
  final TextStyle bidTypeWarningStyle;
  final TextStyle cargoIndicatorStyle;
  final TextStyle cargoWarningStyle;
  final TextStyle bidBudgetIndicatorStyle;
  final TextStyle bidBudgetWarningStyle;

  bool get _bidTypeWarningVisible =>
      bidTypeCap > 0 && stagedDistinctBidCount >= bidTypeCap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _limitLine(
          indicatorKey: TradeScreenMarketKeys.marketBidGoodsIndicatorKey,
          tooltipKey: TradeScreenMarketKeys.marketBidGoodsTooltipKey,
          // ignore: avoid_hardcoded_strings_in_widgets
          indicatorText:
              '${TradeScreenMarketKeys.bidGoodsIndicatorPrefix} '
              '$stagedDistinctBidCount of $bidTypeCap',
          indicatorStyle: bidGoodsIndicatorStyle,
          tooltipMessage:
              TradeScreenMarketKeys.bidTypeLimitTooltipForCap(bidTypeCap),
        ),
        if (_bidTypeWarningVisible) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            TradeScreenMarketKeys.bidTypeLimitWarningText,
            key: TradeScreenMarketKeys.marketBidTypeWarningKey,
            style: bidTypeWarningStyle,
          ),
        ],
        const SizedBox(height: 4),
        _limitLine(
          indicatorKey: TradeScreenMarketKeys.marketCargoIndicatorKey,
          tooltipKey: TradeScreenMarketKeys.marketCargoTooltipKey,
          // ignore: avoid_hardcoded_strings_in_widgets
          indicatorText:
              '${TradeScreenMarketKeys.cargoIndicatorPrefix} '
              '$clampedRemaining',
          indicatorStyle: cargoIndicatorStyle,
          tooltipMessage: TradeScreenMarketKeys.cargoLimitTooltipCopy,
        ),
        if (cargoWarningVisible) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            TradeScreenMarketKeys.cargoLimitWarningText,
            key: TradeScreenMarketKeys.marketCargoWarningKey,
            style: cargoWarningStyle,
          ),
        ],
        const SizedBox(height: 4),
        _limitLine(
          indicatorKey: TradeScreenMarketKeys.marketBidBudgetIndicatorKey,
          tooltipKey: TradeScreenMarketKeys.marketBidBudgetTooltipKey,
          // ignore: avoid_hardcoded_strings_in_widgets
          indicatorText:
              '${TradeScreenMarketKeys.bidBudgetIndicatorPrefix} '
              '$bidBudgetRemaining of $bidBudgetTotal',
          indicatorStyle: bidBudgetIndicatorStyle,
          tooltipMessage: TradeScreenMarketKeys.bidBudgetLimitTooltipCopy,
        ),
        if (bidBudgetWarningVisible) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            TradeScreenMarketKeys.bidBudgetLimitWarningText,
            key: TradeScreenMarketKeys.marketBidBudgetWarningKey,
            style: bidBudgetWarningStyle,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _limitLine({
    required Key indicatorKey,
    required Key tooltipKey,
    required String indicatorText,
    required TextStyle indicatorStyle,
    required String tooltipMessage,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            indicatorText,
            key: indicatorKey,
            style: indicatorStyle,
          ),
        ),
        CtIconAction(
          key: tooltipKey,
          icon: Icons.help_outline,
          tooltip: tooltipMessage,
          semanticLabel: tooltipMessage,
          hitPadding: _limitHelpHitPadding,
          onPressed: () {},
        ),
      ],
    );
  }
}
