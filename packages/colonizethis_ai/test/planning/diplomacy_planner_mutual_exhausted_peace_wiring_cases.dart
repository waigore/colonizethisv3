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

void registerMutualExhaustedPeaceWiringCases() {
  group('mutual-exhausted stalemate wiring into peace orchestration', () {
    test(
      'collectStalledGreatPowerPeaceTargets keeps the blocker for the exhausted-plateau case',
      () {
        // The helper participates in the zero-regiment blocker override set,
        // so even with the enemy classified as the primary invadable OW GP
        // blocker (`isOldWorldGpOnlyInvadableFrontier` + below-quota), peace
        // is produced. Without this wiring, the blocker would be filtered out
        // of the final target set.
        //
        // Trim the enemy base from 9 to 8 so adding the invadable frontier
        // province keeps the enemy at 9 OW (below quota, mutual-plateau peer
        // for this GP at 8 OW).
        final game = mutualExhaustedStalemateGame();
        final gameWithInvadable = Game(
          id: 'g-2509-mutual-exhausted-blocker-keep',
          worldState: WorldState(
            turnState: game.worldState.turnState,
            oldWorld: RegionData(
              provinces: [
                for (final p in game.worldState.oldWorld.provinces)
                  if (p.id != kMutualExhaustedStalemateEnemyOwProvinces.last) p,
                const Province(
                  id: 'oldWorld|frontier',
                  regionId: 'oldWorld',
                  ownerId: kMutualExhaustedStalemateEnemyNationId,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: game.worldState.armies,
          ),
          players: game.players,
          diplomacyRelations: game.diplomacyRelations,
        );
        final snapshot = AIWorldSnapshot(
          playerId: kMutualExhaustedStalemateOwnNationId,
          threats: const ThreatSummary(atWarWith: [kMutualExhaustedStalemateEnemyNationId]),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: <String>['oldWorld|frontier'],
          ),
          economy: const EconomySummary(),
          relations: const {},
        );

        final targets = collectStalledGreatPowerPeaceTargets(
          game: gameWithInvadable,
          snapshot: snapshot,
        );

        expect(
          targets,
          contains(kMutualExhaustedStalemateEnemyNationId),
          reason:
              'Mutually-exhausted plateau must peace the GP blocker even when '
              'it owns the sole invadable frontier (Refs #2509).',
        );
      },
    );

    test(
      'collectStalledGreatPowerPeaceTargets without exhaustion still peaces plateau peer',
      () {
        // Negative control for mutual exhaustion only: treasury/regiment guards
        // reject `mutualExhaustedBelowQuotaGpStalematePeaceTargets`, but
        // `nearQuotaHoldPeaceTargets` still peaces mutual-plateau peers on a
        // GP-only cleared frontier (Refs #2509).
        final game = mutualExhaustedStalemateGame(
          ownTreasury: kMutualExhaustedGpTreasuryMax + 100,
          enemyTreasury: kMutualExhaustedGpTreasuryMax + 100,
          ownRegimentIds: const [
            'u_gp4_a',
            'u_gp4_b',
            'u_gp4_c',
            'u_gp4_d',
            'u_gp4_e',
            'u_gp4_f',
            'u_gp4_g',
            'u_gp4_h',
          ],
          enemyRegimentIds: const [
            'u_gp3_a',
            'u_gp3_b',
            'u_gp3_c',
            'u_gp3_d',
            'u_gp3_e',
            'u_gp3_f',
            'u_gp3_g',
            'u_gp3_h',
          ],
        );
        final gameWithInvadable = Game(
          id: 'g-2509-mutual-exhausted-control',
          worldState: WorldState(
            turnState: game.worldState.turnState,
            oldWorld: RegionData(
              provinces: [
                for (final p in game.worldState.oldWorld.provinces)
                  if (p.id != kMutualExhaustedStalemateEnemyOwProvinces.last) p,
                const Province(
                  id: 'oldWorld|frontier',
                  regionId: 'oldWorld',
                  ownerId: kMutualExhaustedStalemateEnemyNationId,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: game.worldState.armies,
          ),
          players: game.players,
          diplomacyRelations: game.diplomacyRelations,
        );
        final snapshot = AIWorldSnapshot(
          playerId: kMutualExhaustedStalemateOwnNationId,
          threats: const ThreatSummary(atWarWith: [kMutualExhaustedStalemateEnemyNationId]),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: <String>['oldWorld|frontier'],
          ),
          economy: const EconomySummary(),
          relations: const {},
        );

        final exhaustedTargets =
            mutualExhaustedBelowQuotaGpStalematePeaceTargets(
          game: gameWithInvadable,
          snapshot: snapshot,
        );
        expect(
          exhaustedTargets,
          isEmpty,
          reason: 'Exhaustion guard must reject well-resourced GPs.',
        );

        final targets = collectStalledGreatPowerPeaceTargets(
          game: gameWithInvadable,
          snapshot: snapshot,
        );

        expect(
          targets,
          contains(kMutualExhaustedStalemateEnemyNationId),
          reason:
              'Mutual-plateau near-quota hold peace applies even without '
              'regiment/treasury exhaustion on a GP-only cleared frontier.',
        );
      },
    );
  });
}
