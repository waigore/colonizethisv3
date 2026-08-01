// Widget tests for Market first-right chip + Deal Book overseas-profit ledger
// (Refs #4226).
// SPEC/ui/trade-screen.md § Market tab — first-right chip; § Deal Book ledger.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Market first-right chip (Refs #4226)', () {
    testWidgets(
      'timber row shows First right chip when human owns a purchased tile',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGameWithTimberFirstRight(),
          viewport: kTradeMarketTabViewport,
        );

        expect(
          find.byKey(TradeScreenMarketKeys.marketRowFirstRightChipKey('timber')),
          findsOneWidget,
        );
        expect(find.text('First right'), findsOneWidget);
      },
    );

    testWidgets(
      'grain row omits First right chip when only timber has first right',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGameWithTimberFirstRight(),
          viewport: kTradeMarketTabViewport,
        );

        expect(
          find.byKey(TradeScreenMarketKeys.marketRowFirstRightChipKey('grain')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'no First right chips when human has no still-valid purchased tiles',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(),
          viewport: kTradeMarketTabViewport,
        );

        expect(find.text('First right'), findsNothing);
      },
    );
  });

  group('TradeScreen Deal Book overseas profit ledger (Refs #4226)', () {
    testWidgets(
      'renders overseas-profit rows when last-turn credits exist for human',
      (tester) async {
        await pumpTradeScreen(
          tester,
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
          selectDealBookTab: true,
        );

        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookOverseasProfitRowKey(0)),
          findsOneWidget,
        );
        expect(find.textContaining('15'), findsOneWidget);
      },
    );

    testWidgets(
      'omits overseas-profit subsection when no credits last turn',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(),
          selectDealBookTab: true,
        );

        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookOverseasProfitRowKey(0)),
          findsNothing,
        );
      },
    );
  });
}
