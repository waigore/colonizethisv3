// Declare-war scoring case bodies for `observer_goal_phase_test.dart`
// (Refs #3997 Phase 8, #4310 Slice D remainder densify).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerObserverGoalPhaseDeclareWarScoringCases() {
  group('EXPAND suppresses NW declareWar scoring', () {
    test('tribe owning invadable NW scores zero while below OW quota', () {
      final game = Game(
        id: 'g-expand-nw-suppress',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 5, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: 'oldWorld|p0',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              const Province(
                id: 'newWorld|nw1',
                regionId: 'newWorld',
                ownerId: 'tribe1',
              ),
            ],
          ),
        ),
        players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
        minorNations: const [],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: const ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|p0'],
          provincesToVictory: 24,
        ),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
          adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      final scores = computeDiplomaticCandidateScores(
        DiplomaticCandidateScoringInput(
          game: game,
          snapshot: snapshot,
          nationId: 'gp1',
          config: const AIConfig(
            leaderId: 'henry',
            personalityId: 'henry',
            hiddenAgendaId: 'merchant',
          ),
          candidates: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'tribe1',
            ),
          ],
          primaryGoal: StrategicGoal.expand,
        ),
      );
      expect(scores.single, 0);
    });
  });

  // EXPAND companion to the COLONIAL "tribe declare-war is not suppressed at
  // OW quota" pin below. Pins the first S10 AC from issue #2509:
  //   Given a GP with `oldWorldProvincesOwned < 10` and an adjacent minor
  //   owning a province in `invadableProvinceIdsSorted`, when the declare-war
  //   pass runs in EXPAND phase, then `declareWar` toward that minor is among
  //   suggested orders (deterministic for fixed seed).
  // SPEC clause (`SPEC/ai/ai-architecture.md` § Observer goal phases (Full
  // AI), EXPAND): "Acquire OW provinces by the simplest legal path ...
  // Candidates: factions owning at least one province in
  // `invadableProvinceIdsSorted` (OW only). Priority order: (a) adjacent
  // minor owners of invadable provinces ...".
  group('EXPAND allows OW minor declareWar scoring', () {
    test('adjacent invadable minor scores positive while below OW quota', () {
      final game = Game(
        id: 'g-expand-minor-allow',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 20, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: 'oldWorld|minor1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp1_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        tribes: const [],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          provincesToVictory: 24,
          invadableProvinceIdsSorted: ['oldWorld|minor1'],
          adjacentOwnerFactionIdsSorted: ['minor1'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
      );
      const candidate = DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'minor1',
      );
      const config = AIConfig(
        leaderId: 'henry',
        personalityId: 'henry',
        hiddenAgendaId: 'merchant',
      );
      final scores = computeDiplomaticCandidateScores(
        DiplomaticCandidateScoringInput(
          game: game,
          snapshot: snapshot,
          nationId: 'gp1',
          config: config,
          candidates: const [candidate],
          primaryGoal: StrategicGoal.expand,
        ),
      );
      expect(
        scores.single,
        greaterThan(0),
        reason:
            'EXPAND phase must keep adjacent invadable OW minor as a '
            'declareWar candidate per SPEC EXPAND priority order (a).',
      );
      // Determinism guard: same inputs -> same score. Pins the
      // "deterministic for fixed seed" clause of AC #1 without coupling to
      // the broader Full AI determinism harness.
      final repeat = computeDiplomaticCandidateScores(
        DiplomaticCandidateScoringInput(
          game: game,
          snapshot: snapshot,
          nationId: 'gp1',
          config: config,
          candidates: const [candidate],
          primaryGoal: StrategicGoal.expand,
        ),
      );
      expect(repeat.single, scores.single);
    });
  });

  group('DEVELOP suppresses declareWar', () {
    test('all declare-war candidates score zero in develop phase', () {
      final game = Game(
        id: 'g-develop',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 130, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
        ],
        minorNations: const [],
        tribes: const [],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: const ThreatSummary(atWarWith: ['gp2']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 12),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      final scores = computeDiplomaticCandidateScores(
        DiplomaticCandidateScoringInput(
          game: game,
          snapshot: snapshot,
          nationId: 'gp1',
          config: const AIConfig(
            leaderId: 'henry',
            personalityId: 'henry',
            hiddenAgendaId: 'merchant',
          ),
          candidates: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
          primaryGoal: StrategicGoal.conquer,
        ),
      );
      expect(scores.single, kDeclareWarNonAdjacentSuppressedScore);
    });
  });
}
