// Method-precedence and tie-break pins for purchase_land acquisition (Refs #4669).

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

void registerColonialAcquisitionPurchaseLandPrecedenceCases() {
  group('planColonialAcquisition (purchase_land path)', () {
    test(
      'Join Empire and purchase_land both reachable -> Join Empire wins',
      () {
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
