// Case bodies for `colonial_phase_planner_colonial_lite_overtures_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for `planColonialLiteOvertures` in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3 / S10).
//
// Spec contract (issue #2509 § COLONIAL-lite § planColonialLiteOvertures):
//
//   "Inputs: Game, AIWorldSnapshot.
//    Returns: List<DiplomacyOrder> (establishOverture only).
//
//    For each visible NW tribe/minor owner in
//    adjacentNewWorldOwnerFactionIdsSorted ∪
//    preferredColonialTargetFactionIdsSorted:
//      → If no embassy yet, suggest establishOverture(tribe).
//      → Never emit declareWar, joinEmpire chain advance, or
//        purchase_land here.
//    Tiebreak: lowest factionId (deterministic)."
//
// Mirrors the test pattern established for the EXPAND-phase peace planner,
// the COLONIAL-phase peace planner, and the COLONIAL-phase military
// planner: small synthetic fixtures, one branch arm per test, in-module
// pin (the planner module never re-checks COLONIAL-lite outer schedule;
// the dispatcher under #2509 S5 owns that decision).
//
// `planColonialLiteOvertures` tests:
//
//   1. **Missing active player -> empty:** defensive guard pin for the
//      `game.playerById(snapshot.playerId) == null` arm (matches the
//      symmetric guard in `planColonialPeace` / `planColonialMilitary`).
//   2. **Empty candidate union -> empty:** structural short-circuit
//      when both `adjacentNewWorldOwnerFactionIdsSorted` and
//      `preferredColonialTargetFactionIdsSorted` are empty. No visible
//      NW tribe / minor owner -- nothing to overture this turn.
//   3. **AC: single adjacent tribe, no embassy -> [tribe1]:** canonical
//      happy path from the spec ("For each visible NW tribe/minor
//      owner ... if no embassy yet, suggest establishOverture").
//   4. **Single preferred-colonial tribe, no embassy -> [tribe1]:**
//      mirror branch from the preferred-target side; pins that the
//      preferred set contributes candidates exactly like the adjacent
//      set.
//   5. **Tribe in both adjacent + preferred (dedup) -> [tribe1]:** set
//      union pin so duplicates across both inputs collapse to a single
//      output entry.
//   6. **Multiple tribes + minor across adjacent + preferred -> sorted
//      ascending union:** the canonical "lowest factionId tiebreak"
//      from the spec applied across the dedup union.
//   7. **GP-owned candidate id filtered out:** defensive pin -- if a
//      candidate id happens to resolve to a [Player] (a GP), drop it
//      ("Never emit declareWar ... here"; the COLONIAL-lite contract
//      is tribe / minor only).
//   8. **Tribe at embassy stage (hasEmbassy=true) -> excluded:** active
//      player already advanced past the initial overture; the spec
//      "If no embassy yet" rule fires.
//   9. **Tribe at nap stage (hasEmbassy=true) -> excluded:** symmetric
//      `OvertureStage.nap` branch (`hasEmbassy` returns `true` for
//      `embassy`, `nap`, `joinEmpire`).
//  10. **Tribe at joinEmpire stage (hasEmbassy=true) -> excluded:**
//      symmetric `OvertureStage.joinEmpire` branch; pins that the
//      planner does not re-suggest overtures against absorbed tribes.
//  11. **Tribe at none stage (hasEmbassy=false) -> included:** pins
//      that the planner targets the canonical first-overture state
//      (no overture record at all collapses to the same arm).
//  12. **Tribe at tradeConsulate stage (hasEmbassy=false) -> included:**
//      pins that the consulate stage is treated as "no embassy yet"
//      per the [OvertureState.hasEmbassy] semantics.
//  13. **Sibling GP holds embassy with same target -> active player
//      NOT excluded:** pins the active-player constraint on the
//      embassy filter (a different GP's overture must not block the
//      active player's initial overture).
//  14. **Input order shuffled (adjacent reversed) -> ascending sort:**
//      determinism pin (Refs #2509 Must-have #7); the trailing
//      `result.sort()` recovers ascending order even when the input
//      sorted lists are reversed.
//  15. **Determinism:** identical inputs yield identical lists across
//      repeated calls (Must-have #7).
//  16. **Mixed: GP + embassied tribe + fresh tribe + minor in inputs
//      -> only fresh tribe + minor returned:** composite filter pin
//      (GP filter + embassy filter + sort in one fixture).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';


