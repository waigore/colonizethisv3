// Case bodies for colonial_phase_planner_acquisition_purchase_land_test
// (Refs #3997 Phase 8). Purchase_land happy-path pins (Refs #2509 S3).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_acquisition_test_support.dart';

const String _gp1 = kColonialPhaseGp1;
const String _tribe1 = kColonialPhaseTribe1;

const String _nwProv1 = kColonialAcquisitionNwProv1;

const String _nwTile1 = kColonialAcquisitionNwTile1;

void registerColonialAcquisitionPurchaseLandHappyPathCases() {
  group('planColonialAcquisition (purchase_land path)', () {
    test(
      'embassy + valid grain tile + idle Merchant -> purchase_land target',
      () {
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
              'All purchase_land gates pass (embassy stage, peace, '
              'idle Merchant, grain tile not minerally gated, '
              'treasury covers cost) -> planner returns the canonical '
              '(tribe1, purchaseLand) target. Join Empire is '
              'unavailable here because the overture is at `embassy` '
              'not `nap`.',
        );
      },
    );

    test(
      'embassy + prospected mineral tile + idle Merchant -> purchase_land target',
      () {
        final game = buildColonialAcquisitionGame(
          gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
          newWorldProvinces: const [
            Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          ],
          newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
          resourceByTileKey: const {_nwTile1: 'iron'},
          prospectedTilesForGp1: const {_nwTile1},
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
              'Mineral resource (`iron`) gated on prospected-tile '
              'membership; with the tile in playerProspectedTiles, '
              'the planner accepts and returns (tribe1, '
              'purchaseLand).',
        );
      },
    );
  });
}
