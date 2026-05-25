// Pins the canonical `belowQuotaPeerGpPeaceTargets` below-quota
// peer-stalled peace decider in `expand_phase_planner.dart`
// (Refs #2509 S1).
//
// The decider was relocated from `colonial_pressure.dart` so it
// survives the planned S1 deletion of that file. The canonical
// implementation lives in `expand_phase_planner.dart`;
// `colonial_pressure.dart` retains a thin delegating stub for legacy
// callers (the existing `colonial_pressure_test.dart` and
// `colonial_pressure_peer_gap_boundary_test.dart` fixtures, the
// `diplomacy_planner.dart` /
// `diplomacy_planner_peace_targets.dart` /
// `diplomatic_candidate_scoring_offer_peace.dart` consumer chain).
//
// The decider implements the EXPAND-phase "peace other below-quota
// Great Power peers in peer-stalled wars while at least one OW minor
// still owns provinces on the map" pivot for seed-42 gp5/gp6 (the
// mutual gp5/gp6 distraction wars). It composes the canonical
// EXPAND helpers `isOldWorldGpOnlyInvadableFrontier`,
// `soleAtWarGreatPowerId`, `isMutualBelowQuotaPlateauPeer`, and
// `hasUninvadedOldWorldMinor` with the below-quota peer-gap band
// table from `SPEC/ai/ai-architecture.md` § Observer goal phases
// (EXPAND) "While uninvaded OW minors remain, also peace below-quota
// GP peers within three provinces".
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. Outer-quota guard — when the active player is at or above the
//      observer OW quota the decider returns `const []` regardless of
//      partner OW (the quota-met futile-peace collectors own that
//      shape).
//   2. No-minors-no-mutual-plateau guard — when no minor owns OW
//      provinces and the war is not a mutual-plateau peer, the
//      partner is skipped (no peer-gap pivot off a pure GP-only
//      stalemate).
//   3. Mutual-plateau GP-only-frontier carve-out — when the war is a
//      mutual-plateau sole-GP stalemate on a GP-only invadable
//      frontier with no uninvaded OW minors remaining, the partner
//      is peaced unconditionally.
//   4. Symmetric OW-gap cap — `(partnerOw - ownOw).abs() <= 3`
//      pivots when an uninvaded minor pivot remains, `<= 1` otherwise.
//   5. Stronger-self symmetry guard — `!mutualPlateau && ownOw >
//      partnerOw` skips the partner (only the weaker peer pivots off
//      the distraction war).
//   6. Sole-GP-blocker hold-open — on a GP-only invadable frontier
//      with the partner as the sole at-war GP and no uninvaded
//      minor pivot remaining, the war is held open (the partner is
//      skipped, even when the OW gap is within the cap).
//   7. Deterministic ordering — multi-peer results are sorted
//      ascending by `factionId`.
//   8. The delegating stub in `colonial_pressure.dart` returns the
//      same value as the canonical helper for every relevant input —
//      required so the legacy `colonial_pressure_test.dart` and
//      `colonial_pressure_peer_gap_boundary_test.dart` fixtures and
//      the in-file consumer paths agree on the decider.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as colonial_pressure;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpPartner = 'gp_partner';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';

