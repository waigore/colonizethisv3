// Pins the equal-count tiebreak contract of the plurality-winner blocker
// helpers `primaryInvadableOldWorldGpBlocker` (`colonial_pressure.dart`) and
// `primaryColonialGpBlocker` (`observer_goal_phase.dart`) from issue #2509 S10.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI), EXPAND
//     "Acquire OW provinces by the simplest legal path" / blocker-preservation
//     peace targets; COLONIAL "offerPeace toward at-war Great Powers that do
//     not own the primary colonial NW frontier blocker when fighting two or
//     more GPs".
//   - Must-have #7 determinism — `colonizethis_ai` patterns in
//     `economy_planner_test.dart` / `tactical_ai_test.dart`.
//
// The two helpers identify the GP owning the most invadable provinces in
// their respective regions. Both used a quadratic nested-loop implementation
// (`for province { count provinces owned by this owner }`) that depended on
// strict `>` over a running max plus the deterministic outer iteration over
// the sorted invadable list for its tiebreak — when two or more GPs hold the
// same plurality count, the GP whose first owned province appears earliest in
// the sorted invadable list wins. The linearized refactor (Refs
// `colonizethis-turn-resolution-budget.mdc` § Reuse validation state /
// Memoize per-target/per-player computations) must preserve that exact
// behavior; otherwise the COLONIAL / EXPAND peace-target preservation set
// would shift silently for any seed-42 turn that produces a 2-vs-2 split.
//
// Existing coverage gaps this file closes:
//   - `observer_goal_phase_expand_peace_blocker_branches_test.dart` and the
//     consolidated PR #2676 `observer_goal_phase_colonial_peace_blocker_branches_test.dart`
//     both pin "plurality wins (2 vs 1)" but do not exercise an explicit
//     equal-count split between two GPs at the function-unit boundary. A
//     refactor that tied by `factionId` ascending or by last-seen owner
//     would still pass the 2-vs-1 pin but would silently invert this
//     tiebreak.
//   - Neither file pins a "many-province" regression on the strict `>`
//     contract: a refactor that switched to `>=` would also pass the
//     existing 2-vs-1 pin but would flip the tiebreak winner here.
//
// Coverage layers:
//   - Function unit (`primaryInvadableOldWorldGpBlocker`): equal-count
//     tiebreak (2 vs 2 split) with both orderings of which GP's provinces
//     sort first; deterministic 3-GP-tied split.
//   - Function unit (`primaryColonialGpBlocker`): equal-count tiebreak
//     (2 vs 2 split) with both orderings of which GP's provinces sort
//     first; deterministic 3-GP-tied split.
//   - Determinism guard: identical inputs produce identical blocker output
//     across repeat calls.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';

const List<Player> _fourGpRoster = [
  Player(id: _gp1, displayName: 'GP1', isHuman: false),
  Player(id: _gp2, displayName: 'GP2', isHuman: false),
  Player(id: _gp3, displayName: 'GP3', isHuman: false),
  Player(id: _gp4, displayName: 'GP4', isHuman: false),
];

Game _gameForOwBlocker(List<Province> owProvinces) {
  return Game(
    id: 'g-2509-primary-blocker-tiebreak-ow',
    worldState: WorldState(
      turnState: const TurnState(
        turnNumber: 50,
        phase: TurnPhase.orders,
      ),
      oldWorld: RegionData(provinces: owProvinces),
      newWorld: const RegionData(),
    ),
    players: _fourGpRoster,
  );
}

Game _gameForNwBlocker(List<Province> nwProvinces) {
  return Game(
    id: 'g-2509-primary-blocker-tiebreak-nw',
    worldState: WorldState(
      turnState: const TurnState(
        turnNumber: 110,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: nwProvinces),
    ),
    players: _fourGpRoster,
  );
}

