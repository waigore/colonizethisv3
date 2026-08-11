// Phase-transition case bodies for `observer_goal_phase_test.dart`
// (Refs #3997 Phase 8, #4310 Slice D remainder densify).
// Declare-war scoring cases live in
// `observer_goal_phase_declare_war_scoring_cases.dart`.

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
}
