// Pins the canonical `criticalOwHoldPeaceTargets` and
// `stalledBelowQuotaGpLeadPeaceTargets` below-quota EXPAND peace deciders
// at their new home in `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from `colonial_pressure.dart` so they
// survive the planned S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`;
// `colonial_pressure.dart` retains thin delegating stubs for the legacy
// `expand_phase_planner_critical_ow_hold_branches_test.dart`,
// `expand_phase_planner_stalled_below_quota_gp_lead_branches_test.dart`,
// `expand_phase_planner_peer_peace_basic_test.dart`, and `diplomacy_planner_below_quota_peace_test.dart`
// fixtures plus the `diplomacy_planner.dart` /
// `diplomacy_planner_peace_targets.dart` /
// `diplomatic_candidate_scoring_offer_peace.dart` consumer chains until
// the planned deletion.
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
//   * `expand_phase_planner_critical_ow_hold_branches_test.dart` and
//     `expand_phase_planner_stalled_below_quota_gp_lead_branches_test.dart`
//     pin the legacy `colonial_pressure.dart`-side branches (boundary
//     bands, sort determinism, GP-filter, minLeadDeficit table). This
//     file pins the **canonical** invocations against
//     `expand_phase_planner.dart` directly and additionally pins
//     **delegator parity** so the thin stubs in `colonial_pressure.dart`
//     return the same value as the canonical helpers for representative
//     inputs across both functions.
//   * `expand_phase_planner_peer_peace_basic_test.dart` § `criticalOwHoldPeaceTargets`
//     contains the legacy at-threshold happy-path test. Both legacy
//     fixtures depend on the delegating stubs and will continue to pass
//     unchanged after the canonical bodies relocated here.
//   * `diplomacy_planner_below_quota_peace_test.dart` exercises the
//     deciders through the diplomacy-planner orchestration chain (GP
//     wars at 6 OW, sole GP at 7 OW). Those flows depend on the same
//     post-delegation return values pinned here.
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
//   6. The delegating stubs in `colonial_pressure.dart` return the same
//      value as the canonical helpers for every representative input —
//      required so the legacy fixtures and the in-file consumer paths
//      agree on the deciders.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as colonial_pressure;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpPartner = 'gp_partner';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';

/// Builds a minimal `Game` where `gp_own` holds [ownProvinces] OW
/// provinces, the at-war partner [partnerId] holds [partnerProvinces]
/// OW provinces, and the OW map optionally carries:
///
///   * an additional GP [extraGpId] (with [extraGpProvinces] OW
///     provinces) to opt into the "two GPs in atWarWith" multi-front
///     shape used by [stalledBelowQuotaGpLeadPeaceTargets] tests;
///   * a minor [minorId] (with [minorProvinces] OW provinces) used by
///     the GP-only-frontier carve-out tests so the invadable frontier
///     can be shaped to include or exclude minor-owned tiles;
///   * a single invadable province at `oldWorld|invadable_partner`
///     owned by [partnerId] when [invadablePartnerProvince] is `true`,
///     mirroring the `_ownVsPartnerGame` shape from
///     `expand_phase_planner_sole_gp_peace_deciders_test.dart`.
///
/// Diplomacy relations between `gp_own` and the partner default to
/// atWar; the optional extra GP is also placed at war when supplied.
/// Minors are never in the at-war set so the focus stays on the GP
/// lead-peace and critical-hold branches.
Game _ownVsPartnerGame({
  required int ownProvinces,
  required int partnerProvinces,
  String partnerId = _gpPartner,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? minorId,
  int minorProvinces = 0,
  bool invadablePartnerProvince = false,
  bool atWarWithPartner = true,
  bool atWarWithExtraGp = true,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${_gpOwn}_$i',
        regionId: 'oldWorld',
        ownerId: _gpOwn,
      ),
    for (var i = 1; i <= partnerProvinces; i++)
      Province(
        id: 'oldWorld|${partnerId}_$i',
        regionId: 'oldWorld',
        ownerId: partnerId,
      ),
    if (extraGpId != null)
      for (var i = 1; i <= extraGpProvinces; i++)
        Province(
          id: 'oldWorld|${extraGpId}_$i',
          regionId: 'oldWorld',
          ownerId: extraGpId,
        ),
    if (minorId != null)
      for (var i = 1; i <= minorProvinces; i++)
        Province(
          id: 'oldWorld|${minorId}_$i',
          regionId: 'oldWorld',
          ownerId: minorId,
        ),
    if (invadablePartnerProvince)
      Province(
        id: 'oldWorld|invadable_partner',
        regionId: 'oldWorld',
        ownerId: partnerId,
      ),
  ];

  final players = <Player>[
    const Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
    Player(id: partnerId, displayName: partnerId, isHuman: false),
    if (extraGpId != null)
      Player(
        id: extraGpId,
        displayName: extraGpId.toUpperCase(),
        isHuman: false,
      ),
  ];

  final minorNations = <MinorNation>[
    if (minorId != null) MinorNation(id: minorId, displayName: minorId),
  ];

  final relations = <DiplomacyRelation>[
    if (atWarWithPartner)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: partnerId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (extraGpId != null && atWarWithExtraGp)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: extraGpId,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id:
        'g-2509-critical-hold-stalled-lead-canonical-'
        '${ownProvinces}_vs_$partnerProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    diplomacyRelations: relations,
  );
}

