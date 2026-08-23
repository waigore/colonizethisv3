// Case bodies for colonial_phase_planner_acquisition_purchase_land_test
// (Refs #3997 Phase 8). Purchase_land arm pins (Refs #2509 S3).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_acquisition_test_support.dart';

const String _gp1 = kColonialPhaseGp1;
const String _gp2 = kColonialPhaseGp2;
const String _tribe1 = kColonialPhaseTribe1;

const String _nwProv1 = kColonialAcquisitionNwProv1;
const String _nwProvGp = kColonialAcquisitionNwProvGp;

const String _nwTile1 = kColonialAcquisitionNwTile1;

void registerColonialAcquisitionPurchaseLandGuardCasesTail() {
  group('planColonialAcquisition (purchase_land path)', () {
    test('overture at tradeConsulate (no embassy) -> skip', () {
      // `OvertureState.hasEmbassy` is true only for stages in
      // `{embassy, nap, joinEmpire}`. The `tradeConsulate` stage
      // sits one rung below `embassy` and must be rejected by the
      // planner just as it is by the validator.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        overtureStates: <OvertureState>[
          colonialAcquisitionTradeConsulate(_gp1, _tribe1),
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
            'Stage `tradeConsulate` -> hasEmbassy = false; validator '
            'and planner both reject. Pins that early-stage overtures '
            'do not unlock the purchase_land path.',
      );
    });

    test('tile has no resource entry -> skip', () {
      // Validator: "Tile has no resource". Without at least one tile
      // in the province carrying a non-empty resource id, the
      // planner cannot find a satisfying `purchase_land` candidate.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const <String, String>{},
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
            'No resource tiles in the province -> no valid '
            'purchase_land target; validator rejects with "Tile has '
            'no resource"; planner mirrors that gate.',
      );
    });

    test('mineral tile not prospected -> skip', () {
      // Validator: "Mineral tile must be prospected first". The
      // planner mirrors the gate using the active player's
      // `WorldState.playerProspectedTiles` entry. With no entry for
      // gp1, the iron tile fails the gate.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {_nwTile1: 'iron'},
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
            'Mineral tile (`iron`) not in active player\'s prospected '
            'set -> validator rejects; planner mirrors the gate so a '
            'purchase_land target is never emitted toward an '
            'unprospected mineral tile.',
      );
    });

    test('treasury below purchaseLandCost -> skip', () {
      // Validator: "Insufficient treasury for purchase_land (need
      // $cost)". `purchaseLandCost('grain') = 15 *
      // landPurchaseDefaultBasePrice (10) = 150`; treasury 149 fails
      // the gate.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        activePlayerTreasury: 149,
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
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
        treasury: 149,
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Treasury (149) below purchaseLandCost("grain") (150) -> '
            'validator rejects; planner mirrors the gate.',
      );
    });

    test('tile already purchased -> skip', () {
      // Validator: "Tile already purchased by another power" or "You
      // already own this tile". A tile present in
      // `WorldState.purchasedTilesByTileKey` is locked out of
      // additional `purchase_land` orders regardless of buyer
      // identity.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        purchasedTiles: const {_nwTile1: _gp2},
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
            'Tile in purchasedTilesByTileKey is unavailable for new '
            'purchase_land orders; planner skips and finds no other '
            'satisfying tile in the province.',
      );
    });

  });
}
