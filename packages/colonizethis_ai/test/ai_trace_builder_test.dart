import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/src/planning/ai_trace_builder.dart';

void main() {
  test('buildAiTraceSection exports conquest trace fields', () {
    const config = AIConfig(
      leaderId: 'napoleon',
      personalityId: 'napoleon',
      hiddenAgendaId: 'warmonger',
    );
    const snapshot = AIWorldSnapshot(
      playerId: 'gp1',
      threats: ThreatSummary(),
      opportunities: OpportunitySummary(),
      economy: EconomySummary(ownProvinceCount: 7),
      conquest: ConquestSummary(
        oldWorldProvincesOwned: 7,
        provincesToVictory: 24,
        invadableProvinceIdsSorted: ['oldWorld|p_target'],
        preferredConquestTargetFactionIdsSorted: ['minor1'],
      ),
      relations: {},
    );
    final section = buildAiTraceSection(
      nationId: 'gp1',
      turn: 5,
      config: config,
      seeds: AISeedBundle.fromTurnSeed(99),
      snapshot: snapshot,
      primaryGoal: StrategicGoal.conquer,
      goalScores: const {StrategicGoal.conquer: 80},
      economyPlan: const EconomyPlan(
        productionAssignments: [],
        cargoPreference: CargoPreference.none,
      ),
      orders: const Orders(),
      ordersByDomain: const {'armyMove': 1},
      finalOrders: const [],
      declaredWarTargetFactionId: 'minor1',
      conquestArmyMoveCount: 1,
    );

    final aggregates = section.state['aggregates'] as Map<String, Object?>;
    final snap = aggregates['snapshot'] as Map<String, Object?>;
    expect(snap['provincesToVictory'], 24);
    expect(snap['invadableCount'], 1);
    expect(snap['declaredWarTarget'], 'minor1');
    expect(snap['conquestArmyMoveCount'], 1);

    final domainOutputs =
        section.outcome['domainOutputs'] as Map<String, Object?>;
    expect(domainOutputs['conquestArmyMove'], 1);
  });
}