/// Builds a minimal `Game` exposing the OW province distribution this
/// decider's branches rely on:
///
///   * `gp_own` owns [ownProvinces] OW provinces.
///   * `gp_partner` owns [partnerProvinces] OW provinces (always
///     present when [partnerProvinces] > 0). Optional extra GP via
///     [extraGpId] / [extraGpProvinces] for multi-GP-war shapes.
///   * Optional minor `minorId` owns [minorProvinces] OW provinces
///     so `hasUninvadedOldWorldMinor` and `minorsOnMap` can be
///     toggled independently of the at-war set.
///   * Diplomacy relations: `gp_own` is at war with `gp_partner`
///     when [atWarWithPartner] is true; with the optional extra GP
///     when [atWarWithExtraGp] is true; with the minor when
///     [atWarWithMinor] is true.
Game _peerGame({
  required int ownProvinces,
  required int partnerProvinces,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? minorId,
  int minorProvinces = 0,
  bool atWarWithPartner = true,
  bool atWarWithExtraGp = true,
  bool atWarWithMinor = false,
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
        id: 'oldWorld|${_gpPartner}_$i',
        regionId: 'oldWorld',
        ownerId: _gpPartner,
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
  ];

  final players = <Player>[
    const Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
    const Player(id: _gpPartner, displayName: 'GP_PARTNER', isHuman: false),
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
      const DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: _gpPartner,
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
    if (minorId != null && atWarWithMinor)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: minorId,
        state: RelationState.atWar,
        score: 10,
      ),
  ];

  return Game(
    id:
        'g-2509-below-quota-peer-gp-peace-canonical-'
        '${ownProvinces}_vs_$partnerProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
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
  group('belowQuotaPeerGpPeaceTargets — outer guards', () {
    test('returns empty when active player is at or above the OW quota', () {
      // own = 10 (observer quota) places the planner in quota-met
      // territory; the quota-met futile-peace collectors own that
      // shape. The canonical decider must short-circuit before the
      // peer-gap branches even when partner is below quota and a
      // minor still owns provinces (so a regression that flipped the
      // guard polarity would fire).
      final game = _peerGame(
        ownProvinces: 10,
        partnerProvinces: 7,
        minorId: _minor1,
        minorProvinces: 1,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 10,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'isBelowObserverConquestQuota(10) is false; canonical EXPAND '
            'below-quota peer-stalled decider defers to the quota-met '
            'collectors and must not peace any peer here.',
      );
    });

    test(
      'returns empty when no minor owns OW provinces and war is not mutual-plateau',
      () {
        // own=6, partner=8 → not a mutual-plateau (own at 6 is
        // below the 8 OW plateau band). minorsOnMap is false because
        // no minor owns any OW province. The combined "!minorsOnMap
        // && !mutualPlateau" guard must skip every peer, leaving
        // the result empty.
        final game = _peerGame(ownProvinces: 6, partnerProvinces: 8);
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpPartner],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'No on-map minor and no mutual-plateau peer; the canonical '
              'decider must not peace a pure GP-only peer stalemate '
              'without the minor pivot.',
        );
      },
    );

    test('skips at-war minors and tribes (Great Powers only)', () {
      // The decider filters non-GP factions via game.playerById. A
      // minor included in atWarWith must never be returned even
      // when other guards pass — peer-gap is a GP-only pivot.
      final game = _peerGame(
        ownProvinces: 6,
        partnerProvinces: 7,
        minorId: _minor1,
        minorProvinces: 1,
        atWarWithMinor: true,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpPartner, _minor1],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      final result = belowQuotaPeerGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        result,
        isNot(contains(_minor1)),
        reason:
            'Minors must be filtered out by Game.playerById; the canonical '
            'decider is GP-only and must never emit minor ids in the peer '
            'list.',
      );
    });
  });

  group('belowQuotaPeerGpPeaceTargets — partner-quota guard', () {
    test('skips partner that is at or above the OW quota', () {
      // partner=10 (observer quota) keeps the partner in
      // quota-met territory; the canonical below-quota decider only
      // peaces below-quota peer GPs. The OW gap is within the
      // mutual-plateau peer-gap cap but the quota guard must trip
      // first.
      final game = _peerGame(
        ownProvinces: 8,
        partnerProvinces: 10,
        minorId: _minor1,
        minorProvinces: 1,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 8,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Partner sits at the observer quota and is not a below-quota '
            'peer; the canonical decider must keep the war open for the '
            'multi-front collectors above the quota.',
      );
    });
  });

  group('belowQuotaPeerGpPeaceTargets — mutual-plateau carve-out', () {
    test(
      'peaces mutual-plateau peer on GP-only frontier when no uninvaded minor remains',
      () {
        // own=8, partner=8 → mutual-plateau (both in the 8 OW
        // plateau band). The single on-map minor is at war with
        // gp_own so it counts toward minorsOnMap but is filtered
        // out of hasUninvadedOldWorldMinor. The only invadable
        // province is the at-war minor's province but it's owned
        // by an at-war minor so hasUninvadedOldWorldMinor is
        // false. The GP-only-invadable-frontier arm fires because
        // every invadable belongs to a non-minor and the lone
        // partner gp_partner owns it. The carve-out short-circuit
        // must peace the partner unconditionally — even though the
        // gap=0 would also satisfy the standard peer-gap arm, the
        // carve-out documents an independent code path.
        final game = _peerGame(
          ownProvinces: 8,
          partnerProvinces: 8,
          minorId: _minor1,
          minorProvinces: 0,
          atWarWithMinor: true,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const [_gpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|${_gpPartner}_1'],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          [_gpPartner],
          reason:
              'Mutual-plateau peer at gap=0 on a GP-only invadable '
              'frontier with no uninvaded OW minor remaining — the '
              'canonical decider must take the carve-out branch and peace '
              'the lone partner to exit the stalemate.',
        );
      },
    );
  });

  group('belowQuotaPeerGpPeaceTargets — peer-gap cap', () {
    test('peaces partner at 3-province gap when uninvaded minor remains', () {
      // own=6, partner=9 → gap=3 inside the
      // _kMaxPeerOwGapWithMinors=3 ceiling. The on-map minor still
      // owns a province AND is not at war, so
      // hasUninvadedOldWorldMinor is true. The canonical decider
      // must peace the partner so gp_own can pivot off the
      // distraction war and chase the minor frontier instead.
      final game = _peerGame(
        ownProvinces: 6,
        partnerProvinces: 9,
        minorId: _minor1,
        minorProvinces: 1,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpPartner],
        reason:
            'Minor pivot remains and gap=3 is within the canonical peer-gap '
            'cap (3 with minors). Partner must be peaced.',
      );
    });

    test(
      'skips partner at 4-province gap even when uninvaded minor remains',
      () {
        // own=5, partner=9 → gap=4 strictly exceeds the
        // _kMaxPeerOwGapWithMinors=3 ceiling. The decider must
        // keep the war open even though a minor pivot remains —
        // the cap protects the weaker peer from dumping below-quota
        // GP wars at arbitrary OW gaps.
        final game = _peerGame(
          ownProvinces: 5,
          partnerProvinces: 9,
          minorId: _minor1,
          minorProvinces: 1,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 5,
          atWarWith: const [_gpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Gap=4 exceeds the canonical 3-province cap with minors; '
              'partner stays at war so the weaker peer cannot dump GP wars '
              'at arbitrary OW gaps.',
        );
      },
    );

    test(
      'peaces partner at 1-province gap when no uninvaded minor remains',
      () {
        // own=7, partner=8 → gap=1 inside the tighter
        // _kMaxPeerOwGapWithoutMinors=1 ceiling. The on-map minor
        // is already at war with gp_own so minorsOnMap is true
        // (for the !minorsOnMap guard) but
        // hasUninvadedOldWorldMinor is false (the only minor is
        // already at war). The canonical decider must still peace
        // the partner — the partner's invadable province also
        // happens to belong to a non-minor so the GP-only frontier
        // arm would fire too, but the gap=1 standard arm must be
        // the path that produces the result here.
        final game = _peerGame(
          ownProvinces: 7,
          partnerProvinces: 8,
          minorId: _minor1,
          minorProvinces: 1,
          atWarWithMinor: true,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_gpPartner, _minor1],
          invadableProvinceIdsSorted: const ['oldWorld|${_gpPartner}_1'],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          contains(_gpPartner),
          reason:
              'Minor on-map but already at war; the canonical decider '
              'collapses maxPeerOwGap to 1 and must still peace the '
              'partner at gap=1.',
        );
      },
    );

    test('skips partner at 2-province gap when no uninvaded minor remains', () {
      // own=6, partner=8 → gap=2 strictly exceeds the
      // _kMaxPeerOwGapWithoutMinors=1 ceiling once the minor
      // pivot is gone. This pins the asymmetric collapse: the
      // canonical decider must drop the partner even though the
      // gap would be within the with-minors cap.
      final game = _peerGame(
        ownProvinces: 6,
        partnerProvinces: 8,
        minorId: _minor1,
        minorProvinces: 1,
        atWarWithMinor: true,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpPartner, _minor1],
        invadableProvinceIdsSorted: const ['oldWorld|${_gpPartner}_1'],
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        isNot(contains(_gpPartner)),
        reason:
            'No uninvaded minor pivot remains; the canonical cap '
            'collapses to 1 and gap=2 must be dropped.',
      );
    });
  });

  group('belowQuotaPeerGpPeaceTargets — symmetry guard', () {
    test(
      'skips stronger self at 3-province gap even when minor pivot remains',
      () {
        // own=9, partner=6 → gap=3 (within cap) but ownOw >
        // partnerOw and not a mutual-plateau. The
        // stronger-self-symmetry guard must drop the partner;
        // only the weaker peer pivots off the distraction war.
        final game = _peerGame(
          ownProvinces: 9,
          partnerProvinces: 6,
          minorId: _minor1,
          minorProvinces: 1,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 9,
          atWarWith: const [_gpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Stronger self with !mutualPlateau is not peaced; only the '
              'weaker peer pivots off the distraction war per the canonical '
              'symmetry guard.',
        );
      },
    );

    test(
      'peaces equal-strength peer at 0-province gap when not a mutual-plateau',
      () {
        // own=6, partner=6 → gap=0 with !mutualPlateau (both
        // outside the 8 OW plateau band). The stronger-self guard
        // tests `ownOw > partnerOw` — at strict equality the
        // guard does not fire and the partner is peaced.
        final game = _peerGame(
          ownProvinces: 6,
          partnerProvinces: 6,
          minorId: _minor1,
          minorProvinces: 1,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
        );
        expect(
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          [_gpPartner],
          reason:
              'Equal-strength peer is not subject to the stronger-self '
              'guard (strict >); the canonical decider must peace the '
              'partner so a tie does not regress into a held-open war.',
        );
      },
    );
  });

  group('belowQuotaPeerGpPeaceTargets — sole-GP-blocker hold-open', () {
    // The sole-GP-blocker hold-open arm
    //     if (gpOnlyFrontier && soleGpWar == factionId &&
    //         !hasUninvadedOldWorldMinor) continue;
    // is intentionally preserved by the canonical move for
    // byte-equivalence with the legacy `colonial_pressure.dart`
    // body, but it is shadowed by the mutual-plateau carve-out
    // short-circuit (and the symmetric peer-gap cap) on every input
    // currently reachable through this function: when
    // `hasUninvadedOldWorldMinor` is `false` the cap collapses to
    // `_kMaxPeerOwGapWithoutMinors` (1), forcing `gap ≤ 1`; both
    // ownOw and partnerOw must be `< kObserverConquestMinOwProvincesPerGp`
    // (10) per the outer below-quota guards and the partner-quota
    // check, so both are in the 1–9 stalled band; that combination
    // makes `isMutualBelowQuotaPlateauPeer` true; the carve-out
    // therefore fires and adds the partner before the hold-open
    // line is ever reached. The "peaces mutual-plateau peer on
    // GP-only frontier when no uninvaded minor remains" test
    // already pins that adjacent shape. The hold-open guard is
    // kept here as a documented branch for the future S5
    // deletion slice — when the orchestrator and aggregate
    // collectors are rewritten and the carve-out is retired, the
    // guard becomes reachable again and any regression that
    // re-enables peer-stalled peace on a sole-GP-blocker war
    // would surface there. No active-reachability test is added
    // for the existing carve-out-fires path; doing so would
    // duplicate the carve-out test.
  });

  group('belowQuotaPeerGpPeaceTargets — multi-peer ordering', () {
    test('returns peaced peers sorted ascending by factionId', () {
      // Two below-quota peer GPs both inside the cap; the result
      // must be sorted ascending. Use gp_partner and gp_third
      // with gp_third lex-greater than gp_partner so a regression
      // that preserved threats.atWarWith order would still pass
      // accidentally; we want to assert sort order.
      final game = _peerGame(
        ownProvinces: 6,
        partnerProvinces: 7,
        extraGpId: _gpThird,
        extraGpProvinces: 7,
        minorId: _minor1,
        minorProvinces: 1,
      );
      // Wire snapshot in reverse-sort order so the sort step has
      // to actually re-order the result.
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpThird, _gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      expect(
        belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpPartner, _gpThird],
        reason:
            'Multi-peer result must be sorted ascending by factionId '
            '(deterministic; Must-have #7). A regression preserving '
            'threats.atWarWith order would emit [gp_third, gp_partner].',
      );
    });
  });

  group('belowQuotaPeerGpPeaceTargets — determinism (Must-have #7)', () {
    test('returns identical lists for identical inputs across two calls', () {
      final game = _peerGame(
        ownProvinces: 6,
        partnerProvinces: 7,
        minorId: _minor1,
        minorProvinces: 1,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
      );
      final first = belowQuotaPeerGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = belowQuotaPeerGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        second,
        first,
        reason:
            'Pure function — two invocations on the same (Game, snapshot) '
            'must return equal lists (Refs #2509 Must-have #7).',
      );
    });
  });

  group('belowQuotaPeerGpPeaceTargets — delegating stub agreement', () {
    test(
      'colonial_pressure.belowQuotaPeerGpPeaceTargets matches the canonical helper '
      'across the with-minors-pivot peer-gap-3 input',
      () {
        // Same input as the with-minors peer-gap-3 case above. The
        // canonical helper and the colonial_pressure delegating
        // stub must agree byte-for-byte so the planned S1 deletion
        // of colonial_pressure.dart is a safe one-line removal,
        // not a behavioral change.
        final game = _peerGame(
          ownProvinces: 6,
          partnerProvinces: 9,
          minorId: _minor1,
          minorProvinces: 1,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_1'],
        );
        expect(
          colonial_pressure.belowQuotaPeerGpPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          reason:
              'colonial_pressure.dart must remain a thin delegating stub '
              'until S1 deletion; agreement with the canonical helper is '
              'required so the legacy fixtures continue resolving to the '
              'same behavior.',
        );
      },
    );

    test(
      'colonial_pressure.belowQuotaPeerGpPeaceTargets matches the canonical helper '
      'across the no-minors-no-mutual-plateau guard input',
      () {
        // Distinct guard branch from the test above so the
        // delegation invariant is checked on both an inside-cap
        // and an outer-guard input.
        final game = _peerGame(ownProvinces: 6, partnerProvinces: 8);
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [_gpPartner],
        );
        expect(
          colonial_pressure.belowQuotaPeerGpPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
          reason:
              'Outer-guard agreement: the delegating stub must short-circuit '
              'to the same empty list as the canonical helper.',
        );
      },
    );
  });
}
