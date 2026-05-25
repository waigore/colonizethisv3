// Pins the canonical `defaultStartGpPeaceTargets` and
// `nearQuotaHoldPeaceTargets` EXPAND multi-GP peace deciders in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from `colonial_pressure.dart` so they
// survive the planned S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`;
// `colonial_pressure.dart` retains thin delegating stubs for legacy
// callers (the existing `colonial_pressure_default_start_gp_peace_branches_test.dart`
// and `colonial_pressure_test.dart` near-quota fixtures plus the
// `diplomacy_planner.dart` / `diplomacy_planner_peace_targets.dart`
// consumer chain) until the planned deletion.
//
// Live consumers (post-relocation):
//   * `defaultStartGpPeaceTargets` is the EXPAND default-start band
//     pivot: when a GP is at the observer default-start size, peace
//     every at-war Great Power except the GP-only-frontier blocker so
//     the planner can open a minor frontier (seed-42 gp4 zero-gain
//     stall). Composes [hasUninvadedOldWorldMinor],
//     [isOldWorldGpOnlyInvadableFrontier], and
//     [primaryInvadableOldWorldGpBlocker] with the ceiling rules from
//     `SPEC/ai/ai-architecture.md` § Diplomacy targeting.
//   * `nearQuotaHoldPeaceTargets` is the EXPAND 8–9 OW hold-gains
//     pivot: peace distracting GP wars except the
//     `primaryInvadableOldWorldGpBlocker`, with the sole-GP
//     mutual-plateau carve-out peacing the lone blocker when no minor
//     pivot remains (seed-42 gp3). Composes [primaryInvadableOldWorldGpBlocker],
//     [isOldWorldGpOnlyInvadableFrontier], [isMutualBelowQuotaPlateauPeer],
//     and [hasUninvadedOldWorldMinor] with the near-quota band rules.
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. `defaultStartGpPeaceTargets` returns `const []` for each outer
//      guard in order:
//      a. `oldWorldProvincesOwned >= kObserverConquestMinOwProvincesPerGp`
//         (above-quota; quota-met collectors own the decision).
//      b. `oldWorldProvincesOwned > maxOwForGpPeace` where
//         `maxOwForGpPeace` is `kStalledOldWorldProvinceThreshold` when
//         an uninvaded OW minor remains and
//         `kObserverDefaultStartOldWorldProvincesPerGp + 1` otherwise.
//   2. On the GP-only invadable frontier arm the
//      `primaryInvadableOldWorldGpBlocker` is excluded from the peace
//      list; on every other shape the blocker filter is `null` and all
//      at-war GPs are peaced. Non-GP factions in `threats.atWarWith`
//      (tribes, minors) are filtered out via `game.playerById`.
//   3. `nearQuotaHoldPeaceTargets` returns `const []` for each outer
//      guard in order:
//      a. `!isBelowObserverConquestQuota(ownOw)` (quota-met collectors
//         own the decision).
//      b. `!isStalledOldWorldExpansion(ownOw)` (default-start collector
//         owns the decision).
//      c. Empty GP-war set after the `playerById` filter (no GP wars
//         to peace at all).
//   4. On the sole-GP arm the function peaces the lone GP only when
//      the war is a mutual-plateau sole-GP stalemate on a GP-only
//      invadable frontier with no uninvaded OW minors remaining;
//      otherwise, when the lone GP is the
//      `primaryInvadableOldWorldGpBlocker` and a minor pivot remains
//      the war is held open (`const []`). On the multi-GP arm it
//      peaces every at-war GP except the blocker, sorted ascending.
//   5. The delegating stubs in `colonial_pressure.dart` return the
//      same value as the canonical helpers for every relevant input —
//      required so the legacy
//      `colonial_pressure_default_start_gp_peace_branches_test.dart`
//      and `colonial_pressure_test.dart` near-quota fixtures plus the
//      in-file consumer paths agree on the deciders.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as colonial_pressure;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpA = 'gp_a';
const String _gpB = 'gp_b';
const String _gpC = 'gp_c';
const String _minorM1 = 'minor_m1';
const String _minorM2 = 'minor_m2';
const String _tribeT1 = 'tribe_t1';

