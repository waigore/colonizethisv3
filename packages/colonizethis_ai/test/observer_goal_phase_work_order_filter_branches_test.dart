// Pins the per-phase branch contract of `shouldFilterObserverPhaseWorkOrder`
// and its `isNewWorldColonialWorkOrder` helper at the predicate level
// (Refs #2509 S10).
//
// SPEC/ai/ai-architecture.md § Observer goal phases (Full AI):
//
//   EXPAND suppressions: ... `purchase_land` / NW `build_improvement`
//     civilian work ...
//   COLONIAL-lite: ... suppresses NW `declareWar`, invasion army moves, and
//     `purchase_land` only.
//   DEVELOP: Suppresses all new `declareWar` and NW acquisition; forces
//     civilian work selection with improvement-first threshold
//     (`kDevelopCivilianWorkThresholdCap`) ...
//
// The civilian-work side of those phase rules is implemented as branch logic
// in `shouldFilterObserverPhaseWorkOrder` (`observer_goal_phase.dart`):
//
//   if (phase == ObserverGoalPhase.expand) {
//     return isNewWorldColonialWorkOrder(order);
//   }
//   if (phase == ObserverGoalPhase.colonialLite ||
//       phase == ObserverGoalPhase.develop) {
//     if (order.target == kWorkTargetPurchaseLand &&
//         ProvinceId.regionIdFrom(order.targetTileKey) == kNewWorldRegionId) {
//       return true;
//     }
//   }
//   return false;
//
// Existing function-level pins in `observer_goal_phase_test.dart` group
// `shouldFilterObserverPhaseWorkOrder` cover:
//   - EXPAND: NW `purchase_land` and NW `build_improvement` filtered,
//     OW `build_improvement` unfiltered.
//   - COLONIAL-lite: NW `purchase_land` filtered, NW `build_improvement`
//     unfiltered.
//
// What is **not** pinned at the predicate level today:
//   - **COLONIAL** — the only phase where NW acquisition is the imperative;
//     the filter must return `false` for every work order so the
//     `runDomainPlanners` selection pass can pick NW `purchase_land` and NW
//     `build_improvement` targets. A regression that filtered NW orders in
//     COLONIAL would silently block both the SPEC § Observer goal phases
//     (Full AI) COLONIAL imperative ("NW acquisition") and the issue #2509
//     must-have #2 (`purchase_land` is one of the required acquisition
//     paths).
//   - **DEVELOP NW `build_improvement` pass-through** — the DEVELOP
//     imperative is improvement-first (per SPEC § Observer goal phases
//     (Full AI)) and the turn-150 observer gate requires
//     `improvedExtractableCount / extractableResourceTileCount >= 0.70`
//     across **both** OW and NW resource tiles. The filter must drop NW
//     `purchase_land` but keep NW `build_improvement`; a regression that
//     dropped NW `build_improvement` would make the 70% gate unreachable.
//   - **DEVELOP OW `purchase_land` pass-through** — the DEVELOP NW
//     acquisition suppression must be region-scoped: an OW
//     `purchase_land` order is not a colonial acquisition and the filter
//     must not over-fire on it.
//   - **COLONIAL-lite OW `purchase_land` pass-through** — same regional
//     scoping as DEVELOP: the COLONIAL-lite suppression is NW-only.
//   - **`isNewWorldColonialWorkOrder` direct branches** — the predicate is
//     consumed by the EXPAND branch of `shouldFilterObserverPhaseWorkOrder`
//     but is also exported from `observer_goal_phase.dart` for orchestrator
//     and planner reuse; its branch contract (NW + `purchase_land` or NW +
//     `build_improvement` → true; everything else → false) is not pinned in
//     isolation today.
//
// Coverage layers below:
//   - Positive: phase rule fires when intended (NW acquisition is dropped in
//     COLONIAL-lite and DEVELOP; nothing fires in COLONIAL).
//   - Negative: phase rule does **not** over-fire (NW `build_improvement`
//     survives in DEVELOP; OW `purchase_land` survives in DEVELOP and
//     COLONIAL-lite; no order is filtered in COLONIAL).
//   - Branch: every input combination of `isNewWorldColonialWorkOrder` is
//     exercised directly (NW + acquisition target, NW + non-acquisition
//     target, OW + acquisition target, OW + non-acquisition target).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _nationId = 'gp1';
const String _owTile = 'oldWorld|home|0|0';
const String _nwTile = 'newWorld|p1|0|0';

