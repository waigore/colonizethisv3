// Case bodies for colonial_phase_planner_acquisition_purchase_land_test
// (Refs #3997 Phase 8). Purchase_land arm pins (Refs #2509 S3).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_acquisition_test_support.dart';
import 'colonial_phase_planner_acquisition_purchase_land_guard_cases_tail_cases.dart';

const String _gp1 = kColonialPhaseGp1;
const String _gp2 = kColonialPhaseGp2;
const String _tribe1 = kColonialPhaseTribe1;

const String _nwProv1 = kColonialAcquisitionNwProv1;
const String _nwProvGp = kColonialAcquisitionNwProvGp;

const String _nwTile1 = kColonialAcquisitionNwTile1;

void registerColonialAcquisitionPurchaseLandGuardCases() {
  group('planColonialAcquisition (purchase_land path)', () {
    test('no idle Merchant -> null (outer guard)', () {
      // The Join-Empire pass returns null because the overture is at
      // `embassy` (not `nap`). The purchase_land pass would otherwise
      // accept the tribe1 fixture, but the active player has zero
      // Merchant units -> outer guard short-circuits the second
      // loop. A regression that suggested `purchase_land` here would
      // emit an order with no eligible Merchant to execute it.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        resourceByTileKey: const {_nwTile1: 'grain'},
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
        isNull,
        reason:
            'Outer Merchant guard must short-circuit before the per-'
            'province loop fires; otherwise a regression could emit a '
            'purchase_land target with no Merchant to execute it.',
      );
    });

    test('working Merchant does not satisfy outer guard -> null', () {
      // A Merchant exists but is mid-work (`status == working`).
      // [UnitStatus.idle] is required so the resolver can re-task
      // the unit; mirror the Builder-idle filter pinned in
      // `planColonialCivilian`.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[
          colonialAcquisitionMerchant('m_busy', status: UnitStatus.working),
        ],
        resourceByTileKey: const {_nwTile1: 'grain'},
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
        isNull,
        reason:
            'Working Merchants are not assignable to a new purchase_'
            'land directive; the planner must short-circuit when no '
            'idle Merchant exists.',
      );
    });

    test('GP-owned NW province -> skip (no purchase from GP)', () {
      // Validator: "purchase_land target must be a Minor or Tribe
      // province". The planner enforces this structurally via
      // `game.playerById(ownerId) != null` -> skip; mirrors the
      // Join-Empire arm's GP-skip pin.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        newWorldProvinces: const [
          Province(id: _nwProvGp, regionId: 'newWorld', ownerId: _gp2),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {'newWorld|gp2_c|1|1': 'grain'},
        overtureStates: <OvertureState>[colonialAcquisitionEmbassy(_gp1, _gp2)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _gp2),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProvGp],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Validator rejects purchase_land when the owner is another '
            'GP; the planner skips GP-owned NW provinces structurally '
            'so the purchase_land arm is never emitted toward a GP.',
      );
    });

    test('at-war tribe -> skip', () {
      // Validator: "Cannot purchase land: at war with that faction".
      // Even with embassy + valid tile + idle Merchant, the at-war
      // gate must reject the candidate.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        overtureStates: <OvertureState>[
          colonialAcquisitionEmbassy(_gp1, _tribe1),
        ],
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
            'At-war relation rejects purchase_land via the validator; '
            'the planner mirrors that gate.',
      );
    });

    test('no overture -> skip', () {
      // Validator: "Cannot purchase land: embassy required ...". With
      // no `OvertureState(gpId, targetId)` row, `getOverture` returns
      // null -> embassy gate fails.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Missing overture state -> validator rejects with embassy '
            'requirement; planner mirrors the gate.',
      );
    });

  });

  registerColonialAcquisitionPurchaseLandGuardCasesTail();
}
