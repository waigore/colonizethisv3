import 'package:colonizethis_app_ui_chrome/event_feed/turn_news_court_summary.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

TurnNewsCourtSummaryLabels _labels() {
  return TurnNewsCourtSummaryLabels(
    researchFinished: (tech) => '$tech finished',
    researchFinishedMany: (count) => '$count technologies finished',
    researchFinishedUnknown: () => 'a technology finished',
    decreeRefused: () => 'a decree was refused',
    decreesRefused: (count) => '$count decrees were refused',
    battleFought: () => 'a battle was fought',
    battlesFought: (count) => '$count battles were fought',
    marketEconomy: () => 'market and realm accounts',
    workFinished: () => 'work finished',
    worksFinished: (count) => '$count works finished',
  );
}

void main() {
  group('buildTurnNewsCourtSummary', () {
    test('positive: research complete yields tech display clause', () {
      final summary = buildTurnNewsCourtSummary(
        events: const [
          AppResearchCompleteEvent(
            playerId: 'gp1',
            techId: 'tech_sailing',
            turnNumber: 1,
          ),
        ],
        humanPlayerId: 'gp1',
        labels: _labels(),
        techDisplayName: (_) => 'Sailing',
        isCatalogTech: (_) => true,
      );

      expect(summary.clauses, ['Sailing finished']);
      expect(summary.overflowFamilyCount, 0);
    });

    test('positive: priority orders rejected before research', () {
      final summary = buildTurnNewsCourtSummary(
        events: const [
          AppResearchCompleteEvent(
            playerId: 'gp1',
            techId: 'tech_sailing',
            turnNumber: 1,
          ),
          AppOrderRejectedEvent(
            playerId: 'gp1',
            orderKind: OrderKind.move,
            orderSummary: 'move u1',
            reasonCode: 'invalid_destination',
          ),
        ],
        humanPlayerId: 'gp1',
        labels: _labels(),
        techDisplayName: (_) => 'Sailing',
        isCatalogTech: (_) => true,
      );

      expect(summary.clauses, ['a decree was refused', 'Sailing finished']);
    });

    test('negative: rival events omitted', () {
      final summary = buildTurnNewsCourtSummary(
        events: const [
          AppResearchCompleteEvent(
            playerId: 'gp2',
            techId: 'tech_sailing',
            turnNumber: 1,
          ),
        ],
        humanPlayerId: 'gp1',
        labels: _labels(),
        techDisplayName: (_) => 'Sailing',
        isCatalogTech: (_) => true,
      );

      expect(summary.isEmpty, isTrue);
    });

    test('positive: more than three families collapse overflow count', () {
      final summary = buildTurnNewsCourtSummary(
        events: const [
          AppOrderRejectedEvent(
            playerId: 'gp1',
            orderKind: OrderKind.move,
            orderSummary: 'move u1',
            reasonCode: 'invalid_destination',
          ),
          AppResearchCompleteEvent(
            playerId: 'gp1',
            techId: 'tech_sailing',
            turnNumber: 1,
          ),
          AppCombatResultEvent(
            attackerId: 'gp1',
            defenderId: 'gp2',
            winnerId: 'gp1',
            provinceId: 'oldWorld|p1',
            turnNumber: 1,
          ),
          AppMarketTurnSummaryEvent(
            playerId: 'gp1',
            totalSpent: 100,
            totalReceived: 0,
            carryForwardOrderCount: 0,
            turnNumber: 1,
          ),
          AppWorkOrderCompletedEvent(
            playerId: 'gp1',
            unitId: 'u1',
            workTarget: 'fortify',
            targetTileKey: 'ow|1|2',
            provinceId: 'oldWorld|p1',
            turnNumber: 1,
          ),
        ],
        humanPlayerId: 'gp1',
        labels: _labels(),
        techDisplayName: (_) => 'Sailing',
        isCatalogTech: (_) => true,
      );

      expect(summary.clauses.length, 3);
      expect(summary.overflowFamilyCount, 2);
    });

    test('negative: zero overseas profit omitted from market family', () {
      final summary = buildTurnNewsCourtSummary(
        events: const [
          AppOverseasProfitCreditedEvent(
            playerId: 'gp1',
            totalTreasuryCredit: 0,
            creditCount: 0,
            turnNumber: 1,
          ),
        ],
        humanPlayerId: 'gp1',
        labels: _labels(),
        techDisplayName: (_) => 'Sailing',
        isCatalogTech: (_) => true,
      );

      expect(summary.isEmpty, isTrue);
    });
  });
}
