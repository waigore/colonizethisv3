import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show isCastIronLabourPopulationBoundForLockRecoverySeller;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/lock_recovery_seller_test_support.dart';

void registerCastIronLabourGatePopulationBoundCases() {
  group('isCastIronLabourPopulationBoundForLockRecoverySeller (Refs #2847)', () {
    test(
      'positive: material-feasible castIron with fed workers below one run',
      () {
        final game = buildCastIronLabourLockRecoverySellerGame(
          workerPool: const WorkerPool(peasants: 1),
          stockpile: Stockpile.empty
              .applyDelta(CommodityCatalog.iron.id, 4)
              .applyDelta(CommodityCatalog.grain.id, 10),
        );
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: kCastIronLabourLockRecoverySellerId,
          ),
          isTrue,
        );
      },
    );

    test(
      'negative: enough peasants to run castIron when fully fed',
      () {
        final game = buildCastIronLabourLockRecoverySellerGame(
          workerPool: const WorkerPool(peasants: 2),
          stockpile: Stockpile.empty
              .applyDelta(CommodityCatalog.iron.id, 4)
              .applyDelta(CommodityCatalog.grain.id, 10),
        );
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: kCastIronLabourLockRecoverySellerId,
          ),
          isFalse,
        );
      },
    );

    test(
      'negative: healthy GP holding a regiment is out of scope',
      () {
        final game = Game(
          id: 'g-healthy',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p0',
                  regionId: kRegionOldWorld,
                  ownerId: kCastIronLabourLockRecoverySellerId,
                ),
              ],
              units: [
                Unit(
                  id: 'r1',
                  type: 'peasant_levies',
                  ownerId: kCastIronLabourLockRecoverySellerId,
                  locationProvinceId: 'oldWorld|p0',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: kCastIronLabourLockRecoverySellerId,
              displayName: 'Healthy',
              isHuman: false,
              workerPool: const WorkerPool(peasants: 1),
              stockpile: Stockpile.empty
                  .applyDelta(CommodityCatalog.iron.id, 4),
            ),
          ],
        );
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: kCastIronLabourLockRecoverySellerId,
          ),
          isFalse,
        );
      },
    );
  });
}
