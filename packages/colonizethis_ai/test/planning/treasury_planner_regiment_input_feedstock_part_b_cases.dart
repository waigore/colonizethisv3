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



void registerTreasuryRegimentInputFeedstockCasesPartB() {
  group('lock-recovery seller build-input feedstock reservation (Refs #2847 H8-supply)',
      () {
    final threshold = regimentInputThreshold();
    final fabricInput =
        RegimentEconomyCatalog.peasantLevies.buildInputs[kRegimentInputFabricId];

      test('fixture is population-bound with fabric below recruit cost', () {
        final game = populationBoundSellerGame(fabricHeld: 1);
        expect(
          isCastIronLabourPopulationBoundForLockRecoverySeller(
            game: game,
            playerId: kRegimentInputSingleGpId,
          ),
          isTrue,
        );
        expect(
          RegimentEconomyCatalog.peasantLevies.buildInputs[kRegimentInputFabricId],
          1,
          reason: 'regiment build input met at fabric=1',
        );
        expect(peasantFabricCost, greaterThan(1));
      });

      test(
        'withholds wool when fabric meets regiment cost but not peasant recruit',
        () {
          final game = populationBoundSellerGame(fabricHeld: 1);
          expect(
            regimentInputOffersFor(
              runRegimentInputTreasuryPlanner(game),
              kRegimentInputWoolId,
            ),
            isEmpty,
            reason:
                'One fabric satisfies the regiment build input but not the '
                '2-fabric peasant recruit; wool must stay reserved for the '
                'second domestic fabric run.',
          );
        },
      );

      test(
        'resumes offering wool once fabric meets peasant recruit cost of 2',
        () {
          final game = populationBoundSellerGame(fabricHeld: 2);
          expect(
            regimentInputOffersFor(
              runRegimentInputTreasuryPlanner(game),
              kRegimentInputWoolId,
            ),
            isNotEmpty,
            reason:
                'Peasant-recruit fabric staging self-clears at fabric >= 2.',
          );
        },
      );

      test(
        'emits a fabric bid for the remaining unit when fabric meets regiment '
        'cost but not peasant recruit',
        () {
          final game = populationBoundSellerGame(fabricHeld: 1, woolHeld: 20);
          final fabricBids = runRegimentInputTreasuryPlanner(game)
              .where(
                (o) =>
                    o.type == TradeOrderType.bid &&
                    o.commodityId == kRegimentInputFabricId,
              )
              .toList();
          expect(
            fabricBids,
            isNotEmpty,
            reason:
                'One fabric satisfies the regiment build input but not the '
                '2-fabric peasant recruit; the bootstrap must bid for the '
                'remaining unit.',
          );
          expect(
            fabricBids.first.quantity,
            greaterThanOrEqualTo(1),
          );
        },
      );

      test(
        'emits a fabric bid sized to the peasant recruit cost when fabric is '
        'zero and feedstock is on hand',
        () {
          final game = populationBoundSellerGame(fabricHeld: 0, woolHeld: 20);
          final fabricBids = runRegimentInputTreasuryPlanner(game)
              .where(
                (o) =>
                    o.type == TradeOrderType.bid &&
                    o.commodityId == kRegimentInputFabricId,
              )
              .toList();
          expect(
            fabricBids,
            isNotEmpty,
            reason:
                'Population-bound peasant-recruit staging must bid for fabric '
                'once feedstock is on hand.',
          );
          expect(
            fabricBids.first.quantity,
            greaterThanOrEqualTo(peasantFabricCost),
          );
        },
      );

      test(
        'emits no fabric bid once peasant recruit fabric cost is met',
        () {
          final game = populationBoundSellerGame(fabricHeld: 2, woolHeld: 20);
          final fabricBids = runRegimentInputTreasuryPlanner(game)
              .where(
                (o) =>
                    o.type == TradeOrderType.bid &&
                    o.commodityId == kRegimentInputFabricId,
              )
              .toList();
          expect(fabricBids, isEmpty);
        },
      );

      test(
        'labour-infeasible domestic fabric bids fabric directly, not wool '
        'feedstock',
        () {
          final game = populationBoundSellerGame(
            fabricHeld: 0,
            woolHeld: 20,
          ).copyWith(
            players: [
              populationBoundSellerGame(fabricHeld: 0, woolHeld: 20)
                  .players
                  .first
                  .copyWith(workerPool: const WorkerPool(peasants: 1)),
            ],
          );
          expect(
            isDomesticFabricProductionLabourInfeasible(
              game: game,
              playerId: kRegimentInputSingleGpId,
            ),
            isTrue,
          );
          final bids = runRegimentInputTreasuryPlanner(game)
              .where((o) => o.type == TradeOrderType.bid)
              .toList();
          expect(
            bids.where((o) => o.commodityId == kRegimentInputWoolId),
            isEmpty,
            reason: 'Feedstock bids cannot unblock labour-walled fabric runs.',
          );
          expect(
            bids.where((o) => o.commodityId == kRegimentInputFabricId),
            isNotEmpty,
          );
        },
      );

      test(
        'population-bound seller with a regiment still emits a fabric bid when '
        'domestic fabric is labour-infeasible',
        () {
          final base = populationBoundSellerGame(fabricHeld: 1, woolHeld: 20);
          final game = base.copyWith(
            worldState: base.worldState.copyWith(
              armies: [
                const Army(
                  id: 'army-seller',
                  ownerId: kRegimentInputSingleGpId,
                  regionId: kRegionOldWorld,
                  stationedProvinceId: 'oldWorld|p0',
                  regimentUnitIds: ['reg-1'],
                ),
              ],
            ),
            players: [
              base.players.first.copyWith(
                workerPool: const WorkerPool(peasants: 1),
              ),
            ],
          );
          final fabricBids = runRegimentInputTreasuryPlanner(game)
              .where(
                (o) =>
                    o.type == TradeOrderType.bid &&
                    o.commodityId == kRegimentInputFabricId,
              )
              .toList();
          expect(fabricBids, isNotEmpty);
        },
      );
    },
  );
  });
}
