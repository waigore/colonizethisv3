// Unit tests for GAME40001 research finish-time estimate (Refs #4511).
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview (Finish-time line);
// SPEC/game/turn-time-mapping.md § Campaign calendar cap.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_finish_estimate.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_preview.dart';

ResearchSlotTurnPreview _preview({
  int committedProgress = 600,
  int cost = 1800,
  int anticipatedRpPerTurn = 300,
  ResearchFundingLevel funding = ResearchFundingLevel.medium,
  bool debtBlocked = false,
}) {
  return ResearchSlotTurnPreview(
    funding: funding,
    committedProgress: committedProgress,
    cost: cost,
    baseRpPerTurn: anticipatedRpPerTurn,
    industrialBonusRpPerTurn: 0,
    anticipatedRpPerTurn: anticipatedRpPerTurn,
    goldCostPerTurn: funding == ResearchFundingLevel.none ? 0 : 150,
    goldSpentThisTurn: anticipatedRpPerTurn > 0 ? 150 : 0,
    debtBlocked: debtBlocked,
  );
}

void main() {
  suppressLogsForTests();

  group('researchFinishEstimate', () {
    test('positive: remaining <= this-turn RP completes next turn', () {
      final estimate = researchFinishEstimate(
        _preview(
          committedProgress: 1600,
          cost: 1800,
          anticipatedRpPerTurn: 300,
        ),
      );
      expect(estimate, isNotNull);
      expect(estimate!.remainingRp, 200);
      expect(estimate.completesNextTurn, isTrue);
      expect(estimate.turnsRemaining, 1);
    });

    test('positive: N is ceil of remaining / this-turn RP', () {
      final estimate = researchFinishEstimate(
        _preview(committedProgress: 600, cost: 1800, anticipatedRpPerTurn: 300),
      );
      expect(estimate, isNotNull);
      expect(estimate!.remainingRp, 1200);
      expect(estimate.completesNextTurn, isFalse);
      expect(estimate.turnsRemaining, 4);
    });

    test('positive: larger this-turn RP shortens N', () {
      final slower = researchFinishEstimate(
        _preview(committedProgress: 0, cost: 1800, anticipatedRpPerTurn: 300),
      );
      final faster = researchFinishEstimate(
        _preview(committedProgress: 0, cost: 1800, anticipatedRpPerTurn: 390),
      );
      expect(slower!.turnsRemaining, 6);
      expect(faster!.turnsRemaining, 5);
      expect(faster.turnsRemaining, lessThan(slower.turnsRemaining));
    });

    test('negative: None funding omits the estimate', () {
      expect(
        researchFinishEstimate(
          _preview(funding: ResearchFundingLevel.none, anticipatedRpPerTurn: 0),
        ),
        isNull,
      );
    });

    test('negative: debt-blocked slot omits the estimate', () {
      expect(
        researchFinishEstimate(
          _preview(anticipatedRpPerTurn: 0, debtBlocked: true),
        ),
        isNull,
      );
    });
  });

  group('researchFinishCalendarYear', () {
    const calendar = ResearchFinishCalendar(
      currentTurn: 10,
      mapping: TurnTimeMapping.gdd01,
      infiniteMode: false,
    );

    test('positive: year at currentTurn + N when under the campaign cap', () {
      const estimate = ResearchFinishEstimate(
        remainingRp: 300,
        turnsRemaining: 1,
        completesNextTurn: true,
      );
      expect(
        researchFinishCalendarYear(estimate: estimate, calendar: calendar),
        TurnTimeMapping.gdd01.yearAtTurn(11),
      );
    });

    test('negative: year is suppressed when finish turn is after the cap', () {
      const late = ResearchFinishCalendar(
        currentTurn: 199,
        mapping: TurnTimeMapping.gdd01,
        infiniteMode: false,
      );
      const estimate = ResearchFinishEstimate(
        remainingRp: 900,
        turnsRemaining: 3,
        completesNextTurn: false,
      );
      // 199 + 3 = 202 > 201 (gdd01 cap).
      expect(
        researchFinishCalendarYear(estimate: estimate, calendar: late),
        isNull,
      );
    });

    test('positive: infinite mode still shows a year past the cap', () {
      const infinite = ResearchFinishCalendar(
        currentTurn: 199,
        mapping: TurnTimeMapping.gdd01,
        infiniteMode: true,
      );
      const estimate = ResearchFinishEstimate(
        remainingRp: 900,
        turnsRemaining: 3,
        completesNextTurn: false,
      );
      expect(
        researchFinishCalendarYear(estimate: estimate, calendar: infinite),
        TurnTimeMapping.gdd01.yearAtTurn(202),
      );
    });
  });
}