const AIWorldSnapshot _expandSnapshot = AIWorldSnapshot(
  playerId: _nationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(oldWorldProvincesOwned: 7),
  colonial: ColonialSummary(),
  economy: EconomySummary(),
  relations: {},
);

const AIWorldSnapshot _colonialSnapshot = AIWorldSnapshot(
  playerId: _nationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(oldWorldProvincesOwned: 11),
  colonial: ColonialSummary(
    invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1'],
  ),
  economy: EconomySummary(),
  relations: {},
);

const AIWorldSnapshot _developSnapshot = AIWorldSnapshot(
  playerId: _nationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(oldWorldProvincesOwned: 11),
  colonial: ColonialSummary(newWorldProvincesOwned: 2),
  economy: EconomySummary(),
  relations: {},
);

/// COLONIAL-lite requires turn ≥ `kObserverColonialLiteMinTurn`,
/// `oldWorldProvincesOwned >= kObserverColonialLiteNearQuotaOw` and below
/// quota, plus at least one non-GP-owned `newWorld|` province (per
/// `isObserverColonialLitePhase`). The minimum fixture below satisfies all
/// three so the COLONIAL-lite branch is reachable from
/// `observerGoalPhaseFor`.
Game _colonialLiteGame() {
  return Game(
    id: 'g-2509-work-filter-colonial-lite',
    worldState: WorldState(
      turnState: const TurnState(
        turnNumber: kObserverColonialLiteMinTurn,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: const [
          Province(
            id: 'newWorld|tribe1',
            regionId: kNewWorldRegionId,
            ownerId: 'tribe1',
          ),
        ],
      ),
    ),
    players: const [Player(id: _nationId, displayName: 'P1', isHuman: false)],
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
    minorNations: const [],
  );
}

const AIWorldSnapshot _colonialLiteSnapshot = AIWorldSnapshot(
  playerId: _nationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
  ),
  colonial: ColonialSummary(
    invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1'],
  ),
  economy: EconomySummary(),
  relations: {},
);

WorkOrder _workOrder(String target, String tileKey) =>
    WorkOrder(unitId: 'u1', target: target, targetTileKey: tileKey);

