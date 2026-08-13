// Case bodies for pins of the canonical `criticalOwHoldPeaceTargets` and
// `stalledBelowQuotaGpLeadPeaceTargets` below-quota EXPAND peace deciders
// at their new home in `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from `colonial_pressure.dart` so they
// survive the now-completed S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`.
//
// Live consumers (post-relocation):
//   * `criticalOwHoldPeaceTargets` is the EXPAND "critical OW hold"
//     survival peace arm from `SPEC/ai/ai-architecture.md`
//     § Diplomacy targeting — "when OW holdings are at or below
//     `kFewOldWorldProvincesDefendThreshold` and any OW minor remains
//     (peace all GP wars)". It peaces every at-war Great Power once the
//     player has dropped at or below the defend threshold while still
//     strictly below the observer OW quota, so the GP can rebuild
//     without losing the few OW provinces it still holds.
//   * `stalledBelowQuotaGpLeadPeaceTargets` is the EXPAND "peace the
//     leaders, hold the blocker" arm from
//     `SPEC/ai/ai-architecture.md` § Diplomacy targeting. It peaces
//     at-war Great Powers that lead by the band-selected minimum
//     province deficit (`kUnwinnableSoleGpMinProvinceDeficit` on the
//     default-start row; `1` on the post-default 8–9 OW row) while
//     excluding the canonical OW invadable blocker on a GP-only
//     frontier.
//
// Sibling test coverage that this file complements (but does not duplicate):
//
//   * `diplomacy_planner_below_quota_peace_test.dart` exercises the
//     deciders through the diplomacy-planner orchestration chain (GP
//     wars at 6 OW, sole GP at 7 OW). Those flows resolve through the
//     canonical helpers pinned here.
//
// Behavioral invariants pinned at the canonical entry points:
//
//   1. `criticalOwHoldPeaceTargets` short-circuits to `const []` when
//      the at-war filter (`game.playerById(...) != null`) collapses to
//      empty.
//   2. `criticalOwHoldPeaceTargets` fires only inside the
//      `isBelowObserverConquestQuota && ownOw <=
//      kFewOldWorldProvincesDefendThreshold` AND-band; the boundary at
//      `ownOw == kFewOldWorldProvincesDefendThreshold + 1` returns
//      `const []` and the interior `ownOw == kFewOldWorldProvincesDefendThreshold`
//      returns the sorted at-war GP list.
//   3. `stalledBelowQuotaGpLeadPeaceTargets` short-circuits to
//      `const []` at the observer quota even when a GP enemy leads by
//      more than `kUnwinnableSoleGpMinProvinceDeficit` (the quota
//      hand-off to the quota-met deciders).
//   4. `stalledBelowQuotaGpLeadPeaceTargets` selects deficit band
//      `kUnwinnableSoleGpMinProvinceDeficit` on the default-start row
//      (`own <= kObserverDefaultStartOldWorldProvincesPerGp`) and band
//      `1` on the post-default row (8–9 OW). Both boundary rows are
//      pinned with positive and negative cases so the band-selector
//      cannot silently regress.
//   5. `stalledBelowQuotaGpLeadPeaceTargets` excludes the
//      `primaryInvadableOldWorldGpBlocker` on a GP-only invadable
//      frontier while keeping non-blocker GP foes that still satisfy
//      the deficit.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _gpPartner = 'gp_partner';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';


