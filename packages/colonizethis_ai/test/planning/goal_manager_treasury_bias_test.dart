/// Tests for the F6 treasury-acquisition trade goal bias added to
/// `evaluateStrategicGoalScores`. See `SPEC/ai/treasury-planner.md` and
/// Refs #2994 F6 for the bias formula, constants, and ACs covered here.
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;

AIWorldSnapshot _snapshotWithTreasury(int treasury) {
  return AIWorldSnapshot(
    playerId: 'gp1',
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
      provincesToVictory: 24,
    ),
    economy: EconomySummary(treasury: treasury),
    relations: const {},
  );
}

AIWorldSnapshot _snapshotStalledWithTreasury(int treasury) {
  return AIWorldSnapshot(
    playerId: 'gp1',
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
      provincesToVictory: 24,
      invadableProvinceIdsSorted: const ['oldWorld|p1'],
    ),
    economy: EconomySummary(treasury: treasury),
    relations: const {},
  );
}

const AIConfig _kVictoriaPeacemaker = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

void main() {
  group(
    'evaluateStrategicGoalScores treasury-acquisition trade bias (Refs #2994 F6)',
    () {
      test(
        'treasury == 0 forces trade to the emergency dominant floor and beats defend/expand/conquer',
        () {
          final snapshot = _snapshotWithTreasury(0);
          final scores = evaluateStrategicGoalScores(
            snapshot,
            _kVictoriaPeacemaker,
          );
          expect(
            scores[StrategicGoal.trade]!,
            greaterThanOrEqualTo(kEmergencyTradeGoalDominantFloor),
            reason:
                'AC #2994 F6 #1: zero-treasury AI must hit the emergency '
                'trade floor regardless of leader / agenda.',
          );
          expect(
            scores[StrategicGoal.trade]!,
            greaterThan(scores[StrategicGoal.defend]!),
            reason:
                'AC #2994 F6 #1: zero-treasury trade must strictly outrank '
                'defend.',
          );
          expect(
            scores[StrategicGoal.trade]!,
            greaterThan(scores[StrategicGoal.expand]!),
            reason:
                'AC #2994 F6 #1: zero-treasury trade must strictly outrank '
                'expand.',
          );
          expect(
            scores[StrategicGoal.trade]!,
            greaterThan(scores[StrategicGoal.conquer]!),
            reason:
                'AC #2994 F6 #1: zero-treasury trade must strictly outrank '
                'conquer.',
          );
        },
      );

      test(
        'treasury == 0 also overrides the stalled-OW invadable trade clamp',
        () {
          // Legacy stalled-OW path applies `trade = math.min(trade, 35)` and
          // `conquer = math.max(conquer, 120)`. The F6 emergency floor must
          // override both so a broke stalled-OW AI still prioritises trade.
          final snapshot = _snapshotStalledWithTreasury(0);
          final scores = evaluateStrategicGoalScores(
            snapshot,
            _kVictoriaPeacemaker,
          );
          expect(
            scores[StrategicGoal.trade]!,
            greaterThanOrEqualTo(kEmergencyTradeGoalDominantFloor),
            reason:
                'AC #2994 F6 #4: stalled-OW + zero-treasury must still hit '
                'the emergency trade floor (overriding `trade <= 35`).',
          );
          expect(
            scores[StrategicGoal.trade]!,
            greaterThan(scores[StrategicGoal.conquer]!),
            reason:
                'AC #2994 F6 #4: stalled-OW + zero-treasury trade must still '
                'strictly outrank conquer.',
          );
        },
      );

      test(
        'treasury strictly between 0 and the cheapest regiment cost applies a strictly positive linear boost',
        () {
          final threshold = cheapestRegimentBuildTreasuryCost();
          // Pick a midpoint inside the (0, threshold) ramp.
          final treasury = threshold ~/ 2;
          assert(treasury > 0 && treasury < threshold);

          final biasedScores = evaluateStrategicGoalScores(
            _snapshotWithTreasury(treasury),
            _kVictoriaPeacemaker,
          );
          final referenceScores = evaluateStrategicGoalScores(
            _snapshotWithTreasury(threshold),
            _kVictoriaPeacemaker,
          );

          final ratio = treasury / threshold;
          final expectedBoost =
              ((1.0 - ratio) * kTreasuryAcquisitionTradeBoostMax).round();

          expect(
            biasedScores[StrategicGoal.trade]!,
            referenceScores[StrategicGoal.trade]! + expectedBoost,
            reason:
                'AC #2994 F6 #2: trade boost equals '
                '`round((1 - treasury/threshold) * kBoostMax)` on the linear '
                'ramp.',
          );
          expect(
            expectedBoost,
            greaterThan(0),
            reason:
                'AC #2994 F6 #2: linear boost strictly positive on the open '
                'ramp.',
          );
          expect(
            biasedScores[StrategicGoal.trade]!,
            lessThan(kEmergencyTradeGoalDominantFloor),
            reason:
                'AC #2994 F6 #2: mid-ramp boost must stay strictly below the '
                'emergency floor (which only fires at `treasury <= 0`).',
          );
        },
      );

      test(
        'treasury at or above the cheapest regiment cost applies no F6 boost (moderate trade)',
        () {
          final threshold = cheapestRegimentBuildTreasuryCost();

          // Baseline `evaluateStrategicGoalScores` does NOT itself read
          // `treasury`, so the only difference between treasury == threshold
          // and treasury == 10 × threshold is the F6 bias path. AC #2994 F6
          // #3 asserts both sit at the unboosted baseline.
          final atThreshold = evaluateStrategicGoalScores(
            _snapshotWithTreasury(threshold),
            _kVictoriaPeacemaker,
          );
          final wellAbove = evaluateStrategicGoalScores(
            _snapshotWithTreasury(threshold * 10),
            _kVictoriaPeacemaker,
          );
          expect(
            atThreshold[StrategicGoal.trade]!,
            wellAbove[StrategicGoal.trade]!,
            reason:
                'AC #2994 F6 #3: treasury at threshold vs well above '
                'threshold must yield identical trade scores (no F6 bias).',
          );

          // Trade must also remain at or below the emergency floor (the F6
          // emergency floor only fires at `treasury <= 0`).
          expect(
            wellAbove[StrategicGoal.trade]!,
            lessThan(kEmergencyTradeGoalDominantFloor),
            reason:
                'AC #2994 F6 #3: well-funded AI must not hit the emergency '
                'trade floor.',
          );
        },
      );

      test(
        'evaluateStrategicGoalScores remains deterministic when the treasury bias path fires',
        () {
          // AC #2994 F6 #5: identical snapshot/config inputs must produce
          // identical goal-score maps even with the bias path active.
          final firstRun = evaluateStrategicGoalScores(
            _snapshotWithTreasury(0),
            _kVictoriaPeacemaker,
          );
          final secondRun = evaluateStrategicGoalScores(
            _snapshotWithTreasury(0),
            _kVictoriaPeacemaker,
          );
          expect(firstRun, secondRun);
        },
      );
    },
  );
}
