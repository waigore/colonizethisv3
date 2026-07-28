// Widget goldens for the Trade Market tab bid-type slot indicator and gate
// (Refs #4170). Pixel baselines under `app/test/goldens/` close the
// verify-github-issue UI proof gap flagged on issue #4170.
//
// Golden mapping:
//  - AC1  header `Bid goods: U of C` indicator (cap 1 / 3 / 6 variants)
//  - AC2  saturation warning when U >= C
//  - AC6  **Why this limit?** progressive disclosure (cap 1 copy)
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
  bool expandWhyLimit = false,
  Size viewport = const Size(480, 180),
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
            bidGoodsIndicatorStyle: styles.bidGoodsIndicatorStyle,
            bidTypeWarningStyle: styles.bidTypeWarningStyle,
            cargoIndicatorStyle: styles.cargoIndicatorStyle,
            cargoWarningStyle: styles.cargoWarningStyle,
            whyToggleStyle: styles.whyToggleStyle,
            whyBodyStyle: styles.whyBodyStyle,
          ),
        );
      },
    ),
  );

  if (expandWhyLimit) {
    await tester.tap(
      find.byKey(TradeScreenMarketKeys.marketBidTypeWhyToggleKey),
    );
    await tester.pump();
  }
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab bid-type cap goldens (Refs #4170)', () {
    testWidgets(
      'golden: cap 1 saturated with bid-goods warning (AC1/AC2)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketBidTypeCapSaturatedGolden',
        );

        await _pumpMarketBidTypeCapHeaderGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(),
          stagedDistinctBidCount: 1,
          bidTypeCap: 1,
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
      'golden: embassy cap 3 indicator (AC1/AC5)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketBidTypeCapEmbassy3Golden',
        );

        await _pumpMarketBidTypeCapHeaderGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            overtureStates: const <OvertureState>[
              OvertureState(
                gpId: _humanPlayerId,
                targetId: 'minor1',
                stage: OvertureStage.embassy,
              ),
            ],
          ),
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
      'golden: embassy + Trade Fairs cap 6 indicator (AC1/AC5)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketBidTypeCapTradeFairs6Golden',
        );

        await _pumpMarketBidTypeCapHeaderGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            techUnlocked: const <String, bool>{kTechIdTradeFairs: true},
            overtureStates: const <OvertureState>[
              OvertureState(
                gpId: _humanPlayerId,
                targetId: 'minor1',
                stage: OvertureStage.embassy,
              ),
            ],
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
      'golden: Why this limit? expanded copy for cap 1 (AC6)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketBidTypeCapWhyExpandedGolden',
        );

        await _pumpMarketBidTypeCapHeaderGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(),
          stagedDistinctBidCount: 0,
          bidTypeCap: 1,
          expandWhyLimit: true,
          viewport: const Size(480, 220),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWhyBodyKey),
          findsOneWidget,
        );
        expect(
          find.text(TradeScreenMarketKeys.bidTypeWhyLimitCopyCap1),
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
