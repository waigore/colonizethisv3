// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

// Supply / retention / offer-side regiment build-input cases (Refs #3941).
//
// Transcribed 1:1 from the former `treasury_planner_regiment_input_{market_
// supply,retention,feedstock}_test.dart` shards.

import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show
        isCastIronLabourPopulationBoundForLockRecoverySeller,
        isDomesticFabricProductionLabourInfeasible;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_planner_regiment_input_support.dart';



void registerTreasuryRegimentInputRetentionCases() {
  group(
      'lock-recovery seller produced build-input retention '
      '(Refs #2847 H8-extraction)', () {
    final threshold = regimentInputThreshold();
    const surplusFabric = 60;

    test('fabric is a peasant_levies build input (guards the fixture)', () {
      expect(
        RegimentEconomyCatalog.peasantLevies.buildInputs
            .containsKey(kRegimentInputFabricId),
        isTrue,
        reason:
            'This slice assumes the cheapest regiment consumes fabric, which '
            'the lock-recovery seller produces domestically.',
      );
    });

    test(
      'recovered-treasury seller with zero regiments withholds its surplus '
      'fabric from offers',
      () {
        final game = lockRecoverySellerRegimentInputGame(
          treasury: threshold,
          fabricHeld: surplusFabric,
        );
        expect(
          regimentInputOffersFor(
            runRegimentInputTreasuryPlanner(game),
            kRegimentInputFabricId,
          ),
          isEmpty,
          reason:
              'The domestically produced build input must be retained so it '
              'accumulates to the peasant_levies build cost rather than being '
              'sold back into the world market as surplus.',
        );
      },
    );

    test(
      'still-broke zero-regiment seller withholds fabric (treasury-independent '
      'staging, Refs #2847 H8 production allocation)',
      () {
        final game = lockRecoverySellerRegimentInputGame(
          treasury: threshold - 1,
          fabricHeld: surplusFabric,
        );
        expect(
          regimentInputOffersFor(
            runRegimentInputTreasuryPlanner(game),
            kRegimentInputFabricId,
          ),
          isEmpty,
          reason:
              'A broke zero-regiment lock-recovery seller stages the build '
              'input: the produced fabric is retained, not sold, so it banks '
              'toward the regiment build cost.',
        );
      },
    );

    test('seller that already holds a regiment keeps offering fabric', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: surplusFabric,
        hasRegiment: true,
      );
      expect(
        regimentInputOffersFor(
          runRegimentInputTreasuryPlanner(game),
          kRegimentInputFabricId,
        ),
        isNotEmpty,
        reason: 'The retention targets the zero-regiment rebuild gap only.',
      );
    });

    test('quota-met (non-seller) GP above threshold keeps offering fabric', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: surplusFabric,
        owProvinces: 12,
      );
      expect(
        regimentInputOffersFor(
          runRegimentInputTreasuryPlanner(game),
          kRegimentInputFabricId,
        ),
        isNotEmpty,
        reason: 'The retention is scoped to below-quota zero-NW sellers.',
      );
    });

    test('build-input retention path is deterministic', () {
      final game = lockRecoverySellerRegimentInputGame(
        treasury: threshold,
        fabricHeld: surplusFabric,
      );
      expect(
        runRegimentInputTreasuryPlanner(game),
        equals(runRegimentInputTreasuryPlanner(game)),
      );
    });
  });
}