void registerExpandPhasePlannerCriticalOwHoldAndStalledLeadPeaceCasesPartA() {
group('criticalOwHoldPeaceTargets — canonical at-war GP filter', () {
    test('returns const [] when atWarWith collapses to no Great Powers', () {
      // Only a minor is at-war; `game.playerById(...)` filters it out so
      // the helper must short-circuit before checking the critical band.
      final game = Game(
        id: 'g-critical-hold-canonical-minor-only',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 5; i++)
                Province(
                  id: 'oldWorld|${_gpOwn}_$i',
                  regionId: 'oldWorld',
                  ownerId: _gpOwn,
                ),
              for (var i = 1; i <= 3; i++)
                Province(
                  id: 'oldWorld|${_minor1}_$i',
                  regionId: 'oldWorld',
                  ownerId: _minor1,
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: _gpOwn,
            factionId2: _minor1,
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 5,
        atWarWith: const [_minor1],
      );
      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Only a minor is in threats.atWarWith; `game.playerById(...)` '
            'filters it out and the canonical critical-hold path must '
            'short-circuit before checking `ownOw <= '
            'kFewOldWorldProvincesDefendThreshold`. A regression that '
            'dropped the GP filter would surface "minor1" here and leak a '
            'minor war into the GP survival-peace family.',
      );
    });
  });

  group('criticalOwHoldPeaceTargets — canonical critical-band table', () {
    test('returns const [] one province above the defend threshold '
        '(own == kFewOldWorldProvincesDefendThreshold + 1)', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold + 1,
        partnerProvinces: 6,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold + 1,
        atWarWith: const [_gpPartner],
      );
      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Above kFewOldWorldProvincesDefendThreshold the canonical '
            'helper must NOT engage critical-hold peace even while still '
            'below the observer OW quota. A regression that flipped `<=` '
            'to `<` on the threshold would silently widen the band by '
            'one province and weaken seed-42 OW conquest pressure '
            'before the turn-100 gate.',
      );
    });

    test('returns sorted GP list exactly at the defend threshold '
        '(own == kFewOldWorldProvincesDefendThreshold)', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold,
        partnerProvinces: 10,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [_gpPartner],
      );
      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        [_gpPartner],
        reason:
            'At kFewOldWorldProvincesDefendThreshold the canonical helper '
            'must fire — the `<=` boundary belongs inside the critical '
            'band. A regression that flipped `<=` to `<` would surrender '
            'the survival-peace family exactly at the defend threshold '
            'where it is most needed.',
      );
    });

    test('returns const [] at the observer quota '
        '(own == kObserverConquestMinOwProvincesPerGp)', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        partnerProvinces: 12,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_gpPartner],
      );
      expect(
        criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At kObserverConquestMinOwProvincesPerGp the canonical helper '
            'must NOT engage even though `ownOw <= '
            'kFewOldWorldProvincesDefendThreshold` is now defensive '
            'against a future change. The AND-gate with '
            '`isBelowObserverConquestQuota` must short-circuit.',
      );
    });

    test(
      'sorts multiple GP enemies ascending regardless of atWarWith order',
      () {
        final game = buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold,
          partnerProvinces: 10,
          partnerId: 'gp_z',
          extraGpId: 'gp_a',
          extraGpProvinces: 10,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
          atWarWith: const ['gp_z', 'gp_a'],
        );
        expect(
          criticalOwHoldPeaceTargets(game: game, snapshot: snapshot),
          ['gp_a', 'gp_z'],
          reason:
              'The canonical helper must `..sort()` the GP list so the '
              'downstream offer-peace pass observes a stable order. A '
              'regression that omitted the sort would leak the iteration '
              'order of `snapshot.threats.atWarWith` into the diplomacy '
              'pass and break Refs #2509 must-have #7 (determinism).',
        );
      },
    );
  });

  group('stalledBelowQuotaGpLeadPeaceTargets — canonical quota guard', () {
    test('returns const [] at the observer OW quota even when enemy leads', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        partnerProvinces: kObserverConquestMinOwProvincesPerGp + 3,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_gpPartner],
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At-or-above the observer OW quota the below-quota lead-peace '
            'family must hand off to the quota-met deciders '
            '(`quotaMetBelowQuotaAtWarPeaceTargets`, '
            '`consolidateGainsSoleGpPeaceTarget`). A regression that '
            'inverted `!isBelowObserverConquestQuota` would peace at-war '
            'leaders again after quota and silently undo the consolidate '
            'arm.',
      );
    });
  });

  group(
    'stalledBelowQuotaGpLeadPeaceTargets — canonical minLeadDeficit band',
    () {
  });
}
