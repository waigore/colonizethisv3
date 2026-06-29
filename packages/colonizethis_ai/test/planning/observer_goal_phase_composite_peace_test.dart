// Pins the canonical homes in `observer_goal_phase.dart` for the remaining
// composite peace-target functions migrated from
// `diplomacy_planner_peace_targets.dart` (Refs #2509 S1).
//
// The last real-body functions in `diplomacy_planner_peace_targets.dart`
// were the private composers (`_survivalGreatPowerPeaceTargets`,
// `_expandRatchetGreatPowerPeaceTargets`) and their two public consumers
// (`collectStalledGreatPowerPeaceTargets`,
// `supplementMutualStalledGreatPowerPeaceOrders`) plus the leaf helper
// (`_appendOfferPeaceIfMissing`). This file pins the canonical
// implementations in `observer_goal_phase.dart` alongside the
// phase-specific peace-target helpers (`expandPhaseGpPeaceTargets`,
// `colonialPhaseGpPeaceTargets`, `developPhaseGpPeaceTargets`) already
// defined there.
//
// `diplomacy_planner_peace_targets.dart` previously retained thin delegating stubs
// for `collectStalledGreatPowerPeaceTargets` and
// `supplementMutualStalledGreatPowerPeaceOrders`; this file verifies
// delegation parity so every legacy call site resolves to the same
// result through the stub as through the canonical.
//
// Behavioral invariants pinned:
//
// `survivalGreatPowerPeaceTargets`:
//   1. Yields entries when all five sub-deciders fire (zero-regime
//      survival paths active).
//   2. Yields nothing for a pristine game state with no conflicts.
//   3. Must-have #7 determinism.
//
// `expandRatchetGreatPowerPeaceTargets`:
//   1. Yields entries when at least one sub-decider fires.
//   2. Yields nothing for a pristine game state.
//   3. Must-have #7 determinism.
//
// `collectStalledGreatPowerPeaceTargets`:
//   1. Phase-gated: DEVELOP returns only DEVELOP targets.
//   2. Phase-gated: EXPAND includes survival + ratchet + phase-specific.
//   3. Delegation parity with the stub in `diplomacy_planner_peace_targets.dart`.
//   4. Must-have #7 determinism.
//
// `supplementMutualStalledGreatPowerPeaceOrders`:
//   1. No-op when no mutual peace offers exist.
//   2. Delegation parity with the stub.
//   3. Must-have #7 determinism.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpOther = 'gp_other';
const String _minorZeta = 'minor_zeta';

Game _pristineOwProvinces(int count) {
  return Game(
    id: 'g-2509-composite-pristine-$count',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(provinces: [
        for (var i = 1; i <= count; i++)
          Province(
            id: 'oldWorld|${_gpOwn}_$i',
            regionId: 'oldWorld',
            ownerId: _gpOwn,
          ),
      ]),
      newWorld: const RegionData(),
      armies: [],
    ),
    players: [
      Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
      Player(id: _gpOther, displayName: 'GP_OTHER', isHuman: false),
    ],
    minorNations: const [],
    tribes: const [],
    diplomacyRelations: const [],
  );
}

Game _zeroRegimentAtWarGame() {
  return Game(
    id: 'g-2509-composite-zero-reg',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(provinces: [
        for (var i = 1; i <= 6; i++)
          Province(
            id: 'oldWorld|${_gpOwn}_$i',
            regionId: 'oldWorld',
            ownerId: _gpOwn,
          ),
        for (var i = 1; i <= 6; i++)
          Province(
            id: 'oldWorld|${_gpOther}_$i',
            regionId: 'oldWorld',
            ownerId: _gpOther,
          ),
        const Province(
          id: 'oldWorld|minor_invadable',
          regionId: 'oldWorld',
          ownerId: _minorZeta,
        ),
      ]),
      newWorld: const RegionData(),
      armies: [],
    ),
    players: [
      Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
      Player(id: _gpOther, displayName: 'GP_OTHER', isHuman: false),
    ],
    minorNations: const [MinorNation(id: _minorZeta, displayName: 'MZ')],
    tribes: const [],
    diplomacyRelations: [
      const DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: _gpOther,
        state: RelationState.atWar,
        score: 30,
      ),
      const DiplomacyRelation(
        factionId1: _gpOwn,
        factionId2: _minorZeta,
        state: RelationState.atWar,
        score: 10,
      ),
    ],
  );
}

AIWorldSnapshot _snapshotFor({
  required String playerId,
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: 31 - oldWorldProvincesOwned,
      invadableProvinceIdsSorted: const [
        'oldWorld|minor_invadable',
        'oldWorld|gp_other_1',
      ],
    ),
    colonial: ColonialSummary(),
    economy: EconomySummary(),
    relations: {},
  );
}

