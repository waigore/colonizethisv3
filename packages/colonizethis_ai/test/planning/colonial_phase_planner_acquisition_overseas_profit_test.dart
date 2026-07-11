// Unit tests for the overseas-profit-aware target selection in the
// `purchase_land` arm of `planColonialAcquisition`
// (`packages/colonizethis_ai/lib/src/planning/colonial_phase_planner_acquisition.dart`,
// Refs #3758 R7 / S6).
//
// Spec contract (SPEC/ai/phase-planner-architecture.md § Overseas-
// profit-aware purchase-land target selection; SPEC/game/world-market.md
// § Overseas profit): buying land on a tribe/minor tile earns the buyer
// an ongoing overseas profit share `(relationScore / 100) × 0.40`, so a
// higher-relation owner yields a strictly larger share. The
// `purchase_land` arm therefore selects the eligible owner with the
// HIGHEST relation score rather than the first owner in adjacency-
// distance iteration order. Equal relation scores fall back to the
// legacy first-in-iteration-order tiebreak.
//
// These tests build two tribes that BOTH satisfy every `purchase_land`
// gate (idle Merchant, embassy overture, peace, valid grain tile) and
// vary only the relation score and the iteration order, isolating the
// new selection lever from the unchanged gate logic.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_acquisition_test_support.dart';

const String _gp1 = kColonialPhaseGp1;
const String _tribe1 = kColonialPhaseTribe1;
const String _tribe2 = kColonialPhaseTribe2;

const String _nwProv1 = kColonialAcquisitionNwProv1;
const String _nwProv2 = kColonialAcquisitionNwProv2;

const String _nwTile1 = kColonialAcquisitionNwTile1;
const String _nwTile2 = kColonialAcquisitionNwTile2;

void main() {
  group('planColonialAcquisition purchase_land overseas-profit selection '
      '(Refs #3758 S6)', () {
    test('higher-relation owner is preferred over a closer lower-relation '
        'owner', () {
      // Both tribes satisfy every purchase_land gate. tribe2 sorts FIRST
      // (its province leads the invadable list) but has a low relation
      // (40.0); tribe1 sorts second but has a high relation (90.0).
      // Overseas profit scales with relation, so the planner must pick
      // tribe1 even though tribe2 is encountered first.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-3758-overseas-profit',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _nwProv2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain', _nwTile2: 'grain'},
        overtureStates: <OvertureState>[
          colonialAcquisitionEmbassy(_gp1, _tribe1),
          colonialAcquisitionEmbassy(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1, score: 90.0),
          colonialAcquisitionFriendly(_gp1, _tribe2, score: 40.0),
        ],
      );
      // tribe2 first in iteration order, tribe1 second.
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv2, _nwProv1],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.purchaseLand,
        ),
        reason:
            'tribe1 (relation 90.0) yields a larger overseas profit share '
            'than tribe2 (relation 40.0), so the purchase_land arm prefers '
            'tribe1 even though tribe2 is iterated first.',
      );
    });

    test('equal relation scores fall back to the first-in-iteration-order '
        'owner', () {
      // Both tribes satisfy every gate with EQUAL relation (60.0). The
      // overseas-profit tiebreak is a strict `>` so the earliest-iterated
      // owner wins, preserving the legacy first-match selection. tribe1's
      // province leads the invadable list.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-3758-overseas-profit',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _nwProv2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain', _nwTile2: 'grain'},
        overtureStates: <OvertureState>[
          colonialAcquisitionEmbassy(_gp1, _tribe1),
          colonialAcquisitionEmbassy(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1, score: 60.0),
          colonialAcquisitionFriendly(_gp1, _tribe2, score: 60.0),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1, _nwProv2],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.purchaseLand,
        ),
        reason:
            'Equal relation scores (60.0 vs 60.0) fall back to the legacy '
            'first-in-iteration-order tiebreak; tribe1 leads the invadable '
            'list so it wins.',
      );
    });

    test('determinism: identical inputs produce identical targets', () {
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-3758-overseas-profit',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _nwProv2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain', _nwTile2: 'grain'},
        overtureStates: <OvertureState>[
          colonialAcquisitionEmbassy(_gp1, _tribe1),
          colonialAcquisitionEmbassy(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1, score: 90.0),
          colonialAcquisitionFriendly(_gp1, _tribe2, score: 40.0),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv2, _nwProv1],
      );
      final first = planColonialAcquisition(game: game, snapshot: snapshot);
      final second = planColonialAcquisition(game: game, snapshot: snapshot);
      expect(second, first);
      expect(
        first,
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.purchaseLand,
        ),
      );
    });
  });
}
