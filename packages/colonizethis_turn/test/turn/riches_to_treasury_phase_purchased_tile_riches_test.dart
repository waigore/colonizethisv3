/// Integration tests for `richesToTreasuryTurnPhaseHandler` purchased-tile
/// riches handoff (Refs #2991 C5).
///
/// SPEC anchors:
///   - SPEC/program/turn-resolution-phase-details.md § Riches to treasury
///     (purchased-tile riches credits paragraph).
///   - SPEC/game/world-market.md § First right of refusal § Riches handoff.
///   - SPEC/game/world-market.md § Acceptance criteria — "Purchased-tile
///     riches handoff — credit/non-riches/unimproved/post-conquest".
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import '../support/riches_to_treasury_phase_purchased_tile_riches_test_support.dart';
import 'riches_to_treasury_phase_purchased_tile_riches_cases.dart';

void main() {
  group('richesToTreasuryTurnPhaseHandler — purchased-tile riches handoff', () {
    test(
      'AC purchased-tile riches handoff — credit: improved gold tile in '
      'minor province credits owning GP treasury without affecting the '
      "GP's own stockpile riches conversion",
      () {
        final scenario = purchasedTileGoldCreditScenario(
          gpATreasury: 100,
          gpAStockpileGold: 0,
        );
        final next = runPurchasedTileRichesHandler(scenario.game, scenario.config);
        final gpA = gpAFrom(next);
        expect(gpA.stockpile.quantityOf('gold'), equals(0));
        expect(
          gpA.treasury,
          equals(100 + richesBasePrice('gold')),
          reason:
              "owning GP's treasury increases by exactly basePrice('gold') "
              '× units(1) × multiplier(1.0)',
        );
      },
    );

    test(
      'GP own-stockpile riches still convert at the same time as the '
      'purchased-tile credit (no regression)',
      () {
        final scenario = purchasedTileGoldCreditScenario(
          gpATreasury: 100,
          gpAStockpileGold: 2,
        );
        final next = runPurchasedTileRichesHandler(scenario.game, scenario.config);
        final gpA = gpAFrom(next);
        expect(gpA.stockpile.quantityOf('gold'), equals(0));
        expect(gpA.treasury, equals(100 + 3 * richesBasePrice('gold')));
      },
    );

    test(
      'AC purchased-tile riches handoff — non-riches resource: timber tile '
      'produces no purchased-tile credit (stockpile riches still convert)',
      () {
        expectPurchasedTileRichesTreasury(purchasedTileNonRichesScenario());
      },
    );

    test(
      'AC purchased-tile riches handoff — unimproved tile: improvement '
      'level 0 produces no credit',
      () {
        expectPurchasedTileRichesTreasury(purchasedTileUnimprovedScenario());
      },
    );

    test(
      'AC purchased-tile riches handoff — post-conquest filter: when the '
      'purchased province is now owned by a Great Power, the riches '
      'handoff is skipped (the index filters it out)',
      () {
        final game = purchasedTileRichesPostConquestGame();
        final config = purchasedTileRichesConfig(Resource.gold);
        final next = runPurchasedTileRichesHandler(game, config);
        final gpA = gpAFrom(next);
        expect(
          gpA.treasury,
          equals(0),
          reason:
              'post-conquest provinces are filtered out by '
              'PurchasedTileIndex.fromGame, so no riches handoff occurs',
        );
      },
    );

    test(
      'minor seller is never credited — `Game.players` does not gain a '
      'minor entry from the riches handoff',
      () {
        final game = gameWithPurchasedGoldTile(
          gpATreasury: 0,
          gpAStockpileGold: 0,
        );
        final next = runPurchasedTileRichesHandler(
          game,
          purchasedTileRichesConfig(Resource.gold),
        );
        expect(
          next.players.where((p) => p.id == 'M1'),
          isEmpty,
          reason: 'Minors and Tribes are never represented as Player entries',
        );
        expect(next.minorNations, hasLength(1));
      },
    );

    test(
      'no `tileMapByRegion` on config — handler is a no-op for purchased '
      'tile credits and existing GP stockpile riches still convert',
      () {
        expectPurchasedTileRichesTreasury(purchasedTileNoTileMapScenario());
      },
    );

    test(
      'richesCashMultiplier > 1.0 applies to purchased-tile credits — '
      'matches the behaviour of regular riches-to-treasury cash-in',
      () {
        expectPurchasedTileRichesTreasury(purchasedTileMultiplierScenario());
      },
    );

    test(
      'no purchased tiles + no own riches — handler is a complete no-op',
      () {
        final game = purchasedTileRichesNoOpGame();
        final next = runPurchasedTileRichesHandler(
          game,
          purchasedTileRichesConfig(null),
        );
        expect(gpAFrom(next).treasury, equals(42));
      },
    );
  });

  group('applyPurchasedTileRichesHandoff — direct helper', () {
    test('null tileMapByRegion → identity (no-op)', () {
      final game = gameWithPurchasedGoldTile(gpATreasury: 99);
      final result = applyPurchasedTileRichesHandoff(
        game,
        tileMapByRegion: null,
      );
      expect(identical(result, game), isTrue);
    });

    test('empty tileMapByRegion → identity (no-op)', () {
      final game = gameWithPurchasedGoldTile(gpATreasury: 99);
      final result = applyPurchasedTileRichesHandoff(
        game,
        tileMapByRegion: const <String, TileMapResult>{},
      );
      expect(identical(result, game), isTrue);
    });

    test('empty purchased-tile index → identity (no-op)', () {
      final game = TestFixtures.minimalGame();
      final result = applyPurchasedTileRichesHandoff(
        game,
        tileMapByRegion: tileMapByRegionForResource(Resource.gold),
      );
      expect(identical(result, game), isTrue);
    });
  });
}
