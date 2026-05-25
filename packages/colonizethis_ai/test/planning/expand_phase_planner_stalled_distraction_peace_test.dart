// Pins canonical home in `expand_phase_planner_gp_blocker_peace.dart`
// for `stalledExpansionDistractionPeaceTargets` (Refs #2509 S1).
//
// The decider was relocated from
// `diplomacy_planner_peace_targets.dart` so it survives the planned
// S1 deletion of that file. The canonical implementation lives in
// `expand_phase_planner_gp_blocker_peace.dart` (part of
// `expand_phase_planner.dart`); `diplomacy_planner_peace_targets.dart`
// previously retained a thin delegating stub for the legacy
// `diplomacy_planner_stalled_peace_test.dart` fixture and the in-file
// `_expandRatchetGreatPowerPeaceTargets` /
// `stalledOwExpansionNeedsPeacePass` consumer chains until the
// planned deletion.
//
// Behavioral invariants pinned at the canonical entry point:
//
//   1. Returns `const []` when
//      `isStalledOldWorldExpansion(oldWorldProvincesOwned)` is `false`
//      (above the stalled band — the at-quota / consolidate /
//      near-quota deciders own the decision instead).
//   2. Returns `const []` when `threats.atWarWith` is empty.
//   3. Returns `const []` when neither `minorsOwnInvadable` (any
//      invadable OW province owned by a minor) nor
//      `isStalledOldWorldGpBlockerFocus` is true — no minor-on-frontier
//      pivot and no GP-blocker-focus band.
//   4. Fires the minor-on-frontier arm:
//      `keepMinor = stalledFocusMinorTarget`, `keepGp = null`; peaces
//      every at-war minor / tribe except the focused minor. Great
//      Powers in the at-war set are always dropped from the result
//      because the GP-blocker / peer-GP peace deciders own that
//      decision.
//   5. Fires the GP-blocker-focus arm (GP-only invadable frontier +
//      below quota): `keepMinor = null`,
//      `keepGp = primaryInvadableOldWorldGpBlocker`; peaces every
//      at-war minor / tribe — but never any GP (the result excludes
//      Great Powers even when the primary blocker is at war).
//   6. Fires both arms simultaneously when minors own invadable
//      provinces **and** the player is also in the GP-blocker-focus
//      band: keeps both the focused minor and the primary GP blocker
//      wars open while peacing every other minor / tribe distraction.
//   7. Returned list is sorted ascending so emission order is
//      deterministic for fixed inputs (Refs #2509 Must-have #7).
//
// Determinism (Must-have #7): identical `(Game, snapshot)` inputs
// always yield identical results across repeated invocations.
//
// Stub delegation parity: the delegating stub in
// `diplomacy_planner_peace_targets.dart` returns the same value as
// the canonical helper for every representative input — required so
// the legacy `diplomacy_planner_stalled_peace_test.dart` fixture and
// in-file consumer chains agree.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpBlocker = 'gp_blocker';
const String _gpDistract = 'gp_distract';
const String _minorAlpha = 'minor_alpha';
const String _minorBeta = 'minor_beta';
const String _minorGamma = 'minor_gamma';
const String _tribeOne = 'tribe_one';

