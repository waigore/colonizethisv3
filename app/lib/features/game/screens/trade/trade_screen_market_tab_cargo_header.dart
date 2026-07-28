// Market-tab header strip: bid-goods indicator, cargo telemetry, and cap
// warnings. Split from `trade_screen_market_tab.dart` to keep the host
// `build` body under the repo file-size target (Refs #3878, #4170).

/// Persistent header above the Market commodity list (Refs #2993 E5c,
/// #4170 bid-type slots). Renders live bid-goods usage, cargo
/// remaining, and saturation warnings. Shared by the editable and
/// observe-mode bodies so telemetry stays live even when row controls are
/// dimmed.

import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'trade_screen_contract_market.dart';

class MarketTabHeaderStrip extends StatefulWidget {
  const MarketTabHeaderStrip({
    required this.stagedDistinctBidCount,
    required this.bidTypeCap,
    required this.clampedRemaining,
    required this.cargoWarningVisible,
    required this.bidGoodsIndicatorStyle,
    required this.bidTypeWarningStyle,
    required this.cargoIndicatorStyle,
    required this.cargoWarningStyle,
    required this.whyToggleStyle,
    required this.whyBodyStyle,
  });

  final int stagedDistinctBidCount;
  final int bidTypeCap;
  final int clampedRemaining;
  final bool cargoWarningVisible;
  final TextStyle bidGoodsIndicatorStyle;
  final TextStyle bidTypeWarningStyle;
  final TextStyle cargoIndicatorStyle;
  final TextStyle cargoWarningStyle;
  final TextStyle whyToggleStyle;
  final TextStyle whyBodyStyle;

  @override
  State<MarketTabHeaderStrip> createState() => _MarketTabHeaderStripState();
}

class _MarketTabHeaderStripState extends State<MarketTabHeaderStrip> {
  bool _whyExpanded = false;

  bool get _bidTypeWarningVisible =>
      widget.bidTypeCap > 0 &&
      widget.stagedDistinctBidCount >= widget.bidTypeCap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          // ignore: avoid_hardcoded_strings_in_widgets
          '${TradeScreenMarketKeys.bidGoodsIndicatorPrefix} '
          '${widget.stagedDistinctBidCount} of ${widget.bidTypeCap}',
          key: TradeScreenMarketKeys.marketBidGoodsIndicatorKey,
          style: widget.bidGoodsIndicatorStyle,
        ),
        if (_bidTypeWarningVisible) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            TradeScreenMarketKeys.bidTypeLimitWarningText,
            key: TradeScreenMarketKeys.marketBidTypeWarningKey,
            style: widget.bidTypeWarningStyle,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          // ignore: avoid_hardcoded_strings_in_widgets
          '${TradeScreenMarketKeys.cargoIndicatorPrefix} '
          '${widget.clampedRemaining}',
          key: TradeScreenMarketKeys.marketCargoIndicatorKey,
          style: widget.cargoIndicatorStyle,
        ),
        if (widget.cargoWarningVisible) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            TradeScreenMarketKeys.cargoLimitWarningText,
            key: TradeScreenMarketKeys.marketCargoWarningKey,
            style: widget.cargoWarningStyle,
          ),
        ],
        const SizedBox(height: 4),
        InkWell(
          key: TradeScreenMarketKeys.marketBidTypeWhyToggleKey,
          onTap: () => setState(() => _whyExpanded = !_whyExpanded),
          child: Text(
            TradeScreenMarketKeys.bidTypeLimitWhyToggleLabel,
            style: widget.whyToggleStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: EditorialMonoclePalette.muted,
            ),
          ),
        ),
        if (_whyExpanded) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            TradeScreenMarketKeys.bidTypeWhyLimitCopyForCap(widget.bidTypeCap),
            key: TradeScreenMarketKeys.marketBidTypeWhyBodyKey,
            style: widget.whyBodyStyle,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
