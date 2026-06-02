// Test: `Game.worldMarketState` is seeded at game setup with default integer
// prices for every tradeable commodity (Refs #3093 § Price presentation &
// data model, `SPEC/game/world-market.md` § Initial price seeding).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Initial worldMarketState seeding (Refs #3093)', () {
    test(
      'prices map seeds every tradeable commodity with integer catalog default',
      () {
        final result = runInitGame(
          config: GameSetupConfig.defaultConfig,
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );

        final prices = result.game.worldMarketState.prices;

        final expectedIds = <CommodityId>[
          for (final c in CommodityCatalog.all)
            if (c.category != CommodityCategory.riches && c.id != 'spices')
              c.id,
        ];
        expect(
          expectedIds.length,
          22,
          reason:
              'SPEC/game/world-market.md § Tradeable commodities pins '
              '22 tradeable ids on the live catalog.',
        );

        for (final id in expectedIds) {
          expect(
            prices.containsKey(id),
            isTrue,
            reason:
                'Tradeable commodity "$id" must have a seeded price entry '
                'on a new game (SPEC § Initial price seeding).',
          );
          final value = prices[id];
          expect(
            value,
            isA<int>(),
            reason: 'price entry for "$id" must be an integer',
          );
          expect(
            value,
            isNotNull,
          );
          expect(
            value! >= 0,
            isTrue,
            reason: 'price entry for "$id" must be non-negative',
          );
          final catalogDefault = ResourceRules.defaultRules
              .defaultMarketPriceForCommodityId(id);
          expect(
            value,
            catalogDefault,
            reason:
                'price entry for "$id" must equal the catalog default '
                '(`ResourceRules.defaultMarketPriceForCommodityId`).',
          );
        }

        expect(prices.length, expectedIds.length);
      },
    );

    test(
      'prices map contains no riches or spices entries (non-tradeable filter)',
      () {
        final result = runInitGame(
          config: GameSetupConfig.defaultConfig,
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );

        final prices = result.game.worldMarketState.prices;
        for (final id in const ['gold', 'silver', 'gems', 'diamonds', 'spices']) {
          expect(
            prices.containsKey(id),
            isFalse,
            reason:
                'Non-tradeable commodity "$id" must NOT have a seeded '
                'price entry (SPEC § Tradeable commodities).',
          );
        }
      },
    );

    test(
      'prices map pins canonical integer values for representative '
      'raw-resource and manufactured commodities',
      () {
        final result = runInitGame(
          config: GameSetupConfig.defaultConfig,
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );

        final prices = result.game.worldMarketState.prices;
        expect(prices['grain'], 50);
        expect(prices['timber'], 30);
        expect(prices['iron'], 80);
        expect(prices['lumber'], 60);
        expect(prices['castIron'], 220);
        expect(prices['steel'], 530);
      },
    );

    test(
      'lastTurnActivity and carry-forward maps start empty on a fresh game',
      () {
        final result = runInitGame(
          config: GameSetupConfig.defaultConfig,
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );

        final wms = result.game.worldMarketState;
        expect(wms.lastTurnActivity, isEmpty);
        expect(wms.carryForwardOffersByFactionId, isEmpty);
        expect(wms.carryForwardBidsByFactionId, isEmpty);
      },
    );

    test('seeded prices round-trip through JSON', () {
      final result = runInitGame(
        config: GameSetupConfig.defaultConfig,
        options: const InitGameOptions(cellSize: 8, renderPng: false),
      );

      final beforePrices = Map<CommodityId, int>.from(
        result.game.worldMarketState.prices,
      );
      final json = result.game.toJson();
      final restored = Game.fromJson(json);
      expect(restored.worldMarketState.prices, beforePrices);
    });
  });
}
