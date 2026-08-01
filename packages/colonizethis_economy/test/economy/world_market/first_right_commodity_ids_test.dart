import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('firstRightCommodityIdsForPlayer (Refs #4226)', () {
    test('returns commodity for one still-valid purchased timber tile', () {
      const tileKey = 'oldWorld|M1|0|0';
      final game = minorPurchasedTileGame(tileKey: tileKey).copyWith(
        worldState: minorPurchasedTileGame(tileKey: tileKey).worldState.copyWith(
          resourceByTileKey: {tileKey: 'timber'},
        ),
      );
      expect(firstRightCommodityIdsForPlayer(game, 'gpA'), {'timber'});
    });

    test('deduplicates multiple tiles mapping to same commodity', () {
      const tileA = 'oldWorld|M1|0|0';
      const tileB = 'oldWorld|M1|1|0';
      final base = minorPurchasedTileGame(
        tileKey: tileA,
        purchasedTilesByTileKey: {tileA: 'gpA', tileB: 'gpA'},
      );
      final game = base.copyWith(
        worldState: base.worldState.copyWith(
          resourceByTileKey: {tileA: 'timber', tileB: 'timber'},
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|M1': [tileA, tileB],
            },
          },
        ),
      );
      expect(firstRightCommodityIdsForPlayer(game, 'gpA'), {'timber'});
    });

    test('returns multiple commodities for distinct resources', () {
      const tileA = 'oldWorld|M1|0|0';
      const tileB = 'oldWorld|M1|1|0';
      final base = minorPurchasedTileGame(
        tileKey: tileA,
        purchasedTilesByTileKey: {tileA: 'gpA', tileB: 'gpA'},
      );
      final game = base.copyWith(
        worldState: base.worldState.copyWith(
          resourceByTileKey: {tileA: 'timber', tileB: 'iron'},
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|M1': [tileA, tileB],
            },
          },
        ),
      );
      expect(
        firstRightCommodityIdsForPlayer(game, 'gpA'),
        {'timber', 'iron'},
      );
    });

    test('returns empty set when no still-valid purchased tiles', () {
      final game = minorPurchasedTileGame(
        purchasedTilesByTileKey: const {},
      );
      expect(firstRightCommodityIdsForPlayer(game, 'gpA'), isEmpty);
    });
  });
}
