import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('resolveDomainWeights', () {
    test('null overrides returns the leader hardcoded weights', () {
      final base = getDomainWeightsForLeader('napoleon');
      final resolved = resolveDomainWeights('napoleon');
      expect(resolved.economy, base.economy);
      expect(resolved.military, base.military);
      expect(resolved.diplomacy, base.diplomacy);
      expect(resolved.research, base.research);
    });

    test('non-default override value replaces only that field', () {
      // napoleon hardcoded: economy 50, military 90, diplomacy 30, research 50.
      // Registry default for these domain keys is 50. 95 != 50 -> overrides;
      // other keys are absent -> keep napoleon's hardcoded values.
      final resolved = resolveDomainWeights(
        'napoleon',
        overrides: const {'personalityDomainWeights.economy': 95},
      );
      expect(resolved.economy, 95);
      expect(resolved.military, 90, reason: 'untouched key keeps leader value');
      expect(resolved.diplomacy, 30);
      expect(resolved.research, 50);
    });

    test('override equal to registry default does not override', () {
      // Registry default for personalityDomainWeights.military is 50; napoleon
      // hardcoded military is 90. A profile value equal to the default must keep
      // the leader value (only non-default profile values override).
      final resolved = resolveDomainWeights(
        'napoleon',
        overrides: const {'personalityDomainWeights.military': 50},
      );
      expect(resolved.military, 90);
    });

    test('non-integer override is rounded to int', () {
      final resolved = resolveDomainWeights(
        'napoleon',
        overrides: const {'personalityDomainWeights.economy': 70.6},
      );
      expect(resolved.economy, 71);
    });
  });

  group('resolveGoalWeights', () {
    test('null overrides returns the leader hardcoded goal weights', () {
      final base = getGoalWeightsForLeader('victoria');
      final resolved = resolveGoalWeights('victoria');
      expect(resolved.conquer, base.conquer);
      expect(resolved.trade, base.trade);
    });

    test('non-default override replaces the field', () {
      // victoria hardcoded conquer is 10; registry default goal weight is 25.
      final resolved = resolveGoalWeights(
        'victoria',
        overrides: const {'personalityGoalWeights.conquer': 99},
      );
      expect(resolved.conquer, 99);
      expect(resolved.trade, getGoalWeightsForLeader('victoria').trade);
    });
  });

  group('resolveThresholds', () {
    test('null overrides returns the leader hardcoded thresholds', () {
      final base = getThresholdsForLeader('napoleon');
      final resolved = resolveThresholds('napoleon');
      expect(resolved.warLikelihood, base.warLikelihood);
      expect(resolved.peaceTendency, base.peaceTendency);
    });

    test('non-default override replaces the field', () {
      // napoleon hardcoded warLikelihood is 80; registry default threshold is 50.
      final resolved = resolveThresholds(
        'napoleon',
        overrides: const {'personalityThresholds.warLikelihood': 5},
      );
      expect(resolved.warLikelihood, 5);
      expect(
        resolved.peaceTendency,
        getThresholdsForLeader('napoleon').peaceTendency,
      );
    });
  });
}
