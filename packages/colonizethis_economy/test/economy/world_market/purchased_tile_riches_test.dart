/// Unit tests for `computePurchasedTileRichesCredits` (Refs #2991 C5).
///
/// SPEC anchors:
///   - SPEC/game/world-market.md § First right of refusal § Riches handoff
///   - SPEC/game/world-market.md § Acceptance criteria — Purchased-tile
///     riches handoff (credit / non-riches resource / unimproved tile /
///     post-conquest filter).
///   - SPEC/program/turn-resolution-phase-details.md § Riches to treasury
///     (purchased-tile credits paragraph).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/economy/world_market/purchased_tile_index.dart';
import 'package:colonizethis_economy/src/economy/world_market/purchased_tile_riches.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('computePurchasedTileRichesCredits — riches handoff per #2991 C5', () {
    test('AC purchased-tile riches handoff — credit: improved gold tile in '
        'minor province credits owning GP at improvementLevel × basePrice × '
        'multiplier', () {
      final game = purchasedTileScenario(
        resource: Resource.gold,
        improvementLevel: 1,
        roadLevel: 1,
      );
      final index = PurchasedTileIndex.fromGame(game);
      expect(index.length, 1);

      final result = computePurchasedTileRichesCredits(
        game: game,
        tileMapByRegion: tileMapByRegionForResource(Resource.gold),
        purchasedTileIndex: index,
      );

      expect(result.credits, hasLength(1));
      final credit = result.credits.single;
      expect(credit.tileKey, equals('oldWorld|M1|0|0'));
      expect(credit.owningGpId, equals('gpA'));
      expect(credit.sourceFactionId, equals('M1'));
      expect(credit.commodityId, equals('gold'));
      expect(credit.units, equals(1));
      expect(
        credit.treasuryDelta,
        equals(richesBasePrice('gold')),
        reason: 'units=1 × basePrice × multiplier=1.0 truncates to basePrice',
      );

      expect(
        result.treasuryCreditByGpId,
        equals({'gpA': richesBasePrice('gold')}),
      );
      expect(result.totalTreasuryCredit, equals(richesBasePrice('gold')));
    });

    test(
      'multiplier is honoured: richesCashMultiplier=1.5 applies before truncation',
      () {
        final game = purchasedTileScenario(
          resource: Resource.spices,
          improvementLevel: 1,
          roadLevel: 1,
        );
        final result = computePurchasedTileRichesCredits(
          game: game,
          tileMapByRegion: tileMapByRegionForResource(Resource.spices),
          purchasedTileIndex: PurchasedTileIndex.fromGame(game),
          richesCashMultiplier: 1.5,
        );

        expect(result.credits, hasLength(1));
        // spices basePrice = 50; 1 × 50 × 1.5 = 75 (truncated)
        expect(result.credits.single.treasuryDelta, equals(75));
        expect(result.treasuryCreditByGpId['gpA'], equals(75));
      },
    );

    test(
      'AC purchased-tile riches handoff — non-riches resource: timber tile '
      'produces no credit (commodities flow through world market instead)',
      () {
        final game = purchasedTileScenario(
          resource: Resource.timber,
          improvementLevel: 1,
          roadLevel: 1,
        );
        final result = computePurchasedTileRichesCredits(
          game: game,
          tileMapByRegion: tileMapByRegionForResource(Resource.timber),
          purchasedTileIndex: PurchasedTileIndex.fromGame(game),
        );

        expect(result.credits, isEmpty);
        expect(result.treasuryCreditByGpId, isEmpty);
        expect(result, equals(PurchasedTileRichesResult.empty));
      },
    );

    test(
      'AC purchased-tile riches handoff — unimproved tile: improvementLevel=0 '
      'produces no credit even when the resource is in the riches set',
      () {
        final game = purchasedTileScenario(
          resource: Resource.silver,
          improvementLevel: 0,
          roadLevel: 1,
        );
        final result = computePurchasedTileRichesCredits(
          game: game,
          tileMapByRegion: tileMapByRegionForResource(Resource.silver),
          purchasedTileIndex: PurchasedTileIndex.fromGame(game),
        );

        expect(result.credits, isEmpty);
        expect(result.treasuryCreditByGpId, isEmpty);
      },
    );

    test('tile with no road and no port produces no credit (transport level 0 '
        'caps yield to 0)', () {
      final game = purchasedTileScenario(
        resource: Resource.gold,
        improvementLevel: 1,
        roadLevel: 0,
      );
      final result = computePurchasedTileRichesCredits(
        game: game,
        tileMapByRegion: tileMapByRegionForResource(Resource.gold),
        purchasedTileIndex: PurchasedTileIndex.fromGame(game),
      );

      expect(result.credits, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    });

    test('port-flagged tile yields even without road (port = transport 4)', () {
      const tileKey = 'oldWorld|M1|0|0';
      final game = purchasedTileScenario(
        resource: Resource.diamonds,
        improvementLevel: 1,
        roadLevel: 0,
        portsByProvinceSeaboard: const {'oldWorld|M1|north': tileKey},
      );
      final result = computePurchasedTileRichesCredits(
        game: game,
        tileMapByRegion: tileMapByRegionForResource(Resource.diamonds),
        purchasedTileIndex: PurchasedTileIndex.fromGame(game),
      );

      expect(result.credits, hasLength(1));
      expect(result.credits.single.units, equals(1));
      expect(
        result.credits.single.treasuryDelta,
        equals(richesBasePrice('diamonds')),
      );
    });

    test('AC purchased-tile riches handoff — post-conquest filter: when the '
        'purchased province is now owned by a Great Power, no credit is '
        'emitted (the index filters it out at build time)', () {
      // Province owned by gpB (post-conquest); purchased entry maps to gpA.
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$ow|P1|0|0';
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'gpA', displayName: 'GP A', isHuman: true),
          Player(id: 'gpB', displayName: 'GP B', isHuman: false),
        ],
        oldWorld: const RegionData(
          provinces: [Province(id: provinceId, regionId: ow, ownerId: 'gpB')],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {
            provinceId: [tileKey],
          },
        },
        purchasedTilesByTileKey: const {tileKey: 'gpA'},
        tileState: TileMapState()
            .setImprovement(tileKey, 1)
            .setRoadLevel(tileKey, 1),
      );
      final result = computePurchasedTileRichesCredits(
        game: game,
        tileMapByRegion: tileMapByRegionForResource(Resource.gold),
        purchasedTileIndex: PurchasedTileIndex.fromGame(game),
      );

      expect(result.credits, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    });

    test(
      'tribe-owned purchased tile producing spices credits the owning GP',
      () {
        const ow = 'oldWorld';
        const tribeProvinceId = '$ow|T1';
        const tileKey = '$ow|T1|0|0';
        final game = TestFixtures.minimalGame(
          players: const [
            Player(id: 'gpA', displayName: 'GP A', isHuman: true),
          ],
          oldWorld: const RegionData(
            provinces: [
              Province(id: tribeProvinceId, regionId: ow, ownerId: 'T1'),
            ],
          ),
          tileKeysByRegionAndProvince: const {
            ow: {
              tribeProvinceId: [tileKey],
            },
          },
          tribes: const [Tribe(id: 'T1', displayName: 'Tribe 1')],
          purchasedTilesByTileKey: const {tileKey: 'gpA'},
          tileState: TileMapState()
              .setImprovement(tileKey, 1)
              .setRoadLevel(tileKey, 1),
        );
        final result = computePurchasedTileRichesCredits(
          game: game,
          tileMapByRegion: {ow: singleResourceTileMap(Resource.spices)},
          purchasedTileIndex: PurchasedTileIndex.fromGame(game),
        );

        expect(result.credits, hasLength(1));
        final credit = result.credits.single;
        expect(credit.sourceFactionId, equals('T1'));
        expect(credit.owningGpId, equals('gpA'));
        expect(credit.commodityId, equals('spices'));
        expect(credit.treasuryDelta, equals(richesBasePrice('spices')));
      },
    );

    test(
      'multi-tile aggregation — distinct GPs each accrue their own credits',
      () {
        const ow = 'oldWorld';
        const province1 = '$ow|M1';
        const province2 = '$ow|M2';
        // Tile A at (0,0) is in province M1; tile B at (0,1) is in M2.
        const tileA = '$ow|M1|0|0';
        const tileB = '$ow|M2|0|1';
        final game = TestFixtures.minimalGame(
          players: const [
            Player(id: 'gpA', displayName: 'GP A', isHuman: true),
            Player(id: 'gpB', displayName: 'GP B', isHuman: false),
          ],
          oldWorld: const RegionData(
            provinces: [
              Province(id: province1, regionId: ow, ownerId: 'M1'),
              Province(id: province2, regionId: ow, ownerId: 'M2'),
            ],
          ),
          tileKeysByRegionAndProvince: const {
            ow: {
              province1: [tileA],
              province2: [tileB],
            },
          },
          minorNations: const [
            MinorNation(id: 'M1', displayName: 'Minor 1'),
            MinorNation(id: 'M2', displayName: 'Minor 2'),
          ],
          purchasedTilesByTileKey: const {tileA: 'gpA', tileB: 'gpB'},
          tileState: TileMapState()
              .setImprovement(tileA, 1)
              .setRoadLevel(tileA, 1)
              .setImprovement(tileB, 1)
              .setRoadLevel(tileB, 1),
        );
        // 1×2 region grid: row 0 -> M1 with gold; row 1 -> M2 with gems.
        final regionGrid = TileMapResult(
          width: 1,
          height: 2,
          grid: [
            ['M1'],
            ['M2'],
          ],
          resourceGrid: [
            [Resource.gold],
            [Resource.gems],
          ],
        );
        final result = computePurchasedTileRichesCredits(
          game: game,
          tileMapByRegion: {ow: regionGrid},
          purchasedTileIndex: PurchasedTileIndex.fromGame(game),
        );
        expect(result.credits, hasLength(2));
        expect(
          result.treasuryCreditByGpId.keys.toSet(),
          equals({'gpA', 'gpB'}),
        );
        expect(
          result.treasuryCreditByGpId['gpA'],
          equals(richesBasePrice('gold')),
        );
        expect(
          result.treasuryCreditByGpId['gpB'],
          equals(richesBasePrice('gems')),
        );
      },
    );

    test('empty index returns empty result (no work done)', () {
      final game = TestFixtures.minimalGame();
      final result = computePurchasedTileRichesCredits(
        game: game,
        tileMapByRegion: tileMapByRegionForResource(Resource.gold),
        purchasedTileIndex: PurchasedTileIndex.fromGame(game),
      );

      expect(result, equals(PurchasedTileRichesResult.empty));
      expect(result.isEmpty, isTrue);
    });

    test('empty tileMapByRegion returns empty result', () {
      final game = purchasedTileScenario(
        resource: Resource.gold,
        improvementLevel: 1,
        roadLevel: 1,
      );
      final result = computePurchasedTileRichesCredits(
        game: game,
        tileMapByRegion: const <String, TileMapResult>{},
        purchasedTileIndex: PurchasedTileIndex.fromGame(game),
      );

      expect(result, equals(PurchasedTileRichesResult.empty));
    });

    test(
      'determinism — two calls with the same inputs return equal credits',
      () {
        final game = purchasedTileScenario(
          resource: Resource.gems,
          improvementLevel: 1,
          roadLevel: 1,
        );
        final tileMaps = tileMapByRegionForResource(Resource.gems);
        final index = PurchasedTileIndex.fromGame(game);
        final r1 = computePurchasedTileRichesCredits(
          game: game,
          tileMapByRegion: tileMaps,
          purchasedTileIndex: index,
        );
        final r2 = computePurchasedTileRichesCredits(
          game: game,
          tileMapByRegion: tileMaps,
          purchasedTileIndex: index,
        );
        expect(r1.credits.length, equals(r2.credits.length));
        expect(r1.totalTreasuryCredit, equals(r2.totalTreasuryCredit));
        expect(r1.treasuryCreditByGpId, equals(r2.treasuryCreditByGpId));
      },
    );
  });
}
