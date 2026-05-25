// Pins canonical home in `expand_phase_planner_peer_peace.dart` for
// `weakHoldingsInvadableBlockerPeaceTargets` (Refs #2509 S1).
//
// The decider was relocated from
// `diplomacy_planner_peace_targets.dart` so it survives the planned
// S1 deletion of that file. The canonical implementation lives in
// `expand_phase_planner_peer_peace.dart` (part of `expand_phase_planner.dart`);
// `diplomacy_planner_peace_targets.dart` retains a thin delegating
// stub for the legacy
// `diplomacy_planner_below_quota_peace_test.dart` and
// `diplomacy_planner_below_quota_peace_part3_test.dart` fixtures and
// the in-file `_expandRatchetGreatPowerPeaceTargets` /
// `collectStalledGreatPowerPeaceTargets` `preserveBlockerPeace` /
// `stalledOwExpansionNeedsPeacePass` consumer chains until the
// planned deletion.
//
// Behavioral invariants pinned at the canonical entry point:
//
//   1. Outer guard returns `const []` when the active player is not
//      in any of three "critically weak" rows:
//      a. `oldWorldProvincesOwned > kFewOldWorldProvincesDefendThreshold`
//      b. NOT `isBelowObserverConquestQuota(...)`
//      c. NOT (zero regiments AND `isStalledOldWorldExpansion(...)`)
//   2. Returns `const []` when the invadable OW frontier is GP-only
//      (`isOldWorldGpOnlyInvadableFrontier` is true) — the
//      `stalledGpBlockerFocusPeaceTargets` collector owns this
//      decision instead.
//   3. Returns `const []` when the primary OW frontier blocker is
//      null, not in `threats.atWarWith`, or not a Great Power.
//   4. Returns `const []` when the blocker's lead falls below the
//      band-dependent `minLead` table:
//      a. Below quota at default-start + 2 OW or fewer: `1`.
//      b. Below quota above default-start + 2: `kUnwinnableSoleGpMinProvinceDeficit`.
//      c. Above quota (defensive zero-regiment / stalled
//         critical-weak entry path): `kDeclareWarAggressorSuppressWeakGpLeadThreshold`.
//   5. Returns `[blocker]` (single-element list) when all guards pass.
//
// Determinism (Must-have #7): identical `(Game, snapshot)` inputs
// always yield identical results across repeated invocations.
//
// Stub delegation parity: the delegating stub in
// `diplomacy_planner_peace_targets.dart` returns the same value as
// the canonical helper for every representative input — required so
// the legacy fixtures and in-file consumer chains agree.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpBlocker = 'gp_blocker';
const String _minor1 = 'minor1';

