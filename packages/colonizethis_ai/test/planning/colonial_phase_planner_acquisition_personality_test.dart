// Unit tests for the personality-bias arm of `planColonialAcquisition`
// in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 Must-have #4 / S3).
//
// Spec contract
// (`SPEC/ai/phase-planner-architecture.md` § Personality bias and
// `SPEC/ai/ai-personalities.md` § Behavioral modifiers):
//
//   "planColonialAcquisition accepts an optional personalityId. When
//    the personality's warLikelihood > allianceTendency per
//    personalityThresholds (today: napoleon, isabella, frederick,
//    gustavus), the planner prefers declareWar over joinEmpire for
//    the same tribe within the structural priority order; otherwise
//    joinEmpire keeps top rank. The per-province purchase_land arm
//    is unchanged; outer gates (regiments, treasury, sea reachability)
//    still apply."
//
// Acceptance criterion under test
// (issue #2509 § Phase planner unit tests, "COLONIAL personality
// divergence"):
//
//   "Given two identical COLONIAL-phase states that differ only in
//    AIConfig.leaderId (napoleon vs henry) with a tribe target where
//    both Join Empire and declare-war are valid, when
//    planColonialAcquisition runs, then the top-ranked acquisition
//    method differs between personalities per
//    SPEC/ai/ai-personalities.md war vs alliance modifiers."
//
// `planColonialAcquisition` personality tests:
//
//   1. **Napoleon (warmonger) -> declareWar wins over Join Empire:**
//      canonical Must-have #4 happy path. Same tribe, both arms
//      gated to pass; the militaristic ordering returns
//      `AcquisitionMethod.declareWar`.
//   2. **Henry (alliance-leaning) -> Join Empire wins over declareWar:**
//      symmetric pin. Same tribe, both arms gated to pass; the
//      alliance ordering returns `AcquisitionMethod.joinEmpire`.
//   3. **Napoleon vs Henry — same fixture diverges:** AC verbatim.
//      Identical `Game` / `AIWorldSnapshot`; only `personalityId`
//      differs; outputs differ as Must-have #4 requires.
//   4. **Default (no personalityId) keeps legacy Join Empire-first
//      behavior:** the optional parameter is backward-compatible; the
//      existing call signature `planColonialAcquisition(game:, snapshot:)`
//      returns `joinEmpire` exactly as before.
//   5. **Unknown personalityId -> defaultThresholds neutral (50 == 50)
//      -> Join Empire wins:** `getThresholdsForLeader` falls back to
//      neutral defaults when the id is unknown; `warLikelihood`
//      equals `allianceTendency`, so the strict `>` comparison is
//      false and the planner keeps the alliance ordering.
//   6. **Napoleon outer gate (zero regiments) -> Join Empire wins:**
//      the militaristic ordering does not bypass declareWar's outer
//      regiment guard. With no standing regiments the declareWar pass
//      short-circuits at the outer gate and the planner falls through
//      to Join Empire (still per-province valid here).
//   7. **Napoleon outer gate (treasury below cheapest regiment cost)
//      -> Join Empire wins:** the militaristic ordering does not
//      bypass declareWar's outer treasury guard. With treasury below
//      the cheapest regiment build cost the declareWar pass short-
//      circuits and Join Empire is still reachable (treasury covers
//      the smaller `joinEmpireCostForMinorOrTribe`).
//   8. **Napoleon per-province gate (already at war with the tribe)
//      -> Join Empire wins:** declareWar validator parity. Existing
//      atWar status with the candidate owner skips the declareWar
//      candidate; Join Empire still applies because it does not gate
//      on at-war status (the Friendly+ relation gate already rejects
//      hostile rows). Here we use a separate Friendly tribe to
//      preserve Join Empire validity.
//   9. **Determinism (Must-have #7):** identical inputs (including
//      personalityId) produce identical `ColonialAcquisitionTarget`s
//      across repeated calls.
//  10. **All militaristic personalities (`napoleon`, `isabella`,
//      `frederick`, `gustavus`) pick declareWar:** enumeration pin
//      against `personalityThresholds`; protects the SPEC list from
//      silently drifting when leader thresholds are retuned.
//
// All tests use synthetic Game/AIWorldSnapshot fixtures with one
// active GP (`gp1`), a candidate tribe (`tribe1`), an `OvertureState`
// at `OvertureStage.nap`, a Friendly relation, and a standing Home
// Army with one regiment. The fixture keeps OW state empty and the
// New World invadable list to a single tribe-owned province so the
// per-province priority decision is the only variable under test.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _tribe1 = 'tribe1';

const String _nwProv1 = 'newWorld|tribe1_a';

Army _homeArmyWithRegiments(String ownerId, int regimentCount) {
  return Army(
    id: 'home_army:$ownerId',
    ownerId: ownerId,
    regionId: 'oldWorld',
    stationedProvinceId: 'oldWorld|capital_$ownerId',
    isHomeArmy: true,
    regimentUnitIds: <String>[
      for (var i = 0; i < regimentCount; i++) 'reg_${ownerId}_$i',
    ],
  );
}

