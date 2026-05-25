// Pins the canonical `defaultStartFutileMinorPeaceTargets` EXPAND
// default-start futile-minor peace decider in `expand_phase_planner.dart`
// (Refs #2509 S1).
//
// The decider was relocated from `colonial_pressure.dart` so it
// survives the planned S1 deletion of that file. The canonical
// implementation lives in `expand_phase_planner.dart`;
// `colonial_pressure.dart` retains a thin delegating stub for legacy
// callers (the existing `expand_phase_planner_peer_peace_basic_test.dart` §
// `defaultStartFutileMinorPeaceTargets` fixture and the
// `diplomacy_planner.dart` / `diplomacy_planner_peace_targets.dart`
// consumer chain) until the planned deletion.
//
// Live consumer (post-relocation):
//   `defaultStartFutileMinorPeaceTargets` is the EXPAND default-start
//   shortcut that peaces futile minor wars so the planner can pivot
//   off zero-province minor fronts (seed-42 gp4 zero-gain stall).
//   Composes [isOldWorldGpOnlyInvadableFrontier] (canonical band
//   selector) with the observer default-start band table from
//   `SPEC/ai/ai-architecture.md` § Diplomacy targeting.
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. Returns `const []` for each outer guard in order:
//      a. `oldWorldProvincesOwned >= kObserverConquestMinOwProvincesPerGp`
//         (above-quota; quota-met collectors own the decision).
//      b. `oldWorldProvincesOwned > kObserverDefaultStartOldWorldProvincesPerGp + 1`
//         (above the default-start +1 band; near-quota / stalled-band
//         collectors own the decision).
//      c. `invadableProvinceIdsSorted` is empty (no OW invasion target
//         exists this turn so no futile minor war can be diagnosed).
//   2. On the GP-only invadable frontier arm
//      ([isOldWorldGpOnlyInvadableFrontier] true), every at-war minor
//      in `threats.atWarWith` is peaced — returned in ascending lex
//      order over the minor `factionId`s.
//   3. On the mixed minor frontier arm ([isOldWorldGpOnlyInvadableFrontier]
//      false), only at-war minors that own **no** invadable OW
//      province are peaced — minors that own at least one invadable
//      OW province are kept at war (active minor frontier, not
//      futile). Returned in ascending lex order over the minor
//      `factionId`s.
//   4. The delegating stub in `colonial_pressure.dart` returns the
//      same value as the canonical helper for every relevant input —
//      required so the legacy `expand_phase_planner_peer_peace_basic_test.dart` §
//      `defaultStartFutileMinorPeaceTargets` fixture and the
//      `diplomacy_planner_peace_targets.dart` consumer chain agree
//      on the decider.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as colonial_pressure;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpRival = 'gp_rival';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';