/// Builds a `Game` with:
///   * `gp_own` holding [ownProvinces] OW provinces.
///   * Every entry in [provinceOwners] places provinces under the
///     listed factionId (used for both the invadable frontier and
///     for off-frontier holdings that influence
///     `primaryInvadableOldWorldGpBlocker`).
///   * Every minor in [minors] is registered on the map.
///   * Every tribe in [tribes] is registered on the map.
///   * Every GP in [gps] is registered as a non-human player.
///   * The active player is at war with every entry in
///     [atWarFactionIds].
Game _distractionGame({
  required int ownProvinces,
  Map<String, List<String>> provinceOwners = const {},
  List<String> minors = const [],
  List<String> tribes = const [],
  List<String> gps = const [],
  List<String> atWarFactionIds = const [],
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${_gpOwn}_$i',
        regionId: 'oldWorld',
        ownerId: _gpOwn,
      ),
    for (final entry in provinceOwners.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
  ];
  return Game(
    id:
        'g-2509-stalled-distraction-canonical-'
        'own$ownProvinces-${atWarFactionIds.join("-")}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: <Player>[
      const Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
      for (final id in gps)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: [
      for (final id in minors) MinorNation(id: id, displayName: id),
    ],
    tribes: [for (final id in tribes) Tribe(id: id, displayName: id)],
    diplomacyRelations: [
      for (final id in atWarFactionIds)
        DiplomacyRelation(
          factionId1: _gpOwn,
          factionId2: id,
          state: RelationState.atWar,
          score: 30,
        ),
    ],
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
  group('stalledExpansionDistractionPeaceTargets — canonical outer guards', () {
    test('returns const [] when above the stalled OW band', () {
      // ownOw = 10 (quota) → isStalledOldWorldExpansion is false.
      final game = _distractionGame(
        ownProvinces: 10,
        provinceOwners: const {
          _minorAlpha: ['oldWorld|alpha_inv'],
          _gpBlocker: ['oldWorld|blocker_inv'],
        },
        minors: const [_minorAlpha],
        gps: const [_gpBlocker],
        atWarFactionIds: const [_minorAlpha, _gpBlocker],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 10,
        atWarWith: const [_minorAlpha, _gpBlocker],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_inv',
          'oldWorld|blocker_inv',
        ],
      );
      expect(
        stalledExpansionDistractionPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'ownOw = 10 → isStalledOldWorldExpansion(10) is false → '
            'the stalled-band outer guard fires before the at-war / '
            'minor-on-frontier checks. At-quota minor-front decisions '
            'are owned by the quota-met / consolidate deciders.',
      );
    });

    test('returns const [] when threats.atWarWith is empty', () {
      final game = _distractionGame(
        ownProvinces: 7,
        provinceOwners: const {
          _minorAlpha: ['oldWorld|alpha_inv'],
        },
        minors: const [_minorAlpha],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [],
        invadableProvinceIdsSorted: const ['oldWorld|alpha_inv'],
      );
      expect(
        stalledExpansionDistractionPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Empty atWarWith → the empty-at-war guard fires before the '
            'minor-on-frontier scan; nothing to peace.',
      );
    });

    test(
      'returns const [] when neither minorsOwnInvadable nor gpBlockerFocus is true',
      () {
        // ownOw = 7 (stalled, below quota) but no minors / tribes own
        // invadable OW provinces and the frontier is not GP-only (no
        // invadable OW provinces at all) → both pivot conditions fail
        // and the distraction-peace decider short-circuits.
        final game = _distractionGame(
          ownProvinces: 7,
          minors: const [_minorAlpha],
          tribes: const [_tribeOne],
          atWarFactionIds: const [_minorAlpha, _tribeOne],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_minorAlpha, _tribeOne],
          invadableProvinceIdsSorted: const [],
        );
        expect(
          stalledExpansionDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Empty invadable frontier → no minor owns an invadable '
              '(`minorsOwnInvadable` is false) and the GP-only-frontier '
              'gate also returns false because the frontier is empty '
              '→ the helper short-circuits without peacing the '
              'distractions even though the stalled-band and at-war '
              'guards pass.',
        );
      },
    );
  });

  group(
    'stalledExpansionDistractionPeaceTargets — minor-on-frontier arm',
    () {
      test(
        'peaces every at-war minor / tribe except the focused minor; never peaces GPs',
        () {
          // ownOw = 7 (stalled, below quota). minor_beta owns 2
          // invadable provinces — strict-greater wins over minor_alpha
          // (1 invadable) so beta is the focused-minor keep. tribe_one
          // and gp_blocker also at war; tribe is peaced, GP is dropped.
          final game = _distractionGame(
            ownProvinces: 7,
            provinceOwners: const {
              _minorAlpha: ['oldWorld|alpha_inv'],
              _minorBeta: ['oldWorld|beta_inv_1', 'oldWorld|beta_inv_2'],
              _gpBlocker: ['oldWorld|blocker_inv'],
            },
            minors: const [_minorAlpha, _minorBeta],
            tribes: const [_tribeOne],
            gps: const [_gpBlocker],
            atWarFactionIds: const [
              _minorAlpha,
              _minorBeta,
              _tribeOne,
              _gpBlocker,
            ],
          );
          final snapshot = _ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [
              _minorBeta,
              _minorAlpha,
              _tribeOne,
              _gpBlocker,
            ],
            invadableProvinceIdsSorted: const [
              'oldWorld|alpha_inv',
              'oldWorld|beta_inv_1',
              'oldWorld|beta_inv_2',
              'oldWorld|blocker_inv',
            ],
          );
          expect(
            stalledExpansionDistractionPeaceTargets(
              game: game,
              snapshot: snapshot,
            ),
            // Sorted ascending: minor_alpha, tribe_one.
            equals(const <String>[_minorAlpha, _tribeOne]),
            reason:
                'minor-on-frontier arm keeps the focused minor '
                '(minor_beta — 2 invadables vs minor_alpha 1) and peaces '
                'every other at-war minor / tribe. gp_blocker is dropped '
                'from the result because the decider only peaces minors '
                'and tribes (GPs are handled by the GP-blocker / peer '
                'peace deciders). The result is sorted ascending '
                '(`[minor_alpha, tribe_one]`).',
          );
        },
      );
    },
  );

  group(
    'stalledExpansionDistractionPeaceTargets — GP-blocker-focus arm',
    () {
      test(
        'GP-only invadable frontier below quota: peaces every at-war minor / tribe',
        () {
          // ownOw = 7 (stalled, below quota). Invadable frontier is
          // GP-only (only gp_blocker owns invadable OW provinces, no
          // minor on frontier) → isStalledOldWorldGpBlockerFocus fires.
          // minor_alpha and tribe_one are at war but NOT on the
          // frontier; they get peaced. gp_blocker is the primary
          // blocker but is dropped from the result anyway because the
          // distraction-peace decider only peaces minors / tribes.
          final game = _distractionGame(
            ownProvinces: 7,
            provinceOwners: const {
              _gpBlocker: ['oldWorld|blocker_inv'],
            },
            minors: const [_minorAlpha],
            tribes: const [_tribeOne],
            gps: const [_gpBlocker],
            atWarFactionIds: const [_minorAlpha, _tribeOne, _gpBlocker],
          );
          final snapshot = _ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [_minorAlpha, _tribeOne, _gpBlocker],
            invadableProvinceIdsSorted: const ['oldWorld|blocker_inv'],
          );
          expect(
            stalledExpansionDistractionPeaceTargets(
              game: game,
              snapshot: snapshot,
            ),
            equals(const <String>[_minorAlpha, _tribeOne]),
            reason:
                'GP-only frontier below quota → '
                'isStalledOldWorldGpBlockerFocus fires; '
                '`keepGp = gp_blocker` preserves the primary blocker '
                'war, and every at-war minor / tribe is peaced. The '
                'GP blocker itself is excluded from the result because '
                'the decider only emits minor / tribe ids.',
          );
        },
      );
    },
  );

  group(
    'stalledExpansionDistractionPeaceTargets — combined arm',
    () {
      test(
        'minors on frontier + GP-blocker-focus: keeps focused minor and blocker',
        () {
          // ownOw = 7 (stalled, below quota). Invadable frontier is
          // MIXED — minor_beta owns an invadable AND gp_blocker owns
          // 2 invadables (so blocker is also the primary
          // GP-on-invadable). Frontier is NOT GP-only because a minor
          // owns an invadable, so gpBlockerFocus is FALSE — but
          // `minorsOwnInvadable` is TRUE so the minor-on-frontier arm
          // fires and `keepMinor = minor_beta`. minor_alpha and
          // tribe_one are at war as distractions and get peaced.
          //
          // (The combined "both arms fire" shape only occurs if the
          // frontier is GP-only AND a minor still owns OW provinces
          // elsewhere; that shape is exercised by the GP-blocker-focus
          // test above. This test pins the mixed-frontier shape where
          // only the minor arm fires but the GP blocker stays at war
          // structurally because GPs are always excluded from the
          // result.)
          final game = _distractionGame(
            ownProvinces: 7,
            provinceOwners: const {
              _minorBeta: ['oldWorld|beta_inv'],
              _gpBlocker: ['oldWorld|blocker_inv_1', 'oldWorld|blocker_inv_2'],
            },
            minors: const [_minorAlpha, _minorBeta],
            tribes: const [_tribeOne],
            gps: const [_gpBlocker],
            atWarFactionIds: const [
              _minorAlpha,
              _minorBeta,
              _tribeOne,
              _gpBlocker,
            ],
          );
          final snapshot = _ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [
              _minorAlpha,
              _minorBeta,
              _tribeOne,
              _gpBlocker,
            ],
            invadableProvinceIdsSorted: const [
              'oldWorld|beta_inv',
              'oldWorld|blocker_inv_1',
              'oldWorld|blocker_inv_2',
            ],
          );
          expect(
            stalledExpansionDistractionPeaceTargets(
              game: game,
              snapshot: snapshot,
            ),
            equals(const <String>[_minorAlpha, _tribeOne]),
            reason:
                'Mixed frontier (minor + GP) → `minorsOwnInvadable` '
                'true → keepMinor = minor_beta. `gpBlockerFocus` is '
                'false here (frontier is not GP-only) so keepGp = null. '
                'gp_blocker is excluded from the result anyway because '
                'the decider only peaces minors and tribes. Result '
                'sorted ascending.',
          );
        },
      );
    },
  );

  group('Determinism (Must-have #7)', () {
    test('stalledExpansionDistractionPeaceTargets is identical on repeat', () {
      final game = _distractionGame(
        ownProvinces: 7,
        provinceOwners: const {
          _minorBeta: ['oldWorld|beta_inv'],
          _gpBlocker: ['oldWorld|blocker_inv'],
        },
        minors: const [_minorAlpha, _minorBeta, _minorGamma],
        tribes: const [_tribeOne],
        gps: const [_gpBlocker, _gpDistract],
        atWarFactionIds: const [
          _minorAlpha,
          _minorBeta,
          _minorGamma,
          _tribeOne,
          _gpBlocker,
          _gpDistract,
        ],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        // Pass atWarWith in a deliberately non-sorted order so the
        // ascending-sort contract is exercised on repeat.
        atWarWith: const [
          _tribeOne,
          _gpDistract,
          _minorGamma,
          _minorBeta,
          _gpBlocker,
          _minorAlpha,
        ],
        invadableProvinceIdsSorted: const [
          'oldWorld|beta_inv',
          'oldWorld|blocker_inv',
        ],
      );
      final first = stalledExpansionDistractionPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = stalledExpansionDistractionPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, equals(second));
      // minor_beta is the focused minor (the only minor with an
      // invadable); minor_alpha, minor_gamma, tribe_one are peaced.
      // gp_blocker and gp_distract are excluded (only minors/tribes
      // peaced).
      expect(
        first,
        equals(const <String>[_minorAlpha, _minorGamma, _tribeOne]),
        reason:
            'Result must be sorted ascending and stable across '
            'repeated invocations regardless of `atWarWith` iteration '
            'order at the snapshot edge.',
      );
    });
  });

  group('Stub delegation parity', () {
    test(
      'stub mirrors canonical across outer-guard and fire-path inputs',
      () {
        final fixtures = <({Game game, AIWorldSnapshot snapshot, String label})>[
          (
            label: 'outer guard: above stalled band',
            game: _distractionGame(
              ownProvinces: 10,
              provinceOwners: const {
                _minorAlpha: ['oldWorld|alpha_inv'],
              },
              minors: const [_minorAlpha],
              atWarFactionIds: const [_minorAlpha],
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: 10,
              atWarWith: const [_minorAlpha],
              invadableProvinceIdsSorted: const ['oldWorld|alpha_inv'],
            ),
          ),
          (
            label: 'outer guard: empty atWarWith',
            game: _distractionGame(
              ownProvinces: 7,
              provinceOwners: const {
                _minorAlpha: ['oldWorld|alpha_inv'],
              },
              minors: const [_minorAlpha],
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: 7,
              atWarWith: const [],
              invadableProvinceIdsSorted: const ['oldWorld|alpha_inv'],
            ),
          ),
          (
            label: 'outer guard: neither minors-on-frontier nor GP-focus',
            game: _distractionGame(
              ownProvinces: 7,
              minors: const [_minorAlpha],
              tribes: const [_tribeOne],
              atWarFactionIds: const [_minorAlpha, _tribeOne],
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: 7,
              atWarWith: const [_minorAlpha, _tribeOne],
              invadableProvinceIdsSorted: const [],
            ),
          ),
          (
            label: 'fire path: minor-on-frontier arm',
            game: _distractionGame(
              ownProvinces: 7,
              provinceOwners: const {
                _minorBeta: ['oldWorld|beta_inv'],
              },
              minors: const [_minorAlpha, _minorBeta],
              tribes: const [_tribeOne],
              atWarFactionIds: const [_minorAlpha, _minorBeta, _tribeOne],
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: 7,
              atWarWith: const [_minorAlpha, _minorBeta, _tribeOne],
              invadableProvinceIdsSorted: const ['oldWorld|beta_inv'],
            ),
          ),
          (
            label: 'fire path: GP-only frontier (gp-blocker-focus arm)',
            game: _distractionGame(
              ownProvinces: 7,
              provinceOwners: const {
                _gpBlocker: ['oldWorld|blocker_inv'],
              },
              minors: const [_minorAlpha],
              tribes: const [_tribeOne],
              gps: const [_gpBlocker],
              atWarFactionIds: const [_minorAlpha, _tribeOne, _gpBlocker],
            ),
            snapshot: _ownSnapshot(
              oldWorldProvincesOwned: 7,
              atWarWith: const [_minorAlpha, _tribeOne, _gpBlocker],
              invadableProvinceIdsSorted: const ['oldWorld|blocker_inv'],
            ),
          ),
        ];
        for (final fixture in fixtures) {
          final canonical = stalledExpansionDistractionPeaceTargets(
            game: fixture.game,
            snapshot: fixture.snapshot,
          );
          final stub = diplomacy_planner_peace_targets
              .stalledExpansionDistractionPeaceTargets(
                game: fixture.game,
                snapshot: fixture.snapshot,
              );
          expect(
            stub,
            equals(canonical),
            reason:
                'Stub-canonical parity broken for fixture '
                '"${fixture.label}". The legacy '
                '_expandRatchetGreatPowerPeaceTargets and '
                'stalledOwExpansionNeedsPeacePass consumers depend on '
                'this parity until the now-completed S1 deletion.',
          );
        }
      },
    );
  });
}
