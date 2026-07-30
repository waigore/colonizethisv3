// Widget goldens for the Trade Market tab bid-type slot indicator and gate
// (Refs #4170, #4186). Pixel baselines under `app/test/goldens/` close the
// verify-github-issue UI proof gap flagged on issue #4170.
//
// Golden mapping:
//  - AC1  header `Bid goods: U of C` indicator (cap 3 / 6 variants)
//  - AC2  saturation warning when U >= C
//  - AC6  inline question-icon tooltips beside each limit line
//
// SPEC: SPEC/ui/trade-screen.md § Market tab — bid-type cap.

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

Future<void> _pumpMarketBidTypeCapHeaderGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required int stagedDistinctBidCount,
  required int bidTypeCap,
  int clampedRemaining = 10,
  bool cargoWarningVisible = false,
  int bidBudgetTotal = 100,
  int bidBudgetRemaining = 100,
  bool bidBudgetWarningVisible = false,
  Size viewport = const Size(480, 240),
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
          ),
        );
      },
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab bid-type cap goldens (Refs #4170, #4186)', () {
    testWidgets(
      'golden: cap 3 saturated with bid-goods warning (AC1/AC2)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketBidTypeCapSaturatedGolden',
        );

        await _pumpMarketBidTypeCapHeaderGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(),
          stagedDistinctBidCount: 3,
          bidTypeCap: 3,
          clampedRemaining: 9,
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWarningKey),
          findsOneWidget,
        );

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/trade_market_bid_type_cap_saturated.png'),
        );
      },
    );

    testWidgets(
      'golden: default cap 3 indicator (AC1)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketBidTypeCapEmbassy3Golden',
        );

        await _pumpMarketBidTypeCapHeaderGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(),
          stagedDistinctBidCount: 0,
          bidTypeCap: 3,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Bid goods: 0 of 3'), findsOneWidget);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/trade_market_bid_type_cap_embassy_3.png'),
        );
      },
    );

    testWidgets(
      'golden: Trade Fairs cap 6 indicator (AC1)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketBidTypeCapTradeFairs6Golden',
        );

        await _pumpMarketBidTypeCapHeaderGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            techUnlocked: const <String, bool>{kTechIdTradeFairs: true},
          ),
          stagedDistinctBidCount: 0,
          bidTypeCap: 6,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Bid goods: 0 of 6'), findsOneWidget);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(
            'goldens/trade_market_bid_type_cap_trade_fairs_6.png',
          ),
        );
      },
    );

    testWidgets(
      'golden: inline limit tooltips beside each header line (AC6)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketBidTypeCapWhyExpandedGolden',
        );

        await _pumpMarketBidTypeCapHeaderGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(),
          stagedDistinctBidCount: 0,
          bidTypeCap: 3,
          viewport: const Size(480, 200),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidGoodsTooltipKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreenMarketKeys.marketCargoTooltipKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetTooltipKey),
          findsOneWidget,
        );

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(
            'goldens/trade_market_bid_type_cap_why_expanded.png',
          ),
        );
      },
    );
  });
}
