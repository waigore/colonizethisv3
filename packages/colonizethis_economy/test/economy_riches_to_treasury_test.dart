import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Tests for economy_riches_to_treasury.dart. SPEC/program/turn-resolution-phases.md.
void main() {
  group('resolveRichesToTreasury', () {
    test('converts spices to treasury at base price', () {
      final stockpile = stockpileWithDeltas({CommodityCatalog.spices.id: 4});

      final result = resolveRichesToTreasury(stockpile: stockpile);

      expect(result.treasuryDelta, 4 * 50);
      expect(result.stockpile.quantityOf(CommodityCatalog.spices.id), 0);
    });

    test('converts multiple riches and sums treasury delta', () {
      final stockpile = stockpileWithDeltas({
        CommodityCatalog.spices.id: 2,
        CommodityCatalog.silver.id: 1,
      });

      final result = resolveRichesToTreasury(stockpile: stockpile);

      final spicesPrice = 50;
      final silverPrice = richesBasePrice(CommodityCatalog.silver.id);
      expect(result.treasuryDelta, 2 * spicesPrice + 1 * silverPrice);
      expect(result.stockpile.quantityOf(CommodityCatalog.spices.id), 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.silver.id), 0);
    });

    test('non-riches in stockpile are unchanged', () {
      final stockpile = stockpileWithDeltas({
        CommodityCatalog.grain.id: 10,
        CommodityCatalog.gold.id: 2,
      });

      final result = resolveRichesToTreasury(stockpile: stockpile);

      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 10);
      expect(result.stockpile.quantityOf(CommodityCatalog.gold.id), 0);
      expect(
        result.treasuryDelta,
        2 * richesBasePrice(CommodityCatalog.gold.id),
      );
    });

    test('richesCashMultiplier scales treasury delta', () {
      final stockpile = stockpileWithDeltas({CommodityCatalog.spices.id: 2});

      final result = resolveRichesToTreasury(
        stockpile: stockpile,
        richesCashMultiplier: 1.5,
      );

      expect(result.treasuryDelta, (2 * 50 * 1.5).truncate());
      expect(result.stockpile.quantityOf(CommodityCatalog.spices.id), 0);
    });

    test('zero riches yields zero delta and unchanged stockpile', () {
      var stockpile = const Stockpile().applyDelta(
        CommodityCatalog.grain.id,
        5,
      );

      final result = resolveRichesToTreasury(stockpile: stockpile);

      expect(result.treasuryDelta, 0);
      expect(result.stockpile.quantityOf(CommodityCatalog.grain.id), 5);
    });

    test('empty stockpile yields zero delta', () {
      const stockpile = Stockpile();

      final result = resolveRichesToTreasury(stockpile: stockpile);

      expect(result.treasuryDelta, 0);
    });
  });

  group('pendingRichesTreasuryDelta', () {
    test('matches resolveRichesToTreasury treasuryDelta', () {
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.spices.id, 3)
          .applyDelta(CommodityCatalog.gold.id, 1);

      expect(
        pendingRichesTreasuryDelta(stockpile: stockpile),
        resolveRichesToTreasury(stockpile: stockpile).treasuryDelta,
      );
    });

    test('returns zero when stockpile has no riches', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.grain.id,
        5,
      );

      expect(pendingRichesTreasuryDelta(stockpile: stockpile), 0);
    });
  });
}
