// Case bodies for colonial_phase_planner_acquisition_purchase_land_test
// (Refs #3997 Phase 8). Purchase_land arm pins (Refs #2509 S3).

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
const String _nwTile1Alt = kColonialAcquisitionNwTile1Alt;
const String _nwTile2 = kColonialAcquisitionNwTile2;

void registerColonialAcquisitionPurchaseLandHappyPathCases() {
  group('planColonialAcquisition (purchase_land path)', () {
    test(
      'embassy + valid grain tile + idle Merchant -> purchase_land target',
      () {
        // Canonical happy path with a non-mineral resource (`grain`)
        // so the prospect gate is structurally satisfied. The
        // active player has an embassy-stage overture, peace
        // relations, treasury well above purchaseLandCost, an idle
        // Merchant, and exactly one resource tile in the candidate
        // province. Acceptance criterion #2509 § "(COLONIAL
        // acquisition — purchase_land)": "Given a GP in COLONIAL
        // with idle Merchant, treasury ≥ purchase cost, and a
        // visible newWorld| province with a valid purchase_land
        // target tile, when planColonialAcquisition runs and Join
        // Empire is unavailable, then the return value is
        // (tribeFactionId, AcquisitionMethod.purchaseLand)."
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
        // Same happy path but with an `iron` (mineral) resource. The
        // tile is in the active player's prospected set so the
        // mineral-gate is satisfied; the planner returns the
        // canonical purchase_land target.
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

    test(
      'Join Empire and purchase_land both reachable -> Join Empire wins',
      () {
        // Same `tribe1` is reachable via both paths: overture at
        // `nap` (Join Empire eligible), Friendly+ relation, treasury
        // covering joinEmpire cost AND purchaseLand cost, valid tile
        // and idle Merchant in scope. The Method 1 pass must win;
        // the planner should never even reach the second pass.
        final game = buildColonialAcquisitionGame(
          gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
          newWorldProvinces: const [
            Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          ],
          newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
          resourceByTileKey: const {_nwTile1: 'grain'},
          overtureStates: <OvertureState>[
            colonialAcquisitionNap(_gp1, _tribe1),
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
            method: AcquisitionMethod.joinEmpire,
          ),
          reason:
              'Join Empire is "the cheapest, fastest path — always '
              'preferred first" per the spec; when Method 1 is '
              'reachable the second pass is suppressed.',
        );
      },
    );

    test('Join Empire treasury shortfall + purchase_land treasury OK -> '
        'purchase_land target', () {
      // Active player has Join-Empire-eligible overture / relation
      // state for `tribe1`, but treasury is below
      // joinEmpireBaseCost (5000) + 1 * joinEmpirePerProvinceCost
      // (2000) = 7000. Treasury is still well above
      // purchaseLandCost('grain') (150), so the second pass
      // accepts. Pins that:
      //   - the second pass actually runs after Method 1 fails;
      //   - the Method 2 gates differ from Method 1's (e.g. no
      //     `nap` requirement; embassy is enough).
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        activePlayerTreasury: 1000,
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        overtureStates: <OvertureState>[colonialAcquisitionNap(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
        treasury: 1000,
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.purchaseLand,
        ),
        reason:
            'Method 1 fails the joinEmpire treasury gate (1000 < '
            '7000); Method 2 accepts because purchaseLandCost("grain") '
            '(150) is well within treasury and the embassy gate is '
            'satisfied by stage `nap` (hasEmbassy = true).',
      );
    });

    test('two valid tribe targets -> first sorted invadable NW wins', () {
      // Both tribe1 and tribe2 satisfy every purchase_land gate
      // (embassy, peace, valid grain tile, no purchasedTiles
      // collision). The planner picks the tribe whose NW province
      // appears first in `invadableNewWorldProvinceIdsSorted`
      // (ascending). With `_nwProv1 = newWorld|tribe1_a` <
      // `_nwProv2 = newWorld|tribe2_b` the iteration hits tribe1
      // first.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
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
          colonialAcquisitionFriendly(_gp1, _tribe1),
          colonialAcquisitionFriendly(_gp1, _tribe2),
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
            'Iteration over `invadableNewWorldProvinceIdsSorted` is '
            'ascending; the first satisfying province (tribe1) wins '
            'the deterministic tie-break (Refs #2509 Must-have #7).',
      );
    });

    test('determinism: identical inputs produce identical targets', () {
      // Must-have #7 pin: repeated calls on the same game / snapshot
      // must return byte-identical results. Mixed fixture exercises
      // the at-war filter (tribe2 atWar), the embassy gate (tribe1
      // embassy), the alt-tile selection (`_nwTile1Alt` carrying
      // `grain` while `_nwTile1` lacks any resource entry), and the
      // sorted iteration over invadable NW provinces.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-purchase-land',
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _nwProv2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        newWorldUnits: <Unit>[colonialAcquisitionMerchant('m1')],
        resourceByTileKey: const {_nwTile1Alt: 'grain', _nwTile2: 'grain'},
        overtureStates: <OvertureState>[
          colonialAcquisitionEmbassy(_gp1, _tribe1),
          colonialAcquisitionEmbassy(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1),
          colonialAcquisitionAtWar(_gp1, _tribe2),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1, _nwProv2],
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
        reason:
            'Determinism test must run on a satisfying input. tribe1 '
            'wins because tribe2 is at war (excluded) and tribe1 has '
            'a valid grain tile in `_nwTile1Alt`.',
      );
    });
  });
}
