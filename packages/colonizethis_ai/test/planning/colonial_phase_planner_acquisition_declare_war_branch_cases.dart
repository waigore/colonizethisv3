// Case bodies for `colonial_phase_planner_acquisition_declare_war_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_acquisition_test_support.dart';
import 'ai_planner_fixtures.dart';
import 'colonial_phase_planner_acquisition_declare_war_support.dart';

const String _gp1 = colonialAcquisitionDeclareWarGp1;
const String _gp2 = colonialAcquisitionDeclareWarGp2;
const String _tribe1 = colonialAcquisitionDeclareWarTribe1;
const String _tribe2 = colonialAcquisitionDeclareWarTribe2;

const String _nwProv1 = colonialAcquisitionDeclareWarNwProv1;
const String _nwProv2 = colonialAcquisitionDeclareWarNwProv2;
const String _nwProvGp = colonialAcquisitionDeclareWarNwProvGp;

const String _nwTile1 = colonialAcquisitionDeclareWarNwTile1;

void registerColonialPhasePlannerAcquisitionDeclareWarCasesPartA() {
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

  });
}