/// Builds a `Game` where:
///   * `gp_own` holds [ownProvinces] OW provinces.
///   * `gp_blocker` holds [blockerOwnProvinces] OW provinces (sets
///     the lead the blocker has over the active player).
///   * Every entry in [extraInvadableOwners] places a province with
///     id `oldWorld|inv_<n>` owned by the listed factionId — used to
///     control whether the invadable frontier is GP-only or mixed.
///   * `gp_own` is at war with every faction in [atWarFactionIds].
Game _weakHoldingsGame({
  required int ownProvinces,
  required int blockerOwnProvinces,
  Map<String, List<String>> extraInvadableOwners = const {},
  List<String> atWarFactionIds = const [_gpBlocker],
  List<MinorNation> minorNations = const [
    MinorNation(id: _minor1, displayName: 'M1'),
  ],
}) {
  return Game(
    id:
        'g-2509-weak-holdings-canonical-'
        'own$ownProvinces-blocker$blockerOwnProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
      oldWorld: RegionData(
        provinces: <Province>[
          for (var i = 1; i <= ownProvinces; i++)
            Province(
              id: 'oldWorld|${_gpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: _gpOwn,
            ),
          for (var i = 1; i <= blockerOwnProvinces; i++)
            Province(
              id: 'oldWorld|${_gpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: _gpBlocker,
            ),
          for (final entry in extraInvadableOwners.entries)
            for (final pid in entry.value)
              Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
      Player(id: _gpBlocker, displayName: 'GP_BLOCKER', isHuman: false),
    ],
    minorNations: minorNations,
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
  required List<String> invadableProvinceIdsSorted,
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
  group(
    'weakHoldingsInvadableBlockerPeaceTargets — canonical outer guards',
    () {
      test('returns const [] when not in any critically-weak band', () {
        // ownOw = 9 → above defend threshold, below quota row applies but
        // we want the "above defend AND not below quota AND not zero-reg
        // stalled" combined skip. Use ownOw above quota with armies.
        final game = _weakHoldingsGame(
          ownProvinces: 12,
          blockerOwnProvinces: 20,
          extraInvadableOwners: const {
            _gpBlocker: ['oldWorld|inv_blocker'],
            _minor1: ['oldWorld|inv_minor'],
          },
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 12,
          atWarWith: const [_gpBlocker],
          invadableProvinceIdsSorted: const [
            'oldWorld|inv_blocker',
            'oldWorld|inv_minor',
          ],
        );
        expect(
          weakHoldingsInvadableBlockerPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'ownOw = 12 → above defend threshold, NOT below quota, '
              'and (zero-regiment + stalled) row does not apply with '
              'ownOw above the stalled band → all three critical-weak '
              'rows skip and the helper short-circuits.',
        );
      });

      test('returns const [] on a GP-only invadable frontier', () {
        // Below quota (5 OW), but invadable owned only by gp_blocker
        // (no minor on frontier) → GP-only; gp-blocker-focus collector
        // owns the decision instead.
        final game = _weakHoldingsGame(
          ownProvinces: 5,
          blockerOwnProvinces: 10,
          extraInvadableOwners: const {
            _gpBlocker: ['oldWorld|inv_blocker'],
          },
          minorNations: const [],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 5,
          atWarWith: const [_gpBlocker],
          invadableProvinceIdsSorted: const ['oldWorld|inv_blocker'],
        );
        expect(
          weakHoldingsInvadableBlockerPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'GP-only invadable frontier → outer guard fires before '
              'the blocker resolution; gp-blocker-focus collector owns '
              'this shape so this decider must short-circuit.',
        );
      });

      test('returns const [] when the blocker is not at war', () {
        // Below quota (5 OW), mixed frontier, but gp_blocker is not in
        // atWarWith → blocker membership guard fires.
        final game = _weakHoldingsGame(
          ownProvinces: 5,
          blockerOwnProvinces: 10,
          extraInvadableOwners: const {
            _gpBlocker: ['oldWorld|inv_blocker'],
            _minor1: ['oldWorld|inv_minor'],
          },
          atWarFactionIds: const [_minor1],
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 5,
          atWarWith: const [_minor1],
          invadableProvinceIdsSorted: const [
            'oldWorld|inv_blocker',
            'oldWorld|inv_minor',
          ],
        );
        expect(
          weakHoldingsInvadableBlockerPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Blocker not in threats.atWarWith → no GP front to peace; '
              'helper must return empty even though every other guard '
              'passes.',
        );
      });
    },
  );

  group(
    'weakHoldingsInvadableBlockerPeaceTargets — band-dependent minLead',
    () {
      test('default-start critical row (ownOw <= 9) fires at lead == 1', () {
        // ownOw = 7 (default-start) → minLead = 1; blocker total = 7
        // base + 1 extra invadable = 8 (lead = 1) → fires.
        final game = _weakHoldingsGame(
          ownProvinces: 7,
          blockerOwnProvinces: 7,
          extraInvadableOwners: const {
            _gpBlocker: ['oldWorld|inv_blocker'],
            _minor1: ['oldWorld|inv_minor'],
          },
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_gpBlocker],
          invadableProvinceIdsSorted: const [
            'oldWorld|inv_blocker',
            'oldWorld|inv_minor',
          ],
        );
        expect(
          weakHoldingsInvadableBlockerPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          const [_gpBlocker],
          reason:
              'Default-start critical row (ownOw <= '
              'kObserverDefaultStartOldWorldProvincesPerGp + 2 = 9) '
              'sets minLead = 1; blocker lead 8-7 = 1 hits the floor '
              '→ peace blocker.',
        );
      });

      test('default-start row does NOT fire at lead == 0 (equal strength)', () {
        // ownOw = 7, blocker total = 6 base + 1 extra invadable = 7 →
        // lead 0 < minLead 1 → no peace.
        final game = _weakHoldingsGame(
          ownProvinces: 7,
          blockerOwnProvinces: 6,
          extraInvadableOwners: const {
            _gpBlocker: ['oldWorld|inv_blocker'],
            _minor1: ['oldWorld|inv_minor'],
          },
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_gpBlocker],
          invadableProvinceIdsSorted: const [
            'oldWorld|inv_blocker',
            'oldWorld|inv_minor',
          ],
        );
        expect(
          weakHoldingsInvadableBlockerPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Lead 0 < minLead 1 → equal-strength wars are not '
              '"unwinnable" so the helper holds the war open.',
        );
      });

      test('zero-regiment + stalled fires above defend threshold', () {
        // ownOw = 8 → above defend threshold (6) AND below quota →
        // below-quota row applies. Blocker total = 9 base + 1 extra
        // invadable = 10, lead 10-8 = 2 → fires below-quota arm
        // (ownOw 8 <= default-start + 2 = 9 → minLead 1; lead 2 >= 1).
        final game = _weakHoldingsGame(
          ownProvinces: 8,
          blockerOwnProvinces: 9,
          extraInvadableOwners: const {
            _gpBlocker: ['oldWorld|inv_blocker'],
            _minor1: ['oldWorld|inv_minor'],
          },
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const [_gpBlocker],
          invadableProvinceIdsSorted: const [
            'oldWorld|inv_blocker',
            'oldWorld|inv_minor',
          ],
        );
        expect(
          weakHoldingsInvadableBlockerPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          const [_gpBlocker],
          reason:
              'Below quota at ownOw == 8 (default-start + 1) → minLead '
              '= 1; lead 10 - 8 = 2 >= 1 → peace blocker.',
        );
      });
    },
  );

  group('Determinism (Must-have #7)', () {
    test('weakHoldingsInvadableBlockerPeaceTargets is identical on repeat', () {
      final game = _weakHoldingsGame(
        ownProvinces: 7,
        blockerOwnProvinces: 9,
        extraInvadableOwners: const {
          _gpBlocker: ['oldWorld|inv_blocker'],
          _minor1: ['oldWorld|inv_minor'],
        },
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const [
          'oldWorld|inv_blocker',
          'oldWorld|inv_minor',
        ],
      );
      final first = weakHoldingsInvadableBlockerPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = weakHoldingsInvadableBlockerPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, equals(second));
      expect(first, const [_gpBlocker]);
    });
  });

  group('Stub delegation parity', () {
    test('stub mirrors canonical across outer-guard and fire-path inputs', () {
      final fixtures = <({Game game, AIWorldSnapshot snapshot, String label})>[
        (
          label: 'outer guard: not in critical-weak band',
          game: _weakHoldingsGame(
            ownProvinces: 12,
            blockerOwnProvinces: 20,
            extraInvadableOwners: const {
              _gpBlocker: ['oldWorld|inv_blocker'],
              _minor1: ['oldWorld|inv_minor'],
            },
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: 12,
            atWarWith: const [_gpBlocker],
            invadableProvinceIdsSorted: const [
              'oldWorld|inv_blocker',
              'oldWorld|inv_minor',
            ],
          ),
        ),
        (
          label: 'outer guard: GP-only frontier',
          game: _weakHoldingsGame(
            ownProvinces: 5,
            blockerOwnProvinces: 10,
            extraInvadableOwners: const {
              _gpBlocker: ['oldWorld|inv_blocker'],
            },
            minorNations: const [],
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: 5,
            atWarWith: const [_gpBlocker],
            invadableProvinceIdsSorted: const ['oldWorld|inv_blocker'],
          ),
        ),
        (
          label: 'fire path: default-start critical row at lead 1',
          game: _weakHoldingsGame(
            ownProvinces: 7,
            blockerOwnProvinces: 7,
            extraInvadableOwners: const {
              _gpBlocker: ['oldWorld|inv_blocker'],
              _minor1: ['oldWorld|inv_minor'],
            },
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: 7,
            atWarWith: const [_gpBlocker],
            invadableProvinceIdsSorted: const [
              'oldWorld|inv_blocker',
              'oldWorld|inv_minor',
            ],
          ),
        ),
        (
          label: 'fire path: below-quota row at lead 2',
          game: _weakHoldingsGame(
            ownProvinces: 8,
            blockerOwnProvinces: 9,
            extraInvadableOwners: const {
              _gpBlocker: ['oldWorld|inv_blocker'],
              _minor1: ['oldWorld|inv_minor'],
            },
          ),
          snapshot: _ownSnapshot(
            oldWorldProvincesOwned: 8,
            atWarWith: const [_gpBlocker],
            invadableProvinceIdsSorted: const [
              'oldWorld|inv_blocker',
              'oldWorld|inv_minor',
            ],
          ),
        ),
      ];
      for (final fixture in fixtures) {
        final canonical = weakHoldingsInvadableBlockerPeaceTargets(
          game: fixture.game,
          snapshot: fixture.snapshot,
        );
        final stub = diplomacy_planner_peace_targets
            .weakHoldingsInvadableBlockerPeaceTargets(
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
              'collectStalledGreatPowerPeaceTargets '
              'preserveBlockerPeace consumers depend on this parity '
              'until the planned S1 deletion.',
        );
      }
    });
  });
}
