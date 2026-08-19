import 'package:colonizethis_app/widgets/turn_news_court_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

AppCombatResultEvent _combat() {
  return const AppCombatResultEvent(
    provinceId: 'oldWorld|p1',
    attackerId: 'gp1',
    defenderId: 'gp2',
    winnerId: 'gp1',
    turnNumber: 1,
  );
}

AppResearchCompleteEvent _research(String techId) {
  return AppResearchCompleteEvent(
    playerId: 'gp1',
    techId: techId,
    turnNumber: 1,
  );
}

AppOrderRejectedEvent _rejected() {
  return const AppOrderRejectedEvent(
    playerId: 'gp1',
    orderKind: OrderKind.research,
    orderSummary: 'research',
    reasonCode: 'insufficient_treasury',
  );
}

AppWorkOrderCompletedEvent _work() {
  return const AppWorkOrderCompletedEvent(
    playerId: 'gp1',
    unitId: 'u1',
    workTarget: 'fortify',
    targetTileKey: 'oldWorld|p1|0|0',
    provinceId: 'oldWorld|p1',
    turnNumber: 1,
  );
}

AppMarketTurnSummaryEvent _market() {
  return const AppMarketTurnSummaryEvent(
    playerId: 'gp1',
    totalSpent: 10,
    totalReceived: 0,
    carryForwardOrderCount: 0,
    turnNumber: 1,
  );
}

AppProvinceCapturedEvent _capture() {
  return const AppProvinceCapturedEvent(
    provinceId: 'oldWorld|p1',
    previousOwnerId: 'gp2',
    newOwnerId: 'gp1',
    turnNumber: 1,
  );
}

void main() {
  suppressLogsForTests();

  test('omits capture and rival events from court families', () {
    expect(isTurnNewsCourtSourceEvent(_capture(), 'gp1'), isFalse);
    expect(
      isTurnNewsCourtSourceEvent(_research(kTechIdImprovedSailDesign), 'gp2'),
      isFalse,
    );
    expect(isTurnNewsCourtSourceEvent(_combat(), 'gp1'), isTrue);
  });

  test('research complete uses catalog display name not raw id', () {
    final snapshot = buildTurnNewsCourtSnapshot(
      events: [_research(kTechIdImprovedSailDesign)],
      catalogTechDisplayName: (id) =>
          id == kTechIdImprovedSailDesign ? 'Improved Sail Design' : null,
    );
    expect(snapshot.families, hasLength(1));
    expect(
      snapshot.families.single.family,
      TurnNewsCourtFamily.researchComplete,
    );
    expect(snapshot.families.single.techDisplayName, 'Improved Sail Design');
    expect(snapshot.overflowFamilyCount, 0);
  });

  test('unknown tech display name stays null so UI omits raw id', () {
    final snapshot = buildTurnNewsCourtSnapshot(
      events: [_research('not_a_real_tech')],
      catalogTechDisplayName: (_) => null,
    );
    expect(snapshot.families.single.techDisplayName, isNull);
  });

  test(
    'priority order is rejected then research then combat then market then work',
    () {
      final snapshot = buildTurnNewsCourtSnapshot(
        events: [_work(), _combat(), _market(), _research('t'), _rejected()],
        catalogTechDisplayName: (_) => 'Tech',
      );
      expect(snapshot.families.map((h) => h.family).toList(), [
        TurnNewsCourtFamily.orderRejected,
        TurnNewsCourtFamily.researchComplete,
        TurnNewsCourtFamily.combat,
      ]);
      expect(snapshot.overflowFamilyCount, 2);
    },
  );

  test('accumulator commits then clears pending', () {
    final acc = TurnNewsCourtAccumulator();
    acc.consider(_research(kTechIdImprovedSailDesign), 'gp1');
    acc.consider(_capture(), 'gp1');
    final first = acc.commit(
      catalogTechDisplayName: (_) => 'Improved Sail Design',
    );
    expect(first.families, hasLength(1));
    final second = acc.commit(catalogTechDisplayName: (_) => 'X');
    expect(second.isEmpty, isTrue);
  });
}