/// Builds a minimal `Game` whose Old World province list is populated
/// from the supplied [owOwners] map: each entry contributes
/// `count` provinces owned by `factionId`. Province ids are
/// deterministic (`oldWorld|<factionId>_<i>` for `i in 1..count`) so
/// callers can place specific provinces on the invadable list. When
/// any minor or tribe id appears in [owOwners], the corresponding
/// `MinorNation` / `Tribe` entry is added to the game so
/// `playerById`/`minorNations.any` filtering matches the legacy
/// fixture conventions.
Game _gameOf({
  required Map<String, int> owOwners,
  required List<String> atWarPartners,
  bool atWarWithExtraGp = true,
}) {
  final provinces = <Province>[];
  for (final entry in owOwners.entries) {
    for (var i = 1; i <= entry.value; i++) {
      provinces.add(
        Province(
          id: 'oldWorld|${entry.key}_$i',
          regionId: 'oldWorld',
          ownerId: entry.key,
        ),
      );
    }
  }

  final knownMinors = <String>{_minorM1, _minorM2};
  final knownTribes = <String>{_tribeT1};
  final ownerAndPartnerIds = <String>{...owOwners.keys, ...atWarPartners};

  final players = <Player>[
    const Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
    for (final id in ownerAndPartnerIds)
      if (id != _gpOwn &&
          !knownMinors.contains(id) &&
          !knownTribes.contains(id))
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
  ];

  final minorNations = <MinorNation>[
    for (final id in ownerAndPartnerIds)
      if (knownMinors.contains(id)) MinorNation(id: id, displayName: id),
  ];

  final tribes = <Tribe>[
    for (final id in ownerAndPartnerIds)
      if (knownTribes.contains(id)) Tribe(id: id, displayName: id),
  ];

  final relations = <DiplomacyRelation>[
    for (final partner in atWarPartners)
      if (atWarWithExtraGp || players.any((p) => p.id == partner))
        DiplomacyRelation(
          factionId1: _gpOwn,
          factionId2: partner,
          state: RelationState.atWar,
          score: 30,
        ),
  ];

  return Game(
    id: 'g-2509-default-start-and-near-quota-peace-canonical',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: relations,
  );
}

