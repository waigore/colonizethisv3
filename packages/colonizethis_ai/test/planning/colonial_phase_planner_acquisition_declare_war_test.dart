// Unit tests for the `declareWar` arm (Acquisition method 3) of
// `planColonialAcquisition` in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3).
//
// Spec contract (issue #2509 § COLONIAL phase planner §
// planColonialAcquisition, Acquisition method 3):
//
//   "declareWar + invade
//      → Conditions: treasury ≥ regiment build cost, regiments
//        available, tribe/minor is sea-reachable.
//      → Generate declareWar(tribe) + NW army move.
//      → From turn 110: deprioritize war behind Join Empire and
//        purchase_land (fewer turns to complete)."
//
// The planner's `declareWar` arm runs only when both the Join Empire
// pass (Acquisition method 1) and the `purchase_land` pass
// (Acquisition method 2) yield no target. The arm enforces the spec's
// outer "treasury ≥ regiment build cost, regiments available"
// preconditions plus per-province validator parity with the
// order-engine `declareWarSubValidator` in
// `packages/colonizethis_logic/lib/src/orders/validators/diplomatic/`
// `declare_war_validator.dart` (rejects "Already at war with that
// faction" when [RelationState.atWar]).
//
// Outer gates pinned here:
//
//   - **Zero standing regiments -> null.** The active player must
//     hold at least one regiment across Home + field armies; without
//     any units the spec's "Generate declareWar(tribe) + NW army
//     move" follow-up has no army to commit.
//   - **Treasury below cheapest regiment build cost -> null.** The
//     active player must be able to afford at least one new regiment
//     so the order pair is sustainable; mirrors the symmetric
//     `_cheapestRegimentBuildTreasuryCost` gate in
//     `planExpandDeclareWar`.
//
// Per-province gates pinned here:
//
//   - **GP-owned NW province -> skip.** Validator-style structural
//     skip; same `game.playerById(ownerId) != null` partition used by
//     the Join Empire and `purchase_land` arms. declareWar against a
//     GP is COLONIAL's `planColonialMilitary` declared-target / at-war
//     fallback arm, not an acquisition decision.
//   - **At-war tribe / minor -> skip.** Validator rejects with
//     "Already at war with that faction" when [DiplomacyRelation.atWar]
//     is true; the planner mirrors that gate by skipping rows where
//     `relation.atWar == true`. Already-at-war factions are pursued by
//     `planColonialMilitary`'s declared-target / at-war fallback arms
//     instead.
//
// Sea reachability is structurally satisfied by the iteration: every
// candidate appears in
// `ColonialSummary.invadableNewWorldProvinceIdsSorted`, which the
// perception-snapshot builder restricts to provinces reachable from
// owned anchors via `reachableNonOwnedProvinceIdsViaSeas` (see
// `perception_snapshot_builders.dart`). No separate topology probe
// is required at the planner level.
//
// `planColonialAcquisition` declareWar tests:
//
//   1. **Zero regiments -> null:** outer guard pin. Even with
//      treasury and a valid tribe-owned NW invadable province, no
//      standing regiments suppresses the declareWar arm so the
//      conquest army-move pass would have nothing to commit.
//   2. **Treasury below cheapest regiment build cost -> null:**
//      outer guard pin using the deterministic
//      `RegimentEconomyCatalog` minimum (`peasantLevies` at 2000).
//      Treasury 1999 with at least one regiment present still trips
//      the gate.
//   3. **GP-owned NW invadable province -> skip:** structural pin;
//      `game.playerById(ownerId) != null` for the second GP keeps
//      declareWar off the GP target so the COLONIAL acquisition
//      decision stays tribe / minor only.
//   4. **At-war tribe -> skip:** validator-side
//      `relation.atWar == true` rejection. Even with regiments +
//      treasury, the at-war gate must reject the candidate so the
//      planner never re-declares war on an existing front (that
//      pursuit is owned by `planColonialMilitary`).
//   5. **No JE / PL paths, tribe + regiments + treasury ->
//      declareWar target:** canonical happy path. Acceptance
//      criterion #2509 § "(COLONIAL acquisition — declareWar)":
//      "Given a GP in COLONIAL with treasury ≥ regiment build cost
//      and a visible tribe owning a sea-reachable NW province where
//      Join Empire and purchase_land are unavailable, when
//      planColonialAcquisition runs, then the return value is
//      `(tribeFactionId, AcquisitionMethod.declareWar)`."
//   6. **Null relation row (no prior diplomacy) -> declareWar
//      fires:** validator framing `relation == null || relation.atPeace`
//      accepts a missing diplomacy row as at-peace; the planner
//      mirrors that semantics so first-contact tribes are not
//      excluded from the declareWar arm.
//   7. **Join Empire reachable -> Join Empire wins (declareWar
//      suppressed):** priority pin. Even with regiments + treasury
//      sufficient for declareWar, a satisfying Join Empire candidate
//      ends the function in the first pass.
//   8. **purchase_land reachable -> purchase_land wins (declareWar
//      suppressed):** priority pin. Even with regiments + treasury
//      sufficient for declareWar, a satisfying purchase_land
//      candidate ends the function in the second pass.
//   9. **Two valid tribe candidates -> first sorted invadable NW
//      province wins:** deterministic iteration over
//      `ColonialSummary.invadableNewWorldProvinceIdsSorted` (Refs
//      #2509 Must-have #7) — same tiebreak rule as the Join Empire /
//      `purchase_land` arms.
//  10. **Determinism (Must-have #7):** identical inputs produce
//      identical `ColonialAcquisitionTarget`s across repeated calls.
//
// All tests use synthetic Game/AIWorldSnapshot fixtures with one
// active GP (`gp1`), candidate tribes (`tribe1` / `tribe2`), an
// optional GP-owned NW province for the GP-skip pin, and explicit
// army composition so `regimentCountForPlayer` returns a known
// value. The fixtures intentionally omit overture state for tribes
// targeted by the declareWar happy paths -- declareWar does not gate
// on overture stage, so the absence of an overture row is sufficient
// to suppress the Join Empire and `purchase_land` passes.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_acquisition_test_support.dart';
import 'ai_planner_fixtures.dart';

