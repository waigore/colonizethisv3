// Integration pins for Phase 3 diplomacy declare-war OW scoring (Refs #2847).
//
// Verifies `oldWorldConquestWeight` on `_DeclareWarTargetContext` scales
// OW-expansion declare-war addends via `declareWarOldWorldConquestScaledBonus`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const PhasePriorityWeights _owConquestFull = PhasePriorityWeights(
  oldWorldConquest: 1.0,
  newWorldAcquisition: 0.05,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const PhasePriorityWeights _owConquestPartial = PhasePriorityWeights(
  oldWorldConquest: 0.80,
  newWorldAcquisition: 0.05,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const PhasePriorityWeights _owConquestZero = PhasePriorityWeights(
  oldWorldConquest: 0.0,
  newWorldAcquisition: 0.05,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const AIConfig _config = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

/// Stalled OW expansion (ow=7) with adjacent invadable minor — routes through
/// `_declareWarStalledOldWorldExpansionBonuses` OW addends.
const AIWorldSnapshot _stalledAdjacentInvadableMinorSnap = AIWorldSnapshot(
  playerId: 'gp1',
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(weakNeighbors: ['minor1']),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: 7,
    provincesToVictory: 14,
    invadableProvinceIdsSorted: ['oldWorld|minor1_a'],
    adjacentOwnerFactionIdsSorted: ['minor1'],
  ),
  colonial: ColonialSummary(),
  economy: EconomySummary(),
  relations: {},
);

Game _buildGame() => Game(
  id: 'g-phase3-diplomacy-ow-soft-weight',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: 'oldWorld|minor1_a',
          regionId: 'oldWorld',
          ownerId: 'minor1',
        ),
      ],
    ),
    newWorld: const RegionData(),
  ),
  players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
  minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
  aiControlByGpId: const {'gp1': true},
);

int _minorDeclareWarScore({required PhasePlanOutcome phasePlan}) {
  return computeDiplomaticCandidateScores(
    candidates: const [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'minor1',
      ),
    ],
    nationId: 'gp1',
    game: _buildGame(),
    snapshot: _stalledAdjacentInvadableMinorSnap,
    config: _config,
    phasePlan: phasePlan,
  ).single;
}

void main() {
  group('Phase 3 diplomacy declare-war OW soft-weight wiring (Refs #2847)', () {
    test('full OW weight scores higher than zero OW weight', () {
      final fullScore = _minorDeclareWarScore(
        phasePlan: const PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: _owConquestFull,
        ),
      );
      final zeroOwScore = _minorDeclareWarScore(
        phasePlan: const PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: _owConquestZero,
        ),
      );
      expect(
        fullScore,
        greaterThan(zeroOwScore),
        reason:
            'OW-expansion declare-war addends must scale with '
            'oldWorldConquestWeight — full weight retains OW bonuses.',
      );
    });

    test('partial OW weight scores between zero and full', () {
      final fullScore = _minorDeclareWarScore(
        phasePlan: const PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: _owConquestFull,
        ),
      );
      final partialScore = _minorDeclareWarScore(
        phasePlan: const PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: _owConquestPartial,
        ),
      );
      final zeroOwScore = _minorDeclareWarScore(
        phasePlan: const PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: _owConquestZero,
        ),
      );
      expect(partialScore, greaterThan(zeroOwScore));
      expect(partialScore, lessThan(fullScore));
    });

    test('null phasePlan uses oldWorldConquestWeight 1.0 not curve 0.95', () {
      final curveScore = _minorDeclareWarScore(
        phasePlan: const PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: PhasePriorityWeights.earlySprintDefault,
        ),
      );
      final nullPlanScore = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'minor1',
          ),
        ],
        nationId: 'gp1',
        game: _buildGame(),
        snapshot: _stalledAdjacentInvadableMinorSnap,
        config: _config,
        phasePlan: null,
      ).single;
      expect(
        nullPlanScore,
        greaterThan(curveScore),
        reason:
            'Callers without phasePlan must keep pre-Phase-3 OW bonus '
            'magnitudes (weight 1.0), not the early-sprint 0.95 curve.',
      );
    });
  });
}
