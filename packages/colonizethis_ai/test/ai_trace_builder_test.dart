import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/src/planning/ai_trace_builder.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/domain_gate_data.dart';

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
    final section = buildAiTraceSection(
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

  group('Refs #2832 decision-provenance fields', () {
    test(
      'state.observerGoalPhase records the phase string when provided',
      () {
        for (final phase in ObserverGoalPhase.values) {
          final section = buildAiTraceSection(
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
          );
          expect(section.state['observerGoalPhase'], phase.name);
        }
      },
    );

    test(
      'state.observerGoalPhase is omitted when builder argument is null',
      () {
        final section = buildAiTraceSection(
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
        );
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

        final section = buildAiTraceSection(
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
        );

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

        final section = buildAiTraceSection(
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
        );

        final phasePlanJson =
            section.state['phasePlan'] as Map<String, Object?>;
        expect(phasePlanJson['expandDeclareWarTarget'], 'gp3');
        expect(phasePlanJson['expandPeaceTargets'], ['gp2', 'gp5']);
        expect(phasePlanJson.containsKey('colonialAcquisition'), isFalse);
      },
    );

    test(
      'state.phasePlan is omitted when default-plan PhasePlanOutcome has no provenance fields',
      () {
        final section = buildAiTraceSection(
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
          phasePlan: PhasePlanOutcome.defaultExpand,
        );
        // No provenance fields => map is empty => omitted from state.
        expect(section.state.containsKey('phasePlan'), isFalse);
      },
    );

    test(
      'thresholds.constants.agendaModifiers includes spyOrder/buildOrder/research',
      () {
        const techThief = AIConfig(
          leaderId: 'darius',
          personalityId: 'darius',
          hiddenAgendaId: 'tech_thief',
        );
        final section = buildAiTraceSection(
          nationId: 'gp1',
          turn: 5,
          config: techThief,
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
        );

        final constants =
            section.thresholds['constants'] as Map<String, Object?>;
        final agendaModifiers =
            constants['agendaModifiers'] as Map<String, Object?>;
        expect(agendaModifiers['conquer'], 0);
        expect(agendaModifiers['diplomacy'], 0);
        expect(agendaModifiers['spyOrder'], 25);
        expect(agendaModifiers['buildOrder'], 0);
        expect(agendaModifiers['research'], 35);
      },
    );

    test(
      'thresholds.domainGates serializes booleans, conquestPasses, and per-planner thresholds',
      () {
        const gates = DomainGateData(
          workPlannerRan: true,
          buildPlannerRan: true,
          movePlannerRan: true,
          diplomacyPlannerRan: true,
          navalPlannerRan: false,
          researchPlannerRan: true,
          conquestArmyMovePlannerRan: true,
          conquestPasses: 22,
          workThreshold: 40,
          buildThreshold: 30,
          researchThreshold: 40,
        );

        final section = buildAiTraceSection(
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
          domainGateData: gates,
        );

        final domainGates =
            section.thresholds['domainGates'] as Map<String, Object?>;
        expect(domainGates['workPlannerRan'], isTrue);
        expect(domainGates['navalPlannerRan'], isFalse);
        expect(domainGates['conquestArmyMovePlannerRan'], isTrue);
        expect(domainGates['conquestPasses'], 22);
        final innerThresholds =
            domainGates['thresholds'] as Map<String, Object?>;
        expect(innerThresholds['work'], 40);
        expect(innerThresholds['build'], 30);
        expect(innerThresholds['research'], 40);
      },
    );

    test('DomainGateData omits the thresholds map when all threshold inputs are null',
        () {
      const gates = DomainGateData(
        workPlannerRan: false,
        buildPlannerRan: false,
        movePlannerRan: true,
        diplomacyPlannerRan: true,
        navalPlannerRan: false,
        researchPlannerRan: false,
        conquestArmyMovePlannerRan: true,
        conquestPasses: 1,
      );
      final json = gates.toJson();
      expect(json.containsKey('thresholds'), isFalse);
      expect(json['workPlannerRan'], isFalse);
      expect(json['conquestPasses'], 1);
    });

    test('compactPhasePlanJson omits empty arms and surfaces lower-case method names',
        () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribeB',
          method: AcquisitionMethod.joinEmpire,
        ),
      );
      final json = compactPhasePlanJson(phasePlan);
      expect(json.length, 1);
      final acquisition = json['colonialAcquisition'] as Map<String, Object?>;
      expect(acquisition['method'], 'joinEmpire');
      expect(acquisition['targetFactionId'], 'tribeB');
    });
  });
}
