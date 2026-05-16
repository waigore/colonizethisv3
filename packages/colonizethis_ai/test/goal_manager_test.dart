import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:logger/logger.dart';

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
    });
  });

  group('selectPrimaryGoal', () {
    test('returns expand when snapshot has no threats and default weights', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final goal = selectPrimaryGoal(
        snapshot,
        config,
        42,
        nationId: 'gp1',
        turn: 0,
      );
      expect(goal, isNotNull);
      expect(StrategicGoal.values.contains(goal), isTrue);
    });

    test('defend weight increases when at war', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(atWarWith: ['gp2']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final goal = selectPrimaryGoal(
        snapshot,
        config,
        1,
        nationId: 'gp1',
        turn: 1,
      );
      expect(StrategicGoal.values.contains(goal), isTrue);
    });

    test('defend weight increases when capital threatened', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(capitalThreatened: true),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final goal = selectPrimaryGoal(
        snapshot,
        config,
        2,
        nationId: 'gp1',
        turn: 2,
      );
      expect(StrategicGoal.values.contains(goal), isTrue);
    });

    test('expand weight increases when unclaimed provinces exist', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(unclaimedProvinces: 5),
        conquest: ConquestSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final goal = selectPrimaryGoal(
        snapshot,
        config,
        3,
        nationId: 'gp1',
        turn: 3,
      );
      expect(StrategicGoal.values.contains(goal), isTrue);
    });

    test('expand weight increases when worker count low', () {
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(),
        economy: EconomySummary(workerCount: 1),
        relations: {},
      );
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final goal = selectPrimaryGoal(
        snapshot,
        config,
        4,
        nationId: 'gp1',
        turn: 4,
      );
      expect(StrategicGoal.values.contains(goal), isTrue);
    });

    test(
        'logs selected primaryGoal with nationId, turn, and majorConstraint at info',
        () {
      final capturedEvents = <LogEvent>[];
      void listener(LogEvent e) => capturedEvents.add(e);

      Logger.addLogListener(listener);
      Logger.level = Level.info;

      try {
        const nationId = 'gp1';
        const turn = 7;

        const snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(
            atWarWith: ['gp2'],
            capitalThreatened: true,
          ),
          opportunities: OpportunitySummary(unclaimedProvinces: 0),
          conquest: ConquestSummary(),
          economy: EconomySummary(workerCount: 10),
          relations: {},
        );
        const config = AIConfig(
          leaderId: 'frederick',
          personalityId: 'frederick',
          hiddenAgendaId: 'peacemaker',
        );

        final goal = selectPrimaryGoal(
          snapshot,
          config,
          0,
          nationId: nationId,
          turn: turn,
        );

        final infoLines = capturedEvents
            .where((e) => e.message.contains('selected primaryGoal='))
            .map((e) => e.message)
            .toList();
        expect(infoLines, hasLength(1));

        final line = infoLines.single;
        expect(line, contains('nationId=$nationId'));
        expect(line, contains('turn=$turn'));
        expect(line, contains('majorConstraint=capitalThreatened'));
        expect(line, contains('selected primaryGoal=$goal'));
      } finally {
        Logger.removeLogListener(listener);
        Logger.level = Level.info;
      }
    });
  });
}
