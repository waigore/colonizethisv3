// Case bodies for `diplomacy_planner_mutual_exhausted_peace_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Pins `mutualExhaustedBelowQuotaGpStalematePeaceTargets` from issue #2509.
//
// SPEC (`SPEC/ai/ai-architecture.md` § Diplomacy targeting): when both sides of
// a sole at-war GP pair are mutual-plateau peers below the observer quota AND
// both are exhausted in regiments (≤ `kMutualExhaustedGpRegimentMax`) AND
// treasury (≤ `kMutualExhaustedGpTreasuryMax`), the helper peaces the blocker
// even on a GP-only invadable frontier so both sides rebuild before re-engaging
// (observer seed-42 gp3/gp4 3-regiment 0-treasury turn-100 stalemate).
//
// Coverage:
//   - Positive: gp3-like and gp4-like exhausted-plateau fixture → peer enemy.
//   - Negative: ownOw at quota → empty.
//   - Negative: ownOw outside stalled band → empty.
//   - Negative: own treasury above ceiling → empty.
//   - Negative: own regiments above ceiling → empty.
//   - Negative: enemy treasury above ceiling → empty.
//   - Negative: enemy regiments above ceiling → empty.
//   - Negative: not sole GP war (two GPs at war) → empty.
//   - Negative: mutual gap > 1 OW province → empty.
//   - Determinism: identical inputs → identical outputs across calls.
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/mutual_exhausted_stalemate_test_support.dart';

void registerMutualExhaustedPeaceTargetsCases() {
  group('mutualExhaustedBelowQuotaGpStalematePeaceTargets', () {
    test('positive: gp3/gp4-like exhausted plateau peaces the peer enemy', () {
      final game = mutualExhaustedStalemateGame();
      final snapshot = mutualExhaustedStalemateSnapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, [kMutualExhaustedStalemateEnemyNationId]);
    });

    test('negative: own GP already at observer quota returns empty', () {
      final game = mutualExhaustedStalemateGame(
        extraOwnOwProvinces: const ['oldWorld|gp4_9', 'oldWorld|gp4_10'],
      );
      final snapshot = mutualExhaustedStalemateSnapshotForOwn(ownOw: 10);

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: own GP outside stalled OW band returns empty', () {
      final game = mutualExhaustedStalemateGame();
      final snapshot = AIWorldSnapshot(
        playerId: kMutualExhaustedStalemateOwnNationId,
        threats: const ThreatSummary(atWarWith: [kMutualExhaustedStalemateEnemyNationId]),
        opportunities: const OpportunitySummary(),
        conquest: const ConquestSummary(
          oldWorldProvincesOwned: 0,
          invadableProvinceIdsSorted: <String>[],
        ),
        economy: const EconomySummary(),
        relations: const {},
      );

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: own OW below late-stalled floor returns empty', () {
      // Trim ownership so the own side holds fewer than
      // `kMutualExhaustedGpStalemateMinOw` (8) OW provinces. The early-game /
      // collapsed-survival case is handled by `criticalWeakGpSurvivalPeaceTargets`,
      // not the mutual-exhausted helper.
      final base = mutualExhaustedStalemateGame();
      final reduced = Game(
        id: 'g-2509-mutual-exhausted-floor',
        worldState: WorldState(
          turnState: base.worldState.turnState,
          oldWorld: RegionData(
            provinces: [
              for (final p in base.worldState.oldWorld.provinces)
                if (p.ownerId != kMutualExhaustedStalemateOwnNationId ||
                    int.parse(p.id.split('_').last) <
                        kMutualExhaustedGpStalemateMinOw - 1)
                  p,
            ],
          ),
          newWorld: const RegionData(),
          armies: base.worldState.armies,
        ),
        players: base.players,
        diplomacyRelations: base.diplomacyRelations,
      );
      // Own side now holds 7 OW provinces (< floor 8) but is still otherwise
      // in the stalled band.
      final snapshot = mutualExhaustedStalemateSnapshotForOwn(ownOw: 7);

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: reduced,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: own treasury above ceiling returns empty', () {
      final game = mutualExhaustedStalemateGame(
        ownTreasury: kMutualExhaustedGpTreasuryMax + 1,
      );
      final snapshot = mutualExhaustedStalemateSnapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: own regiments above ceiling returns empty', () {
      final tooManyRegiments = <String>[
        for (var i = 0; i < kMutualExhaustedGpRegimentMax + 1; i++)
          'u_gp4_$i',
      ];
      final game = mutualExhaustedStalemateGame(ownRegimentIds: tooManyRegiments);
      final snapshot = mutualExhaustedStalemateSnapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: enemy treasury above ceiling returns empty', () {
      final game = mutualExhaustedStalemateGame(
        enemyTreasury: kMutualExhaustedGpTreasuryMax + 1,
      );
      final snapshot = mutualExhaustedStalemateSnapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: enemy regiments above ceiling returns empty', () {
      final tooManyEnemyRegiments = <String>[
        for (var i = 0; i < kMutualExhaustedGpRegimentMax + 1; i++)
          'u_gp3_$i',
      ];
      final game = mutualExhaustedStalemateGame(
        enemyRegimentIds: tooManyEnemyRegiments,
      );
      final snapshot = mutualExhaustedStalemateSnapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });
  });
}
