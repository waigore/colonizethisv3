// Case bodies for `observer_goal_phase_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerObserverGoalPhasePhaseAndDeclareWarCases() {
  group('hasColonialAcquisitionTargets', () {
    test('true when invadable NW provinces remain', () {
      const colonial = ColonialSummary(
        invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
      );
      expect(hasColonialAcquisitionTargets(colonial), isTrue);
    });

    test('true when adjacent NW tribe owners remain', () {
      const colonial = ColonialSummary(
        adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
      );
      expect(hasColonialAcquisitionTargets(colonial), isTrue);
    });

    test(
      'true when both invadable provinces and adjacent owners are present',
      () {
        const colonial = ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
          adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
        );
        expect(hasColonialAcquisitionTargets(colonial), isTrue);
      },
    );

    test('false when NW holdings exist but no acquisition targets', () {
      const colonial = ColonialSummary(newWorldProvincesOwned: 12);
      expect(hasColonialAcquisitionTargets(colonial), isFalse);
    });

    test('false when colonial summary is fully empty', () {
      const colonial = ColonialSummary();
      expect(hasColonialAcquisitionTargets(colonial), isFalse);
    });

    test('drives observerGoalPhaseFor EXPAND -> COLONIAL transition guard', () {
      const baseSnapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 10),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        hasColonialAcquisitionTargets(baseSnapshot.colonial),
        isTrue,
        reason: 'guard fires the COLONIAL branch in observerGoalPhaseFor',
      );
      expect(
        observerGoalPhaseFor(snapshot: baseSnapshot),
        ObserverGoalPhase.colonial,
      );

      const developSnapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 10),
        colonial: ColonialSummary(newWorldProvincesOwned: 5),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        hasColonialAcquisitionTargets(developSnapshot.colonial),
        isFalse,
        reason: 'absence of guard routes observerGoalPhaseFor to DEVELOP',
      );
      expect(
        observerGoalPhaseFor(snapshot: developSnapshot),
        ObserverGoalPhase.develop,
      );
    });

    test('determinism: identical input returns identical bool', () {
      const colonial = ColonialSummary(
        invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
        adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
      );
      final a = hasColonialAcquisitionTargets(colonial);
      final b = hasColonialAcquisitionTargets(colonial);
      expect(a, b);
    });
  });

  // `isEarlyColonialExpansion` (goal-scoring sibling of
  // `hasColonialAcquisitionTargets`) is pinned in
  // `observer_goal_phase_is_early_colonial_expansion_test.dart`; it lives in
  // its own file so this suite stays under the 1000-non-comment-line cap
  // (`repo.dart_file_non_comment_line_size`).

  group('observerGoalPhaseFor', () {
    test('expand when below observer OW quota', () {
      const snap = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 8),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        observerGoalPhaseFor(snapshot: snap),
        ObserverGoalPhase.expand,
      );
      expect(
        shouldSuppressNewWorldColonialOrders(snapshot: snap),
        isTrue,
      );
    });

    test('colonialLite at 9 OW turn 120 with tribe-owned NW', () {
      final game = Game(
        id: 'g-lite',
        worldState: WorldState(
          turnState: const TurnState(
            turnNumber: 120,
            phase: TurnPhase.orders,
          ),
          oldWorld: const RegionData(),
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
      const snap = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 9),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|nw1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        observerGoalPhaseFor(snapshot: snap, game: game),
        ObserverGoalPhase.colonialLite,
      );
      expect(
        shouldSuppressNewWorldColonialOrders(snapshot: snap, game: game),
        isFalse,
      );
      expect(
        shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
          snapshot: snap,
          game: game,
        ),
        isTrue,
      );
    });

    test('colonial when at quota with acquisition targets', () {
      const snap = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 10),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        observerGoalPhaseFor(snapshot: snap),
        ObserverGoalPhase.colonial,
      );
      expect(
        shouldSuppressNewWorldColonialOrders(snapshot: snap),
        isFalse,
      );
    });

    test('develop when at quota without colonial targets', () {
      const snap = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 12),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        observerGoalPhaseFor(snapshot: snap),
        ObserverGoalPhase.develop,
      );
      expect(isObserverDevelopPhase(snapshot: snap), isTrue);
    });
  });



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
