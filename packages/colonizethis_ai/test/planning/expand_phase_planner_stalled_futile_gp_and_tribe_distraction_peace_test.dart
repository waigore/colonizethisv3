// Pins the canonical `stalledFutileGpPeaceTargets` and
// `atWarGpDistractionTribePeaceTargets` EXPAND-stalled peace deciders in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from
// `diplomacy_planner_peace_targets.dart` so they survive the planned
// S1 deletion of that file. The canonical implementations live in
// `expand_phase_planner.dart`; `diplomacy_planner_peace_targets.dart`
// previously retained thin delegating stubs for legacy callers (the existing
// `diplomacy_planner_stalled_peace_test.dart` § `stalledFutileGpPeaceTargets`
// fixture and the `_expandRatchetGreatPowerPeaceTargets` /
// `collectStalledGreatPowerPeaceTargets` /
// `stalledOwExpansionNeedsPeacePass` consumer chains within
// `diplomacy_planner_peace_targets.dart` itself) until the planned
// deletion.
//
// Live consumers (post-relocation):
//   * `stalledFutileGpPeaceTargets` is the EXPAND-stalled shortcut
//     that peaces every at-war Great Power that owns no invadable OW
//     province while at least one minor still holds invadable land,
//     so regiments concentrate on the active minor frontier.
//   * `atWarGpDistractionTribePeaceTargets` is the EXPAND-stalled
//     shortcut that peaces every at-war tribe while at least one
//     Great Power is on the same map, so regiments concentrate on
//     the OW consolidation push instead of bleeding into tribe
//     fronts.
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
// `stalledFutileGpPeaceTargets`:
//   1. Returns `const []` for each outer guard in order:
//      a. `!isStalledOldWorldExpansion(oldWorldProvincesOwned)`
//         — above the stalled OW band the above-quota collectors
//         own the decision.
//      b. `invadableProvinceIdsSorted` is empty — no OW invasion
//         target so a futile-GP diagnosis cannot fire.
//      c. No minor owns any invadable OW province — the frontier
//         is GP-only / unowned, so the
//         `stalledGpBlockerFocusPeaceTargets` collector owns the
//         decision instead.
//   2. When the guards pass, every at-war Great Power in
//      `threats.atWarWith` (filtered via `Game.playerById`) that
//      owns **no** province in `invadableProvinceIdsSorted` is
//      peaced; GPs that own at least one invadable OW province are
//      kept at war (active blockers). Returned in ascending lex
//      order over the GP `factionId`s.
//
// `atWarGpDistractionTribePeaceTargets`:
//   1. Returns `const []` for each outer guard in order:
//      a. `!isStalledOldWorldExpansion(oldWorldProvincesOwned)`
//         — above the stalled OW band the GP-distraction tribe
//         shortcut does not apply.
//      b. No at-war Great Power present in `threats.atWarWith` —
//         without an active GP front the tribe peace is not
//         justified.
//   2. When the guards pass, every at-war tribe in
//      `threats.atWarWith` (membership tested via `Game.tribes`)
//      is peaced. Minors and at-war Great Powers are filtered out.
//      Returned in ascending lex order over the tribe `factionId`s.
//
// Delegation parity:
//   3. The delegating stubs in
//      `diplomacy_planner_peace_targets.dart` return the same
//      values as the canonical helpers for every relevant input —
//      required so the legacy `diplomacy_planner_stalled_peace_test.dart`
//      fixture and the `_expandRatchetGreatPowerPeaceTargets` /
//      `collectStalledGreatPowerPeaceTargets` consumer chains agree
//      on both deciders.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpRivalA = 'gp_rival_a';
const String _gpRivalB = 'gp_rival_b';
const String _minor1 = 'minor1';
const String _tribeA = 'tribe_a';
const String _tribeB = 'tribe_b';

