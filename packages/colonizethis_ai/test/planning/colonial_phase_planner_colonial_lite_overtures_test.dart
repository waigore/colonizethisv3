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

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _tribe1 = 'tribe1';
const String _tribe2 = 'tribe2';
const String _tribe3 = 'tribe3';
const String _minor1 = 'minor1';

/// Game scaffold for COLONIAL-lite overture tests. Tribes, minors, and
/// overture states are passed in so each test can shape diplomatic
/// state. Old World and New World provinces are intentionally empty
/// because the planner does not query province ownership directly -- it
/// reads the visible-owner faction id lists from the snapshot and the
/// embassy filter from `game.overtureStates`.
Game _colonialLiteGame({
  int turnNumber = 125,
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false),
    Player(id: _gp2, displayName: 'GP2', isHuman: false),
  ],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  List<OvertureState> overtureStates = const [],
}) {
  return Game(
    id: 'g-2509-colonial-lite-overtures-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    overtureStates: overtureStates,
  );
}

/// Snapshot tuned for COLONIAL-lite: own OW defaults to 9 (the
/// COLONIAL-lite outer schedule -- "OW ≥9 and <10"). Tests shape the
/// `adjacentNw` and `preferredColonial` candidate lists to exercise the
/// union, GP filter, and embassy filter. The planner does not re-check
/// the phase so the values are still consistent with COLONIAL-lite only
/// so debugging traces stay coherent.
AIWorldSnapshot _colonialLiteSnapshot({
  List<String> adjacentNw = const [],
  List<String> preferredColonial = const [],
  int oldWorldProvincesOwned = 9,
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: 31,
    ),
    colonial: ColonialSummary(
      adjacentNewWorldOwnerFactionIdsSorted: adjacentNw,
      preferredColonialTargetFactionIdsSorted: preferredColonial,
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('planColonialLiteOvertures', () {
    test('missing active player -> empty', () {
      // Defensive guard pin: `snapshot.playerId` does not resolve to a
      // [Player] in the game so `game.playerById` returns null. The
      // planner short-circuits before any candidate / embassy scan.
      // A regression that always emitted the snapshot's candidate set
      // here would issue overtures for a player that does not exist
      // in the game roster.
      final game = _colonialLiteGame(
        players: const [Player(id: _gp2, displayName: 'GP2', isHuman: false)],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialLiteSnapshot(adjacentNw: const [_tribe1]);
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Active player is missing from the game roster; the planner '
            'must short-circuit and never emit overtures.',
      );
    });

    test('empty candidate union -> empty', () {
      // Both `adjacentNewWorldOwnerFactionIdsSorted` and
      // `preferredColonialTargetFactionIdsSorted` are empty so the
      // union has no candidates. The planner returns empty without
      // touching `game.overtureStates`. This pins the
      // "no visible NW tribe / minor owner" structural short-circuit.
      final game = _colonialLiteGame();
      final snapshot = _colonialLiteSnapshot();
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'No visible NW tribe / minor owners across either input set; '
            'the planner has nothing to overture this turn.',
      );
    });

    test('AC: single adjacent tribe, no embassy -> [tribe1]', () {
      // Canonical happy path from the spec ("For each visible NW
      // tribe/minor owner ... if no embassy yet, suggest
      // establishOverture"). Adjacent NW owner = tribe1, no overture
      // state at all -> tribe1 returned. A regression that filtered
      // tribes structurally would surface here as empty.
      final game = _colonialLiteGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialLiteSnapshot(adjacentNw: const [_tribe1]);
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [_tribe1],
        reason:
            'Single adjacent tribe with no existing overture is the '
            'canonical "if no embassy yet, suggest establishOverture" '
            'happy path.',
      );
    });

    test('single preferred-colonial tribe, no embassy -> [tribe1]', () {
      // Mirror branch: the candidate comes from
      // `preferredColonialTargetFactionIdsSorted` instead of
      // `adjacentNewWorldOwnerFactionIdsSorted`. Both lists feed the
      // union and behave identically.
      final game = _colonialLiteGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialLiteSnapshot(
        preferredColonial: const [_tribe1],
      );
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [_tribe1],
        reason:
            'Preferred-colonial targets contribute candidates just like '
            'adjacent NW owners (both inputs feed the union).',
      );
    });

    test('tribe in both adjacent + preferred (dedup) -> [tribe1]', () {
      // Set-union pin: tribe1 appears in BOTH inputs. The planner uses
      // a `Set` to collect candidates so duplicates collapse to a
      // single output entry. A regression that used a list concat
      // would emit `[tribe1, tribe1]` and the orchestrator would emit
      // a duplicate overture order.
      final game = _colonialLiteGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialLiteSnapshot(
        adjacentNw: const [_tribe1],
        preferredColonial: const [_tribe1],
      );
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [_tribe1],
        reason:
            'tribe1 is present in both candidate lists; the set union '
            'must deduplicate so only one overture is suggested.',
      );
    });

    test('multiple tribes + minor across both inputs -> sorted union', () {
      // Pins the "Tiebreak: lowest factionId (deterministic)" rule
      // across the dedup union. tribe2 + tribe3 from adjacent,
      // tribe1 + minor1 from preferred -> all four sorted ascending.
      final game = _colonialLiteGame(
        tribes: const [
          Tribe(id: _tribe1, displayName: 'T1'),
          Tribe(id: _tribe2, displayName: 'T2'),
          Tribe(id: _tribe3, displayName: 'T3'),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _colonialLiteSnapshot(
        adjacentNw: const [_tribe2, _tribe3],
        preferredColonial: const [_tribe1, _minor1],
      );
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [_minor1, _tribe1, _tribe2, _tribe3],
        reason:
            'Union across both candidate lists is sorted ascending '
            '(lowest factionId tiebreak from the spec).',
      );
    });

    test('GP-owned candidate id filtered out (defensive)', () {
      // Defensive pin: if a candidate id happens to resolve to a
      // [Player] (a Great Power), drop it. The COLONIAL-lite
      // contract is tribe / minor only -- "Never emit declareWar"
      // implies GP-vs-GP wars are out of scope. A regression that
      // skipped the GP filter would emit `establishOverture(gp2)`
      // which the order engine then rejects.
      final game = _colonialLiteGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialLiteSnapshot(adjacentNw: const [_gp2, _tribe1]);
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [_tribe1],
        reason:
            'gp2 resolves via `game.playerById`; the GP filter drops it '
            'so only tribe1 is suggested.',
      );
    });

    test('tribe at embassy stage -> excluded', () {
      // Embassy filter pin: active player + tribe1 + stage=embassy
      // means `hasEmbassy` is true so the planner skips tribe1.
      // The candidate union still contains tribe1, but the embassy
      // filter excludes it. A regression that omitted the embassy
      // filter would re-issue the initial overture against an
      // already-embassied tribe.
      final game = _colonialLiteGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        overtureStates: const [
          OvertureState(
            gpId: _gp1,
            targetId: _tribe1,
            stage: OvertureStage.embassy,
          ),
        ],
      );
      final snapshot = _colonialLiteSnapshot(adjacentNw: const [_tribe1]);
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Active player already holds an embassy with tribe1; the '
            'planner must not re-issue the initial overture.',
      );
    });

    test('tribe at nap stage -> excluded', () {
      // `OvertureState.hasEmbassy` returns true for `embassy`, `nap`,
      // and `joinEmpire`. Pin the `nap` branch explicitly.
      final game = _colonialLiteGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        overtureStates: const [
          OvertureState(
            gpId: _gp1,
            targetId: _tribe1,
            stage: OvertureStage.nap,
          ),
        ],
      );
      final snapshot = _colonialLiteSnapshot(adjacentNw: const [_tribe1]);
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'NAP stage carries `hasEmbassy=true`; the embassy filter '
            'must exclude tribe1.',
      );
    });

    test('tribe at joinEmpire stage -> excluded', () {
      // Pin the `joinEmpire` branch of `hasEmbassy`. Once a tribe is
      // absorbed into the empire chain, the planner stops emitting
      // initial overtures (acquisition is now driven by
      // `planColonialAcquisition`).
      final game = _colonialLiteGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        overtureStates: const [
          OvertureState(
            gpId: _gp1,
            targetId: _tribe1,
            stage: OvertureStage.joinEmpire,
          ),
        ],
      );
      final snapshot = _colonialLiteSnapshot(adjacentNw: const [_tribe1]);
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'joinEmpire stage carries `hasEmbassy=true`; the planner '
            'stops emitting initial overtures for an absorbed tribe.',
      );
    });

    test('tribe at stage=none -> included', () {
      // `OvertureStage.none` is the default for unseeded entries and
      // is treated as "no embassy yet" per `OvertureState.hasEmbassy`
      // returning false. Explicitly pin the case where an overture
      // record exists at stage=none (vs being absent entirely).
      final game = _colonialLiteGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        overtureStates: const [
          OvertureState(
            gpId: _gp1,
            targetId: _tribe1,
            stage: OvertureStage.none,
          ),
        ],
      );
      final snapshot = _colonialLiteSnapshot(adjacentNw: const [_tribe1]);
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [_tribe1],
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
      final game = _colonialLiteGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        overtureStates: const [
          OvertureState(
            gpId: _gp1,
            targetId: _tribe1,
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );
      final snapshot = _colonialLiteSnapshot(adjacentNw: const [_tribe1]);
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [_tribe1],
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
        final game = _colonialLiteGame(
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          overtureStates: const [
            OvertureState(
              gpId: _gp2,
              targetId: _tribe1,
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final snapshot = _colonialLiteSnapshot(adjacentNw: const [_tribe1]);
        expect(
          planColonialLiteOvertures(game: game, snapshot: snapshot),
          const [_tribe1],
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
      final game = _colonialLiteGame(
        tribes: const [
          Tribe(id: _tribe1, displayName: 'T1'),
          Tribe(id: _tribe2, displayName: 'T2'),
          Tribe(id: _tribe3, displayName: 'T3'),
        ],
      );
      final snapshot = _colonialLiteSnapshot(
        adjacentNw: const [_tribe3, _tribe2, _tribe1],
      );
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [_tribe1, _tribe2, _tribe3],
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
        final game = _colonialLiteGame(
          players: const [
            Player(id: _gp1, displayName: 'GP1', isHuman: false),
            Player(id: _gp2, displayName: 'GP2', isHuman: false),
          ],
          tribes: const [
            Tribe(id: _tribe1, displayName: 'T1'),
            Tribe(id: _tribe2, displayName: 'T2'),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
          overtureStates: const [
            OvertureState(
              gpId: _gp1,
              targetId: _tribe2,
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final snapshot = _colonialLiteSnapshot(
          adjacentNw: const [_tribe2, _gp2],
          preferredColonial: const [_tribe1, _minor1],
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
        final game = _colonialLiteGame(
          tribes: const [
            Tribe(id: _tribe1, displayName: 'T1'),
            Tribe(id: _tribe2, displayName: 'T2'),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
          overtureStates: const [
            OvertureState(
              gpId: _gp1,
              targetId: _tribe2,
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final snapshot = _colonialLiteSnapshot(
          adjacentNw: const [_gp2, _tribe2, _tribe1],
          preferredColonial: const [_minor1, _tribe2],
        );
        expect(
          planColonialLiteOvertures(game: game, snapshot: snapshot),
          const [_minor1, _tribe1],
          reason:
              'Composite filter: gp2 dropped (GP filter), tribe2 dropped '
              '(embassy filter), tribe1 + minor1 sorted ascending.',
        );
      },
    );
  });
}