AIWorldSnapshot _snapshot({
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
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('defaultStartGpPeaceTargets — outer guards', () {
    test('returns const [] when at the observer OW quota', () {
      // OW == kObserverConquestMinOwProvincesPerGp → not below quota →
      // helper short-circuits before ceiling/blocker logic. The
      // EXPAND→COLONIAL handoff lets the quota-met collectors govern
      // post-quota wars.
      final game = _gameOf(
        owOwners: const {_gpOwn: 10, _gpA: 1},
        atWarPartners: const [_gpA],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_gpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At quota the EXPAND default-start pivot is no longer in scope; '
            'the canonical helper must return empty so the COLONIAL/'
            'COLONIAL-lite peace rules govern post-quota wars.',
      );
    });

    test('returns const [] above ceiling without an uninvaded minor', () {
      // OW = 9, no minors on the map → maxOwForGpPeace = 8 →
      // ownOw > 8 → empty. Locks the no-minor ceiling shape.
      final game = _gameOf(
        owOwners: const {_gpOwn: 9, _gpA: 5},
        atWarPartners: const [_gpA],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [_gpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Without an uninvaded minor on the map the ceiling is '
            'kObserverDefaultStartOldWorldProvincesPerGp + 1, so OW=9 '
            'must NOT engage the canonical pivot — there is no minor '
            'frontier to pivot to.',
      );
    });

    test(
      'returns the lone non-blocker GP at ceiling WITH an uninvaded minor',
      () {
        // OW = 9, an uninvaded minor (m1) holds an OW province →
        // hasUninvadedOldWorldMinor true → ceiling = 9 → eligible.
        // The only invadable OW belongs to the minor, so the
        // frontier is not GP-only → invadableBlocker = null →
        // every at-war GP is peaced (gp_a alone here).
        final game = _gameOf(
          owOwners: const {_gpOwn: 9, _minorM1: 1},
          atWarPartners: const [_gpA],
          atWarWithExtraGp: false,
        );
        final snapshot = _snapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [_gpA],
          invadableProvinceIdsSorted: const ['oldWorld|minor_m1_1'],
        );
        expect(
          defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gpA],
          reason:
              'With an uninvaded minor on the map the ceiling extends to '
              'kStalledOldWorldProvinceThreshold and the lone non-blocker '
              'GP must be returned. A regression that kept the ceiling at '
              'the no-minor value here would block the minor-frontier '
              'pivot the rule was added for.',
        );
      },
    );
  });

  group('defaultStartGpPeaceTargets — blocker / frontier branches', () {
    test('mixed minor + GP frontier returns every at-war GP', () {
      // gp_a owns one invadable OW; minor_m1 owns another. The minor
      // owner makes the frontier non-GP-only → invadableBlocker null
      // → every at-war GP is peaced ascending.
      final game = _gameOf(
        owOwners: const {_gpOwn: 8, _gpA: 1, _gpB: 0, _minorM1: 1},
        atWarPartners: const [_gpA, _gpB],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        atWarWith: const [_gpA, _gpB],
        invadableProvinceIdsSorted: const [
          'oldWorld|gp_a_1',
          'oldWorld|minor_m1_1',
        ],
      );
      expect(
        defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gpA, _gpB],
        reason:
            'When the frontier mixes GP and minor owners no GP qualifies '
            'as the blocker (the minor pivot remains), so every at-war '
            'GP is peaced in ascending factionId order.',
      );
    });

    test(
      'GP-only frontier with multiple GPs at war excludes only the blocker',
      () {
        // Pure GP frontier: gp_a owns the sole invadable OW; gp_b
        // also at war but owns nothing on the frontier. The canonical
        // helper must drop gp_a (blocker) and return [gp_b] sorted.
        final game = _gameOf(
          owOwners: const {_gpOwn: 8, _gpA: 1, _gpB: 0},
          atWarPartners: const [_gpA, _gpB],
        );
        final snapshot = _snapshot(
          oldWorldProvincesOwned:
              kObserverDefaultStartOldWorldProvincesPerGp + 1,
          atWarWith: const [_gpA, _gpB],
          invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
        );
        expect(
          defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gpB],
          reason:
              'On a GP-only frontier the blocker (gp_a) holds the only '
              'winnable OW front and must be preserved; remaining GP '
              'wars (gp_b) are peaced ascending.',
        );
      },
    );
  });

  group(
    'defaultStartGpPeaceTargets — atWarWith filter / sort / determinism',
    () {
      test('non-GP factions are filtered out of the returned list', () {
        // atWarWith mixes a tribe with a Great Power; the tribe must
        // be dropped because game.playerById(tribe_t1) == null. The
        // GP-only frontier is true (gp_a owns the only invadable OW)
        // so blocker exclusion drops gp_a as well → empty.
        final game = _gameOf(
          owOwners: const {_gpOwn: 7, _gpA: 1, _tribeT1: 0},
          atWarPartners: const [_gpA],
          atWarWithExtraGp: false,
        );
        final snapshot = _snapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_tribeT1, _gpA],
          invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
        );
        expect(
          defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Tribes are filtered before sort via playerById; with a '
              'GP-only frontier the lone GP foe (the blocker) is also '
              'excluded so the result is empty.',
        );
      });

      test('multi-GP roster returns deterministically ascending output', () {
        // Three at-war GPs supplied out of order; gp_a is the blocker
        // (owns the only invadable OW). The canonical helper must
        // return [gp_b, gp_c] ascending across two consecutive calls
        // (Refs #2509 Must-have #7).
        final game = _gameOf(
          owOwners: const {_gpOwn: 7, _gpA: 1, _gpB: 0, _gpC: 0},
          atWarPartners: const [_gpC, _gpA, _gpB],
        );
        final snapshot = _snapshot(
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const [_gpC, _gpA, _gpB],
          invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
        );
        final first = defaultStartGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = defaultStartGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(
          first,
          const [_gpB, _gpC],
          reason:
              'On a GP-only frontier the blocker (gp_a) is excluded; '
              'remaining GPs return ascending across an out-of-order input.',
        );
        expect(
          second,
          first,
          reason:
              'Two consecutive canonical-helper invocations on identical '
              'inputs must return identical lists (Must-have #7).',
        );
      });
    },
  );

  group('defaultStartGpPeaceTargets — delegation equality', () {
    test(
      'colonial_pressure stub matches canonical helper across representative shapes',
      () {
        // Iterate three diagnostic fixtures (above-quota guard, GP-only
        // frontier blocker exclusion, mixed-frontier all-GPs) and pin
        // that the colonial_pressure stub mirrors the canonical
        // expand_phase_planner helper for each.
        final cases = <(Game, AIWorldSnapshot, String)>[
          (
            _gameOf(
              owOwners: const {_gpOwn: 10, _gpA: 1},
              atWarPartners: const [_gpA],
            ),
            _snapshot(
              oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
              atWarWith: const [_gpA],
              invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
            ),
            'above quota',
          ),
          (
            _gameOf(
              owOwners: const {_gpOwn: 7, _gpA: 1, _gpB: 0},
              atWarPartners: const [_gpA, _gpB],
            ),
            _snapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpA, _gpB],
              invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
            ),
            'GP-only frontier excludes blocker',
          ),
          (
            _gameOf(
              owOwners: const {_gpOwn: 7, _gpA: 1, _minorM1: 1},
              atWarPartners: const [_gpA],
            ),
            _snapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpA],
              invadableProvinceIdsSorted: const [
                'oldWorld|gp_a_1',
                'oldWorld|minor_m1_1',
              ],
            ),
            'mixed frontier returns all GPs',
          ),
        ];
        for (final (game, snapshot, label) in cases) {
          expect(
            colonial_pressure.defaultStartGpPeaceTargets(
              game: game,
              snapshot: snapshot,
            ),
            defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
            reason:
                'colonial_pressure delegating stub must mirror the '
                'canonical helper for case "$label" so the legacy '
                'fixtures and consumer chain agree on the decider.',
          );
        }
      },
    );
  });

  group('nearQuotaHoldPeaceTargets — outer guards', () {
    test('returns const [] when at the observer OW quota', () {
      // OW == kObserverConquestMinOwProvincesPerGp → not below quota →
      // canonical helper short-circuits.
      final game = _gameOf(
        owOwners: const {_gpOwn: 10, _gpA: 1},
        atWarPartners: const [_gpA],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_gpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At quota the EXPAND near-quota hold-gains pivot is out of '
            'scope; the canonical helper must return empty so quota-met '
            'collectors govern post-quota wars.',
      );
    });

    test('returns const [] when below the stalled-band threshold', () {
      // OW = kObserverDefaultStartOldWorldProvincesPerGp (default
      // start) → !isStalledOldWorldExpansion → empty so the
      // default-start collector owns the decision.
      final game = _gameOf(
        owOwners: const {_gpOwn: 7, _gpA: 1},
        atWarPartners: const [_gpA],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_gpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Below the stalled-band threshold the default-start '
            'collector (defaultStartGpPeaceTargets) owns the EXPAND '
            'pivot; the canonical near-quota helper must short-circuit.',
      );
    });

    test('returns const [] when no Great Powers are at war', () {
      // gp_own at 8 OW → in stalled band, below quota → both outer
      // guards pass. atWarWith carries only a tribe → playerById
      // filter empties the gp-war set → const [].
      final game = _gameOf(
        owOwners: const {_gpOwn: 8, _tribeT1: 0},
        atWarPartners: const [],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [_tribeT1],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'A tribe-only atWarWith leaves an empty GP-war set after '
            'playerById filtering; the canonical helper must short-circuit '
            'before any blocker / frontier scan.',
      );
    });
  });

  group('nearQuotaHoldPeaceTargets — sole-GP arm', () {
    test(
      'sole GP mutual-plateau on GP-only frontier with no minor pivot peaces lone GP',
      () {
        // gp_own=8, gp_a=8 → mutual-plateau peer (|partner-own| <= 1,
        // both stalled below quota). Only invadable OW is gp_a's →
        // GP-only frontier. No OW minors → !hasUninvadedOldWorldMinor.
        // Canonical helper returns the unsorted single-GP list.
        final game = _gameOf(
          owOwners: const {_gpOwn: 8, _gpA: 8},
          atWarPartners: const [_gpA],
        );
        final snapshot = _snapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
          atWarWith: const [_gpA],
          invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
        );
        expect(
          nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
          const [_gpA],
          reason:
              'The mutual-plateau sole-GP carve-out peaces the lone GP '
              'when the war is a stalemate on a GP-only invadable '
              'frontier with no remaining OW minor pivot.',
        );
      },
    );

    test('sole GP blocker with no minor pivot holds the war open', () {
      // gp_own=8, gp_a=10 (not mutual-plateau peer because |10-8|>1),
      // no minor on the map → hasUninvadedOldWorldMinor=false. gp_a
      // owns the only invadable OW (GP-only frontier). Sole GP at war
      // is the blocker; minor pivot is absent so the
      // sole-GP-blocker hold-open guard fires and the canonical helper
      // returns const [] — keep fighting the blocker.
      final game = _gameOf(
        owOwners: const {_gpOwn: 8, _gpA: 10},
        atWarPartners: const [_gpA],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [_gpA],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'When the lone GP is the primary invadable OW blocker and '
            'no minor pivot remains, the canonical helper must hold '
            'the war open (return const []) so the planner keeps '
            'fighting the blocker. A regression that dropped the '
            '!hasUninvadedOldWorldMinor gate would silently surrender '
            'the war here.',
      );
    });

    test(
      'sole GP fall-through (non-blocker, non-plateau) returns the single-GP list',
      () {
        // gp_own=8, gp_a=8 (stalled-plateau peers). gp_a holds nothing
        // on the invadable list; the sole invadable OW is owned by
        // minor_m1 → frontier is NOT GP-only. Plateau check fires but
        // gpOnlyFrontier=false → mutual-plateau carve-out skipped. The
        // blocker is null because gp_a owns no invadable, so the
        // sole-GP-blocker hold guard does not trigger. Multi-GP arm
        // requires length >= 2; with length 1 the function falls
        // through to `return gpWars` (single-GP fall-through path).
        final game = _gameOf(
          owOwners: const {_gpOwn: 8, _gpA: 8, _minorM1: 1},
          atWarPartners: const [_gpA],
        );
        final snapshot = _snapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
          atWarWith: const [_gpA],
          invadableProvinceIdsSorted: const ['oldWorld|minor_m1_1'],
        );
        expect(
          nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
          const [_gpA],
          reason:
              'The sole-GP fall-through path returns the single-GP list '
              'unchanged when neither the mutual-plateau carve-out nor '
              'the blocker hold-open guard fires.',
        );
      },
    );
  });

  group('nearQuotaHoldPeaceTargets — multi-GP arm', () {
    test('multi-GP at war excludes the blocker and returns ascending', () {
      // gp_own=8 (stalled-plateau, below quota). Three GPs at war
      // supplied out of order; gp_a owns the sole invadable OW
      // (blocker). Canonical helper returns [gp_b, gp_c] ascending.
      final game = _gameOf(
        owOwners: const {_gpOwn: 8, _gpA: 1, _gpB: 0, _gpC: 0},
        atWarPartners: const [_gpC, _gpA, _gpB],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [_gpC, _gpA, _gpB],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        const [_gpB, _gpC],
        reason:
            'The multi-GP arm excludes only the primary invadable OW '
            'blocker (gp_a) and returns the remaining GPs ascending '
            'across an out-of-order input list.',
      );
    });

    test(
      'multi-GP with null blocker (no invadable OW) returns every at-war GP sorted',
      () {
        // gp_own=8 (stalled-plateau). Two GPs at war but
        // invadableProvinceIdsSorted is empty → blocker == null →
        // every at-war GP is returned ascending.
        final game = _gameOf(
          owOwners: const {_gpOwn: 8, _gpA: 0, _gpB: 0},
          atWarPartners: const [_gpA, _gpB],
        );
        final snapshot = _snapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [_gpB, _gpA],
        );
        expect(
          nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
          const [_gpA, _gpB],
          reason:
              'When no invadable OW exists the blocker is null and the '
              'multi-GP arm peaces every at-war GP ascending.',
        );
      },
    );
  });

  group('nearQuotaHoldPeaceTargets — determinism / delegation', () {
    test('identical inputs return identical lists across two calls', () {
      final game = _gameOf(
        owOwners: const {_gpOwn: 8, _gpA: 1, _gpB: 0},
        atWarPartners: const [_gpA, _gpB],
      );
      final snapshot = _snapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
        atWarWith: const [_gpA, _gpB],
        invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
      );
      final first = nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot);
      final second = nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot);
      expect(
        second,
        first,
        reason:
            'Two consecutive canonical-helper invocations on identical '
            'inputs must return identical lists (Must-have #7).',
      );
    });

    test(
      'colonial_pressure stub matches canonical helper across representative shapes',
      () {
        // Iterate four diagnostic fixtures (above-quota guard, sole-GP
        // mutual-plateau peace, sole-GP blocker hold, multi-GP exclude
        // blocker) and pin that the colonial_pressure stub mirrors the
        // canonical expand_phase_planner helper for each.
        final cases = <(Game, AIWorldSnapshot, String)>[
          (
            _gameOf(
              owOwners: const {_gpOwn: 10, _gpA: 1},
              atWarPartners: const [_gpA],
            ),
            _snapshot(
              oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
              atWarWith: const [_gpA],
              invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
            ),
            'above quota',
          ),
          (
            _gameOf(
              owOwners: const {_gpOwn: 8, _gpA: 8},
              atWarPartners: const [_gpA],
            ),
            _snapshot(
              oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
              atWarWith: const [_gpA],
              invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
            ),
            'sole-GP mutual-plateau peace',
          ),
          (
            _gameOf(
              owOwners: const {_gpOwn: 8, _gpA: 8, _minorM1: 1},
              atWarPartners: const [_gpA],
            ),
            _snapshot(
              oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
              atWarWith: const [_gpA],
              invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
            ),
            'sole-GP blocker hold-open',
          ),
          (
            _gameOf(
              owOwners: const {_gpOwn: 8, _gpA: 1, _gpB: 0, _gpC: 0},
              atWarPartners: const [_gpA, _gpB, _gpC],
            ),
            _snapshot(
              oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold - 1,
              atWarWith: const [_gpA, _gpB, _gpC],
              invadableProvinceIdsSorted: const ['oldWorld|gp_a_1'],
            ),
            'multi-GP exclude blocker',
          ),
        ];
        for (final (game, snapshot, label) in cases) {
          expect(
            colonial_pressure.nearQuotaHoldPeaceTargets(
              game: game,
              snapshot: snapshot,
            ),
            nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
            reason:
                'colonial_pressure delegating stub must mirror the '
                'canonical helper for case "$label" so the legacy '
                'fixtures and consumer chain agree on the decider.',
          );
        }
      },
    );
  });
}
