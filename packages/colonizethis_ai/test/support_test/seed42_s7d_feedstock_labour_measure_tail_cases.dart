import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/seed42_s7d_feedstock_helpers.dart';
import '../support/seed42_s7d_feedstock_helpers_test_support.dart';

void registerSeed42S7dFeedstockLabourMeasureTailCases() {
  group('castIronFeedstockExtractionLabourFutile', () {
    // castIron's labourPerOutput is 5; a lock-recovery seller's raw labour
    // ceiling sits at 1-2 on seed 42, so the helper localizes the
    // castIron-feedstock order-matching gap off the critical path.
    const castIronMinLabour = 5;

    test(
      'positive: raw labour ceiling below the castIron labourPerOutput is '
      'futile (a filled feedstock bid still cannot run the recipe)',
      () {
        // 2 peasants -> raw ceiling 2 < 5, regardless of food on hand: even a
        // fully-fed seller cannot fund one castIron run.
        final game = buildSeed42S7dFeedstockHelperGame(workers: const WorkerPool(peasants: 2));
        expect(playerRawLabourSupply(game, kSeed42S7dFeedstockHelperPlayerId), 2);
        expect(
          castIronFeedstockExtractionLabourFutile(
            game,
            kSeed42S7dFeedstockHelperPlayerId,
            castIronMinLabour,
          ),
          isTrue,
        );
      },
    );

    test(
      'negative: raw labour ceiling at or above the castIron labourPerOutput is '
      'not futile (the feedstock bid would matter)',
      () {
        // 1 journeyman -> raw ceiling 6 >= 5: a filled timber/iron bid could
        // yield a labour-feasible castIron run, so feedstock supply is on-path.
        final game = buildSeed42S7dFeedstockHelperGame(workers: const WorkerPool(journeymen: 1));
        expect(playerRawLabourSupply(game, kSeed42S7dFeedstockHelperPlayerId), 6);
        expect(
          castIronFeedstockExtractionLabourFutile(
            game,
            kSeed42S7dFeedstockHelperPlayerId,
            castIronMinLabour,
          ),
          isFalse,
        );
      },
    );

    test('boundary: raw ceiling exactly equal to labourPerOutput is not futile', () {
      // 5 peasants -> raw ceiling 5 == 5: one run is exactly fundable.
      final game = buildSeed42S7dFeedstockHelperGame(workers: const WorkerPool(peasants: 5));
      expect(playerRawLabourSupply(game, kSeed42S7dFeedstockHelperPlayerId), 5);
      expect(
        castIronFeedstockExtractionLabourFutile(
          game,
          kSeed42S7dFeedstockHelperPlayerId,
          castIronMinLabour,
        ),
        isFalse,
      );
    });

    test('negative: a non-positive min labourPerOutput is never futile', () {
      // No castIron recipe (min == 0) means the labour ceiling is trivially
      // sufficient; the helper must not report futility.
      final game = buildSeed42S7dFeedstockHelperGame(workers: const WorkerPool());
      expect(
        castIronFeedstockExtractionLabourFutile(game, kSeed42S7dFeedstockHelperPlayerId, 0),
        isFalse,
      );
    });

    test(
      'unknown player: zero raw labour is below the positive threshold => '
      'futile',
      () {
        final game = buildSeed42S7dFeedstockHelperGame(workers: const WorkerPool(peasants: 10));
        expect(
          castIronFeedstockExtractionLabourFutile(
            game,
            'no_such_player',
            castIronMinLabour,
          ),
          isTrue,
        );
      },
    );
  });
}
