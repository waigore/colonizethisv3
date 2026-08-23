import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'goal_manager_select_primary_goal_cases.dart';

void main() {
  group('evaluateStrategicGoalScores', () {
    test('raises conquer above default when far from military victory', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          provincesToVictory: 24,
        ),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final scores = evaluateStrategicGoalScores(snapshot, config);
      final baseline = evaluateStrategicGoalScores(
        const AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 31,
            provincesToVictory: 0,
          ),
          economy: EconomySummary(),
          relations: {},
        ),
        config,
      );
      expect(
        scores[StrategicGoal.conquer]!,
        greaterThan(baseline[StrategicGoal.conquer]!),
      );
      expect(
        scores[StrategicGoal.conquer]!,
        greaterThanOrEqualTo(kMinimumConquerScoreWhenFarFromVictory),
      );
    });

    test(
      'late colonial pressure keeps conquer/expand floors after eight NW provinces',
      () {
        const snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            provincesToVictory: 24,
          ),
          colonial: ColonialSummary(
            newWorldProvincesOwned: kColonialFewNwProvincesThreshold,
            invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        const config = AIConfig(
          leaderId: 'victoria',
          personalityId: 'victoria',
          hiddenAgendaId: 'peacemaker',
        );
        final scores = evaluateStrategicGoalScores(snapshot, config);
        expect(
          scores[StrategicGoal.conquer]!,
          greaterThanOrEqualTo(kMinimumColonialConquerScoreWhenPressure),
        );
        expect(
          scores[StrategicGoal.expand]!,
          greaterThanOrEqualTo(kMinimumColonialExpandScoreWhenPressure),
        );
        expect(
          scores[StrategicGoal.conquer]!,
          greaterThan(scores[StrategicGoal.diplomacy]!),
        );
      },
    );

    test(
      'stalled Old World holdings favor conquer over diplomacy for henry',
      () {
        const snapshot = AIWorldSnapshot(
          playerId: 'gp4',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
          ),
          colonial: ColonialSummary(
            invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'merchant',
        );
        final scores = evaluateStrategicGoalScores(snapshot, config);
        expect(
          scores[StrategicGoal.conquer]!,
          greaterThan(scores[StrategicGoal.diplomacy]!),
        );
      },
    );

    test(
      'colonial pressure raises conquer/expand above diplomacy for peacemaker',
      () {
        const snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 7,
            provincesToVictory: 24,
          ),
          colonial: ColonialSummary(
            newWorldProvincesOwned: 0,
            invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: EconomySummary(),
          relations: {},
        );
        const config = AIConfig(
          leaderId: 'victoria',
          personalityId: 'victoria',
          hiddenAgendaId: 'peacemaker',
        );
        final scores = evaluateStrategicGoalScores(snapshot, config);
        expect(
          scores[StrategicGoal.conquer]!,
          greaterThan(scores[StrategicGoal.diplomacy]!),
        );
        expect(
          scores[StrategicGoal.expand]!,
          greaterThan(scores[StrategicGoal.diplomacy]!),
        );
      },
    );
  });

  group('majorConstraintForStrategicGoal', () {
    test('defend reports capitalThreatened when capital is threatened', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(atWarWith: ['gp2'], capitalThreatened: true),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'frederick',
        personalityId: 'frederick',
        hiddenAgendaId: 'peacemaker',
      );
      expect(
        majorConstraintForStrategicGoal(StrategicGoal.defend, snapshot, config),
        'capitalThreatened',
      );
    });
  });

  group('majorConstraintForStrategicGoal', () {
    test('defend reports capitalThreatened when capital is threatened', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(atWarWith: ['gp2'], capitalThreatened: true),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'frederick',
        personalityId: 'frederick',
        hiddenAgendaId: 'peacemaker',
      );
      expect(
        majorConstraintForStrategicGoal(StrategicGoal.defend, snapshot, config),
        'capitalThreatened',
      );
    });
  });

  registerSelectPrimaryGoalCases();
}