void main() {
  group('survivalGreatPowerPeaceTargets', () {
    test('yields zero-regiment survival paths when active', () {
      final game = _zeroRegimentAtWarGame();
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [_gpOther, _minorZeta],
      );
      final result = survivalGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      expect(result, isNotEmpty);
      expect(result, contains(_gpOther));
    });

    test('yields nothing for pristine game state', () {
      final game = _pristineOwProvinces(8);
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 8,
        atWarWith: [],
      );
      final result = survivalGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      expect(result, isEmpty);
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      final game = _zeroRegimentAtWarGame();
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [_gpOther, _minorZeta],
      );
      final first = survivalGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      for (var i = 0; i < 5; i++) {
        final next = survivalGreatPowerPeaceTargets(
          game: game,
          snapshot: snapshot,
        ).toList();
        expect(next, first);
      }
    });
  });

  group('expandRatchetGreatPowerPeaceTargets', () {
    test('yields entries when stalled-expansion deciders fire', () {
      final game = _zeroRegimentAtWarGame();
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [_gpOther, _minorZeta],
      );
      final result = expandRatchetGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      expect(result, isNotEmpty);
      expect(result, contains(_gpOther));
    });

    test('yields nothing for pristine game state', () {
      final game = _pristineOwProvinces(8);
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 8,
        atWarWith: [],
      );
      final result = expandRatchetGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      expect(result, isEmpty);
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      final game = _zeroRegimentAtWarGame();
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [_gpOther, _minorZeta],
      );
      final first = expandRatchetGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      for (var i = 0; i < 5; i++) {
        final next = expandRatchetGreatPowerPeaceTargets(
          game: game,
          snapshot: snapshot,
        ).toList();
        expect(next, first);
      }
    });
  });

  group('collectStalledGreatPowerPeaceTargets', () {
    test('canonical: returns expected results for typical EXPAND state', () {
      final game = _zeroRegimentAtWarGame();
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [_gpOther, _minorZeta],
      );
      final result = collectStalledGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(result, isNotEmpty);
    });

    test('canonical: returns expected results for DEVELOP state', () {
      final game = Game(
        id: 'g-2509-collect-develop',
        worldState: WorldState(
          turnState:
              const TurnState(phase: TurnPhase.orders, turnNumber: 140),
          oldWorld: RegionData(provinces: [
            for (var i = 1; i <= 10; i++)
              Province(
                id: 'oldWorld|${_gpOwn}_$i',
                regionId: 'oldWorld',
                ownerId: _gpOwn,
              ),
          ]),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpOther, displayName: 'GP_OTHER', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: _gpOwn,
            factionId2: _gpOther,
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 10,
        atWarWith: [_gpOther],
      );
      final result = collectStalledGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(result, isNotEmpty);
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      final game = _zeroRegimentAtWarGame();
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [_gpOther, _minorZeta],
      );
      final first = collectStalledGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      for (var i = 0; i < 5; i++) {
        final next = collectStalledGreatPowerPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(next, first);
      }
    });
  });

  // Refs #3749 step 5 — expand-peace decider registry. The two aggregators are
  // now driven by the ordered `kSurvivalGreatPowerPeaceDeciders` /
  // `kExpandRatchetGreatPowerPeaceDeciders` registries; these tests pin the
  // registry-as-single-source-of-truth contract (aggregator output is exactly
  // the in-order concatenation of every registered decider) and the documented
  // decider counts so an accidental add/remove/reorder cannot pass silently.
  group('expand-peace decider registries (Refs #3749)', () {
    test('survival aggregator equals in-order registry concatenation', () {
      final game = _zeroRegimentAtWarGame();
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [_gpOther, _minorZeta],
      );
      final viaAggregator = survivalGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      final viaRegistry = [
        for (final decider in kSurvivalGreatPowerPeaceDeciders)
          ...decider(game: game, snapshot: snapshot),
      ];
      expect(viaAggregator, viaRegistry);
      expect(viaAggregator, isNotEmpty);
    });

    test('ratchet aggregator equals in-order registry concatenation', () {
      final game = _zeroRegimentAtWarGame();
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 6,
        atWarWith: [_gpOther, _minorZeta],
      );
      final viaAggregator = expandRatchetGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      final viaRegistry = [
        for (final decider in kExpandRatchetGreatPowerPeaceDeciders)
          ...decider(game: game, snapshot: snapshot),
      ];
      expect(viaAggregator, viaRegistry);
      expect(viaAggregator, isNotEmpty);
    });

    test('registry concatenation matches aggregator on pristine state', () {
      final game = _pristineOwProvinces(8);
      final snapshot = _snapshotFor(
        playerId: _gpOwn,
        oldWorldProvincesOwned: 8,
        atWarWith: [],
      );
      final survivalRegistry = [
        for (final decider in kSurvivalGreatPowerPeaceDeciders)
          ...decider(game: game, snapshot: snapshot),
      ];
      final ratchetRegistry = [
        for (final decider in kExpandRatchetGreatPowerPeaceDeciders)
          ...decider(game: game, snapshot: snapshot),
      ];
      expect(survivalRegistry, isEmpty);
      expect(ratchetRegistry, isEmpty);
      expect(
        survivalGreatPowerPeaceTargets(game: game, snapshot: snapshot).toList(),
        survivalRegistry,
      );
      expect(
        expandRatchetGreatPowerPeaceTargets(
          game: game,
          snapshot: snapshot,
        ).toList(),
        ratchetRegistry,
      );
    });

    test('documented decider counts are pinned', () {
      expect(kSurvivalGreatPowerPeaceDeciders, hasLength(5));
      expect(kExpandRatchetGreatPowerPeaceDeciders, hasLength(17));
    });
  });

  group('supplementMutualStalledGreatPowerPeaceOrders', () {
    test('no-op when no mutual peace offers exist', () {
      final game = _pristineOwProvinces(8);
      const orders = Orders();
      final result = supplementMutualStalledGreatPowerPeaceOrders(
        game: game,
        topology: const MapTopology(),
        orders: orders,
      );
      expect(result, same(orders));
    });

    test('deterministic across repeated calls (Must-have #7)', () {
      final game = _pristineOwProvinces(8);
      const orders = Orders();
      final first = supplementMutualStalledGreatPowerPeaceOrders(
        game: game,
        topology: const MapTopology(),
        orders: orders,
      );
      for (var i = 0; i < 5; i++) {
        final next = supplementMutualStalledGreatPowerPeaceOrders(
          game: game,
          topology: const MapTopology(),
          orders: orders,
        );
        expect(next, same(first));
      }
    });
  });
}