void registerColonialLiteOverturesSortCases() {
  group('planColonialLiteOvertures', () {
    test('tribe at stage=none -> included', () {
      // `OvertureStage.none` is the default for unseeded entries and
      // is treated as "no embassy yet" per `OvertureState.hasEmbassy`
      // returning false. Explicitly pin the case where an overture
      // record exists at stage=none (vs being absent entirely).
      final game = buildColonialLiteOvertureGame(
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
        overtureStates: const [
          OvertureState(
            gpId: kColonialPhaseGp1,
            targetId: kColonialPhaseTribe1,
            stage: OvertureStage.none,
          ),
        ],
      );
      final snapshot = buildColonialLiteOvertureSnapshot(
        adjacentNw: const [kColonialPhaseTribe1],
      );
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [kColonialPhaseTribe1],
        reason:
            'Stage=none carries `hasEmbassy=false`; the planner treats '
            'it as "no embassy yet" and suggests the initial overture.',
      );
    });

    test('tribe at tradeConsulate stage -> included', () {
      // Trade consulate is the first overture rung but still carries
      // `hasEmbassy=false`. The spec's "if no embassy yet" rule must
      // therefore include the tribe -- the initial overture is what
      // advances past the consulate stage anyway.
      final game = buildColonialLiteOvertureGame(
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
        overtureStates: const [
          OvertureState(
            gpId: kColonialPhaseGp1,
            targetId: kColonialPhaseTribe1,
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );
      final snapshot = buildColonialLiteOvertureSnapshot(
        adjacentNw: const [kColonialPhaseTribe1],
      );
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [kColonialPhaseTribe1],
        reason:
            'tradeConsulate stage still carries `hasEmbassy=false`; the '
            'planner must suggest the initial overture so the relation '
            'can advance to embassy on the next turn.',
      );
    });

    test(
      'sibling GP holds embassy with same target -> active NOT excluded',
      () {
        // The embassy filter is keyed on the (gpId, targetId) pair, not
        // just targetId. A sibling GP (gp2) holding an embassy with
        // tribe1 must not block the active player (gp1) from
        // initiating its own overture. A regression that filtered on
        // targetId alone would silently de-prioritize tribe1 for every
        // GP once any one GP advanced past the consulate stage.
        final game = buildColonialLiteOvertureGame(
          tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
          overtureStates: const [
            OvertureState(
              gpId: kColonialPhaseGp2,
              targetId: kColonialPhaseTribe1,
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final snapshot = buildColonialLiteOvertureSnapshot(
          adjacentNw: const [kColonialPhaseTribe1],
        );
        expect(
          planColonialLiteOvertures(game: game, snapshot: snapshot),
          const [kColonialPhaseTribe1],
          reason:
              'gp2 holds the embassy with tribe1; active player gp1 still '
              'has no embassy of its own and must initiate an overture.',
        );
      },
    );

    test('input order shuffled (adjacent reversed) -> ascending sort', () {
      // Determinism pin (Must-have #7). Inputs are supplied in
      // descending order; the trailing `result.sort()` restores
      // ascending order. A regression that returned the iteration
      // order of the Set would surface here as a Dart-runtime-defined
      // order rather than the spec's lowest-factionId tiebreak.
      final game = buildColonialLiteOvertureGame(
        tribes: const [
          Tribe(id: kColonialPhaseTribe1, displayName: 'T1'),
          Tribe(id: kColonialPhaseTribe2, displayName: 'T2'),
          Tribe(id: kColonialPhaseTribe3, displayName: 'T3'),
        ],
      );
      final snapshot = buildColonialLiteOvertureSnapshot(
        adjacentNw: const [
          kColonialPhaseTribe3,
          kColonialPhaseTribe2,
          kColonialPhaseTribe1,
        ],
      );
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [
          kColonialPhaseTribe1,
          kColonialPhaseTribe2,
          kColonialPhaseTribe3,
        ],
        reason:
            'Trailing `result.sort()` enforces ascending order regardless '
            'of input order (Refs #2509 Must-have #7 / lowest-factionId '
            'tiebreak from the spec).',
      );
    });

    test(
      'Refs #2509 Must-have #7 determinism: identical inputs -> identical list',
      () {
        // Pins Must-have #7 (determinism) at the in-module level. The
        // mixed-input fixture exercises the union, the GP filter, the
        // embassy filter, and the sort in one pass; repeating the call
        // must yield byte-identical lists.
        final game = buildColonialLiteOvertureGame(
          players: const [
            Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
            Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
          ],
          tribes: const [
            Tribe(id: kColonialPhaseTribe1, displayName: 'T1'),
            Tribe(id: kColonialPhaseTribe2, displayName: 'T2'),
          ],
          minorNations: const [
            MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: kColonialPhaseGp1,
              targetId: kColonialPhaseTribe2,
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final snapshot = buildColonialLiteOvertureSnapshot(
          adjacentNw: const [kColonialPhaseTribe2, kColonialPhaseGp2],
          preferredColonial: const [kColonialPhaseTribe1, kColonialPhaseMinor1],
        );
        final first = planColonialLiteOvertures(game: game, snapshot: snapshot);
        final second = planColonialLiteOvertures(
          game: game,
          snapshot: snapshot,
        );
        expect(second, first);
      },
    );

    test(
      'composite: GP + embassied tribe + fresh tribe + minor -> filtered sorted',
      () {
        // Composite pin exercising all three filters (GP filter +
        // embassy filter + sort) in one fixture. Inputs:
        //   adjacent = [gp2, tribe2, tribe1]
        //   preferred = [minor1, tribe2]
        // Embassy state: gp1 -> tribe2 (stage=embassy).
        // Expected:
        //   - gp2 dropped by the GP filter
        //   - tribe2 dropped by the embassy filter (gp1 already has
        //     embassy)
        //   - tribe1 + minor1 survive -> sorted ascending = [minor1,
        //     tribe1]
        final game = buildColonialLiteOvertureGame(
          tribes: const [
            Tribe(id: kColonialPhaseTribe1, displayName: 'T1'),
            Tribe(id: kColonialPhaseTribe2, displayName: 'T2'),
          ],
          minorNations: const [
            MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: kColonialPhaseGp1,
              targetId: kColonialPhaseTribe2,
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final snapshot = buildColonialLiteOvertureSnapshot(
          adjacentNw: const [
            kColonialPhaseGp2,
            kColonialPhaseTribe2,
            kColonialPhaseTribe1,
          ],
          preferredColonial: const [kColonialPhaseMinor1, kColonialPhaseTribe2],
        );
        expect(
          planColonialLiteOvertures(game: game, snapshot: snapshot),
          const [kColonialPhaseMinor1, kColonialPhaseTribe1],
          reason:
              'Composite filter: gp2 dropped (GP filter), tribe2 dropped '
              '(embassy filter), tribe1 + minor1 sorted ascending.',
        );
      },
    );
  });
}