void main() {
  group('shouldFilterObserverPhaseWorkOrder COLONIAL branch', () {
    test('phase fixture resolves to COLONIAL (control)', () {
      expect(
        observerGoalPhaseFor(snapshot: _colonialSnapshot),
        ObserverGoalPhase.colonial,
        reason:
            'COLONIAL coverage requires OW quota met (>=10) and visible '
            'colonial acquisition targets. Fixture must place GP in '
            'COLONIAL so the no-filter contract is exercised, not the '
            'DEVELOP fall-through.',
      );
    });

    test('COLONIAL keeps NW purchase_land available for selection', () {
      expect(
        shouldFilterObserverPhaseWorkOrder(
          _workOrder(kWorkTargetPurchaseLand, _nwTile),
          snapshot: _colonialSnapshot,
        ),
        isFalse,
        reason:
            'COLONIAL imperative is NW acquisition (SPEC § Observer goal '
            'phases (Full AI) COLONIAL row); filtering NW purchase_land '
            'would silently block must-have #2 (`purchase_land` is one of '
            'the required acquisition paths).',
      );
    });

    test('COLONIAL keeps NW build_improvement available for selection', () {
      expect(
        shouldFilterObserverPhaseWorkOrder(
          _workOrder(kWorkTargetBuildImprovement, _nwTile),
          snapshot: _colonialSnapshot,
        ),
        isFalse,
        reason:
            'COLONIAL must allow NW build_improvement so post-acquisition '
            'improvements on newly GP-owned NW tiles can feed the turn-150 '
            '70% extractable improvement gate without waiting for DEVELOP.',
      );
    });

    test('COLONIAL keeps OW purchase_land available for selection', () {
      expect(
        shouldFilterObserverPhaseWorkOrder(
          _workOrder(kWorkTargetPurchaseLand, _owTile),
          snapshot: _colonialSnapshot,
        ),
        isFalse,
        reason:
            'COLONIAL must not apply NW-targeted suppressions to OW orders.',
      );
    });

    test('COLONIAL keeps OW build_improvement available for selection', () {
      expect(
        shouldFilterObserverPhaseWorkOrder(
          _workOrder(kWorkTargetBuildImprovement, _owTile),
          snapshot: _colonialSnapshot,
        ),
        isFalse,
        reason:
            'COLONIAL imposes no civilian-work filters; OW work orders are '
            'unaffected by the phase predicate.',
      );
    });
  });

  group('shouldFilterObserverPhaseWorkOrder DEVELOP branch', () {
    test('phase fixture resolves to DEVELOP (control)', () {
      expect(
        observerGoalPhaseFor(snapshot: _developSnapshot),
        ObserverGoalPhase.develop,
        reason:
            'DEVELOP coverage requires OW quota met (>=10) and no visible '
            'colonial acquisition targets. Fixture must place GP in '
            'DEVELOP so the NW-acquisition suppression contract is '
            'exercised, not the COLONIAL fall-through.',
      );
    });

    test('DEVELOP drops NW purchase_land (NW acquisition suppression)', () {
      expect(
        shouldFilterObserverPhaseWorkOrder(
          _workOrder(kWorkTargetPurchaseLand, _nwTile),
          snapshot: _developSnapshot,
        ),
        isTrue,
        reason:
            'DEVELOP suppresses all NW acquisition (SPEC § Observer goal '
            'phases (Full AI) DEVELOP rule); `purchase_land` toward a NW '
            'tile is the canonical NW acquisition work target.',
      );
    });

    test(
      'DEVELOP keeps NW build_improvement (DEVELOP imperative, 70% gate)',
      () {
        expect(
          shouldFilterObserverPhaseWorkOrder(
            _workOrder(kWorkTargetBuildImprovement, _nwTile),
            snapshot: _developSnapshot,
          ),
          isFalse,
          reason:
              'DEVELOP imperative is improvement-first development across '
              'both regions; NW `build_improvement` on GP-owned tiles must '
              'survive the filter so the turn-150 70% extractable '
              'improvement gate remains reachable for NW tiles.',
        );
      },
    );

    test(
      'DEVELOP keeps OW purchase_land (NW suppression is region-scoped)',
      () {
        expect(
          shouldFilterObserverPhaseWorkOrder(
            _workOrder(kWorkTargetPurchaseLand, _owTile),
            snapshot: _developSnapshot,
          ),
          isFalse,
          reason:
              'OW `purchase_land` is not a colonial acquisition; the DEVELOP '
              'NW-acquisition filter must not over-fire on OW orders.',
        );
      },
    );

    test(
      'DEVELOP keeps OW build_improvement (DEVELOP imperative, 70% gate)',
      () {
        expect(
          shouldFilterObserverPhaseWorkOrder(
            _workOrder(kWorkTargetBuildImprovement, _owTile),
            snapshot: _developSnapshot,
          ),
          isFalse,
          reason:
              'DEVELOP imperative is improvement-first development across '
              'both regions; OW build_improvement is the primary contributor '
              'to the 70% extractable improvement gate.',
        );
      },
    );
  });

  group('shouldFilterObserverPhaseWorkOrder COLONIAL-lite OW pass-through', () {
    test('phase fixture resolves to COLONIAL-lite (control)', () {
      expect(
        observerGoalPhaseFor(
          snapshot: _colonialLiteSnapshot,
          game: _colonialLiteGame(),
        ),
        ObserverGoalPhase.colonialLite,
        reason:
            'COLONIAL-lite requires turn ≥ kObserverColonialLiteMinTurn, '
            'oldWorldProvincesOwned >= kObserverColonialLiteNearQuotaOw and '
            'below quota, plus non-GP-owned newWorld| ownership. Fixture '
            'must place GP in COLONIAL-lite so the OW pass-through '
            'contract is exercised, not the EXPAND fall-through.',
      );
    });

    test('COLONIAL-lite keeps OW purchase_land (NW suppression only)', () {
      expect(
        shouldFilterObserverPhaseWorkOrder(
          _workOrder(kWorkTargetPurchaseLand, _owTile),
          snapshot: _colonialLiteSnapshot,
          game: _colonialLiteGame(),
        ),
        isFalse,
        reason:
            'COLONIAL-lite suppresses NW `declareWar`, invasion army moves, '
            'and `purchase_land` only (SPEC § Observer goal phases (Full '
            'AI) COLONIAL-lite row); OW `purchase_land` is unaffected.',
      );
    });
  });

  group('isNewWorldColonialWorkOrder branch coverage', () {
    test('NW purchase_land is a New World colonial work order', () {
      expect(
        isNewWorldColonialWorkOrder(
          _workOrder(kWorkTargetPurchaseLand, _nwTile),
        ),
        isTrue,
      );
    });

    test('NW build_improvement is a New World colonial work order', () {
      expect(
        isNewWorldColonialWorkOrder(
          _workOrder(kWorkTargetBuildImprovement, _nwTile),
        ),
        isTrue,
      );
    });

    test('NW explore is not a New World colonial work order', () {
      // Civilian work targets exist beyond `purchase_land` /
      // `build_improvement` (e.g. `explore`, `prospect`); only the two
      // listed targets are EXPAND-suppressed regardless of region.
      expect(
        isNewWorldColonialWorkOrder(_workOrder(kWorkTargetExplore, _nwTile)),
        isFalse,
      );
    });

    test('OW purchase_land is not a New World colonial work order', () {
      expect(
        isNewWorldColonialWorkOrder(
          _workOrder(kWorkTargetPurchaseLand, _owTile),
        ),
        isFalse,
        reason:
            'Region-scoping is the primary discriminator; OW work targets '
            'are never New World colonial orders.',
      );
    });

    test('OW build_improvement is not a New World colonial work order', () {
      expect(
        isNewWorldColonialWorkOrder(
          _workOrder(kWorkTargetBuildImprovement, _owTile),
        ),
        isFalse,
      );
    });
  });

  group('shouldFilterObserverPhaseWorkOrder determinism', () {
    test(
      'same inputs produce same filter outcome (Refs #2509 must-have #7)',
      () {
        final order = _workOrder(kWorkTargetPurchaseLand, _nwTile);
        final first = shouldFilterObserverPhaseWorkOrder(
          order,
          snapshot: _developSnapshot,
        );
        final second = shouldFilterObserverPhaseWorkOrder(
          order,
          snapshot: _developSnapshot,
        );
        expect(first, second);
      },
    );

    test('EXPAND fixture remains the predicate boundary (control)', () {
      // Sanity check that the existing EXPAND coverage in
      // `observer_goal_phase_test.dart` group
      // `shouldFilterObserverPhaseWorkOrder` is consistent with this file:
      // EXPAND filters NW `build_improvement` while DEVELOP keeps it. The
      // two branches must not collapse into the same rule, since the 70%
      // gate depends on DEVELOP allowing NW `build_improvement`.
      final order = _workOrder(kWorkTargetBuildImprovement, _nwTile);
      expect(
        shouldFilterObserverPhaseWorkOrder(order, snapshot: _expandSnapshot),
        isTrue,
        reason:
            'EXPAND must continue to filter NW `build_improvement` (existing '
            'pin in `observer_goal_phase_test.dart` group '
            '`shouldFilterObserverPhaseWorkOrder`). Listed here as the '
            'control case so any regression that collapsed EXPAND and '
            'DEVELOP rules would fail this group as well.',
      );
      expect(
        shouldFilterObserverPhaseWorkOrder(order, snapshot: _developSnapshot),
        isFalse,
        reason:
            'DEVELOP must keep NW `build_improvement` (the 70% gate '
            'imperative). This file is the function-level pin for that '
            'half of the branch.',
      );
    });
  });
}
