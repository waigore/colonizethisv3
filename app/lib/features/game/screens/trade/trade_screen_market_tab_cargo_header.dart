// Market-tab cargo-remaining indicator + cap-warning header strip.
// Split from `trade_screen_market_tab.dart` to keep the host `build`
// body under the repo file-size target (Refs #3878).

/// Persistent header above the Market commodity list (Refs #2993 E5c).
///
/// Renders `Cargo remaining: X` and, when the cross-commodity bid cap is
/// saturated, the cargo-limit warning line. Shared by the editable and
/// observe-mode bodies so telemetry stays live even when row controls are
/// dimmed.

import 'package:flutter/material.dart';

import 'trade_screen_contract_market.dart';

class MarketTabCargoHeader extends StatelessWidget {
  const MarketTabCargoHeader({
    required this.clampedRemaining,
    required this.warningVisible,
    required this.cargoIndicatorStyle,
    required this.cargoWarningStyle,
  });

  final int clampedRemaining;
  final bool warningVisible;
  final TextStyle cargoIndicatorStyle;
  final TextStyle cargoWarningStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          // ignore: avoid_hardcoded_strings_in_widgets
          '${TradeScreenMarketKeys.cargoIndicatorPrefix} $clampedRemaining',
          key: TradeScreenMarketKeys.marketCargoIndicatorKey,
          style: cargoIndicatorStyle,
        ),
        if (warningVisible) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            TradeScreenMarketKeys.cargoLimitWarningText,
            key: TradeScreenMarketKeys.marketCargoWarningKey,
            style: cargoWarningStyle,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