OvertureState _nap(String gpId, String targetId, {int sinceTurn = 100}) =>
    OvertureState(
      gpId: gpId,
      targetId: targetId,
      stage: OvertureStage.nap,
      sinceTurn: sinceTurn,
    );

DiplomacyRelation _friendly(String a, String b, {int score = 60}) =>
    DiplomacyRelation(
      factionId1: a,
      factionId2: b,
      score: score,
      level: RelationLevel.friendly,
    );

DiplomacyRelation _atWar(String a, String b, {int score = 10}) =>
    DiplomacyRelation(
      factionId1: a,
      factionId2: b,
      score: score,
      level: RelationLevel.hostile,
      state: RelationState.atWar,
    );

/// Canonical "both Join Empire and declareWar valid for tribe1"
/// fixture. Active GP holds one regiment, treasury (100 000) covers
/// both `joinEmpireCostForMinorOrTribe(tribe1)` and the cheapest
/// regiment build cost. A single tribe-owned NW invadable province
/// (`newWorld|tribe1_a`) keeps the per-province priority decision
/// the only variable under test.
Game _bothValidGame({
  int activePlayerTreasury = 100000,
  List<Army>? armies,
  List<DiplomacyRelation>? diplomacyRelations,
  List<OvertureState>? overtureStates,
  List<Province>? newWorldProvinces,
}) {
  final armiesResolved = armies ?? <Army>[_homeArmyWithRegiments(_gp1, 1)];
  final relationsResolved =
      diplomacyRelations ?? <DiplomacyRelation>[_friendly(_gp1, _tribe1)];
  final overturesResolved =
      overtureStates ?? <OvertureState>[_nap(_gp1, _tribe1)];
  final provincesResolved =
      newWorldProvinces ??
      const <Province>[
        Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
      ];
  return Game(
    id: 'g-2509-colonial-acquisition-personality',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 130, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: provincesResolved),
      armies: armiesResolved,
    ),
    players: [
      Player(
        id: _gp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: activePlayerTreasury,
      ),
      const Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
    tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
    overtureStates: overturesResolved,
    diplomacyRelations: relationsResolved,
  );
}

AIWorldSnapshot _bothValidSnapshot({
  List<String> invadableNw = const [_nwProv1],
  int treasury = 100000,
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: 10,
      provincesToVictory: 31,
    ),
    colonial: ColonialSummary(invadableNewWorldProvinceIdsSorted: invadableNw),
    economy: EconomySummary(treasury: treasury),
    relations: const {},
  );
}

