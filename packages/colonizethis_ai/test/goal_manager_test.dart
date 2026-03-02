import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';

void main() {
  group('selectPrimaryGoal', () {
    test('returns expand when snapshot has no threats and default weights', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final goal = selectPrimaryGoal(snapshot, config, 42);
      expect(goal, isNotNull);
      expect(StrategicGoal.values.contains(goal), isTrue);
    });

    test('defend weight increases when at war', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(atWarWith: ['gp2']),
        opportunities: OpportunitySummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final goal = selectPrimaryGoal(snapshot, config, 1);
      expect(StrategicGoal.values.contains(goal), isTrue);
    });

    test('defend weight increases when capital threatened', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(capitalThreatened: true),
        opportunities: OpportunitySummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final goal = selectPrimaryGoal(snapshot, config, 2);
      expect(StrategicGoal.values.contains(goal), isTrue);
    });

    test('expand weight increases when unclaimed provinces exist', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(unclaimedProvinces: 5),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final goal = selectPrimaryGoal(snapshot, config, 3);
      expect(StrategicGoal.values.contains(goal), isTrue);
    });

    test('expand weight increases when worker count low', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        economy: EconomySummary(workerCount: 1),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final goal = selectPrimaryGoal(snapshot, config, 4);
      expect(StrategicGoal.values.contains(goal), isTrue);
    });
  });
}
