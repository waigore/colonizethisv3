// Unit tests for `planColonialLiteNaval` in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3 / S10).
//
// Spec contract (issue #2509 § COLONIAL-lite § planColonialLiteNaval):
//
//   "Inputs: Game, AIWorldSnapshot.
//    Returns: List<NavalOrder> (exploration + cargo only).
//
//      → Naval exploration of unrevealed NW sea zones adjacent to
//        visible NW provinces.
//      → Cargo routing (deliver riches to OW stockpile) using existing
//        colonial naval pathing.
//      → Never suggest invasion transport or NW army staging here."
//
// Mirrors the test pattern established for the COLONIAL-phase military
// planner (`colonial_phase_planner_military_test.dart`) and the
// COLONIAL-lite overture planner
// (`colonial_phase_planner_colonial_lite_overtures_test.dart`): small
// synthetic fixtures, one branch arm per test, in-module pin (the
// planner module never re-checks the COLONIAL-lite outer schedule; the
// dispatcher under #2509 S5 owns that decision).
//
// `planColonialLiteNaval` tests:
//
//   1. **Missing active player -> defaultPlan:** defensive guard pin
//      for the `game.playerById(snapshot.playerId) == null` arm
//      (matches the symmetric guard in
//      [planColonialLiteOvertures] and [planColonialMilitary]).
//   2. **Empty NW invadable -> defaultPlan:** structural empty-list
//      short-circuit so an empty constraint never leaks to the
//      orchestrator.
//   3. **AC: single tribe-owned NW invadable -> restrict to that
//      province + tribe as sole owner:** canonical happy path for the
//      COLONIAL-lite naval exploration focus (issue #2509
//      § COLONIAL-lite § planColonialLiteNaval "exploration ... adjacent
//      to visible NW provinces").
//   4. **Single minor-owned NW invadable -> restrict to that province
//      + minor as sole owner:** mirror branch from the minor-owner side;
//      pins that the planner does not discriminate between tribes and
//      minor nations -- both are first-class COLONIAL-lite targets per
//      issue #2509 § COLONIAL-lite ("visible NW tribe / minor owners").
//   5. **Multiple tribe-owned NW invadable -> all those provinces,
//      sorted ascending:** the COLONIAL-lite naval focus keeps ALL
//      tribe-owned provinces, sorted ascending, regardless of input
//      order (Refs #2509 Must-have #7).
//   6. **GP-owned NW invadable filtered out (structural):** pins the
//      GP suppression branch -- a GP-owned NW invadable province must
//      NOT appear in the plan because COLONIAL-lite is the safeguard
//      for tribe / minor NW penetration only (issue #2509
//      § COLONIAL-lite suppresses NW `declareWar`, so GP-owned NW
//      cannot legitimately become a COLONIAL-lite naval target).
//   7. **Mixed: tribe + minor + GP-owned NW invadable -> only tribe +
//      minor returned, sorted ascending:** composite filter pin (GP
//      filter + multi-owner union in one fixture).
//   8. **Only GP-owned NW invadable -> defaultPlan:** priority-arm
//      fall-through pin; with no tribe / minor contributing any NW
//      invadable the planner returns the default plan and the
//      orchestrator falls back to legacy free-choice colonial naval
//      behaviour.
//   9. **Orphan NW invadable id (no owner in province-owner map) ->
//      silently skipped:** defensive pin for the
//      `if (owner == null) continue` branch; a stale invadable id with
//      no province record must not blow up the planner.
//  10. **Determinism (Must-have #7):** identical inputs yield identical
//      plans across repeated calls.
//  11. **OW invadable structurally suppressed:** even with an at-war
//      tribe owning an OW invadable province in the conquest summary
//      and no NW invadable in the colonial summary, the plan must NOT
//      pick up the OW province -- the planner only reads
//      `invadableNewWorldProvinceIdsSorted`.
//  12. **At-war tribe-owner NOT a precondition for inclusion:** the
//      COLONIAL-lite naval focus targets tribe / minor owners
//      regardless of war state (the COLONIAL-lite contract is
//      structural NW-acquisition seed work, not retaliation; the
//      `at-war` predicate from `planColonialMilitary` is intentionally
//      absent here).
//  13. **Owner list mirrors province contributions (no phantom
//      owners):** a tribe with no NW invadable contribution must NOT
//      appear in `priorityTargetOwnerFactionIdsSorted` even when it is
//      otherwise visible in the snapshot via other summary fields.
//  14. **Owner list deduplicates across multiple provinces from the
//      same tribe:** two provinces owned by `tribe1` must surface
//      `tribe1` only once in `priorityTargetOwnerFactionIdsSorted`.
//  15. **Input order shuffled -> ascending sort:** determinism pin
//      under defensive input handling; the trailing
//      `priorityProvinces.sort()` recovers ascending order even when
//      the snapshot's invadable list arrives un-sorted.
//  16. **ColonialLiteNavalPlan value equality + defaultPlan equals
//      explicit all-empty instance:** value-class pin so orchestrator
//      wiring tests (#2509 S5) can compare planner output against the
//      shared default OR a fresh `const ColonialLiteNavalPlan`.
//
// The "exploration + cargo only" naval-order envelope itself (sea-zone
// move generation via topology + ranked colonial cargo routing) lives
// at the orchestrator layer (#2509 S5) and the existing
// `colonial_naval_scoring.dart` helpers; it is intentionally out of
// scope for this in-module pin -- the unit pins the deterministic
// destination filter (tribe / minor NW invadable provinces) that the
// orchestrator consumes.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _tribe1 = 'tribe1';
const String _tribe2 = 'tribe2';
const String _minor1 = 'minor1';

