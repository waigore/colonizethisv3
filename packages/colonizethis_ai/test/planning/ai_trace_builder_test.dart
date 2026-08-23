import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/src/planning/ai_trace_builder.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/domain_gate_data.dart';
import 'ai_trace_builder_tail_cases.dart';

const _config = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'warmonger',
);

const _snapshot = AIWorldSnapshot(
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

void main() {
  test('buildAiTraceSection exports conquest trace fields', () {
    final section = buildAiTraceSection(AiTraceBuildInput(
      nationId: 'gp1',
      turn: 5,
      config: _config,
      seeds: AISeedBundle.fromTurnSeed(99),
      snapshot: _snapshot,
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
    ));

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

  group('Refs #2832 decision-provenance fields', () {
    test(
      'state.observerGoalPhase records the phase string when provided',
      () {
        for (final phase in ObserverGoalPhase.values) {
          final section = buildAiTraceSection(AiTraceBuildInput(
            nationId: 'gp1',
            turn: 5,
            config: _config,
            seeds: AISeedBundle.fromTurnSeed(99),
            snapshot: _snapshot,
            primaryGoal: StrategicGoal.conquer,
            goalScores: const {StrategicGoal.conquer: 80},
            economyPlan: const EconomyPlan(
              productionAssignments: [],
              cargoPreference: CargoPreference.none,
            ),
            orders: const Orders(),
            ordersByDomain: const {},
            finalOrders: const [],
            observerGoalPhase: phase,
          ));
          expect(section.state['observerGoalPhase'], phase.name);
        }
      },
    );

    test(
      'state.observerGoalPhase is omitted when builder argument is null',
      () {
        final section = buildAiTraceSection(AiTraceBuildInput(
          nationId: 'gp1',
          turn: 5,
          config: _config,
          seeds: AISeedBundle.fromTurnSeed(99),
          snapshot: _snapshot,
          primaryGoal: StrategicGoal.conquer,
          goalScores: const {StrategicGoal.conquer: 80},
          economyPlan: const EconomyPlan(
            productionAssignments: [],
            cargoPreference: CargoPreference.none,
          ),
          orders: const Orders(),
          ordersByDomain: const {},
          finalOrders: const [],
        ));
        expect(section.state.containsKey('observerGoalPhase'), isFalse);
        expect(section.state.containsKey('phasePlan'), isFalse);
        final thresholds = section.thresholds;
        expect(thresholds.containsKey('domainGates'), isFalse);
      },
    );

    test(
      'state.phasePlan emits COLONIAL acquisition target with declareWar method',
      () {
        const acquisition = ColonialAcquisitionTarget(
          targetFactionId: 'tribeA',
          method: AcquisitionMethod.declareWar,
        );
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialAcquisitionTarget: acquisition,
          colonialPeaceTargetFactionIdsSorted: ['gp3'],
        );

        final section = buildAiTraceSection(AiTraceBuildInput(
          nationId: 'gp1',
          turn: 5,
          config: _config,
          seeds: AISeedBundle.fromTurnSeed(99),
          snapshot: _snapshot,
          primaryGoal: StrategicGoal.conquer,
          goalScores: const {StrategicGoal.conquer: 80},
          economyPlan: const EconomyPlan(
            productionAssignments: [],
            cargoPreference: CargoPreference.none,
          ),
          orders: const Orders(),
          ordersByDomain: const {},
          finalOrders: const [],
          observerGoalPhase: ObserverGoalPhase.colonial,
          phasePlan: phasePlan,
        ));

        final phasePlanJson =
            section.state['phasePlan'] as Map<String, Object?>;
        final acquisitionJson =
            phasePlanJson['colonialAcquisition'] as Map<String, Object?>;
        expect(acquisitionJson['targetFactionId'], 'tribeA');
        expect(acquisitionJson['method'], 'declareWar');
        expect(phasePlanJson['colonialPeaceTargets'], ['gp3']);
        // Empty / null entries are omitted.
        expect(phasePlanJson.containsKey('expandDeclareWarTarget'), isFalse);
        expect(phasePlanJson.containsKey('expandPeaceTargets'), isFalse);
      },
    );

    test(
      'state.phasePlan emits EXPAND declareWar target when set',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandDeclareWarTargetFactionId: 'gp3',
          expandPeaceTargetFactionIdsSorted: ['gp2', 'gp5'],
        );

        final section = buildAiTraceSection(AiTraceBuildInput(
          nationId: 'gp1',
          turn: 5,
          config: _config,
          seeds: AISeedBundle.fromTurnSeed(99),
          snapshot: _snapshot,
          primaryGoal: StrategicGoal.conquer,
          goalScores: const {StrategicGoal.conquer: 80},
          economyPlan: const EconomyPlan(
            productionAssignments: [],
            cargoPreference: CargoPreference.none,
          ),
          orders: const Orders(),
          ordersByDomain: const {},
          finalOrders: const [],
          observerGoalPhase: ObserverGoalPhase.expand,
          phasePlan: phasePlan,
        ));

        final phasePlanJson =
            section.state['phasePlan'] as Map<String, Object?>;
        expect(phasePlanJson['expandDeclareWarTarget'], 'gp3');
        expect(phasePlanJson['expandPeaceTargets'], ['gp2', 'gp5']);
        expect(phasePlanJson.containsKey('colonialAcquisition'), isFalse);
      },
    );
  });

  registerAiTraceBuilderTailCases();
}