/// Builds a minimal `Game` where `gp_own` holds [ownProvinces] OW
/// provinces. When [rivalGpProvinces] > 0 a second Great Power
/// `gp_rival` is added with that many OW provinces. Each minor in
/// [minorOwProvincesByMinorId] owns the listed OW province ids; the
/// listed ids are also the minor's "active" provinces for the
/// invadable scan.
Game _ownGame({
  required int ownProvinces,
  int rivalGpProvinces = 0,
  Map<String, List<String>> minorOwProvincesByMinorId = const {},
  List<String> atWarMinorIds = const [],
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${_gpOwn}_$i',
        regionId: 'oldWorld',
        ownerId: _gpOwn,
      ),
    if (rivalGpProvinces > 0)
      for (var i = 1; i <= rivalGpProvinces; i++)
        Province(
          id: 'oldWorld|${_gpRival}_$i',
          regionId: 'oldWorld',
          ownerId: _gpRival,
        ),
    for (final entry in minorOwProvincesByMinorId.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
  ];

  final players = <Player>[
    const Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
    if (rivalGpProvinces > 0)
      const Player(id: _gpRival, displayName: 'GP_RIVAL', isHuman: false),
  ];

  final minorNations = <MinorNation>[
    for (final id in minorOwProvincesByMinorId.keys)
      MinorNation(id: id, displayName: id),
  ];

  final relations = <DiplomacyRelation>[
    for (final id in atWarMinorIds)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id:
        'g-2509-default-start-futile-minor-canonical-'
        'own$ownProvinces-rival$rivalGpProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
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
  group('defaultStartFutileMinorPeaceTargets — outer guards', () {
    test('returns const [] when above the observer OW quota', () {
      // At-quota gp_own with one at-war minor that owns no invadable OW
      // (futile minor by the mixed-frontier rule), but the above-quota
      // guard fires first so the quota-met collectors own the decision.
      final game = _ownGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        minorOwProvincesByMinorId: const {_minor1: []},
        atWarMinorIds: const [_minor1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const ['oldWorld|future_target'],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Above the observer OW quota the canonical EXPAND default-start '
            'futile-minor pivot must short-circuit so the quota-met '
            'futile-peace collectors take over.',
      );
    });

    test('returns const [] strictly above the default-start +1 band', () {
      // gp_own at kObserverDefaultStartOldWorldProvincesPerGp + 2 — the
      // default-start band is exceeded but still below quota; the
      // near-quota / stalled-band collectors own the decision in that
      // shape.
      const ownOw = kObserverDefaultStartOldWorldProvincesPerGp + 2;
      final game = _ownGame(
        ownProvinces: ownOw,
        minorOwProvincesByMinorId: const {_minor1: []},
        atWarMinorIds: const [_minor1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: ownOw,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const ['oldWorld|gp_target'],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Strictly above the default-start +1 band the decider must '
            'short-circuit so the near-quota / stalled-band collectors '
            'select peace targets instead.',
      );
    });

    test('returns const [] when invadableProvinceIdsSorted is empty', () {
      // gp_own at default-start size with a futile minor in atWarWith but
      // no invadable OW provinces at all — no futile-minor diagnosis is
      // possible so the decider must short-circuit.
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        minorOwProvincesByMinorId: const {_minor1: []},
        atWarMinorIds: const [_minor1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const [],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'With no invadable OW the futile-minor pivot cannot be '
            'diagnosed so the decider must short-circuit.',
      );
    });
  });

  group(
    'defaultStartFutileMinorPeaceTargets — GP-only invadable frontier arm',
    () {
      test(
        'peaces every at-war minor sorted ascending when frontier is GP-only',
        () {
          // gp_own at default-start size with two at-war minors that own
          // zero OW and a GP rival owning the only invadable OW province.
          // isOldWorldGpOnlyInvadableFrontier is true (minor1, minor2 do
          // NOT own the invadable OW; only gp_rival does) so the
          // GP-only arm fires and every at-war minor is peaced. The
          // returned list must be sorted ascending by minor factionId.
          final game = _ownGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            rivalGpProvinces: 1,
            minorOwProvincesByMinorId: const {_minor2: [], _minor1: []},
            atWarMinorIds: const [_minor1, _minor2],
          );
          final snapshot = _ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_minor2, _minor1],
            invadableProvinceIdsSorted: const ['oldWorld|${_gpRival}_1'],
          );
          expect(
            defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
            const [_minor1, _minor2],
            reason:
                'On a GP-only invadable frontier the futile-minor pivot '
                'peaces every at-war minor (no minor pivot remains) and '
                'returns them sorted ascending by factionId.',
          );
        },
      );

      test(
        'returns const [] when no at-war minors are present on GP-only arm',
        () {
          // gp_own at default-start size on a GP-only invadable frontier
          // but with no at-war minors at all — the GP-only arm runs but
          // yields no peace targets.
          final game = _ownGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            rivalGpProvinces: 1,
            atWarMinorIds: const [],
          );
          final snapshot = _ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_gpRival],
            invadableProvinceIdsSorted: const ['oldWorld|${_gpRival}_1'],
          );
          expect(
            defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
            isEmpty,
            reason:
                'With no at-war minors the GP-only arm must return an '
                'empty list — at-war GPs are not in scope for this '
                'futile-minor decider.',
          );
        },
      );

      test('GP-only arm filters non-minor entries out of atWarWith', () {
        // gp_own at default-start size with both a minor and an at-war
        // GP in `atWarWith`. On the GP-only arm, only the minor
        // factionId survives the `game.minorNations.any` filter; the
        // GP must be excluded so the GP arm is not silently broadened.
        final game = _ownGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          rivalGpProvinces: 1,
          minorOwProvincesByMinorId: const {_minor1: []},
          atWarMinorIds: const [_minor1],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_minor1, _gpRival],
          invadableProvinceIdsSorted: const ['oldWorld|${_gpRival}_1'],
        );
        expect(
          defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
          const [_minor1],
          reason:
              'A regression that broadened "at-war minor" to "any at-war '
              'faction" would include gp_rival here, undermining the '
              'EXPAND-phase declare-war push toward the GP blocker.',
        );
      });
    },
  );

  group('defaultStartFutileMinorPeaceTargets — mixed minor frontier arm', () {
    test('peaces only futile minors (no invadable province owned)', () {
      // gp_own at default-start size with two at-war minors: minor1
      // owns one invadable OW province (active minor frontier — keep
      // at war), minor2 owns zero invadable OW (futile minor — peace
      // it). Only minor2 must be in the result.
      const minor1InvadablePid = 'oldWorld|${_minor1}_1';
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        minorOwProvincesByMinorId: const {
          _minor1: [minor1InvadablePid],
          _minor2: [],
        },
        atWarMinorIds: const [_minor1, _minor2],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_minor1, _minor2],
        invadableProvinceIdsSorted: const [minor1InvadablePid],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        const [_minor2],
        reason:
            'On the mixed minor frontier arm only minors that own '
            '*no* invadable OW province are peaced; active-frontier '
            'minors (own at least one invadable OW) must stay at war.',
      );
    });

    test(
      'mixed arm returns ascending-sorted minor ids when many are futile',
      () {
        // Both minors are futile (own no invadable OW); they're listed
        // in `atWarWith` in non-sorted order so the helper's sort is
        // observable. Result must be `[minor1, minor2]` ascending.
        const minorOwnedPid = 'oldWorld|${_minor1}_active';
        final game = _ownGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          minorOwProvincesByMinorId: const {
            _minor1: [],
            _minor2: [],
            'minor3_active': [minorOwnedPid],
          },
          atWarMinorIds: const [_minor2, _minor1],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_minor2, _minor1],
          invadableProvinceIdsSorted: const [minorOwnedPid],
        );
        expect(
          defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
          const [_minor1, _minor2],
          reason:
              'A regression that dropped the trailing sort would emit '
              '[minor2, minor1] here in atWarWith order — the sort '
              'guards downstream deterministic peace-target ordering.',
        );
      },
    );

    test('mixed arm filters non-minor entries out of atWarWith', () {
      // gp_own at default-start size with a futile minor and an
      // at-war GP in atWarWith. On the mixed arm, the GP must be
      // excluded so the helper does not silently broaden to GP
      // wars. The minor and the GP both fail to own an invadable
      // OW (it's owned by a different minor), but only the minor
      // qualifies for peace.
      const otherMinorInvadablePid = 'oldWorld|other_minor_active';
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        rivalGpProvinces: 1,
        minorOwProvincesByMinorId: const {
          _minor1: [],
          'other_minor_active': [otherMinorInvadablePid],
        },
        atWarMinorIds: const [_minor1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_minor1, _gpRival],
        invadableProvinceIdsSorted: const [otherMinorInvadablePid],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        const [_minor1],
        reason:
            'A regression that broadened "at-war minor" to "any at-war '
            'faction without an invadable" would also include '
            'gp_rival, undermining the EXPAND-phase declare-war push.',
      );
    });
  });

  group('defaultStartFutileMinorPeaceTargets — band boundary', () {
    test('includes the default-start +1 band (own == default-start + 1)', () {
      // gp_own at kObserverDefaultStartOldWorldProvincesPerGp + 1, the
      // upper inclusive boundary of the default-start band, must still
      // qualify for the futile-minor pivot. This pins the `<=` band
      // upper bound (`ownOw > default-start + 1` short-circuits).
      const ownOw = kObserverDefaultStartOldWorldProvincesPerGp + 1;
      final game = _ownGame(
        ownProvinces: ownOw,
        minorOwProvincesByMinorId: const {_minor1: []},
        atWarMinorIds: const [_minor1],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: ownOw,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const ['oldWorld|future_target'],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        const [_minor1],
        reason:
            'The upper inclusive boundary of the default-start band '
            '(own == default-start + 1) must still qualify; a '
            'regression that flipped `>` to `>=` would short-circuit '
            'here and leave the futile minor war open.',
      );
    });
  });

  group('defaultStartFutileMinorPeaceTargets — determinism', () {
    test('returns identical lists across three consecutive calls', () {
      // Must-have #7: pure-function determinism. The decider has two
      // arms and a sort; the same `(Game, AIWorldSnapshot)` inputs must
      // always yield the same `List<String>`.
      const minor1InvadablePid = 'oldWorld|${_minor1}_1';
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        minorOwProvincesByMinorId: const {
          _minor1: [minor1InvadablePid],
          _minor2: [],
        },
        atWarMinorIds: const [_minor1, _minor2],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_minor1, _minor2],
        invadableProvinceIdsSorted: const [minor1InvadablePid],
      );
      final first = defaultStartFutileMinorPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = defaultStartFutileMinorPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final third = defaultStartFutileMinorPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        first,
        const [_minor2],
        reason:
            'Canonical decider must return only the futile minor across '
            'every invocation.',
      );
      expect(
        second,
        first,
        reason:
            'Must-have #7: identical inputs must always yield identical '
            'lists (call 2 vs call 1).',
      );
      expect(
        third,
        first,
        reason:
            'Must-have #7: identical inputs must always yield identical '
            'lists (call 3 vs call 1).',
      );
    });
  });

  group('defaultStartFutileMinorPeaceTargets — colonial_pressure delegation '
      'equality scan', () {
    test('colonial_pressure stub mirrors the canonical helper across '
        'GP-only and mixed-frontier fixtures', () {
      // Each fixture exercises one branch of the canonical decider.
      // For each, the canonical helper and the delegating stub in
      // `colonial_pressure.dart` must return identical lists — the
      // legacy `expand_phase_planner_peer_peace_basic_test.dart` fixture and the
      // `diplomacy_planner_peace_targets.dart` consumer chain rely
      // on the equivalence until the planned S1 deletion.
      const minor1InvadablePid = 'oldWorld|${_minor1}_1';
      final fixtures = <({String name, Game game, AIWorldSnapshot snapshot})>[
        (
          name: 'GP-only invadable frontier, two at-war minors',
          game: _ownGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            rivalGpProvinces: 1,
            minorOwProvincesByMinorId: const {_minor1: [], _minor2: []},
            atWarMinorIds: const [_minor1, _minor2],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_minor1, _minor2],
            invadableProvinceIdsSorted: const ['oldWorld|${_gpRival}_1'],
          ),
        ),
        (
          name: 'mixed-frontier, only futile minor peaced',
          game: _ownGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            minorOwProvincesByMinorId: const {
              _minor1: [minor1InvadablePid],
              _minor2: [],
            },
            atWarMinorIds: const [_minor1, _minor2],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_minor1, _minor2],
            invadableProvinceIdsSorted: const [minor1InvadablePid],
          ),
        ),
        (
          name: 'above-quota guard',
          game: _ownGame(
            ownProvinces: kObserverConquestMinOwProvincesPerGp,
            minorOwProvincesByMinorId: const {_minor1: []},
            atWarMinorIds: const [_minor1],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            atWarWith: const [_minor1],
            invadableProvinceIdsSorted: const ['oldWorld|gp_target'],
          ),
        ),
        (
          name: 'above default-start +1 band guard',
          game: _ownGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 2,
            minorOwProvincesByMinorId: const {_minor1: []},
            atWarMinorIds: const [_minor1],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned:
                kObserverDefaultStartOldWorldProvincesPerGp + 2,
            atWarWith: const [_minor1],
            invadableProvinceIdsSorted: const ['oldWorld|gp_target'],
          ),
        ),
        (
          name: 'empty invadable list guard',
          game: _ownGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            minorOwProvincesByMinorId: const {_minor1: []},
            atWarMinorIds: const [_minor1],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_minor1],
            invadableProvinceIdsSorted: const [],
          ),
        ),
      ];

      for (final fx in fixtures) {
        final canonical = defaultStartFutileMinorPeaceTargets(
          game: fx.game,
          snapshot: fx.snapshot,
        );
        final stub = colonial_pressure.defaultStartFutileMinorPeaceTargets(
          game: fx.game,
          snapshot: fx.snapshot,
        );
        expect(
          stub,
          canonical,
          reason:
              'Delegating stub must mirror the canonical helper for '
              'fixture "${fx.name}".',
        );
      }
    });
  });
}