/// Game scaffold for COLONIAL-lite naval tests. New World provinces,
/// players, tribes, and minors are passed in so each test can shape
/// ownership independently. Old World defaults to empty because the
/// planner does not query OW state (the OW invadable summary is read
/// only by [planExpandMilitary] / [planColonialMilitary], not by
/// [planColonialLiteNaval]).
Game _colonialLiteGame({
  int turnNumber = 125,
  List<Province> newWorldProvinces = const [],
  List<Province> oldWorldProvinces = const [],
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false),
    Player(id: _gp2, displayName: 'GP2', isHuman: false),
    Player(id: _gp3, displayName: 'GP3', isHuman: false),
  ],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-colonial-lite-naval-t$turnNumber',
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

/// Snapshot tuned for COLONIAL-lite: own OW defaults to 9 (the
/// COLONIAL-lite outer schedule -- "OW ≥9 and <10"). Tests shape
/// `invadableNw` and `invadableOw` to exercise the structural OW
/// suppression and the tribe / minor / GP owner filter. The planner
/// does not re-check the phase so the values are still consistent with
/// COLONIAL-lite only so debugging traces stay coherent.
AIWorldSnapshot _colonialLiteSnapshot({
  List<String> invadableNw = const [],
  List<String> invadableOw = const [],
  List<String> atWarWith = const [],
  int oldWorldProvincesOwned = 9,
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

void main() {
  group('planColonialLiteNaval', () {
    test('missing active player -> defaultPlan', () {
      // Defensive guard pin: snapshots pointing at a non-existent
      // player must not crash; the planner returns the default plan.
      // Matches the symmetric guard in [planColonialLiteOvertures] and
      // [planColonialMilitary].
      final game = _colonialLiteGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialLiteSnapshot(
        invadableNw: const ['newWorld|tribe1_a'],
        playerId: 'ghost-player',
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        same(ColonialLiteNavalPlan.defaultPlan),
        reason:
            'Active player is missing from the game roster; the planner '
            'must short-circuit before reading any owner state and return '
            'the shared defaultPlan instance.',
      );
    });

    test('empty NW invadable -> defaultPlan', () {
      // No NW frontier means there is no province to filter; the
      // function must short-circuit before any owner scan so an empty
      // constraint never leaks to the orchestrator.
      final game = _colonialLiteGame();
      final snapshot = _colonialLiteSnapshot(invadableNw: const []);
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        same(ColonialLiteNavalPlan.defaultPlan),
      );
    });

    test(
      'AC: single tribe-owned NW invadable -> restrict to that province '
      '+ tribe as sole owner',
      () {
        // Canonical happy path from the spec: a single tribe-owned NW
        // invadable province surfaces in the plan as the exploration
        // focus. A regression that filtered tribes structurally
        // would show empty here.
        final game = _colonialLiteGame(
          newWorldProvinces: const [
            Province(
              id: 'newWorld|tribe1_a',
              regionId: 'newWorld',
              ownerId: _tribe1,
            ),
          ],
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        );
        final snapshot = _colonialLiteSnapshot(
          invadableNw: const ['newWorld|tribe1_a'],
        );
        expect(
          planColonialLiteNaval(game: game, snapshot: snapshot),
          const ColonialLiteNavalPlan(
            priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
            priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
          ),
          reason:
              'Canonical COLONIAL-lite naval focus: single tribe-owned NW '
              'invadable -> plan restricts to that province and lists the '
              'tribe as the sole priority owner.',
        );
      },
    );

    test(
      'single minor-owned NW invadable -> restrict to that province + minor '
      'as sole owner',
      () {
        // Mirror branch from the minor-owner side. Tribes and minors are
        // both first-class COLONIAL-lite naval targets per issue #2509
        // § COLONIAL-lite "establishOverture toward visible NW tribe /
        // minor owners".
        final game = _colonialLiteGame(
          newWorldProvinces: const [
            Province(
              id: 'newWorld|minor1_a',
              regionId: 'newWorld',
              ownerId: _minor1,
            ),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _colonialLiteSnapshot(
          invadableNw: const ['newWorld|minor1_a'],
        );
        expect(
          planColonialLiteNaval(game: game, snapshot: snapshot),
          const ColonialLiteNavalPlan(
            priorityNwProvinceIdsSorted: <String>['newWorld|minor1_a'],
            priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
          ),
          reason:
              'Minors are first-class COLONIAL-lite naval targets (same '
              'class as tribes); the planner does not discriminate '
              'between Tribe and MinorNation entries.',
        );
      },
    );

    test(
      'multiple tribe-owned NW invadable -> all those provinces, '
      'sorted ascending',
      () {
        // Multiple tribe-owned NW invadable provinces: the COLONIAL-lite
        // naval focus keeps ALL of them, sorted ascending, regardless
        // of the input order. Defensive determinism against future
        // builder changes (Refs #2509 Must-have #7).
        final game = _colonialLiteGame(
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
        final snapshot = _colonialLiteSnapshot(
          invadableNw: const ['newWorld|tribe1_b', 'newWorld|tribe1_a'],
        );
        expect(
          planColonialLiteNaval(game: game, snapshot: snapshot),
          const ColonialLiteNavalPlan(
            priorityNwProvinceIdsSorted: <String>[
              'newWorld|tribe1_a',
              'newWorld|tribe1_b',
            ],
            priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
          ),
          reason:
              'COLONIAL-lite naval focus keeps ALL tribe-owned NW invadable '
              'provinces, sorted ascending. Output order is independent of '
              'the input invadable list order.',
        );
      },
    );

    test('GP-owned NW invadable filtered out (structural)', () {
      // GP-owned NW invadable must NOT appear in the plan. COLONIAL-lite
      // is the safeguard for tribe / minor NW penetration only;
      // GP-owned NW is structurally excluded because the spec suppresses
      // NW `declareWar` and `purchase_land` here (issue #2509
      // § COLONIAL-lite suppressed list).
      final game = _colonialLiteGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|gp2_a',
            regionId: 'newWorld',
            ownerId: _gp2,
          ),
        ],
      );
      final snapshot = _colonialLiteSnapshot(
        invadableNw: const ['newWorld|gp2_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        same(ColonialLiteNavalPlan.defaultPlan),
        reason:
            'GP-owned NW invadable is structurally excluded from the '
            'COLONIAL-lite naval focus; with no tribe / minor contributing '
            'any province the plan falls back to defaultPlan.',
      );
    });

    test(
      'mixed: tribe + minor + GP-owned NW invadable -> only tribe + minor '
      'returned, sorted ascending',
      () {
        // Composite filter pin (GP filter + multi-owner union). The
        // GP-owned province is dropped; the tribe and minor provinces
        // surface in `priorityNwProvinceIdsSorted` (sorted ascending),
        // and both owners appear in
        // `priorityTargetOwnerFactionIdsSorted` (sorted ascending,
        // deduplicated).
        final game = _colonialLiteGame(
          newWorldProvinces: const [
            Province(
              id: 'newWorld|tribe1_a',
              regionId: 'newWorld',
              ownerId: _tribe1,
            ),
            Province(
              id: 'newWorld|minor1_a',
              regionId: 'newWorld',
              ownerId: _minor1,
            ),
            Province(
              id: 'newWorld|gp2_a',
              regionId: 'newWorld',
              ownerId: _gp2,
            ),
          ],
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _colonialLiteSnapshot(
          invadableNw: const [
            'newWorld|tribe1_a',
            'newWorld|minor1_a',
            'newWorld|gp2_a',
          ],
        );
        expect(
          planColonialLiteNaval(game: game, snapshot: snapshot),
          const ColonialLiteNavalPlan(
            priorityNwProvinceIdsSorted: <String>[
              'newWorld|minor1_a',
              'newWorld|tribe1_a',
            ],
            priorityTargetOwnerFactionIdsSorted: <String>[_minor1, _tribe1],
          ),
          reason:
              'Composite filter: GP-owned NW invadable dropped; tribe + '
              'minor NW invadable surface in the plan with both lists '
              'sorted ascending. minor1 < tribe1 lexically so minor1 '
              'sorts first in both fields.',
        );
      },
    );

    test('only GP-owned NW invadable -> defaultPlan', () {
      // Priority-arm fall-through pin: with no tribe / minor
      // contributing any NW invadable, the planner returns the default
      // plan and the orchestrator falls back to legacy free-choice
      // colonial naval behaviour.
      final game = _colonialLiteGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|gp2_a',
            regionId: 'newWorld',
            ownerId: _gp2,
          ),
          Province(
            id: 'newWorld|gp3_a',
            regionId: 'newWorld',
            ownerId: _gp3,
          ),
        ],
      );
      final snapshot = _colonialLiteSnapshot(
        invadableNw: const ['newWorld|gp2_a', 'newWorld|gp3_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        same(ColonialLiteNavalPlan.defaultPlan),
        reason:
            'Only GP-owned NW invadable + no tribe / minor contributor '
            '-> defaultPlan (the orchestrator falls back to the legacy '
            'free-choice colonial naval behaviour over the full NW '
            'invadable set).',
      );
    });

    test('orphan NW invadable id with no owner -> silently skipped', () {
      // A snapshot can list an invadable NW id that no longer maps to a
      // province (stale fixture, mid-resolution diff, etc.). The
      // planner must silently skip the orphan via the
      // `if (owner == null) continue` branch and not blow up.
      final game = _colonialLiteGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialLiteSnapshot(
        invadableNw: const ['newWorld|orphan', 'newWorld|tribe1_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Orphan invadable id (no province record) is silently '
            'skipped; the live tribe-owned province still surfaces in '
            'the plan.',
      );
    });

    test('determinism: identical inputs yield identical plans', () {
      // Pure-function determinism (Refs #2509 Must-have #7) -- the
      // planner is called twice with the same inputs and must return
      // equal plans across both calls.
      final game = _colonialLiteGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
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
      final snapshot = _colonialLiteSnapshot(
        invadableNw: const ['newWorld|tribe1_a', 'newWorld|minor1_a'],
      );
      final first = planColonialLiteNaval(game: game, snapshot: snapshot);
      final second = planColonialLiteNaval(game: game, snapshot: snapshot);
      expect(first, equals(second));
    });

    test('OW invadable structurally suppressed', () {
      // Even with an at-war tribe owning an OW invadable province in
      // the conquest summary and an empty NW invadable list in the
      // colonial summary, the plan must NOT pick up the OW province
      // -- the planner only reads
      // `colonial.invadableNewWorldProvinceIdsSorted`. This pins the
      // structural OW suppression from the spec ("Naval exploration of
      // unrevealed NW sea zones ...").
      final game = _colonialLiteGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|tribe1_a',
            regionId: 'oldWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialLiteSnapshot(
        invadableNw: const [],
        invadableOw: const ['oldWorld|tribe1_a'],
        atWarWith: const [_tribe1],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        same(ColonialLiteNavalPlan.defaultPlan),
        reason:
            'OW invadable provinces must never appear in the COLONIAL-lite '
            'naval focus; the planner only reads the NW invadable list '
            'from the colonial summary.',
      );
    });

    test('at-war state is NOT a precondition for inclusion', () {
      // The COLONIAL-lite naval focus targets tribe / minor owners
      // regardless of war state. This is intentionally different from
      // [planColonialMilitary], where the at-war fallback arm gates on
      // `snapshot.threats.atWarWith`. COLONIAL-lite is structural
      // NW-acquisition seed work (exploration + cargo), not
      // retaliation -- the planner must surface tribes / minors even
      // when not yet at war with them.
      final game = _colonialLiteGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialLiteSnapshot(
        invadableNw: const ['newWorld|tribe1_a'],
        atWarWith: const [],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'COLONIAL-lite naval focus surfaces tribe / minor owners '
            'without requiring an at-war predicate (unlike '
            'planColonialMilitary). The COLONIAL-lite contract is '
            'pre-war seed work, not retaliation.',
      );
    });

    test('owner list mirrors province contributions (no phantom owners)', () {
      // A tribe with no NW invadable contribution must NOT appear in
      // `priorityTargetOwnerFactionIdsSorted`. This pins the
      // "owner list mirrors actual destinations" contract so a
      // downstream orchestrator never sees a phantom target.
      final game = _colonialLiteGame(
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
      final snapshot = _colonialLiteSnapshot(
        // tribe2's province is NOT in the snapshot invadable list, so
        // tribe2 must NOT surface as a priority owner.
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Only tribes / minors that actually contribute an NW invadable '
            'province appear in priorityTargetOwnerFactionIdsSorted. '
            'tribe2 exists in the game roster but contributes nothing so '
            'it is absent from the plan.',
      );
    });

    test('owner list deduplicates across multiple provinces from same tribe',
        () {
      // Two provinces owned by `tribe1` must surface `tribe1` only once
      // in `priorityTargetOwnerFactionIdsSorted`. The set-based owner
      // collection in the planner is responsible for the dedup.
      final game = _colonialLiteGame(
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
            id: 'newWorld|tribe1_c',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialLiteSnapshot(
        invadableNw: const [
          'newWorld|tribe1_a',
          'newWorld|tribe1_b',
          'newWorld|tribe1_c',
        ],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
            'newWorld|tribe1_b',
            'newWorld|tribe1_c',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Three provinces owned by tribe1 surface tribe1 only once in '
            'priorityTargetOwnerFactionIdsSorted (set-based dedup).',
      );
    });

    test('input order shuffled -> ascending sort recovers', () {
      // Defensive determinism pin: even if a future builder regression
      // delivers the invadable list reversed, the planner's trailing
      // `priorityProvinces.sort()` recovers ascending order.
      final game = _colonialLiteGame(
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
      final snapshot = _colonialLiteSnapshot(
        // Reversed input order.
        invadableNw: const [
          'newWorld|tribe1_b',
          'newWorld|tribe1_a',
          'newWorld|minor1_a',
        ],
      );
      final plan = planColonialLiteNaval(game: game, snapshot: snapshot);
      expect(
        plan.priorityNwProvinceIdsSorted,
        const <String>[
          'newWorld|minor1_a',
          'newWorld|tribe1_a',
          'newWorld|tribe1_b',
        ],
        reason: 'Trailing sort recovers ascending order across reversed input.',
      );
      expect(
        plan.priorityTargetOwnerFactionIdsSorted,
        const <String>[_minor1, _tribe1],
        reason: 'Owner list also sorted ascending across the dedup set.',
      );
    });

    test(
      'ColonialLiteNavalPlan value equality + defaultPlan equals explicit '
      'all-empty instance',
      () {
        // Value-class pin so orchestrator wiring tests (#2509 S5) can
        // compare planner output against the shared defaultPlan OR a
        // fresh `const ColonialLiteNavalPlan(...)` with matching list
        // contents. List equality is content-based, not identity-based.
        const planA = ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        );
        const planB = ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        );
        expect(planA, equals(planB));
        expect(planA.hashCode, equals(planB.hashCode));

        const explicitDefault = ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>[],
          priorityTargetOwnerFactionIdsSorted: <String>[],
        );
        expect(
          ColonialLiteNavalPlan.defaultPlan,
          equals(explicitDefault),
          reason:
              'defaultPlan compares equal to a fresh all-empty const '
              'instance; orchestrator wiring tests can assert against '
              'either form.',
        );

        // toString smoke test for diagnostic output consistency.
        expect(
          planA.toString(),
          equals(
            'ColonialLiteNavalPlan('
            'priorityNwProvinceIdsSorted: [newWorld|tribe1_a], '
            'priorityTargetOwnerFactionIdsSorted: [tribe1])',
          ),
        );
      },
    );
  });
}
