// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

// Supply / retention / offer-side regiment build-input cases (Refs #3941).
//
// Transcribed 1:1 from the former `treasury_planner_regiment_input_{market_
// supply,retention,feedstock}_test.dart` shards.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_regiment_input_support.dart';



void registerTreasuryRegimentInputFeedstockCasesPartA() {
  group('lock-recovery seller build-input feedstock reservation (Refs #2847 H8-supply)',
      () {
    final threshold = regimentInputThreshold();
    final fabricInput =
        RegimentEconomyCatalog.peasantLevies.buildInputs[kRegimentInputFabricId];

    test('fabric is produced from wool/cotton (guards the fixture assumption)',
        () {
      expect(
        fabricInput,
        isNotNull,
        reason:
            'This slice assumes the cheapest regiment consumes fabric and that '
            'fabric is produced from a feedstock recipe.',
      );
      final fabricFeedstock = ProductionRecipesCatalog.all
          .where((r) => r.outputCommodityId == kRegimentInputFabricId)
          .expand((r) => r.inputQuantities.keys)
          .toSet();
      expect(
        fabricFeedstock,
        contains(kRegimentInputWoolId),
        reason: 'A fabric recipe must consume wool for this fixture to hold.',
      );
    });

    test(
      'recovered-treasury seller with zero fabric and zero regiments '
      'withholds its surplus wool from offers',
      () {
        final game = lockRecoverySellerRegimentInputGame(
          treasury: threshold,
          fabricHeld: 0,
        );
        expect(
          regimentInputOffersFor(
            runRegimentInputTreasuryPlanner(game),
            kRegimentInputWoolId,
          ),
          isEmpty,
          reason:
              'The feedstock for the missing fabric build input must be '
              'retained so it accumulates to a feasible production run rather '
              'than being sold as surplus.',
        );
      },
    );

    test(
      'still-broke zero-regiment seller withholds wool (treasury-independent '
      'staging, Refs #2847 H8 production allocation)',
      () {
        final game = lockRecoverySellerRegimentInputGame(
          treasury: threshold - 1,
          fabricHeld: 0,
        );
        expect(
          regimentInputOffersFor(
            runRegimentInputTreasuryPlanner(game),
            kRegimentInputWoolId,
          ),
          isEmpty,
          reason:
              'A broke zero-regiment lock-recovery seller stages feedstock: the '
              'wool is retained so it accumulates to a feasible fabric run.',
        );
      },
    );

    test('seller already holding the fabric input keeps offering wool', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: fabricInput!,
      );
      expect(
        regimentInputOffersFor(
          runRegimentInputTreasuryPlanner(game),
          kRegimentInputWoolId,
        ),
        isNotEmpty,
        reason:
            'Once the build input is on hand the reservation self-clears and '
            'the seller resumes offering its surplus feedstock.',
      );
    });

    test('seller that already holds a regiment keeps offering wool', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: 0,
        hasRegiment: true,
      );
      expect(
        regimentInputOffersFor(
          runRegimentInputTreasuryPlanner(game),
          kRegimentInputWoolId,
        ),
        isNotEmpty,
        reason: 'The reservation targets the zero-regiment rebuild gap only.',
      );
    });

    test('quota-met (non-seller) GP above threshold keeps offering wool', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: 0,
        owProvinces: 12,
      );
      expect(
        regimentInputOffersFor(
          runRegimentInputTreasuryPlanner(game),
          kRegimentInputWoolId,
        ),
        isNotEmpty,
      );
    });

    test('feedstock-reservation path is deterministic', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: 0,
      );
      expect(
        runRegimentInputTreasuryPlanner(game),
        equals(runRegimentInputTreasuryPlanner(game)),
      );
    });
  });
}