void main() {
  group('planColonialAcquisition (personality bias — Must-have #4)', () {
    test('napoleon (warmonger) -> declareWar wins over Join Empire', () {
      final game = _bothValidGame();
      final snapshot = _bothValidSnapshot();
      expect(
        planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          personalityId: 'napoleon',
        ),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.declareWar,
        ),
        reason:
            'napoleon thresholds (warLikelihood=80, allianceTendency=25) '
            'satisfy warLikelihood > allianceTendency, so the declareWar '
            'pass runs before the Join Empire pass and returns the '
            'tribe target with method declareWar.',
      );
    });

    test('henry (alliance-leaning) -> Join Empire wins over declareWar', () {
      final game = _bothValidGame();
      final snapshot = _bothValidSnapshot();
      expect(
        planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          personalityId: 'henry',
        ),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'henry thresholds (warLikelihood=10, allianceTendency=75) do '
            'not satisfy warLikelihood > allianceTendency, so the legacy '
            'Join Empire-first ordering applies and returns the tribe '
            'target with method joinEmpire.',
      );
    });

    test(
      'napoleon vs henry on identical fixture -> top-ranked methods diverge',
      () {
        // AC pinned verbatim (issue #2509 § Phase planner unit tests
        // "COLONIAL personality divergence"). Same Game + AIWorldSnapshot
        // fed twice; only personalityId varies between calls; outputs
        // diverge by AcquisitionMethod alone (tribe id matches).
        final game = _bothValidGame();
        final snapshot = _bothValidSnapshot();
        final napoleonResult = planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          personalityId: 'napoleon',
        );
        final henryResult = planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          personalityId: 'henry',
        );
        expect(napoleonResult, isNotNull);
        expect(henryResult, isNotNull);
        expect(
          napoleonResult!.targetFactionId,
          henryResult!.targetFactionId,
          reason: 'Same fixture -> same tribe target on both calls.',
        );
        expect(
          napoleonResult.method,
          AcquisitionMethod.declareWar,
          reason: 'napoleon picks declareWar (war > alliance).',
        );
        expect(
          henryResult.method,
          AcquisitionMethod.joinEmpire,
          reason: 'henry picks joinEmpire (alliance > war).',
        );
        expect(
          napoleonResult.method,
          isNot(henryResult.method),
          reason: 'Must-have #4 requires the two leaders to diverge.',
        );
      },
    );

    test('default (no personalityId) keeps legacy Join Empire-first', () {
      final game = _bothValidGame();
      final snapshot = _bothValidSnapshot();
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'Backward-compatible: the optional personalityId defaults to '
            'null, which means no war preference and the planner keeps '
            'the legacy Join Empire-first ordering.',
      );
    });

    test('unknown personalityId -> neutral defaults -> Join Empire', () {
      // `getThresholdsForLeader` falls back to `defaultThresholds`
      // (all fields = 50) for unknown ids. warLikelihood (50) is not
      // strictly greater than allianceTendency (50), so the legacy
      // ordering applies.
      final game = _bothValidGame();
      final snapshot = _bothValidSnapshot();
      expect(
        planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          personalityId: 'totally_unknown_leader_id',
        ),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'Unknown personality -> neutral 50/50 thresholds -> strict > '
            'comparison is false -> Join Empire-first.',
      );
    });

    test('napoleon with zero regiments -> declareWar outer gate fails -> '
        'falls through to Join Empire', () {
      // Militaristic personality does not bypass the structural
      // outer gates. With no standing regiments the declareWar pass
      // short-circuits at the outer guard and Join Empire still
      // applies because nap + Friendly + treasury are intact.
      final game = _bothValidGame(armies: const <Army>[]);
      final snapshot = _bothValidSnapshot();
      expect(
        planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          personalityId: 'napoleon',
        ),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'declareWar outer gate (regiments >= 1) fails first; napoleon '
            'is not exempt from outer gates and falls through to Join '
            'Empire on the same fixture.',
      );
    });

    test(
      'napoleon already at war with the only Join-Empire tribe -> '
      'declareWar skips it (validator parity), Join Empire also rejected '
      '(Friendly+ gate) -> falls through to purchase_land/null per legacy',
      () {
        // At-war relation rejects both the declareWar candidate
        // (`relation.atWar == true`) and the Join Empire candidate
        // (`relation.score < Friendly`). With only one tribe and both
        // arms gated out, the planner returns null. The purpose of
        // this test is to confirm napoleon's militaristic ordering
        // does not invent a target where the validator gates are
        // failing.
        final game = _bothValidGame(
          diplomacyRelations: <DiplomacyRelation>[_atWar(_gp1, _tribe1)],
        );
        final snapshot = _bothValidSnapshot();
        expect(
          planColonialAcquisition(
            game: game,
            snapshot: snapshot,
            personalityId: 'napoleon',
          ),
          isNull,
          reason:
              'Both Join Empire (relation < Friendly) and declareWar '
              '(relation.atWar == true) reject the only candidate; '
              'militaristic ordering cannot fabricate a target.',
        );
      },
    );

    test(
      'determinism (Must-have #7) -> identical inputs, identical outputs',
      () {
        final game = _bothValidGame();
        final snapshot = _bothValidSnapshot();
        final first = planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          personalityId: 'napoleon',
        );
        final second = planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          personalityId: 'napoleon',
        );
        expect(
          first,
          isNotNull,
          reason:
              'Determinism test must run on a '
              'satisfying input.',
        );
        expect(
          second,
          first,
          reason:
              'planColonialAcquisition is a pure function — identical '
              '(game, snapshot, personalityId) inputs must yield identical '
              'ColonialAcquisitionTargets across repeated calls.',
        );
      },
    );

    test('all militaristic personalities (warLikelihood > allianceTendency) '
        'pick declareWar; alliance-leaning ones pick joinEmpire', () {
      // Enumeration pin against personalityThresholds. Today
      // napoleon / isabella / frederick / gustavus have
      // warLikelihood > allianceTendency; victoria / henry /
      // deruyter do not. The SPEC list in
      // SPEC/ai/phase-planner-architecture.md § Personality bias
      // tracks this enumeration. If a future rebalance inverts a
      // threshold this test surfaces the drift before it silently
      // changes acquisition behavior.
      final game = _bothValidGame();
      final snapshot = _bothValidSnapshot();
      const expected = <String, AcquisitionMethod>{
        'napoleon': AcquisitionMethod.declareWar,
        'isabella': AcquisitionMethod.declareWar,
        'frederick': AcquisitionMethod.declareWar,
        'gustavus': AcquisitionMethod.declareWar,
        'victoria': AcquisitionMethod.joinEmpire,
        'henry': AcquisitionMethod.joinEmpire,
        'deruyter': AcquisitionMethod.joinEmpire,
      };
      for (final entry in expected.entries) {
        final result = planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          personalityId: entry.key,
        );
        expect(result, isNotNull, reason: 'No result for ${entry.key}.');
        expect(
          result!.method,
          entry.value,
          reason:
              '${entry.key} should pick ${entry.value} '
              '(personalityThresholds entry: warLikelihood vs '
              'allianceTendency). If this fails after a threshold '
              'rebalance, update SPEC/ai/phase-planner-architecture.md '
              '§ Personality bias enumeration.',
        );
      }
    });
  });
}