AIWorldSnapshot _ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: _gpOwn,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
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
      final snapshot = _ownSnapshot(
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
      final game = _ownVsPartnerGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold + 1,
        partnerProvinces: 6,
      );
      final snapshot = _ownSnapshot(
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
      final game = _ownVsPartnerGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold,
        partnerProvinces: 10,
      );
      final snapshot = _ownSnapshot(
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
      final game = _ownVsPartnerGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        partnerProvinces: 12,
      );
      final snapshot = _ownSnapshot(
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
        final game = _ownVsPartnerGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold,
          partnerProvinces: 10,
          partnerId: 'gp_z',
          extraGpId: 'gp_a',
          extraGpProvinces: 10,
        );
        final snapshot = _ownSnapshot(
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
      final game = _ownVsPartnerGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        partnerProvinces: kObserverConquestMinOwProvincesPerGp + 3,
      );
      final snapshot = _ownSnapshot(
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
      test(
        'default-start row requires lead `kUnwinnableSoleGpMinProvinceDeficit`',
        () {
          // own == kObserverDefaultStartOldWorldProvincesPerGp (7) so the
          // minLeadDeficit table selects kUnwinnableSoleGpMinProvinceDeficit
          // (2). lead exactly 2 peaces.
          final game = _ownVsPartnerGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            partnerProvinces:
                kObserverDefaultStartOldWorldProvincesPerGp +
                kUnwinnableSoleGpMinProvinceDeficit,
          );
          final snapshot = _ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_gpPartner],
          );
          expect(
            stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
            [_gpPartner],
            reason:
                'Default-start row (own <= '
                'kObserverDefaultStartOldWorldProvincesPerGp) requires lead '
                '== kUnwinnableSoleGpMinProvinceDeficit. A regression that '
                'collapsed both rows to `1` would peace one-province '
                'leaders at default start and trade away early-game '
                'pressure.',
          );
        },
      );

      test('default-start row skips one-province lead (below band)', () {
        final game = _ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_gpPartner],
        );
        expect(
          stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Default-start row must skip lead 1 — only '
              'kUnwinnableSoleGpMinProvinceDeficit (2) qualifies. Pins the '
              'negative boundary of the band selector against a regression '
              'that broadened the row to `>= own + 1`.',
        );
      });

      test('post-default row peaces a one-province lead (8 OW + 1)', () {
        final game = _ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 2,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned:
              kObserverDefaultStartOldWorldProvincesPerGp + 1,
          atWarWith: const [_gpPartner],
        );
        expect(
          stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
          [_gpPartner],
          reason:
              'Post-default row (own > kObserverDefaultStartOldWorldProvincesPerGp) '
              'requires lead 1 only. A regression that kept '
              'kUnwinnableSoleGpMinProvinceDeficit on the post-default row '
              'would refuse to peace near-quota leaders and starve the '
              'pivot-to-minors arm of throughput.',
        );
      });

      test('post-default row skips a tied enemy (lead == 0)', () {
        final game = _ownVsPartnerGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned:
              kObserverDefaultStartOldWorldProvincesPerGp + 1,
          atWarWith: const [_gpPartner],
        );
        expect(
          stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Tied enemy on the post-default row fails the `>= own + 1` '
              'gate. Pins the negative boundary against a regression that '
              'used `>= own` instead.',
        );
      });
    },
  );

  group('stalledBelowQuotaGpLeadPeaceTargets — canonical GP-only blocker', () {
    test('skips the primary invadable OW GP blocker on a GP-only frontier', () {
      // The partner owns the only invadable OW frontier province and
      // leads by 2 (the default-start band). On a GP-only frontier the
      // primary blocker must be excluded even though it satisfies the
      // deficit gate — so the canonical helper returns const [] when
      // the sole at-war GP is the blocker.
      final game = _ownVsPartnerGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces:
            kObserverDefaultStartOldWorldProvincesPerGp +
            kUnwinnableSoleGpMinProvinceDeficit,
        invadablePartnerProvince: true,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_partner'],
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'On a GP-only invadable frontier the primary blocker is '
            'excluded from the lead-peace list so the EXPAND planner '
            'keeps fighting the canonical OW frontier blocker. A '
            'regression that dropped the carve-out would peace the '
            'blocker and surrender the OW frontier the planner needs '
            'to push past quota.',
      );
    });

    test('keeps a non-blocker GP that satisfies the deficit when the '
        'GP-only blocker is also at war', () {
      // Partner is the GP-only frontier blocker (owns the only
      // invadable province). gp_third is a non-blocker GP at war
      // with own and leads by 2 → must still peace.
      final game = _ownVsPartnerGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces:
            kObserverDefaultStartOldWorldProvincesPerGp +
            kUnwinnableSoleGpMinProvinceDeficit,
        invadablePartnerProvince: true,
        extraGpId: _gpThird,
        extraGpProvinces:
            kObserverDefaultStartOldWorldProvincesPerGp +
            kUnwinnableSoleGpMinProvinceDeficit,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpPartner, _gpThird],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_partner'],
      );
      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        [_gpThird],
        reason:
            'Non-blocker GP foes that satisfy the deficit must remain '
            'in the lead-peace list even when the GP-only blocker is '
            'co-belligerent. Pins the carve-out as exclusion-only — '
            'never expand-all-GP — so the planner does not peace the '
            'frontier blocker by accident.',
      );
    });
  });

  group('Delegating stubs match canonical', () {
    test('colonial_pressure.criticalOwHoldPeaceTargets matches canonical', () {
      // Pin delegator parity across the band table: empty-after-filter,
      // boundary above threshold, interior at threshold, and at-quota.
      final scenarios = <({Game game, AIWorldSnapshot snapshot})>[
        (
          game: Game(
            id: 'g-delegator-minor-only',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 80,
              ),
              oldWorld: RegionData(
                provinces: [
                  for (var i = 1; i <= 5; i++)
                    Province(
                      id: 'oldWorld|${_gpOwn}_$i',
                      regionId: 'oldWorld',
                      ownerId: _gpOwn,
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
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: 5,
            atWarWith: const [_minor1],
          ),
        ),
        (
          game: _ownVsPartnerGame(
            ownProvinces: kFewOldWorldProvincesDefendThreshold,
            partnerProvinces: 10,
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
            atWarWith: const [_gpPartner],
          ),
        ),
        (
          game: _ownVsPartnerGame(
            ownProvinces: kFewOldWorldProvincesDefendThreshold + 1,
            partnerProvinces: 10,
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold + 1,
            atWarWith: const [_gpPartner],
          ),
        ),
        (
          game: _ownVsPartnerGame(
            ownProvinces: kObserverConquestMinOwProvincesPerGp,
            partnerProvinces: 12,
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            atWarWith: const [_gpPartner],
          ),
        ),
      ];
      for (final scenario in scenarios) {
        final canonical = criticalOwHoldPeaceTargets(
          game: scenario.game,
          snapshot: scenario.snapshot,
        );
        final delegated = colonial_pressure.criticalOwHoldPeaceTargets(
          game: scenario.game,
          snapshot: scenario.snapshot,
        );
        expect(
          delegated,
          canonical,
          reason:
              'colonial_pressure.criticalOwHoldPeaceTargets must agree '
              'with the canonical expand_phase_planner implementation '
              'across the band table; the delegating stub is the only '
              'live caller path the legacy fixtures and the '
              'diplomacy_planner consumer chain reach until the planned '
              'S1 deletion of colonial_pressure.dart.',
        );
      }
    });

    test(
      'colonial_pressure.stalledBelowQuotaGpLeadPeaceTargets matches canonical',
      () {
        // Pin delegator parity across: quota guard, default-start band
        // (positive + negative), post-default band (positive + negative),
        // and GP-only blocker carve-out (sole-blocker negative +
        // non-blocker positive).
        final scenarios = <({Game game, AIWorldSnapshot snapshot})>[
          (
            game: _ownVsPartnerGame(
              ownProvinces: kObserverConquestMinOwProvincesPerGp,
              partnerProvinces: kObserverConquestMinOwProvincesPerGp + 3,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
              atWarWith: const [_gpPartner],
            ),
          ),
          (
            game: _ownVsPartnerGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              partnerProvinces:
                  kObserverDefaultStartOldWorldProvincesPerGp +
                  kUnwinnableSoleGpMinProvinceDeficit,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpPartner],
            ),
          ),
          (
            game: _ownVsPartnerGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpPartner],
            ),
          ),
          (
            game: _ownVsPartnerGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
              partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 2,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp + 1,
              atWarWith: const [_gpPartner],
            ),
          ),
          (
            game: _ownVsPartnerGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              partnerProvinces:
                  kObserverDefaultStartOldWorldProvincesPerGp +
                  kUnwinnableSoleGpMinProvinceDeficit,
              invadablePartnerProvince: true,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpPartner],
              invadableProvinceIdsSorted: const ['oldWorld|invadable_partner'],
            ),
          ),
          (
            game: _ownVsPartnerGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              partnerProvinces:
                  kObserverDefaultStartOldWorldProvincesPerGp +
                  kUnwinnableSoleGpMinProvinceDeficit,
              invadablePartnerProvince: true,
              extraGpId: _gpThird,
              extraGpProvinces:
                  kObserverDefaultStartOldWorldProvincesPerGp +
                  kUnwinnableSoleGpMinProvinceDeficit,
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpPartner, _gpThird],
              invadableProvinceIdsSorted: const ['oldWorld|invadable_partner'],
            ),
          ),
        ];
        for (final scenario in scenarios) {
          final canonical = stalledBelowQuotaGpLeadPeaceTargets(
            game: scenario.game,
            snapshot: scenario.snapshot,
          );
          final delegated = colonial_pressure
              .stalledBelowQuotaGpLeadPeaceTargets(
                game: scenario.game,
                snapshot: scenario.snapshot,
              );
          expect(
            delegated,
            canonical,
            reason:
                'colonial_pressure.stalledBelowQuotaGpLeadPeaceTargets must '
                'agree with the canonical expand_phase_planner '
                'implementation across the quota guard, the minLeadDeficit '
                'band selector, and the GP-only blocker carve-out — the '
                'delegating stub is the only live caller path the legacy '
                'fixtures and the diplomatic_candidate_scoring_offer_peace '
                'consumer chain reach until the planned S1 deletion of '
                'colonial_pressure.dart.',
          );
        }
      },
    );
  });
}
