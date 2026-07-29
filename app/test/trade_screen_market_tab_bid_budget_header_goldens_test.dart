// Widget goldens for the Trade Market tab treasury bid-budget header (Refs
// #4186). Pixel baselines under `app/test/goldens/` close the
// verify-github-issue UI proof gap flagged on issue #4186.
//
// Golden mapping:
//  - AC1  header `Bid budget: R of B` indicator (saturated variant)
//  - AC2  treasury bid-limit danger warning when R == 0
//  - AC7  **Why this limit?** progressive disclosure (bid-budget copy)
//
// SPEC: SPEC/ui/trade-screen.md § Market tab — treasury bid budget indicator.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_tab.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_tab_build_sections.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_tab_cargo_header.dart';

import 'golden_capture_harness.dart';
import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

Future<void> _pumpMarketBidBudgetHeaderGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  int stagedDistinctBidCount = 1,
  int bidTypeCap = 1,
  int clampedRemaining = 9,
  bool cargoWarningVisible = false,
  required int bidBudgetTotal,
  required int bidBudgetRemaining,
  required bool bidBudgetWarningVisible,
  bool expandBidBudgetWhyLimit = false,
  Size viewport = const Size(480, 280),
}) async {
  final MarketTabContent content = MarketTabContent(
    game: game,
    playerId: _humanPlayerId,
    canEdit: true,
  );

  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: viewport,
    center: false,
    child: Builder(
      builder: (BuildContext context) {
        final styles = content.marketTabTextStyles(Theme.of(context));
        return SizedBox(
          width: viewport.width,
          child: MarketTabHeaderStrip(
            stagedDistinctBidCount: stagedDistinctBidCount,
            bidTypeCap: bidTypeCap,
            clampedRemaining: clampedRemaining,
            cargoWarningVisible: cargoWarningVisible,
            bidBudgetTotal: bidBudgetTotal,
            bidBudgetRemaining: bidBudgetRemaining,
            bidBudgetWarningVisible: bidBudgetWarningVisible,
            bidGoodsIndicatorStyle: styles.bidGoodsIndicatorStyle,
            bidTypeWarningStyle: styles.bidTypeWarningStyle,
            cargoIndicatorStyle: styles.cargoIndicatorStyle,
            cargoWarningStyle: styles.cargoWarningStyle,
            bidBudgetIndicatorStyle: styles.bidBudgetIndicatorStyle,
            bidBudgetWarningStyle: styles.bidBudgetWarningStyle,
            whyToggleStyle: styles.whyToggleStyle,
            whyBodyStyle: styles.whyBodyStyle,
          ),
        );
      },
    ),
  );

  if (expandBidBudgetWhyLimit) {
    await tester.tap(
      find.byKey(TradeScreenMarketKeys.marketBidBudgetWhyToggleKey),
    );
    await tester.pump();
  }
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab bid-budget header goldens (Refs #4186)', () {
    testWidgets(
      'golden: treasury bid budget saturated with danger warning (AC1/AC2)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketBidBudgetSaturatedGolden',
        );

        await _pumpMarketBidBudgetHeaderGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(),
          bidBudgetTotal: 90,
          bidBudgetRemaining: 0,
          bidBudgetWarningVisible: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Bid budget: 0 of 90'), findsOneWidget);
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWarningKey),
          findsOneWidget,
        );

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/trade_market_bid_budget_saturated.png'),
        );
      },
    );

    testWidgets(
      'golden: bid-budget Why this limit? expanded copy (AC7)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketBidBudgetWhyExpandedGolden',
        );

        await _pumpMarketBidBudgetHeaderGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(),
          bidBudgetTotal: 100,
          bidBudgetRemaining: 70,
          bidBudgetWarningVisible: false,
          expandBidBudgetWhyLimit: true,
          viewport: const Size(480, 320),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWhyBodyKey),
          findsOneWidget,
        );
        expect(
          find.text(TradeScreenMarketKeys.bidBudgetWhyLimitCopy),
          findsOneWidget,
        );

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(
            'goldens/trade_market_bid_budget_why_expanded.png',
          ),
        );
      },
    );
  });
}