AIWorldSnapshot _expandSnapshotForOw({
  required List<String> invadableOw,
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 8,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

AIWorldSnapshot _colonialSnapshotForNw({
  required List<String> invadableNw,
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: 21,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('primaryInvadableOldWorldGpBlocker tiebreak', () {
    test('2-vs-2 split: gp2 wins when its sorted provinces appear first', () {
      // gp2 owns oldWorld|a*, gp3 owns oldWorld|b*. Sorted iteration visits
      // gp2's provinces before gp3's, so gp2 reaches count=2 before gp3 ever
      // updates the running max. Under strict `>` gp3 cannot displace gp2.
      final game = _gameForOwBlocker(const [
        Province(id: 'oldWorld|a1', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|a2', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|b1', regionId: 'oldWorld', ownerId: _gp3),
        Province(id: 'oldWorld|b2', regionId: 'oldWorld', ownerId: _gp3),
      ]);
      final snapshot = _expandSnapshotForOw(
        invadableOw: const [
          'oldWorld|a1',
          'oldWorld|a2',
          'oldWorld|b1',
          'oldWorld|b2',
        ],
      );
      expect(
        primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
        _gp2,
        reason:
            'Equal-count plurality must resolve by first-iterated-province '
            'order over `invadableProvinceIdsSorted`. A refactor that '
            'switched the strict `>` to `>=` would flip this to gp3 and '
            'silently invert the EXPAND blocker-preservation set on every '
            '2-vs-2 turn.',
      );
    });

    test('2-vs-2 split: gp3 wins when its sorted provinces appear first', () {
      // Symmetric inversion: gp3's provinces (oldWorld|a*) now sort before
      // gp2's (oldWorld|b*). The plurality winner flips to gp3 because the
      // first-iterated GP owner reaches count=2 first.
      final game = _gameForOwBlocker(const [
        Province(id: 'oldWorld|a1', regionId: 'oldWorld', ownerId: _gp3),
        Province(id: 'oldWorld|a2', regionId: 'oldWorld', ownerId: _gp3),
        Province(id: 'oldWorld|b1', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|b2', regionId: 'oldWorld', ownerId: _gp2),
      ]);
      final snapshot = _expandSnapshotForOw(
        invadableOw: const [
          'oldWorld|a1',
          'oldWorld|a2',
          'oldWorld|b1',
          'oldWorld|b2',
        ],
      );
      expect(
        primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot),
        _gp3,
        reason:
            'Equal-count plurality must resolve by first-iterated-province '
            'order, not by ascending factionId. A refactor that picked the '
            'lowest factionId on a tie would still return gp2 here and '
            'fail this symmetric inversion of the previous case.',
      );
    });

    test('3-way 2-2-2 tie: first GP in sorted order wins deterministically',
        () {
      // gp2, gp3, gp4 each own two invadable OW provinces; sorted iteration
      // visits gp2's pair first. Determinism guard: identical inputs must
      // produce an identical winner across repeat calls (must-have #7).
      final game = _gameForOwBlocker(const [
        Province(id: 'oldWorld|a1', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|a2', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|b1', regionId: 'oldWorld', ownerId: _gp3),
        Province(id: 'oldWorld|b2', regionId: 'oldWorld', ownerId: _gp3),
        Province(id: 'oldWorld|c1', regionId: 'oldWorld', ownerId: _gp4),
        Province(id: 'oldWorld|c2', regionId: 'oldWorld', ownerId: _gp4),
      ]);
      final snapshot = _expandSnapshotForOw(
        invadableOw: const [
          'oldWorld|a1',
          'oldWorld|a2',
          'oldWorld|b1',
          'oldWorld|b2',
          'oldWorld|c1',
          'oldWorld|c2',
        ],
      );
      final first = primaryInvadableOldWorldGpBlocker(
        game: game,
        snapshot: snapshot,
      );
      final second = primaryInvadableOldWorldGpBlocker(
        game: game,
        snapshot: snapshot,
      );
      expect(first, _gp2);
      expect(
        second,
        _gp2,
        reason:
            'Determinism guard: identical fixture must produce the same '
            'plurality winner on repeat calls.',
      );
    });
  });

  group('primaryColonialGpBlocker tiebreak', () {
    test('2-vs-2 split: gp2 wins when its sorted provinces appear first', () {
      // Mirror of the OW tiebreak case for the NW colonial blocker. gp2 owns
      // the first two invadable NW provinces in sorted order; gp3 owns the
      // remaining two. The COLONIAL blocker-preservation set keeps the war
      // with gp2 intact and peaces gp3 (when both are at war).
      final game = _gameForNwBlocker(const [
        Province(id: 'newWorld|a1', regionId: 'newWorld', ownerId: _gp2),
        Province(id: 'newWorld|a2', regionId: 'newWorld', ownerId: _gp2),
        Province(id: 'newWorld|b1', regionId: 'newWorld', ownerId: _gp3),
        Province(id: 'newWorld|b2', regionId: 'newWorld', ownerId: _gp3),
      ]);
      final snapshot = _colonialSnapshotForNw(
        invadableNw: const [
          'newWorld|a1',
          'newWorld|a2',
          'newWorld|b1',
          'newWorld|b2',
        ],
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        _gp2,
        reason:
            'Equal-count plurality must resolve by first-iterated-province '
            'order over `invadableNewWorldProvinceIdsSorted`. A refactor '
            'switching strict `>` to `>=` would flip this to gp3 and '
            'silently shift COLONIAL peace-preservation onto the wrong GP.',
      );
    });

    test('2-vs-2 split: gp3 wins when its sorted provinces appear first', () {
      // Symmetric inversion to confirm the tiebreak is genuinely
      // first-iterated-province driven, not a factionId-ascending bias.
      final game = _gameForNwBlocker(const [
        Province(id: 'newWorld|a1', regionId: 'newWorld', ownerId: _gp3),
        Province(id: 'newWorld|a2', regionId: 'newWorld', ownerId: _gp3),
        Province(id: 'newWorld|b1', regionId: 'newWorld', ownerId: _gp2),
        Province(id: 'newWorld|b2', regionId: 'newWorld', ownerId: _gp2),
      ]);
      final snapshot = _colonialSnapshotForNw(
        invadableNw: const [
          'newWorld|a1',
          'newWorld|a2',
          'newWorld|b1',
          'newWorld|b2',
        ],
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        _gp3,
      );
    });

    test('3-way 2-2-2 tie: first GP in sorted order wins deterministically',
        () {
      final game = _gameForNwBlocker(const [
        Province(id: 'newWorld|a1', regionId: 'newWorld', ownerId: _gp2),
        Province(id: 'newWorld|a2', regionId: 'newWorld', ownerId: _gp2),
        Province(id: 'newWorld|b1', regionId: 'newWorld', ownerId: _gp3),
        Province(id: 'newWorld|b2', regionId: 'newWorld', ownerId: _gp3),
        Province(id: 'newWorld|c1', regionId: 'newWorld', ownerId: _gp4),
        Province(id: 'newWorld|c2', regionId: 'newWorld', ownerId: _gp4),
      ]);
      final snapshot = _colonialSnapshotForNw(
        invadableNw: const [
          'newWorld|a1',
          'newWorld|a2',
          'newWorld|b1',
          'newWorld|b2',
          'newWorld|c1',
          'newWorld|c2',
        ],
      );
      final first = primaryColonialGpBlocker(game: game, snapshot: snapshot);
      final second = primaryColonialGpBlocker(game: game, snapshot: snapshot);
      expect(first, _gp2);
      expect(second, _gp2, reason: 'Determinism guard (must-have #7).');
    });

    test('large-N many-province scenario: plurality winner is stable', () {
      // 30-invadable-NW fixture stresses the linearized scan path (the
      // previous quadratic implementation traversed 30 * 30 = 900 inner
      // iterations; the refactored version visits each province twice).
      // The plurality GP must remain gp3 with 15 owned invadable NW
      // provinces against gp2's 10 and gp4's 5.
      final provinces = <Province>[
        for (var i = 0; i < 10; i++)
          Province(
            id: 'newWorld|gp2_$i',
            regionId: 'newWorld',
            ownerId: _gp2,
          ),
        for (var i = 0; i < 15; i++)
          Province(
            id: 'newWorld|gp3_$i',
            regionId: 'newWorld',
            ownerId: _gp3,
          ),
        for (var i = 0; i < 5; i++)
          Province(
            id: 'newWorld|gp4_$i',
            regionId: 'newWorld',
            ownerId: _gp4,
          ),
      ];
      final game = _gameForNwBlocker(provinces);
      final invadable = [for (final p in provinces) p.id]..sort();
      final snapshot = _colonialSnapshotForNw(invadableNw: invadable);
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        _gp3,
        reason:
            'Strict plurality (15 > 10 > 5) must continue to resolve to gp3 '
            'after the quadratic-to-linear refactor. A regression that '
            'tallied counts incorrectly (e.g. counting tribe-owned or '
            'unowned provinces, or skipping the strict `>` update) would '
            'shift the winner.',
      );
    });
  });
}
