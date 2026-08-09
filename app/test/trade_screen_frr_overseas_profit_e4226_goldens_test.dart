// Widget goldens for Market first-right chip + Deal Book overseas-profit
// ledger (Refs #4226). Pixel baselines under `app/test/goldens/` close the
// verify-github-issue UI proof gap flagged on issue #4226.
//
// Golden mapping:
//  - AC-1  timber row shows compact First right chip when holdings exist
//  - AC-2  grain row omits First right chip when no still-valid holdings
//  - AC-6  Deal Book overseas-profit ledger row (commodity × qty — amount)
//
// SPEC: SPEC/ui/trade-screen.md § Market tab — first-right chip;
//       § Deal Book — overseas-profit ledger.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_deal_book.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_tab.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

Map<CommodityId, int> _stableMarketGoldenPrices() {
  return <CommodityId, int>{
    CommodityCatalog.grain.id: 8,
    CommodityCatalog.timber.id: 40,
  };
}

Future<void> _pumpMarketTabGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required Size viewport,
}) async {
  final Player player = game.players.firstWhere(
    (Player p) => p.id == _humanPlayerId,
  );

  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: viewport,
    center: false,
    includeLocalizations: true,
    wrapInProviderScope: true,
    overrides: <Override>[
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      shellPlayerContextProvider.overrideWith(
        (Ref ref) => tradeTestShellPlayerContext(player: player),
      ),
    ],
    child: SizedBox(
      width: viewport.width,
      height: viewport.height,
      child: MarketTabContent(
        game: game,
        playerId: _humanPlayerId,
        canEdit: true,
      ),
    ),
  );
}

Future<void> _pumpDealBookGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required Size viewport,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: viewport,
    center: false,
    includeLocalizations: true,
    child: SizedBox(
      width: viewport.width,
      height: viewport.height,
      child: SingleChildScrollView(
        child: DealBookTabContent(
          game: game,
          playerId: _humanPlayerId,
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('TradeScreen #4226 FRR + overseas-profit goldens', () {
    testWidgets(
      'golden: timber row First right chip when holdings exist (AC-1)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketTimberFirstRightChipGolden',
        );

        await _pumpMarketTabGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGameWithTimberFirstRight(
          ).copyWith(
            worldMarketState: WorldMarketState(
              prices: _stableMarketGoldenPrices(),
              lastTurnActivity: <CommodityId, MarketActivity>{
                CommodityCatalog.timber.id: const MarketActivity(
                  totalBidQuantity: 2,
                  totalOfferQuantity: 1,
                ),
              },
            ),
          ),
          viewport: const Size(480, 720),
        );

        final Finder timberRow = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey('timber'),
        );
        await tester.scrollUntilVisible(
          timberRow,
          80,
          scrollable: find.byType(Scrollable).first,
        );
        await pumpForGolden(tester);

        expect(tester.takeException(), isNull);
        expect(timberRow, findsOneWidget);
        expect(
          find.byKey(TradeScreenMarketKeys.marketRowFirstRightChipKey('timber')),
          findsOneWidget,
        );

        await expectLater(
          timberRow,
          matchesGoldenFile('goldens/trade_market_timber_first_right_chip.png'),
        );
      },
    );

    testWidgets(
      'golden: grain row omits First right chip without holdings (AC-2)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketGrainNoFirstRightChipGolden',
        );

        await _pumpMarketTabGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            prices: _stableMarketGoldenPrices(),
            lastTurnActivity: <CommodityId, MarketActivity>{
              CommodityCatalog.grain.id: const MarketActivity(
                totalBidQuantity: 3,
                totalOfferQuantity: 0,
              ),
            },
          ),
          viewport: const Size(480, 360),
        );

        final Finder grainRow = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey('grain'),
        );

        expect(tester.takeException(), isNull);
        expect(grainRow, findsOneWidget);
        expect(
          find.byKey(TradeScreenMarketKeys.marketRowFirstRightChipKey('grain')),
          findsNothing,
        );
        expect(find.text('First right'), findsNothing);

        await expectLater(
          grainRow,
          matchesGoldenFile('goldens/trade_market_grain_no_first_right_chip.png'),
        );
      },
    );

    testWidgets(
      'golden: Deal Book overseas-profit ledger row (AC-6)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeDealBookOverseasProfitLedgerGolden',
        );

        await _pumpDealBookGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            lastTurnOverseasProfitCreditsByGpId: const {
              kTradeTestHumanPlayerId: [
                OverseasProfitCreditRecord(
                  creditKind: OverseasProfitCreditKind.tileOwnerShare,
                  commodityId: 'timber',
                  quantity: 5,
                  profitTreasury: 15,
                  buyerFactionId: 'gp_aragon',
                  sourceFactionId: 'M1',
                ),
              ],
            },
          ),
          viewport: const Size(520, 200),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookOverseasProfitRowKey(0)),
          findsOneWidget,
        );

        await expectLater(
          find.byKey(TradeScreenDealBookKeys.dealBookOverseasProfitRowKey(0)),
          matchesGoldenFile('goldens/trade_deal_book_overseas_profit_row.png'),
        );
      },
    );
  });
}