/// Builds a minimal `Game` where `gp_own` holds [ownProvinces] OW
/// provinces. [gpRivalProvincesById] adds one Great Power per entry
/// owning the listed OW province ids. [minorOwProvincesByMinorId]
/// registers each minor as a `MinorNation` and assigns the listed OW
/// province ids to them. [tribeIds] registers each id as a `Tribe`.
/// [atWarFactionIds] adds an `atWar` `DiplomacyRelation` for each
/// listed faction id (works for GPs, minors, and tribes uniformly).
Game _ownGame({
  required int ownProvinces,
  Map<String, List<String>> gpRivalProvincesById = const {},
  Map<String, List<String>> minorOwProvincesByMinorId = const {},
  List<String> tribeIds = const [],
  List<String> atWarFactionIds = const [],
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${_gpOwn}_$i',
        regionId: 'oldWorld',
        ownerId: _gpOwn,
      ),
    for (final entry in gpRivalProvincesById.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
    for (final entry in minorOwProvincesByMinorId.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
  ];

  final players = <Player>[
    const Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
    for (final id in gpRivalProvincesById.keys)
      Player(id: id, displayName: id, isHuman: false),
  ];

  final minorNations = <MinorNation>[
    for (final id in minorOwProvincesByMinorId.keys)
      MinorNation(id: id, displayName: id),
  ];

  final tribes = <Tribe>[
    for (final id in tribeIds) Tribe(id: id, displayName: id),
  ];

  final relations = <DiplomacyRelation>[
    for (final id in atWarFactionIds)
      DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id:
        'g-2509-stalled-futile-gp-and-tribe-distraction-canonical-'
        'own$ownProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
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
  group('stalledFutileGpPeaceTargets — outer guards', () {
    test('returns const [] above the stalled OW band (own == quota)', () {
      // gp_own at the observer OW quota — isStalledOldWorldExpansion is
      // false so the canonical decider must short-circuit before the
      // futile-GP scan.
      final game = _ownGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        gpRivalProvincesById: const {
          _gpRivalA: ['oldWorld|${_gpRivalA}_target'],
        },
        minorOwProvincesByMinorId: const {
          _minor1: ['oldWorld|${_minor1}_active'],
        },
        atWarFactionIds: const [_gpRivalA],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_gpRivalA],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_active'],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At the observer OW quota the stalled-OW guard must fire '
            'and short-circuit the futile-GP pivot so the quota-met '
            'collectors take over.',
      );
    });

    test('returns const [] when invadableProvinceIdsSorted is empty', () {
      // gp_own in the stalled band with an at-war GP but no invadable OW
      // — the empty-invadable guard must short-circuit.
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        gpRivalProvincesById: const {_gpRivalA: []},
        minorOwProvincesByMinorId: const {_minor1: []},
        atWarFactionIds: const [_gpRivalA],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpRivalA],
        invadableProvinceIdsSorted: const [],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'No invadable OW means a futile-GP pivot cannot be diagnosed '
            'this turn; the decider must short-circuit before the '
            'province-owner scan.',
      );
    });

    test('returns const [] when no minor owns any invadable OW province', () {
      // gp_own in the stalled band, at war with a GP, but the only
      // invadable OW province is GP-owned (no minor on the invadable
      // frontier). The minorsOwnInvadable guard must short-circuit so
      // the stalledGpBlockerFocus collector owns the decision instead.
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        gpRivalProvincesById: const {
          _gpRivalA: ['oldWorld|${_gpRivalA}_target'],
          _gpRivalB: [],
        },
        atWarFactionIds: const [_gpRivalA, _gpRivalB],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpRivalA, _gpRivalB],
        invadableProvinceIdsSorted: const ['oldWorld|${_gpRivalA}_target'],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'A GP-only invadable frontier is not a futile-GP pivot — '
            'the stalledGpBlockerFocus collector handles that shape '
            'instead, so this decider must short-circuit.',
      );
    });
  });

  group('stalledFutileGpPeaceTargets — futile-GP fire path', () {
    test(
      'peaces every at-war GP that owns no invadable OW (sorted ascending)',
      () {
        // gp_own in the stalled band; a minor (minor1) holds the
        // invadable OW province (mixed frontier). gp_rival_b is also
        // at war but owns NONE of the invadable provinces (futile —
        // peace it). gp_rival_a is at war and owns one of the
        // invadable provinces (active blocker — keep at war). Result
        // must be exactly [gp_rival_b] (gp_rival_a filtered out).
        const minor1Pid = 'oldWorld|${_minor1}_active';
        const rivalAPid = 'oldWorld|${_gpRivalA}_blocker';
        final game = _ownGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          gpRivalProvincesById: const {
            _gpRivalA: [rivalAPid],
            _gpRivalB: [],
          },
          minorOwProvincesByMinorId: const {
            _minor1: [minor1Pid],
          },
          atWarFactionIds: const [_gpRivalA, _gpRivalB],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_gpRivalB, _gpRivalA],
          invadableProvinceIdsSorted: const [minor1Pid, rivalAPid],
        );
        expect(
          stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gpRivalB],
          reason:
              'A regression that broadened "futile GP" to "every at-war '
              'GP" would also include gp_rival_a here, dropping the '
              'active OW frontier blocker from the war.',
        );
      },
    );

    test('fire path filters minors and tribes out of atWarWith', () {
      // gp_own in the stalled band, mixed frontier (minor holds
      // invadable). atWarWith contains a futile GP, a minor, and a
      // tribe. Only the GP must surface — minors and tribes have
      // their own dedicated peace deciders.
      const minor1Pid = 'oldWorld|${_minor1}_active';
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        gpRivalProvincesById: const {_gpRivalA: []},
        minorOwProvincesByMinorId: const {
          _minor1: [minor1Pid],
        },
        tribeIds: const [_tribeA],
        atWarFactionIds: const [_gpRivalA, _minor1, _tribeA],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpRivalA, _minor1, _tribeA],
        invadableProvinceIdsSorted: const [minor1Pid],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gpRivalA],
        reason:
            'A regression that broadened the filter to "any at-war '
            'faction without an invadable OW" would include minor1 '
            'and tribe_a, double-peacing them with the dedicated '
            'minor / tribe collectors.',
      );
    });

    test('fire path returns ascending-sorted GP ids when many are futile', () {
      // Two futile GPs (own no invadable OW) listed in atWarWith in
      // non-sorted order. Result must be ascending [gp_rival_a,
      // gp_rival_b].
      const minor1Pid = 'oldWorld|${_minor1}_active';
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        gpRivalProvincesById: const {_gpRivalA: [], _gpRivalB: []},
        minorOwProvincesByMinorId: const {
          _minor1: [minor1Pid],
        },
        atWarFactionIds: const [_gpRivalA, _gpRivalB],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpRivalB, _gpRivalA],
        invadableProvinceIdsSorted: const [minor1Pid],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gpRivalA, _gpRivalB],
        reason:
            'A regression that dropped the trailing sort would emit '
            '[gp_rival_b, gp_rival_a] in atWarWith order, breaking '
            'downstream deterministic peace-target ordering.',
      );
    });
  });

  group('stalledFutileGpPeaceTargets — band boundaries', () {
    test('fires at the upper inclusive boundary of the stalled OW band', () {
      // own == kStalledOldWorldProvinceThreshold (still stalled).
      // The decider must run normally and surface the futile GP.
      const minor1Pid = 'oldWorld|${_minor1}_active';
      final game = _ownGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        gpRivalProvincesById: const {_gpRivalA: []},
        minorOwProvincesByMinorId: const {
          _minor1: [minor1Pid],
        },
        atWarFactionIds: const [_gpRivalA],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [_gpRivalA],
        invadableProvinceIdsSorted: const [minor1Pid],
      );
      expect(
        stalledFutileGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gpRivalA],
        reason:
            'A regression that flipped the stalled-OW guard to a '
            'strict-less-than would short-circuit at the upper '
            'inclusive boundary and leave the futile GP war open.',
      );
    });
  });

  group('atWarGpDistractionTribePeaceTargets — outer guards', () {
    test('returns const [] above the stalled OW band (own == quota)', () {
      // gp_own at the observer OW quota with an at-war GP and an
      // at-war tribe. The stalled-OW guard must fire so the tribe
      // peace shortcut does not apply (above-quota collectors own
      // the decision).
      final game = _ownGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        gpRivalProvincesById: const {_gpRivalA: []},
        tribeIds: const [_tribeA],
        atWarFactionIds: const [_gpRivalA, _tribeA],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_gpRivalA, _tribeA],
      );
      expect(
        atWarGpDistractionTribePeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Above the stalled OW band the canonical decider must '
            'short-circuit so quota-met collectors govern tribe '
            'peace decisions.',
      );
    });

    test('returns const [] when no Great Power is in atWarWith', () {
      // gp_own in the stalled band with an at-war tribe but no GP
      // war — the GP-distraction precondition must fire and
      // short-circuit. (Without an active GP front the tribe peace
      // is not justified.)
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        tribeIds: const [_tribeA],
        atWarFactionIds: const [_tribeA],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_tribeA],
      );
      expect(
        atWarGpDistractionTribePeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Without an active GP front the GP-distraction tribe '
            'peace shortcut does not apply; the decider must '
            'short-circuit.',
      );
    });
  });

  group('atWarGpDistractionTribePeaceTargets — fire path', () {
    test(
      'peaces every at-war tribe sorted ascending when GP front is active',
      () {
        // gp_own in the stalled band, at war with one GP and two
        // tribes. Tribes must be peaced in ascending lex order, the GP
        // must be filtered out (handled by GP-blocker / consolidate
        // collectors elsewhere).
        final game = _ownGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          gpRivalProvincesById: const {_gpRivalA: []},
          tribeIds: const [_tribeA, _tribeB],
          atWarFactionIds: const [_gpRivalA, _tribeA, _tribeB],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_tribeB, _tribeA, _gpRivalA],
        );
        expect(
          atWarGpDistractionTribePeaceTargets(game: game, snapshot: snapshot),
          const [_tribeA, _tribeB],
          reason:
              'A regression that dropped the sort would emit '
              '[tribe_b, tribe_a] in atWarWith order; one that '
              'broadened "tribe" to "any non-GP faction" would also '
              'include gp_rival_a or minors.',
        );
      },
    );

    test('fire path filters minors out of atWarWith', () {
      // gp_own in the stalled band, at war with a GP, a minor, and a
      // tribe. Only the tribe must surface — the GP is filtered as
      // a non-distraction front and the minor is routed through the
      // dedicated minor peace collectors.
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        gpRivalProvincesById: const {_gpRivalA: []},
        minorOwProvincesByMinorId: const {_minor1: []},
        tribeIds: const [_tribeA],
        atWarFactionIds: const [_gpRivalA, _minor1, _tribeA],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpRivalA, _minor1, _tribeA],
      );
      expect(
        atWarGpDistractionTribePeaceTargets(game: game, snapshot: snapshot),
        const [_tribeA],
        reason:
            'Minors must not surface here — they have dedicated '
            'minor peace deciders and double-peacing distorts '
            'the EXPAND OW push.',
      );
    });

    test('fire path returns const [] when only a GP is at war (no tribes)', () {
      // gp_own in the stalled band, at war with a GP only. The GP
      // front is active so the precondition fires, but there are
      // no tribes in atWarWith so the result is the empty list.
      final game = _ownGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        gpRivalProvincesById: const {_gpRivalA: []},
        tribeIds: const [_tribeA],
        atWarFactionIds: const [_gpRivalA],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpRivalA],
      );
      expect(
        atWarGpDistractionTribePeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Without an at-war tribe the fire path returns the '
            'empty list even with the GP front active.',
      );
    });
  });

  group('canonical determinism (Must-have #7)', () {
    test(
      'stalledFutileGpPeaceTargets returns identical lists across calls',
      () {
        const minor1Pid = 'oldWorld|${_minor1}_active';
        final game = _ownGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          gpRivalProvincesById: const {
            _gpRivalA: ['oldWorld|${_gpRivalA}_blocker'],
            _gpRivalB: [],
          },
          minorOwProvincesByMinorId: const {
            _minor1: [minor1Pid],
          },
          atWarFactionIds: const [_gpRivalA, _gpRivalB],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_gpRivalB, _gpRivalA],
          invadableProvinceIdsSorted: const [
            minor1Pid,
            'oldWorld|${_gpRivalA}_blocker',
          ],
        );
        final first = stalledFutileGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = stalledFutileGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final third = stalledFutileGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(
          first,
          const [_gpRivalB],
          reason:
              'Canonical decider must return only the futile GP across '
              'every invocation.',
        );
        expect(
          second,
          first,
          reason:
              'Must-have #7: identical inputs must always yield '
              'identical lists (call 2 vs call 1).',
        );
        expect(
          third,
          first,
          reason:
              'Must-have #7: identical inputs must always yield '
              'identical lists (call 3 vs call 1).',
        );
      },
    );

    test(
      'atWarGpDistractionTribePeaceTargets returns identical lists across calls',
      () {
        final game = _ownGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          gpRivalProvincesById: const {_gpRivalA: []},
          tribeIds: const [_tribeA, _tribeB],
          atWarFactionIds: const [_gpRivalA, _tribeA, _tribeB],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_tribeB, _gpRivalA, _tribeA],
        );
        final first = atWarGpDistractionTribePeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = atWarGpDistractionTribePeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final third = atWarGpDistractionTribePeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(
          first,
          const [_tribeA, _tribeB],
          reason:
              'Canonical decider must return both at-war tribes sorted '
              'ascending across every invocation.',
        );
        expect(
          second,
          first,
          reason:
              'Must-have #7: identical inputs must always yield '
              'identical lists (call 2 vs call 1).',
        );
        expect(
          third,
          first,
          reason:
              'Must-have #7: identical inputs must always yield '
              'identical lists (call 3 vs call 1).',
        );
      },
    );
  });

  group('diplomacy_planner_peace_targets stub delegation equality scan', () {
    test(
      'stalledFutileGpPeaceTargets stub mirrors canonical across fixtures',
      () {
        const minor1Pid = 'oldWorld|${_minor1}_active';
        const rivalAPid = 'oldWorld|${_gpRivalA}_blocker';
        final fixtures = <({String name, Game game, AIWorldSnapshot snapshot})>[
          (
            name: 'fire path, futile GP and active GP blocker',
            game: _ownGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              gpRivalProvincesById: const {
                _gpRivalA: [rivalAPid],
                _gpRivalB: [],
              },
              minorOwProvincesByMinorId: const {
                _minor1: [minor1Pid],
              },
              atWarFactionIds: const [_gpRivalA, _gpRivalB],
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpRivalB, _gpRivalA],
              invadableProvinceIdsSorted: const [minor1Pid, rivalAPid],
            ),
          ),
          (
            name: 'above-quota guard',
            game: _ownGame(
              ownProvinces: kObserverConquestMinOwProvincesPerGp,
              gpRivalProvincesById: const {_gpRivalA: []},
              minorOwProvincesByMinorId: const {
                _minor1: ['oldWorld|${_minor1}_active'],
              },
              atWarFactionIds: const [_gpRivalA],
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
              atWarWith: const [_gpRivalA],
              invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_active'],
            ),
          ),
          (
            name: 'empty invadable guard',
            game: _ownGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              gpRivalProvincesById: const {_gpRivalA: []},
              atWarFactionIds: const [_gpRivalA],
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpRivalA],
              invadableProvinceIdsSorted: const [],
            ),
          ),
          (
            name: 'GP-only invadable guard (no minor on frontier)',
            game: _ownGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              gpRivalProvincesById: const {
                _gpRivalA: [rivalAPid],
                _gpRivalB: [],
              },
              atWarFactionIds: const [_gpRivalA, _gpRivalB],
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpRivalA, _gpRivalB],
              invadableProvinceIdsSorted: const [rivalAPid],
            ),
          ),
        ];
        for (final fx in fixtures) {
          final canonical = stalledFutileGpPeaceTargets(
            game: fx.game,
            snapshot: fx.snapshot,
          );
          final stub = diplomacy_peace_targets.stalledFutileGpPeaceTargets(
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
      },
    );

    test('atWarGpDistractionTribePeaceTargets stub mirrors canonical '
        'across fixtures', () {
      final fixtures = <({String name, Game game, AIWorldSnapshot snapshot})>[
        (
          name: 'fire path, two tribes plus GP front',
          game: _ownGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            gpRivalProvincesById: const {_gpRivalA: []},
            tribeIds: const [_tribeA, _tribeB],
            atWarFactionIds: const [_gpRivalA, _tribeA, _tribeB],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_tribeB, _tribeA, _gpRivalA],
          ),
        ),
        (
          name: 'above-quota guard',
          game: _ownGame(
            ownProvinces: kObserverConquestMinOwProvincesPerGp,
            gpRivalProvincesById: const {_gpRivalA: []},
            tribeIds: const [_tribeA],
            atWarFactionIds: const [_gpRivalA, _tribeA],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            atWarWith: const [_gpRivalA, _tribeA],
          ),
        ),
        (
          name: 'no-GP-front guard (tribe-only war)',
          game: _ownGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            tribeIds: const [_tribeA],
            atWarFactionIds: const [_tribeA],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_tribeA],
          ),
        ),
        (
          name: 'GP-only war (no tribe in atWarWith)',
          game: _ownGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            gpRivalProvincesById: const {_gpRivalA: []},
            tribeIds: const [_tribeA],
            atWarFactionIds: const [_gpRivalA],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_gpRivalA],
          ),
        ),
      ];
      for (final fx in fixtures) {
        final canonical = atWarGpDistractionTribePeaceTargets(
          game: fx.game,
          snapshot: fx.snapshot,
        );
        final stub = diplomacy_peace_targets
            .atWarGpDistractionTribePeaceTargets(
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
