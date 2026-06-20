// Unit tests for `planColonialNaval` in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3).
//
// Spec contract (issue #2509 § COLONIAL phase planner § planColonialNaval):
//
//   "Colonial naval missions:
//      → Transport regiments to NW invasion staging.
//      → Explore unrevealed NW tiles.
//      → Cargo routing for overseas extraction."
//
// This planner covers the **invasion-transport** arm of that contract.
// The exploration + cargo arms are satisfied at the orchestrator layer
// (#2509 S5) by the existing `colonial_naval_scoring.dart` helpers, so
// `defaultPlan` means "no invasion-transport directive this turn" --
// the legacy free-choice colonial naval pipeline continues to emit
// exploration / cargo moves as before.
//
// Mirrors the test pattern established for [planColonialMilitary] in
// `colonial_phase_planner_military_test.dart`: small synthetic
// fixtures, one branch arm per test, in-module pin (the planner module
// never re-checks phase, so these tests stay scoped to the priority-arm
// branches plus the structural OW suppression and the defensive
// guards). The shared `colonialDeclaredWarTargetFactionId` parameter
// also mirrors `planColonialMilitary` so the orchestrator (#2509 S5)
// can pair the army-move plan with the naval-transport plan against
// the same colonial declare-war target with no shape mismatch.
//
// `planColonialNaval` tests:
//
//   1. **Below quota (own OW = 9) -> defaultPlan:** outer COLONIAL
//      guard pin -- the planner refuses to act for a GP that has not
//      yet reached the EXPAND -> COLONIAL transition threshold even
//      when NW invadable provinces and at-war owners are present.
//   2. **Player not in game -> defaultPlan:** defensive guard pin
//      (matches [planColonialMilitary] / [planColonialPeace] /
//      [planColonialLiteNaval] for snapshots pointing at non-existent
//      players).
//   3. **Empty NW invadable -> defaultPlan:** structural empty-list
//      short-circuit so an empty constraint never leaks to the
//      orchestrator.
//   4. **AC: declared colonial target owns one NW invadable -> restrict
//      to that province + target as sole owner:** canonical priority-1
//      happy path (issue #2509 § planColonialNaval "Transport regiments
//      to NW invasion staging").
//   5. **Declared colonial target owns multiple NW invadable ->
//      sorted-ascending province list:** priority 1 keeps all
//      target-owned provinces; output order is independent of input
//      order.
//   6. **Declared colonial target owns no NW invadable -> defaultPlan:**
//      priority-1 fall-back so the orchestrator can fall back to the
//      legacy free-choice exploration / cargo pipeline rather than
//      receive an empty constraint.
//   7. **AC: no declared target, at-war tribe owns NW invadable ->
//      restrict to those provinces + sorted at-war owners:** priority-2
//      fallback canonical case (tribes are first-class colonial
//      invasion targets per issue #2509 § planColonialAcquisition).
//   8. **No declared target, multiple at-war owners (tribe + minor) ->
//      union of provinces + sorted owners:** priority-2 union across
//      faction classes (tribes, minors, GPs all valid invasion
//      targets in COLONIAL).
//   9. **At-war owner with no NW invadable contribution dropped from
//      owner list:** pins the "owner list mirrors actual destinations"
//      contract so the orchestrator never sees a phantom target.
//  10. **No declared target, no at-war owners hold NW invadable ->
//      defaultPlan:** both priority arms exhausted.
//  11. **Declared colonial target wins over at-war fallback (priority 1
//      over 2):** explicit priority pin to prevent re-ordering
//      regressions; mirrors the symmetric pin in
//      [planColonialMilitary].
//  12. **OW invadable structurally suppressed:** even with an at-war
//      faction owning an OW invadable province in the conquest summary
//      and a NW invadable in the colonial summary, the plan must NOT
//      pick up the OW province -- the planner only reads the NW
//      invadable list.
//  13. **Declared target on OW-only invadable -> defaultPlan:**
//      symmetric OW-suppression pin from the priority-1 side (target
//      owns nothing in NW invadable so the plan falls back to default
//      rather than reaching into OW).
//  14. **Orphan NW invadable id with no owner -> silently skipped:**
//      defensive pin for the `if (owner == null) continue` branch in
//      the at-war fallback arm.
//  15. **Determinism (Must-have #7):** identical inputs yield
//      identical plans across repeated calls.
//  16. **GP-owned NW invadable NOT structurally filtered:** explicit
//      divergence from [planColonialLiteNaval]. COLONIAL allows
//      invasion against any faction class (issue #2509 §
//      planColonialAcquisition step 3), so a declared colonial target
//      that is a GP owning NW invadable surfaces in the plan as the
//      invasion-transport focus.
//  17. **GP-owned NW invadable via at-war fallback:** mirror branch
//      from the priority-2 side -- a GP at war owning NW invadable
//      contributes its provinces to the invasion-transport plan in
//      COLONIAL (whereas it would be filtered out in COLONIAL-lite).
//  18. **Multi-player game: filter is owner-scoped, not
//      active-player-scoped:** isolation pin -- the active player's
//      own ownership has no effect on the destination filter.
//  19. **ColonialNavalPlan value equality + defaultPlan equals
//      explicit all-empty instance:** value-class pin so tests in the
//      orchestrator wiring slice (#2509 S5) can compare planner output
//      against the shared default OR a fresh `const ColonialNavalPlan(...)`.
//  20. **Input order shuffled -> ascending sort recovers:** defensive
//      determinism pin against future snapshot-builder regressions.
//
// The "invasion-transport order envelope" itself (transport-ship
// pairing, sea-zone routing via topology, beachhead staging) lives at
// the orchestrator layer (#2509 S5) and the existing
// `colonial_naval_scoring.dart` helpers; it is intentionally out of
// scope for this in-module pin -- the unit pins the deterministic
// destination filter (NW invadable provinces to land transport at)
// that the orchestrator consumes.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _tribe1 = 'tribe1';
const String _tribe2 = 'tribe2';
const String _minor1 = 'minor1';