const String _gp1 = kColonialPhaseGp1;
const String _gp2 = kColonialPhaseGp2;
const String _tribe1 = kColonialPhaseTribe1;
const String _tribe2 = kColonialPhaseTribe2;

const String _nwProv1 = kColonialAcquisitionNwProv1;
const String _nwProv2 = kColonialAcquisitionNwProv2;
const String _nwProvGp = kColonialAcquisitionNwProvGp;

const String _nwTile1 = kColonialAcquisitionNwTile1;

void main() {
  group('planColonialAcquisition (declareWar path)', () {
    test('zero regiments -> null (outer guard)', () {
      // Even with treasury and a valid tribe-owned NW invadable
      // province, no standing regiments suppresses the declareWar
      // arm so the conquest army-move pass would have nothing to
      // commit. A regression that emitted a declareWar target here
      // would surface an order pair the orchestrator could not
      // complete (declareWar + NW army move per spec).
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        armies: const <Army>[],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Outer regiment guard must short-circuit before the '
            'declareWar per-province loop fires; declareWar without '
            'a standing regiment emits an order pair the conquest '
            'army-move pass cannot follow up on.',
      );
    });

    test('treasury below cheapest regiment build cost -> null', () {
      // Outer treasury gate using the deterministic
      // `RegimentEconomyCatalog` minimum. `peasantLevies` pins the
      // cheapest cost at 2000 today; treasury 1999 trips the gate
      // even with a standing regiment present (so the regiment-count
      // guard succeeds first).
      final cheapest = cheapestRegimentBuildCost();
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        activePlayerTreasury: cheapest - 1,
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 5)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
        treasury: cheapest - 1,
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Treasury (${cheapest - 1}) below cheapest regiment '
            'build cost ($cheapest) trips the declareWar outer '
            'treasury guard so the planner does not commit a war it '
            'cannot reinforce.',
      );
    });

    test('GP-owned NW invadable province -> skip', () {
      // Structural GP-skip: declareWar against another Great Power is
      // COLONIAL's `planColonialMilitary` declared-target / at-war
      // fallback territory, not an acquisition decision. The planner
      // mirrors the Join Empire / `purchase_land` arms' GP-skip via
      // `game.playerById(ownerId) != null`.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        newWorldProvinces: const [
          Province(id: _nwProvGp, regionId: 'newWorld', ownerId: _gp2),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 5)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionPeaceNeutral(_gp1, _gp2),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProvGp],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'GP-owned NW invadable provinces are skipped by '
            '`game.playerById(ownerId) != null`; declareWar toward a '
            'GP is reasoned about by planColonialMilitary, not the '
            'acquisition planner.',
      );
    });

    test('at-war tribe -> skip', () {
      // Validator: "Already at war with that faction". Even with
      // regiments + treasury sufficient for declareWar, an existing
      // war must short-circuit the candidate so the planner never
      // re-declares war on an active front. Already-at-war tribes
      // are pursued by planColonialMilitary's declared-target /
      // at-war fallback arms instead.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 5)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionAtWar(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'At-war relation rejects declareWar via the validator; '
            'the planner mirrors that gate so the COLONIAL acquisition '
            'decision never re-declares an existing war.',
      );
    });

    test('AC: tribe + regiments + treasury -> declareWar target', () {
      // Acceptance criterion (issue #2509 § Phase planner unit tests):
      // "Given a GP in COLONIAL with treasury ≥ regiment build cost
      // and a visible tribe owning a sea-reachable NW province where
      // Join Empire and purchase_land are unavailable, when
      // planColonialAcquisition runs, then the return value is
      // (tribeFactionId, AcquisitionMethod.declareWar)."
      //
      // Join Empire is suppressed by the absence of an overture
      // (Join Empire requires stage == nap); purchase_land is
      // suppressed by the absence of any Merchant unit anywhere.
      // declareWar therefore wins as the third-priority arm.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 5)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.declareWar,
        ),
        reason:
            'All declareWar gates pass (regiments > 0, treasury >= '
            'cheapest regiment build cost, tribe owner, not at war); '
            'Join Empire fails (no overture) and purchase_land fails '
            '(no Merchant) so declareWar is the COLONIAL acquisition '
            'choice per spec.',
      );
    });

    test('null relation row (first contact) -> declareWar fires', () {
      // Validator framing: `final atPeace = relation == null ||
      // relation.atPeace;` accepts a missing diplomacy row as at-peace.
      // The planner mirrors that semantics: a tribe with no prior
      // DiplomacyRelation row is still a valid declareWar candidate
      // so first-contact tribes are not excluded from the third arm.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 5)],
        diplomacyRelations: const <DiplomacyRelation>[],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.declareWar,
        ),
        reason:
            'Missing DiplomacyRelation row is treated as at-peace by '
            'the validator (`relation == null || relation.atPeace`); '
            'the planner mirrors that gate so first-contact tribes '
            'are valid declareWar candidates.',
      );
    });

    test(
      'Join Empire reachable -> Join Empire wins (declareWar suppressed)',
      () {
        // Priority pin: even with regiments + treasury sufficient for
        // declareWar, a satisfying Join Empire candidate ends the
        // function in the first pass. Pins the spec's "Join Empire is
        // always preferred first" framing across all three arms.
        final game = buildColonialAcquisitionGame(
          gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
          newWorldProvinces: const [
            Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          ],
          armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 5)],
          overtureStates: <OvertureState>[
            colonialAcquisitionNap(_gp1, _tribe1),
          ],
          diplomacyRelations: <DiplomacyRelation>[
            colonialAcquisitionFriendly(_gp1, _tribe1),
          ],
        );
        final snapshot = buildColonialAcquisitionSnapshot(
          invadableNw: const [_nwProv1],
        );
        expect(
          planColonialAcquisition(game: game, snapshot: snapshot),
          const ColonialAcquisitionTarget(
            targetFactionId: _tribe1,
            method: AcquisitionMethod.joinEmpire,
          ),
          reason:
              'Join Empire (Method 1) reachable -> the function returns '
              'in the first pass and declareWar (Method 3) is never '
              'evaluated; pins the "always preferred first" priority.',
        );
      },
    );

    test(
      'purchase_land reachable -> purchase_land wins (declareWar suppressed)',
      () {
        // Priority pin: even with regiments + treasury sufficient for
        // declareWar, a satisfying purchase_land candidate ends the
        // function in the second pass. Pins the structural Method 2 ->
        // Method 3 ordering.
        final game = Game(
          id: 'g-2509-colonial-acquisition-declare-war-priority-pl',
          worldState: WorldState(
            turnState: const TurnState(
              turnNumber: 130,
              phase: TurnPhase.orders,
            ),
            oldWorld: const RegionData(),
            newWorld: RegionData(
              provinces: const [
                Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
              ],
              units: <Unit>[
                Unit(
                  id: 'm1',
                  type: kUnitTypeMerchant,
                  ownerId: _gp1,
                  locationProvinceId: _nwProv1,
                  tileKey: '$_nwProv1|5|5',
                  status: UnitStatus.idle,
                ),
              ],
            ),
            armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 5)],
            resourceByTileKey: const {_nwTile1: 'grain'},
          ),
          players: const [
            Player(
              id: _gp1,
              displayName: 'GP1',
              isHuman: false,
              treasury: 100000,
            ),
            Player(id: _gp2, displayName: 'GP2', isHuman: false),
          ],
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          overtureStates: <OvertureState>[
            colonialAcquisitionEmbassy(_gp1, _tribe1),
          ],
          diplomacyRelations: <DiplomacyRelation>[
            colonialAcquisitionFriendly(_gp1, _tribe1),
          ],
        );
        final snapshot = buildColonialAcquisitionSnapshot(
          invadableNw: const [_nwProv1],
        );
        expect(
          planColonialAcquisition(game: game, snapshot: snapshot),
          const ColonialAcquisitionTarget(
            targetFactionId: _tribe1,
            method: AcquisitionMethod.purchaseLand,
          ),
          reason:
              'purchase_land (Method 2) reachable -> the function returns '
              'in the second pass and declareWar (Method 3) is never '
              'evaluated; pins the Method 2 -> Method 3 priority.',
        );
      },
    );

    test('two valid tribe targets -> first sorted invadable NW wins', () {
      // Deterministic iteration over
      // `ColonialSummary.invadableNewWorldProvinceIdsSorted`: the
      // first sorted entry (`_nwProv1` = "newWorld|tribe1_a") wins
      // over the second (`_nwProv2` = "newWorld|tribe2_b"). Mirrors
      // the Join Empire / purchase_land arms' tiebreak so all three
      // priority levels share one iteration contract.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _nwProv2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 5)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
          colonialAcquisitionPeaceNeutral(_gp1, _tribe2),
        ],
      );
      // Snapshot lists invadable in sorted order; the planner walks
      // them as provided.
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1, _nwProv2],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.declareWar,
        ),
        reason:
            'Two valid tribe-owned NW provinces -> the planner picks '
            'the first sorted entry (Refs #2509 Must-have #7 '
            'deterministic ordering). Tribe2 is skipped on the second '
            'iteration only when tribe1 is invalid.',
      );
    });

    test(
      'determinism: identical inputs produce identical declareWar targets',
      () {
        // Refs #2509 Must-have #7. The planner must be pure: identical
        // inputs always yield identical `ColonialAcquisitionTarget`s.
        final game = buildColonialAcquisitionGame(
          gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
          newWorldProvinces: const [
            Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
            Province(id: _nwProv2, regionId: 'newWorld', ownerId: _tribe2),
          ],
          armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 5)],
          diplomacyRelations: <DiplomacyRelation>[
            colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
            colonialAcquisitionPeaceNeutral(_gp1, _tribe2),
          ],
        );
        final snapshot = buildColonialAcquisitionSnapshot(
          invadableNw: const [_nwProv1, _nwProv2],
        );
        final first = planColonialAcquisition(game: game, snapshot: snapshot);
        final second = planColonialAcquisition(game: game, snapshot: snapshot);
        expect(
          second,
          equals(first),
          reason:
              'Pure-function determinism (Refs #2509 Must-have #7): '
              'the second call must return a ColonialAcquisitionTarget '
              'value-equal to the first.',
        );
        expect(
          first,
          const ColonialAcquisitionTarget(
            targetFactionId: _tribe1,
            method: AcquisitionMethod.declareWar,
          ),
          reason:
              'Pin the actual return so the determinism check cannot '
              'silently regress to `(null, null)` on both calls.',
        );
      },
    );
  });

  group('planColonialAcquisition declareWar Path E (Refs #2924)', () {
    test('treasury zero with NW recovery override emits declareWar target', () {
      final cheapest = cheapestRegimentBuildCost();
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        activePlayerTreasury: 0,
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 1)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
        treasury: 0,
        newWorldProvincesOwned: 0,
      );
      expect(
        planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          expandEconomyPlan: kNwTreasuryRecoveryOverridePlan,
        ),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.declareWar,
        ),
        reason:
            'Under the treasury-recovery resource-need override '
            '(treasury == 0, NW == 0, boostTreasuryRecoveryCargo) '
            'the declareWar arm must waive the planner-level '
            'treasury gate so the NW conquest → riches chain can '
            'begin without bypassing build affordability.',
      );
      expect(cheapest, greaterThan(0));
    });

    test(
      'partial treasury with boostTreasuryRecoveryCargo emits declareWar',
      () {
        final game = buildColonialAcquisitionGame(
          gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
          activePlayerTreasury: 500,
          newWorldProvinces: const [
            Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          ],
          armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 1)],
          diplomacyRelations: <DiplomacyRelation>[
            colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
          ],
        );
        final snapshot = buildColonialAcquisitionSnapshot(
          invadableNw: const [_nwProv1],
          treasury: 500,
          newWorldProvincesOwned: 0,
        );
        expect(
          planColonialAcquisition(
            game: game,
            snapshot: snapshot,
            expandEconomyPlan: const ExpandEconomyPlan(
              forceCheapestRegimentBuild: false,
              boostTreasuryRecoveryCargo: true,
            ),
          ),
          const ColonialAcquisitionTarget(
            targetFactionId: _tribe1,
            method: AcquisitionMethod.declareWar,
          ),
          reason:
              'Path E declare-war waiver must persist after Path F raises '
              'treasury above zero but below the regiment threshold.',
        );
      },
    );

    test('treasury zero without override keeps declareWar suppressed', () {
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        activePlayerTreasury: 0,
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 1)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
        treasury: 0,
        newWorldProvincesOwned: 0,
      );
      expect(
        planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
        ),
        isNull,
        reason:
            'Regression guard: without boostTreasuryRecoveryCargo the '
            'legacy treasury >= cheapestRegimentBuildTreasuryCost gate '
            'must still suppress declareWar at treasury zero.',
      );
    });
  });
}
