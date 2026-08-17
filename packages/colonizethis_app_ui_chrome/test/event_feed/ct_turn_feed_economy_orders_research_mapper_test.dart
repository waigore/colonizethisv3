import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_feed_test_context.dart';

void main() {
  group('buildCtTurnFeedEntries economy orders research', () {
    test('AppResearchCompleteEvent tappable for catalog tech', () {
      var navigated = false;
      final entry = singleTurnFeedEntry(
        const AppResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'tech_sailing',
          turnNumber: 1,
        ),
        TurnFeedTestContext(
          isCatalogTech: (_) => true,
          researchCompleteLine: (_) => 'Research: Sailing',
          navigateToTechnologyScreen: () => navigated = true,
        ),
      );

      expect(entry.text, 'Research: Sailing');
      expect(entry.linkAffordance, isTrue);
      entry.onTap?.call();
      expect(navigated, isTrue);
    });

    test('AppResearchCompleteEvent non-tappable for unknown catalog tech', () {
      final entry = singleTurnFeedEntry(
        const AppResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'unknown_tech',
          turnNumber: 1,
        ),
        TurnFeedTestContext(
          researchCompleteLine: (_) => 'Research: Unknown',
        ),
      );

      expect(entry.text, 'Research: Unknown');
      expect(entry.linkAffordance, isFalse);
      expect(entry.onTap, isNull);
    });

    test('AppOrderRejectedEvent text and optional tap', () {
      final entry = singleTurnFeedEntry(
        const AppOrderRejectedEvent(
          playerId: 'gp1',
          orderKind: OrderKind.move,
          orderSummary: 'move u1',
          reasonCode: 'insufficient_treasury',
        ),
        TurnFeedTestContext(
          orderRejectedTapForKind: (_) => () {},
        ),
      );

      expect(entry.text, 'Order rejected: insufficient treasury.');
      expect(entry.linkAffordance, isTrue);
    });

    test('AppWorkOrderCompletedEvent text and work tap', () {
      var tappedUnit = '';
      final entry = singleTurnFeedEntry(
        const AppWorkOrderCompletedEvent(
          playerId: 'gp1',
          unitId: 'u1',
          workTarget: 'fortify',
          targetTileKey: 'ow|1|2',
          provinceId: 'oldWorld|cap',
          turnNumber: 1,
        ),
        TurnFeedTestContext(
          workTargetLabel: (_) => 'Fortify',
          workOrderCompletedTap: ({
            required unitId,
            required targetTileKey,
          }) {
            tappedUnit = unitId;
            return () {};
          },
        ),
      );

      expect(entry.text, 'Capital work completed! Fortify finished!');
      entry.onTap?.call();
      expect(tappedUnit, 'u1');
    });

    test('AppOverseasProfitCreditedEvent link when tap provided', () {
      final entry = singleTurnFeedEntry(
        const AppOverseasProfitCreditedEvent(
          playerId: 'gp1',
          totalTreasuryCredit: 50,
          creditCount: 2,
          turnNumber: 1,
        ),
        TurnFeedTestContext(overseasProfitCreditedTap: () {}),
      );

      expect(
        entry.text,
        'Overseas profit credited: £50 from 2 rival purchase(s). '
        'Tap to open Deal Book.',
      );
      expect(entry.linkAffordance, isTrue);
    });

    test('AppMarketTurnSummaryEvent uses overseas profit tap', () {
      final entry = singleTurnFeedEntry(
        const AppMarketTurnSummaryEvent(
          playerId: 'gp1',
          totalSpent: 10,
          totalReceived: 20,
          carryForwardOrderCount: 0,
          turnNumber: 1,
        ),
        TurnFeedTestContext(overseasProfitCreditedTap: () {}),
      );

      expect(entry.text, 'Market: bought £10 · sold £20');
      expect(entry.linkAffordance, isTrue);
    });

    test('AppEconomyTurnSummaryEvent link when summary tap provided', () {
      final entry = singleTurnFeedEntry(
        const AppEconomyTurnSummaryEvent(
          playerId: 'gp1',
          treasuryDelta: 100,
          stockpileDeltas: {'grain': 5},
          turnNumber: 1,
        ),
        TurnFeedTestContext(economyTurnSummaryTap: () {}),
      );

      expect(entry.text, 'Realm: treasury +£100 · grain +5');
      expect(entry.linkAffordance, isTrue);
    });
  });
}