/// Game scaffold for COLONIAL-phase naval tests. New World provinces,
/// players, tribes, and minors are passed in so each test can shape
/// ownership independently. Old World defaults to empty because the
/// planner does not query OW state (the OW summary is read only for
/// the outer quota gate, not the destination filter).
Game _colonialGame({
  int turnNumber = 130,
  List<Province> newWorldProvinces = const [],
  List<Province> oldWorldProvinces = const [],
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: 9999),
    Player(id: _gp2, displayName: 'GP2', isHuman: false, treasury: 9999),
    Player(id: _gp3, displayName: 'GP3', isHuman: false, treasury: 9999),
  ],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-colonial-phase-planner-naval-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: RegionData(provinces: newWorldProvinces),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot tuned for COLONIAL: own OW defaults to 10 (at quota -- the
/// EXPAND -> COLONIAL transition has fired). Tests shape `atWarWith`,
/// `invadableNw`, `invadableOw`, and `oldWorldProvincesOwned` to
/// exercise specific priority arms and the structural OW suppression.
/// The planner does not re-check the phase so the values are still
/// consistent with COLONIAL only so debugging traces stay coherent.
AIWorldSnapshot _colonialSnapshot({
  required List<String> atWarWith,
  List<String> invadableNw = const [],
  List<String> invadableOw = const [],
  int oldWorldProvincesOwned = 10,
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: 31,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: ColonialSummary(invadableNewWorldProvinceIdsSorted: invadableNw),
    economy: const EconomySummary(),
    relations: const {},
  );
}

const ExpandEconomyPlan _nwTreasuryRecoveryOverridePlan = ExpandEconomyPlan(
  forceCheapestRegimentBuild: true,
  boostTreasuryRecoveryCargo: true,
);

const String _nwProvTribeA = 'newWorld|tribe1_a';

AIWorldSnapshot _lockRecoveryBelowQuotaSnapshot({
  required List<String> invadableNw,
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(atWarWith: [_tribe1]),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 9,
      provincesToVictory: 31,
      invadableProvinceIdsSorted: const [],
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      newWorldProvincesOwned: 0,
    ),
    economy: const EconomySummary(treasury: 0),
    relations: const {},
  );
}

