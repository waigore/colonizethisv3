// Pins the `quotaMetFutileBelowQuotaGpPeaceTargets` branch table at the
// function-unit boundary (Refs #2509 S10).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI):
//     A quota-met GP should stop dragging on below-quota GP fronts that are
//     not blocking its own remaining invadable Old World frontier. The helper
//     returns the set of below-quota at-war GP factions that own none of this
//     GP's invadable OW provinces and are not the primary invadable OW
//     blocker — peace offers are emitted toward that set. The function is
//     defensive: only Great Powers in `atWarWith` count, only below-quota
//     enemy GPs count, blockers and invadable-owning enemies are always
//     excluded, and the returned list is sorted by `factionId` ascending so
//     the determinism contract (Refs #2509 Must-have #7) holds for fixed
//     seed-bundle inputs.
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `diplomacy_planner_stalled_peace_test.dart` group
//     `'quotaMetFutileBelowQuotaGpPeaceTargets peace below-quota non-blocker
//     victim'` pins **one** positive case (12 OW own, 8 OW enemy gp3,
//     single below-quota non-blocker GP at war returns `['gp3']`). It does
//     not exercise the early-guard branches (own below quota, no invadable
//     OW), the non-GP `atWarWith` filter, the quota-met enemy skip arm,
//     the invadable-owning enemy skip arm, the blocker-equality skip arm,
//     or the deterministic sort across multiple eligible enemies.
//   - `expand_phase_planner_peer_peace_basic_test.dart` covers sibling peace-target helpers
//     (`belowQuotaPeerGpPeaceTargets`, `nearQuotaHoldPeaceTargets`,
//     `defaultStartGpPeaceTargets`, `criticalOwHoldPeaceTargets`,
//     `colonialBuildOrderThresholdCap`, `isEarlyColonialExpansion`,
//     `hasColonialAcquisitionTargets`). It does not call
//     `quotaMetFutileBelowQuotaGpPeaceTargets`.
//
// What's not currently pinned (this file's coverage):
//
//   1. **Early-guard `own below quota`:** when `oldWorldProvincesOwned`
//      is one below the quota even though every other input would yield
//      a non-empty target list, the helper must short-circuit to `[]`.
//      The quota threshold is the only seam between this helper and the
//      EXPAND-phase peace helpers; a regression that flipped the
//      comparison to `<=` would silently peace allies the same turn the
//      GP crossed the quota boundary.
//   2. **Early-guard `no invadable OW`:** with no invadable OW
//      provinces, the blocker check is meaningless and there is nothing
//      to defend — the helper must short-circuit even when otherwise
//      eligible below-quota enemy GPs exist. This is the post-cleanup
//      state where the GP should defer to other quota-met peace helpers
//      (`consolidateGainsSoleGpPeaceTarget`, `quotaMetBelowQuotaAtWarPeaceTargets`).
//   3. **Non-GP `atWarWith` filter:** minors and tribes can appear in
//      `snapshot.threats.atWarWith` (the threat summary collapses every
//      relation), but this helper only emits peace toward Great Powers.
//      A regression that removed the `game.playerById(factionId) ==
//      null` skip would silently emit a minor as a peace target,
//      polluting the deterministic order set produced by the diplomacy
//      planner.
//   4. **Quota-met enemy skip:** an enemy GP at or above the observer
//      quota is by definition not the "futile below-quota" target type
//      this helper addresses; peace there is owned by the consolidate
//      helpers. The skip is `continue`, not `return` — pinning the skip
//      separately from the early-guard arms ensures a regression that
//      removed the per-enemy quota check does not silently leak
//      quota-met enemies into the result set.
//   5. **Invadable-owning enemy skip:** an enemy GP that owns at least
//      one province in `snapshot.conquest.invadableProvinceIdsSorted`
//      must remain at war; peace toward it would forfeit the OW
//      acquisition path the quota-met GP is still pursuing. Pinned at
//      the boundary so swapping the `provinceOwner[pid] == factionId`
//      lookup for the inverse (or skipping the existence check) cannot
//      regress unnoticed.
//   6. **Blocker-equality skip (defensive):** the primary invadable OW
//      blocker (`primaryInvadableOldWorldGpBlocker`) is the GP holding
//      the most invadable OW provinces. By construction the blocker
//      also satisfies the invadable-owning arm above, so the
//      `factionId == blocker` clause is a defensive backstop against a
//      future blocker-resolution refactor (e.g. counting adjacent
//      provinces instead of own-counted invadables) that could decouple
//      the blocker identity from the invadable-ownership signal. Pin
//      the blocker-equality skip on a fixture where the blocker happens
//      to own one of the invadable provinces so the result is
//      identical with or without the defensive backstop — the pin
//      documents the contract independently of the implementation.
//   7. **Deterministic sort across multiple eligible enemies:** when
//      two or more below-quota non-blocker non-invadable-owning enemy
//      GPs are at war, the returned list is sorted by `factionId`
//      ascending. Required by Must-have #7 so a fixed seed yields
//      identical merged orders run after run.
//   8. **Quota-met boundary `own == kObserverConquestMinOwProvincesPerGp`:**
//      with own OW equal to the quota the helper enters its main pass
//      (no early-guard short-circuit). A regression that flipped the
//      strict inequality `<` to `<=` in `isBelowObserverConquestQuota`
//      would silently re-engage the EXPAND-only early-guard at the
//      quota threshold and produce `[]` here — the boundary case
//      ensures that flip is caught at this helper boundary too.
//
// Coverage layers:
//   - **Function unit (`quotaMetFutileBelowQuotaGpPeaceTargets`):** early
//     guards (own below quota, no invadable OW) / non-GP filter /
//     quota-met enemy skip / invadable-owning enemy skip / blocker-equality
//     skip / multi-target sort / quota boundary `own == quota` branch
//     table.
//
// Pin strategy: small synthetic 4-GP fixtures, varying province ownership
// and `atWarWith` membership one branch at a time. Each test asserts the
// returned list verbatim (including ordering) so a regression in either
// the guard ladder or the sort is caught at the function boundary.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

