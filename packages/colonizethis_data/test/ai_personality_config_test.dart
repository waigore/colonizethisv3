import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('getThresholdsForLeader', () {
    test('returns default for unknown leader', () {
      final t = getThresholdsForLeader('unknown_leader');
      expect(t.warLikelihood, 50);
      expect(t.peaceTendency, 50);
      expect(t.allianceTendency, 50);
      expect(t.researchNaval, 50);
      expect(t.researchMilitary, 50);
      expect(t.researchEconomic, 50);
      expect(t.researchExploration, 50);
    });

    test('returns configured thresholds for victoria (low war, high peace/alliance)', () {
      final t = getThresholdsForLeader('victoria');
      expect(t.warLikelihood, lessThan(50));
      expect(t.peaceTendency, greaterThan(50));
      expect(t.allianceTendency, greaterThan(50));
    });

    test('returns configured thresholds for napoleon (high war, lower peace/alliance)', () {
      final t = getThresholdsForLeader('napoleon');
      expect(t.warLikelihood, greaterThan(50));
      expect(t.peaceTendency, lessThan(50));
      expect(t.allianceTendency, lessThan(50));
    });

    test('returns configured thresholds for henry (very low war)', () {
      final t = getThresholdsForLeader('henry');
      expect(t.warLikelihood, lessThan(30));
    });
  });

  group('getArchetypeDisplayNameForLeader', () {
    test('returns display name for known leader', () {
      expect(getArchetypeDisplayNameForLeader('napoleon'), 'Fortifier');
      expect(getArchetypeDisplayNameForLeader('victoria'), 'Industrial Trader');
      expect(getArchetypeDisplayNameForLeader('isabella'), kUnitTypeExplorer);
    });
    test('returns null for unknown leader', () {
      expect(getArchetypeDisplayNameForLeader('unknown'), isNull);
    });
  });

  group('canonicalLeaderIdForPersonality', () {
    test('returns canonical id unchanged when already canonical', () {
      expect(canonicalLeaderIdForPersonality('victoria'), 'victoria');
      expect(canonicalLeaderIdForPersonality('napoleon'), 'napoleon');
    });

    test('maps variant leader keys from naming config to canonical ids', () {
      expect(canonicalLeaderIdForPersonality('england_leader'), 'victoria');
      expect(canonicalLeaderIdForPersonality('france_leader'), 'napoleon');
      expect(canonicalLeaderIdForPersonality('spain_leader'), 'isabella');
      expect(canonicalLeaderIdForPersonality('portugal_leader'), 'henry');
      expect(canonicalLeaderIdForPersonality('netherlands_leader'), 'deruyter');
      expect(canonicalLeaderIdForPersonality('prussia_leader'), 'frederick');
      expect(canonicalLeaderIdForPersonality('prussia_reserve_leader'), 'frederick');
      expect(canonicalLeaderIdForPersonality('sweden_leader'), 'gustavus');
    });

    test('falls back to input for unknown ids so defaults apply', () {
      expect(canonicalLeaderIdForPersonality('unknown_leader'), 'unknown_leader');
    });
  });

  group('PersonalityThresholds', () {
    test('default constructor uses 50 for all fields', () {
      const t = PersonalityThresholds();
      expect(t.warLikelihood, 50);
      expect(t.peaceTendency, 50);
      expect(t.allianceTendency, 50);
      expect(t.researchNaval, 50);
      expect(t.researchMilitary, 50);
      expect(t.researchEconomic, 50);
      expect(t.researchExploration, 50);
    });
  });
}