void main() {
  group('planColonialNaval', () {
    test('below quota (own OW = 9) -> defaultPlan', () {
      // COLONIAL outer gate: `isBelowObserverConquestQuota` is true
      // when own OW is strictly below `kObserverConquestMinOwProvincesPerGp`
      // (10). The planner short-circuits before reading invadable or
      // owner state so a mis-dispatched EXPAND-territory call cannot
      // leak NW invasion-transport destinations -- mirrors the
      // symmetric guard in [planColonialMilitary].
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1],
        invadableNw: const ['newWorld|tribe1_a'],
        oldWorldProvincesOwned: 9,
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        same(ColonialNavalPlan.defaultPlan),
        reason:
            'GP below the observer OW quota is still EXPAND territory '
            'for the phase-planner contract; the outer '
            '`isBelowObserverConquestQuota` guard must short-circuit '
            'before reading any NW invadable state.',
      );
    });

    test('player not in game -> defaultPlan (defensive guard)', () {
      // Defensive guard pin: snapshots pointing at a non-existent
      // player must not crash; the planner returns the default plan.
      // Matches the equivalent guard in [planColonialMilitary] and
      // [planColonialLiteNaval].
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1],
        invadableNw: const ['newWorld|tribe1_a'],
        playerId: 'ghost-player',
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        same(ColonialNavalPlan.defaultPlan),
      );
    });

    test('empty NW invadable -> defaultPlan', () {
      // No NW frontier means there is no province to filter; the
      // function must short-circuit before any priority-arm scan so
      // an empty constraint never leaks to the orchestrator.
      final game = _colonialGame();
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1],
        invadableNw: const [],
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        same(ColonialNavalPlan.defaultPlan),
      );
    });

    test('AC: declared colonial target owns one NW invadable -> restrict to '
        'that province + target as sole owner', () {
      // Acceptance criterion (issue #2509 § COLONIAL phase planner §
      // planColonialNaval "Transport regiments to NW invasion
      // staging"): priority 1 fires when the declared colonial
      // target owns at least one invadable NW province. The plan
      // restricts invasion-transport landing to exactly that
      // province and lists only the target as the priority owner.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe1,
        ),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Priority 1: declared colonial target owns one NW '
            'invadable province -> plan restricts invasion-transport '
            'landing to that province and lists only the target as '
            'the priority owner.',
      );
    });

    test('declared colonial target owns multiple NW invadable -> all those '
        'provinces, sorted ascending', () {
      // Multiple invadable provinces under the same declared
      // colonial target: the plan keeps all of them, sorted
      // ascending, regardless of input order in
      // invadableNewWorldProvinceIdsSorted (defensive determinism
      // against future builder changes).
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
          Province(
            id: 'newWorld|tribe1_b',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [],
        invadableNw: const ['newWorld|tribe1_b', 'newWorld|tribe1_a'],
      );
      expect(
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe1,
        ),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
            'newWorld|tribe1_b',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Priority 1 keeps ALL NW invadable provinces owned by '
            'the declared colonial target, sorted ascending. Output '
            'order is independent of the input invadable list order.',
      );
    });

    test('declared colonial target owns no NW invadable -> defaultPlan', () {
      // Priority 1 fails when the declared target owns nothing in NW
      // invadable. Per the spec the orchestrator should fall back to
      // its existing free-choice colonial naval pipeline (exploration
      // / cargo), so the planner returns the default plan rather than
      // an empty constraint.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [
          Tribe(id: _tribe1, displayName: 'T1'),
          Tribe(id: _tribe2, displayName: 'T2'),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe2,
        ),
        same(ColonialNavalPlan.defaultPlan),
        reason:
            'When the declared colonial target owns nothing in NW '
            'invadable, the plan falls back to defaultPlan so the '
            'orchestrator can run the legacy exploration / cargo '
            'pipeline freely. An empty constraint must never leak.',
      );
    });

    test('AC: no declared target, at-war tribe owns NW invadable -> '
        'restrict to those provinces + sorted at-war owners', () {
      // Priority 2 fires when no declared target is given and at
      // least one at-war faction owns an NW invadable province.
      // The plan restricts invasion-transport landing to the union
      // of those provinces and lists the at-war owners sorted
      // ascending. Tribes are first-class colonial invasion
      // targets per issue #2509 § planColonialAcquisition step 3.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Priority 2 (at-war fallback): no declare-war target + '
            'an at-war tribe owns one NW invadable -> plan restricts '
            'invasion-transport landing to that province and lists '
            'the at-war owner.',
      );
    });

    test('no declared target, multiple at-war owners (tribe + minor) -> '
        'union of their invadable + sorted owners', () {
      // At-war fallback covers any faction class (GP, minor, tribe).
      // Two at-war owners contribute provinces; the plan unions
      // them and lists both owners sorted ascending.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|minor1_a',
            regionId: 'newWorld',
            ownerId: _minor1,
          ),
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1, _minor1],
        invadableNw: const ['newWorld|tribe1_a', 'newWorld|minor1_a'],
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: List<String>.unmodifiable(
            const <String>['newWorld|minor1_a', 'newWorld|tribe1_a'],
          ),
          priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(
            const <String>[_minor1, _tribe1],
          ),
        ),
        reason:
            'Priority 2 unions provinces across all at-war owners '
            '(tribe + minor). Provinces and owners are both sorted '
            'ascending in the plan output.',
      );
    });

    test('at-war owner with no NW invadable contribution is dropped from '
        'owner list', () {
      // An at-war faction that does NOT own any NW invadable
      // province must NOT appear in
      // priorityTargetOwnerFactionIdsSorted. This pins the "owner
      // list mirrors actual destinations" contract so a downstream
      // orchestrator never sees a phantom target.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [
          Tribe(id: _tribe1, displayName: 'T1'),
          Tribe(id: _tribe2, displayName: 'T2'),
        ],
      );
      final snapshot = _colonialSnapshot(
        // tribe2 is at war but owns nothing in NW invadable, so
        // should be dropped from the owner list.
        atWarWith: const [_tribe1, _tribe2],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Only at-war owners that actually contribute an NW '
            'invadable province appear in '
            'priorityTargetOwnerFactionIdsSorted. tribe2 is at war '
            'but contributes nothing so it is dropped.',
      );
    });

    test(
      'no declared target, no at-war owners hold NW invadable -> defaultPlan',
      () {
        // Priority 2 fails when no at-war faction owns an invadable
        // NW province. Both priority arms exhausted -> defaultPlan;
        // the orchestrator falls back to legacy free-choice
        // exploration / cargo behaviour.
        final game = _colonialGame(
          newWorldProvinces: const [
            Province(
              id: 'newWorld|tribe1_a',
              regionId: 'newWorld',
              ownerId: _tribe1,
            ),
          ],
          tribes: const [
            Tribe(id: _tribe1, displayName: 'T1'),
            Tribe(id: _tribe2, displayName: 'T2'),
          ],
        );
        final snapshot = _colonialSnapshot(
          // tribe2 is at war but does NOT own the invadable province.
          atWarWith: const [_tribe2],
          invadableNw: const ['newWorld|tribe1_a'],
        );
        expect(
          planColonialNaval(game: game, snapshot: snapshot),
          same(ColonialNavalPlan.defaultPlan),
          reason:
              'No declared colonial target + no at-war faction owning '
              'an NW invadable -> defaultPlan (the orchestrator falls '
              'back to the legacy free-choice exploration / cargo '
              'behaviour).',
        );
      },
    );

    test(
      'declared colonial target wins over at-war fallback (priority 1 over 2)',
      () {
        // Both arms could fire (target owns invadable AND another
        // at-war faction owns invadable), but priority 1 (declared
        // colonial target) takes precedence and excludes the at-war
        // non-target from the owner list.
        final game = _colonialGame(
          newWorldProvinces: const [
            Province(
              id: 'newWorld|tribe1_a',
              regionId: 'newWorld',
              ownerId: _tribe1,
            ),
            Province(
              id: 'newWorld|tribe2_a',
              regionId: 'newWorld',
              ownerId: _tribe2,
            ),
          ],
          tribes: const [
            Tribe(id: _tribe1, displayName: 'T1'),
            Tribe(id: _tribe2, displayName: 'T2'),
          ],
        );
        final snapshot = _colonialSnapshot(
          atWarWith: const [_tribe1, _tribe2],
          invadableNw: const ['newWorld|tribe1_a', 'newWorld|tribe2_a'],
        );
        expect(
          planColonialNaval(
            game: game,
            snapshot: snapshot,
            colonialDeclaredWarTargetFactionId: _tribe1,
          ),
          const ColonialNavalPlan(
            priorityInvasionTransportProvinceIdsSorted: <String>[
              'newWorld|tribe1_a',
            ],
            priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
          ),
          reason:
              'Priority 1 (declared colonial target) wins over '
              'priority 2 (at-war fallback). tribe2 is at war and '
              'also owns an NW invadable province but is correctly '
              'excluded from the plan because a declared target is '
              'given.',
        );
      },
    );

    test('AC: OW invadable structurally suppressed (#2509 OW suppression)', () {
      // Acceptance criterion (issue #2509 § COLONIAL phase planner §
      // planColonialNaval): given an at-war minor owning an OW
      // invadable province that appears in
      // ConquestSummary.invadableProvinceIdsSorted, the plan must
      // NOT include the OW province. The planner only reads the NW
      // invadable list -- OW suppression is structural, not
      // predicate-based.
      final game = _colonialGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1, _minor1],
        invadableNw: const ['newWorld|tribe1_a'],
        // Even though the minor is at war AND owns an OW invadable
        // province in the conquest summary, the plan must not pick
        // up the OW province.
        invadableOw: const ['oldWorld|minor1_a'],
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'COLONIAL OW suppression: the planner only reads '
            'snapshot.colonial.invadableNewWorldProvinceIdsSorted '
            '(NW-only). The OW invadable province must NOT leak into '
            'the plan even when an at-war owner is mentioned in the '
            'conquest summary.',
      );
    });

    test('declared target on OW-only invadable -> defaultPlan (structural OW '
        'suppression)', () {
      // Even with a declared target that owns ONLY OW invadable
      // provinces, the planner must return defaultPlan because the
      // NW invadable list is empty. Combined with the previous
      // test this pins the structural OW suppression from both
      // sides.
      final game = _colonialGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_minor1],
        invadableNw: const [],
        invadableOw: const ['oldWorld|minor1_a'],
      );
      expect(
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _minor1,
        ),
        same(ColonialNavalPlan.defaultPlan),
        reason:
            'NW invadable list is empty -> the outer guard fires '
            'and returns defaultPlan regardless of any OW invadable '
            'state. COLONIAL OW suppression is structural at the '
            'planner level.',
      );
    });

    test('orphan NW invadable id with no owner -> silently skipped', () {
      // Defensive pin: an invadable province whose owner is missing
      // from the world (orphan / mid-transition) is silently skipped
      // rather than crashing. Tests the `if (owner == null) continue`
      // branch in the at-war fallback arm.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1],
        // Include an unknown id that won't be in provinceOwner map.
        invadableNw: const ['newWorld|tribe1_a', 'newWorld|ghost'],
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Orphan NW invadable id with no owner is silently '
            'skipped; the rest of the priority 2 scan still produces '
            'a valid plan.',
      );
    });

    test(
      'Refs #2509 Must-have #7 determinism: identical inputs -> identical plan',
      () {
        // Determinism pin (issue #2509 Must-have #7). Mixed-input
        // fixture exercises priority 1 with two destinations; the
        // same plan must come out twice in a row.
        final game = _colonialGame(
          newWorldProvinces: const [
            Province(
              id: 'newWorld|tribe1_a',
              regionId: 'newWorld',
              ownerId: _tribe1,
            ),
            Province(
              id: 'newWorld|tribe1_b',
              regionId: 'newWorld',
              ownerId: _tribe1,
            ),
          ],
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        );
        final snapshot = _colonialSnapshot(
          atWarWith: const [_tribe1, _gp2],
          invadableNw: const ['newWorld|tribe1_b', 'newWorld|tribe1_a'],
        );
        final first = planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe1,
        );
        final second = planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe1,
        );
        expect(second, equals(first), reason: 'Same inputs -> same plan.');
      },
    );

    test('AC divergence from planColonialLiteNaval: declared colonial target '
        'GP owns NW invadable -> included in invasion-transport plan', () {
      // Explicit divergence from [planColonialLiteNaval]: COLONIAL
      // allows invasion (declareWar + transport) against any
      // faction class -- tribes, minor nations, AND Great Powers
      // blocking the colonial frontier (issue #2509 §
      // planColonialAcquisition step 3). A GP-owned NW invadable
      // province MUST surface in the plan when the declared
      // colonial target is that GP. The COLONIAL-lite sibling, by
      // contrast, filters GP-owned NW invadable out entirely.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2],
        invadableNw: const ['newWorld|gp2_a'],
      );
      expect(
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _gp2,
        ),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|gp2_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_gp2],
        ),
        reason:
            'COLONIAL allows invasion against GP colonial blockers '
            '(declareWar acquisition method 3). A GP-owned NW '
            'invadable province surfaces in the invasion-transport '
            'plan when that GP is the declared colonial target. '
            'COLONIAL-lite would filter this out structurally; '
            'COLONIAL must not.',
      );
    });

    test(
      'GP-owned NW invadable via at-war fallback (priority 2) -> included',
      () {
        // Mirror branch from priority 2: a GP at war owning an NW
        // invadable province contributes that province to the
        // invasion-transport plan even without an explicit
        // colonialDeclaredWarTargetFactionId. Pins the structural
        // divergence from [planColonialLiteNaval] from the at-war
        // fallback side.
        final game = _colonialGame(
          newWorldProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          ],
        );
        final snapshot = _colonialSnapshot(
          atWarWith: const [_gp2],
          invadableNw: const ['newWorld|gp2_a'],
        );
        expect(
          planColonialNaval(game: game, snapshot: snapshot),
          const ColonialNavalPlan(
            priorityInvasionTransportProvinceIdsSorted: <String>[
              'newWorld|gp2_a',
            ],
            priorityTargetOwnerFactionIdsSorted: <String>[_gp2],
          ),
          reason:
              'COLONIAL at-war fallback admits GP owners. An at-war '
              'GP owning an NW invadable province is a legitimate '
              'invasion-transport target (the GP colonial blocker '
              'scenario from issue #2509 § primaryColonialGpBlocker).',
        );
      },
    );

    test('multi-player game: invadable filter is owner-scoped, not '
        'active-player-scoped', () {
      // Isolation pin: the active player is gp1 but the planner is
      // filtering invadable provinces by their OWNER (the enemy
      // faction). gp1's own province ownership is irrelevant to
      // the filter -- what matters is whether the invadable list
      // contains provinces owned by the declared target / at-war
      // factions.
      final game = _colonialGame(
        newWorldProvinces: const [
          // gp3 owns this -- at war but should be ignored because
          // not the declared target.
          Province(id: 'newWorld|gp3_0', regionId: 'newWorld', ownerId: _gp3),
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp3, _tribe1],
        invadableNw: const ['newWorld|gp3_0', 'newWorld|tribe1_a'],
      );
      expect(
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe1,
        ),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Priority 1 restricts ONLY to the declared target. gp3 '
            'is also at war and also owns an NW invadable province '
            'but is correctly excluded because the planner is keyed '
            'on owner == colonialDeclaredWarTargetFactionId.',
      );
    });

    test('input order shuffled -> ascending sort recovers', () {
      // Defensive determinism pin: even if a future builder
      // regression delivers the invadable list reversed, the
      // planner's trailing `destinations.sort()` recovers ascending
      // order for both priority arms.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
          Province(
            id: 'newWorld|tribe1_b',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
          Province(
            id: 'newWorld|minor1_a',
            regionId: 'newWorld',
            ownerId: _minor1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _colonialSnapshot(
        // Reversed input order across both owners.
        atWarWith: const [_tribe1, _minor1],
        invadableNw: const [
          'newWorld|tribe1_b',
          'newWorld|tribe1_a',
          'newWorld|minor1_a',
        ],
      );
      final plan = planColonialNaval(game: game, snapshot: snapshot);
      expect(
        plan.priorityInvasionTransportProvinceIdsSorted,
        const <String>[
          'newWorld|minor1_a',
          'newWorld|tribe1_a',
          'newWorld|tribe1_b',
        ],
        reason:
            'Trailing sort recovers ascending province order across '
            'reversed input.',
      );
      expect(
        plan.priorityTargetOwnerFactionIdsSorted,
        const <String>[_minor1, _tribe1],
        reason: 'Owner list also sorted ascending across the dedup set.',
      );
    });

    group('Path E below-quota waiver (Refs #2924)', () {
      test(
        'treasury-recovery override emits NW transport destinations below quota',
        () {
          final game = _colonialGame(
            newWorldProvinces: const [
              Province(
                id: _nwProvTribeA,
                regionId: 'newWorld',
                ownerId: _tribe1,
              ),
            ],
            tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          );
          final snapshot = _lockRecoveryBelowQuotaSnapshot(
            invadableNw: const [_nwProvTribeA],
          );
          expect(
            planColonialNaval(
              game: game,
              snapshot: snapshot,
              colonialDeclaredWarTargetFactionId: _tribe1,
              expandEconomyPlan: _nwTreasuryRecoveryOverridePlan,
            ),
            ColonialNavalPlan(
              priorityInvasionTransportProvinceIdsSorted: const [_nwProvTribeA],
              priorityTargetOwnerFactionIdsSorted: const [_tribe1],
            ),
            reason:
                'EXPAND universal colonial dispatch must honour the '
                'treasury-recovery override by waiving the below-quota '
                'outer guard so invasion-transport naval moves can '
                'follow a declared tribal war target.',
          );
        },
      );

      test(
        'below quota without override keeps defaultPlan regression guard',
        () {
          final game = _colonialGame(
            newWorldProvinces: const [
              Province(
                id: _nwProvTribeA,
                regionId: 'newWorld',
                ownerId: _tribe1,
              ),
            ],
            tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          );
          final snapshot = _lockRecoveryBelowQuotaSnapshot(
            invadableNw: const [_nwProvTribeA],
          );
          expect(
            planColonialNaval(
              game: game,
              snapshot: snapshot,
              colonialDeclaredWarTargetFactionId: _tribe1,
              expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
            ),
            same(ColonialNavalPlan.defaultPlan),
            reason:
                'Without boostTreasuryRecoveryCargo the legacy '
                'isBelowObserverConquestQuota guard must still block '
                'NW naval plans for below-quota GPs.',
          );
        },
      );
    });

    test('ColonialNavalPlan value equality: same fields compare equal', () {
      // Value-class pin: `==` and `hashCode` must compare by list
      // contents so tests can assert against literal constructions
      // without relying on object identity.
      const a = ColonialNavalPlan(
        priorityInvasionTransportProvinceIdsSorted: <String>[
          'newWorld|tribe1_a',
        ],
        priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
      );
      const b = ColonialNavalPlan(
        priorityInvasionTransportProvinceIdsSorted: <String>[
          'newWorld|tribe1_a',
        ],
        priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
      );
      const c = ColonialNavalPlan(
        priorityInvasionTransportProvinceIdsSorted: <String>[
          'newWorld|tribe2_a',
        ],
        priorityTargetOwnerFactionIdsSorted: <String>[_tribe2],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));

      // toString smoke test for diagnostic output consistency.
      expect(
        a.toString(),
        equals(
          'ColonialNavalPlan('
          'priorityInvasionTransportProvinceIdsSorted: [newWorld|tribe1_a], '
          'priorityTargetOwnerFactionIdsSorted: [tribe1])',
        ),
      );
    });

    test(
      'ColonialNavalPlan.defaultPlan equals explicit all-empty instance',
      () {
        // Default-plan pin: tests in the orchestrator wiring slice
        // (#2509 S5) may compare planner output against the shared
        // default instance OR a fresh `const ColonialNavalPlan(...)`.
        // Both must succeed.
        expect(
          ColonialNavalPlan.defaultPlan,
          equals(
            const ColonialNavalPlan(
              priorityInvasionTransportProvinceIdsSorted: <String>[],
              priorityTargetOwnerFactionIdsSorted: <String>[],
            ),
          ),
        );
      },
    );
  });
}