/// Game with the supplied OW [provinces] and a default 4-GP roster.
///
/// Fixtures override `players`, `minorNations`, `tribes`, and
/// `diplomacyRelations` per-test; the helper only needs the OW
/// province table (for `provinceCountOwnedBy` + `getProvinceOwnerMap`),
/// the player roster (for the `game.playerById` filter), and the
/// `atWarWith` snapshot field (carried on the snapshot, not the game).
Game _gameWithOwProvinces({
  required List<Province> provinces,
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false),
    Player(id: _gp2, displayName: 'GP2', isHuman: false),
    Player(id: _gp3, displayName: 'GP3', isHuman: false),
    Player(id: _gp4, displayName: 'GP4', isHuman: false),
  ],
  List<MinorNation> minorNations = const [
    MinorNation(id: _minor1, displayName: 'M1'),
  ],
  List<Tribe> tribes = const [Tribe(id: _tribe1, displayName: 'T1')],
}) {
  return Game(
    id: 'g-quota-met-futile',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 110),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Snapshot scaffold; tests override `oldWorldProvincesOwned`,
/// `invadableProvinceIdsSorted`, and `atWarWith` per-branch.
AIWorldSnapshot _snapshot({
  required int ownOw,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: ownOw,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// `count` OW provinces under [ownerId] starting at the given numeric prefix
/// so successive owner blocks do not collide on province ids.
List<Province> _ownedProvinces(String ownerId, int count, int idOffset) {
  return <Province>[
    for (var i = 0; i < count; i++)
      Province(
        id: 'oldWorld|${ownerId}_${idOffset + i}',
        regionId: 'oldWorld',
        ownerId: ownerId,
      ),
  ];
}

void main() {
  group('quotaMetFutileBelowQuotaGpPeaceTargets — early guards', () {
    test('returns [] when own OW is one below the observer quota '
        '(`isBelowObserverConquestQuota` early guard)', () {
      // Below-quota own + below-quota non-blocker non-invadable-owning enemy:
      // the main pass would normally include gp3, but the early guard
      // short-circuits regardless because this helper only applies
      // **after** the quota is met.
      final game = _gameWithOwProvinces(
        provinces: <Province>[
          ..._ownedProvinces(_gp1, kObserverConquestMinOwProvincesPerGp - 1, 0),
          ..._ownedProvinces(_gp3, 8, 0),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
      );
      final snapshot = _snapshot(
        ownOw: kObserverConquestMinOwProvincesPerGp - 1,
        atWarWith: const [_gp3],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'The futile-below-quota peace helper is reserved for quota-met '
            'GPs; the EXPAND-phase peace helpers own the below-quota set. '
            'Flipping `<` to `<=` in `isBelowObserverConquestQuota` would '
            'silently regress this early guard and double-emit peace from '
            'two helpers on the same turn.',
      );
    });

    test('returns [] when no invadable OW provinces remain '
        '(`invadableProvinceIdsSorted.isEmpty` early guard)', () {
      // Quota-met own + below-quota non-blocker non-invadable-owning enemy:
      // without an invadable OW frontier there is nothing to defend, so the
      // consolidate helpers (not this one) own the peace decision.
      final game = _gameWithOwProvinces(
        provinces: <Province>[
          ..._ownedProvinces(_gp1, kObserverConquestMinOwProvincesPerGp + 2, 0),
          ..._ownedProvinces(_gp3, 8, 0),
        ],
      );
      final snapshot = _snapshot(
        ownOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gp3],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'No invadable OW frontier means there is nothing this helper '
            'must defend by keeping a war active; deferring to the '
            'consolidate / quota-met helpers keeps responsibilities '
            'partitioned.',
      );
    });
  });

  group('quotaMetFutileBelowQuotaGpPeaceTargets — per-enemy filters', () {
    test('skips non-GP factions in `atWarWith` (minors / tribes filtered)', () {
      // A minor and a tribe appear in `atWarWith` alongside a valid
      // below-quota non-blocker GP. Only the GP must surface as a target.
      final game = _gameWithOwProvinces(
        provinces: <Province>[
          ..._ownedProvinces(_gp1, kObserverConquestMinOwProvincesPerGp + 2, 0),
          ..._ownedProvinces(_gp3, 8, 0),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
      );
      final snapshot = _snapshot(
        ownOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_minor1, _tribe1, _gp3],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gp3],
        reason:
            'Minors and tribes must be filtered by `game.playerById` even '
            'when they appear in `atWarWith`; only Great Powers should '
            'surface as peace targets for this helper.',
      );
    });

    test('skips at-war enemy GPs that have met the observer quota', () {
      // gp2 is at quota (10 OW) so the per-enemy guard skips it; gp3 is
      // still below quota and remains eligible.
      final game = _gameWithOwProvinces(
        provinces: <Province>[
          ..._ownedProvinces(_gp1, kObserverConquestMinOwProvincesPerGp + 2, 0),
          ..._ownedProvinces(_gp2, kObserverConquestMinOwProvincesPerGp, 0),
          ..._ownedProvinces(_gp3, 8, 0),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
      );
      final snapshot = _snapshot(
        ownOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gp2, _gp3],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gp3],
        reason:
            'Quota-met enemy GPs are not "futile below quota" by definition; '
            'peace toward them is owned by the consolidate helpers. The '
            'per-enemy quota check must stay strictly below the threshold '
            '(matches `isBelowObserverConquestQuota`).',
      );
    });

    test(
      'skips at-war enemy GPs that own one of the invadable OW provinces',
      () {
        // gp2 owns the only invadable OW province; even though it is below
        // quota the helper must keep the war alive so the OW acquisition path
        // stays open.
        final game = _gameWithOwProvinces(
          provinces: <Province>[
            ..._ownedProvinces(
              _gp1,
              kObserverConquestMinOwProvincesPerGp + 2,
              0,
            ),
            ..._ownedProvinces(_gp2, 7, 0),
            ..._ownedProvinces(_gp3, 8, 0),
            const Province(
              id: 'oldWorld|gp2_inv',
              regionId: 'oldWorld',
              ownerId: _gp2,
            ),
          ],
        );
        final snapshot = _snapshot(
          ownOw: kObserverConquestMinOwProvincesPerGp + 2,
          atWarWith: const [_gp2, _gp3],
          invadableProvinceIdsSorted: const ['oldWorld|gp2_inv'],
        );
        expect(
          quotaMetFutileBelowQuotaGpPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          const [_gp3],
          reason:
              'Peacing an enemy GP that owns the GP\'s remaining invadable OW '
              'frontier forfeits the conquest path that the quota-met GP is '
              'still pursuing; gp2 must stay at war and only the futile '
              'gp3 front is peaced.',
        );
      },
    );

    test('skips the primary invadable OW blocker (defensive backstop)', () {
      // gp2 is the primary invadable OW blocker (owns both invadable
      // provinces). The blocker-equality clause acts as a backstop for a
      // future blocker-resolution refactor; on this fixture it produces the
      // same result as the invadable-owning skip, but the helper must
      // exclude gp2 either way and surface only the below-quota non-blocker
      // non-invadable-owning gp3 front.
      final game = _gameWithOwProvinces(
        provinces: <Province>[
          ..._ownedProvinces(_gp1, kObserverConquestMinOwProvincesPerGp + 2, 0),
          ..._ownedProvinces(_gp2, 6, 0),
          ..._ownedProvinces(_gp3, 8, 0),
          const Province(
            id: 'oldWorld|gp2_inv_a',
            regionId: 'oldWorld',
            ownerId: _gp2,
          ),
          const Province(
            id: 'oldWorld|gp2_inv_b',
            regionId: 'oldWorld',
            ownerId: _gp2,
          ),
        ],
      );
      final snapshot = _snapshot(
        ownOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gp2, _gp3],
        invadableProvinceIdsSorted: const [
          'oldWorld|gp2_inv_a',
          'oldWorld|gp2_inv_b',
        ],
      );
      // Sanity: confirm `primaryInvadableOldWorldGpBlocker` returns gp2
      // for the synthetic fixture so the blocker-equality arm is the
      // contract under test.
      expect(
        primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
        _gp2,
        reason:
            'Fixture sanity: gp2 owns the plurality of invadable OW so the '
            'blocker resolves to gp2 — the blocker-equality skip arm in '
            '`quotaMetFutileBelowQuotaGpPeaceTargets` must therefore '
            'exclude gp2 even if the invadable-owning skip is bypassed by '
            'a future refactor.',
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gp3],
        reason:
            'gp2 is the primary invadable OW blocker; peacing it would '
            'lose the OW acquisition path. The defensive `factionId == '
            'blocker` clause guarantees blocker exclusion independently '
            'of the invadable-owning lookup.',
      );
    });
  });

  group('quotaMetFutileBelowQuotaGpPeaceTargets — multi-target ordering', () {
    test(
      'returns multiple below-quota non-blocker enemy GPs sorted by factionId',
      () {
        // gp4, gp3, gp2 all below quota, none own invadable; blocker is the
        // minor-owner so no GP is excluded by the blocker arm. The result
        // must be the deterministic ascending-`factionId` sort.
        final game = _gameWithOwProvinces(
          provinces: <Province>[
            ..._ownedProvinces(
              _gp1,
              kObserverConquestMinOwProvincesPerGp + 2,
              0,
            ),
            ..._ownedProvinces(_gp2, 8, 0),
            ..._ownedProvinces(_gp3, 8, 0),
            ..._ownedProvinces(_gp4, 7, 0),
            const Province(
              id: 'oldWorld|inv1',
              regionId: 'oldWorld',
              ownerId: _minor1,
            ),
          ],
        );
        // Intentionally interleave the `atWarWith` order (gp4 before gp2)
        // so the assertion catches a regression that returns the targets in
        // `atWarWith` traversal order instead of the deterministic sort.
        final snapshot = _snapshot(
          ownOw: kObserverConquestMinOwProvincesPerGp + 2,
          atWarWith: const [_gp4, _gp2, _gp3],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        );
        expect(
          quotaMetFutileBelowQuotaGpPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          const [_gp2, _gp3, _gp4],
          reason:
              'Must-have #7 (determinism): the returned list must be sorted '
              'by `factionId` ascending so a fixed seed yields identical '
              'merged orders run after run. Returning `atWarWith` traversal '
              'order would silently drop this guarantee for multi-front '
              'quota-met peace turns.',
        );
      },
    );
  });

  group(
    'quotaMetFutileBelowQuotaGpPeaceTargets — shared collector migration '
    '(Refs #3717)',
    () {
      test(
        'filters an interleaved non-GP entry AND sorts the remaining eligible '
        'GPs (shared gpAtWarPeaceTargetsWhere skeleton)',
        () {
          // Regression guard for the migration of this decider onto the shared
          // `gpAtWarPeaceTargetsWhere` collector: the GP filter (formerly an
          // inline `game.playerById(..) == null` skip) and the ascending sort
          // now live inside the shared helper. Interleave a minor before two
          // eligible below-quota non-blocker GPs (gp4 ahead of gp2) so a
          // regression that dropped the GP filter would surface `minor1`, and
          // one that returned `atWarWith` traversal order would surface
          // `[gp4, gp2]` instead of the sorted `[gp2, gp4]`.
          final game = _gameWithOwProvinces(
            provinces: <Province>[
              ..._ownedProvinces(
                _gp1,
                kObserverConquestMinOwProvincesPerGp + 2,
                0,
              ),
              ..._ownedProvinces(_gp2, 8, 0),
              ..._ownedProvinces(_gp4, 7, 0),
              const Province(
                id: 'oldWorld|inv1',
                regionId: 'oldWorld',
                ownerId: _minor1,
              ),
            ],
          );
          final snapshot = _snapshot(
            ownOw: kObserverConquestMinOwProvincesPerGp + 2,
            atWarWith: const [_minor1, _gp4, _gp2],
            invadableProvinceIdsSorted: const ['oldWorld|inv1'],
          );
          expect(
            quotaMetFutileBelowQuotaGpPeaceTargets(
              game: game,
              snapshot: snapshot,
            ),
            const [_gp2, _gp4],
            reason:
                'After routing through gpAtWarPeaceTargetsWhere the helper must '
                'still drop the interleaved minor and return the eligible GPs '
                'in ascending factionId order — byte-identical to the inline '
                'loop it replaced.',
          );
        },
      );
    },
  );

  group('quotaMetFutileBelowQuotaGpPeaceTargets — quota boundary', () {
    test('enters main pass when own OW equals the observer quota '
        '(strict `<` boundary)', () {
      // own OW == quota: `isBelowObserverConquestQuota` is false (strict
      // `<` comparison) so the early guard does not fire and the main pass
      // produces the expected `[gp3]`. A regression that switched to `<=`
      // would yield `[]` here.
      final game = _gameWithOwProvinces(
        provinces: <Province>[
          ..._ownedProvinces(_gp1, kObserverConquestMinOwProvincesPerGp, 0),
          ..._ownedProvinces(_gp3, 8, 0),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
      );
      final snapshot = _snapshot(
        ownOw: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_gp3],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gp3],
        reason:
            'The quota boundary `own == kObserverConquestMinOwProvincesPerGp` '
            'is the first turn a GP qualifies for this helper. Flipping the '
            'comparison would silently delay the futile-below-quota peace '
            'pass by one quota tick.',
      );
    });
  });
}
