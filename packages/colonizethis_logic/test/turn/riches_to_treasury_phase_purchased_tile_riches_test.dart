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
import 'package:colonizethis_logic/src/turn/phases/riches_to_treasury_phase.dart';
import 'package:colonizethis_logic/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_logic/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group('richesToTreasuryTurnPhaseHandler — purchased-tile riches handoff', () {
    test(
      'AC purchased-tile riches handoff — credit: improved gold tile in '
      'minor province credits owning GP treasury without affecting the '
      "GP's own stockpile riches conversion",
      () {
        final game = _gameWithPurchasedGoldTile(
          gpATreasury: 100,
          gpAStockpileGold: 0,
        );
        final acc = TurnPipelineState(game: game);
        final config = TurnResolverConfig(
          topology: const MapTopology(nodes: [], edges: []),
          orders: const Orders(),
          tileMapByRegion: _tileMapByRegion(Resource.gold),
        );

        final next =
            (richesToTreasuryTurnPhaseHandler(acc, config, 3)
                    as TurnPhaseStepContinue)
                .pipeline
                .game;

        final gpA = next.players.firstWhere((p) => p.id == 'gpA');
        // Stockpile gold was 0 → still 0; the credit applied is the
        // purchased-tile yield × basePrice × multiplier (1.0 default).
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
        final game = _gameWithPurchasedGoldTile(
          gpATreasury: 100,
          gpAStockpileGold: 2,
        );
        final acc = TurnPipelineState(game: game);
        final config = TurnResolverConfig(
          topology: const MapTopology(nodes: [], edges: []),
          orders: const Orders(),
          tileMapByRegion: _tileMapByRegion(Resource.gold),
        );

        final next =
            (richesToTreasuryTurnPhaseHandler(acc, config, 3)
                    as TurnPhaseStepContinue)
                .pipeline
                .game;

        final gpA = next.players.firstWhere((p) => p.id == 'gpA');
        // Own stockpile gold (2) cashed in at basePrice + 1 unit from the
        // purchased tile = 3 × basePrice('gold').
        expect(gpA.stockpile.quantityOf('gold'), equals(0));
        expect(gpA.treasury, equals(100 + 3 * richesBasePrice('gold')));
      },
    );

    test(
      'AC purchased-tile riches handoff — non-riches resource: timber tile '
      'produces no purchased-tile credit (stockpile riches still convert)',
      () {
        final game = _gameWithPurchasedTileResource(
          resource: Resource.timber,
          improvementLevel: 1,
          roadLevel: 1,
          gpATreasury: 100,
          gpAStockpileGold: 1,
        );
        final acc = TurnPipelineState(game: game);
        final config = TurnResolverConfig(
          topology: const MapTopology(nodes: [], edges: []),
          orders: const Orders(),
          tileMapByRegion: _tileMapByRegion(Resource.timber),
        );

        final next =
            (richesToTreasuryTurnPhaseHandler(acc, config, 3)
                    as TurnPhaseStepContinue)
                .pipeline
                .game;

        final gpA = next.players.firstWhere((p) => p.id == 'gpA');
        // Only own stockpile (1 gold) is cashed in; no purchased-tile
        // credit applies because timber is not a riches commodity.
        expect(gpA.treasury, equals(100 + 1 * richesBasePrice('gold')));
      },
    );

    test(
      'AC purchased-tile riches handoff — unimproved tile: improvement '
      'level 0 produces no credit',
      () {
        final game = _gameWithPurchasedTileResource(
          resource: Resource.silver,
          improvementLevel: 0,
          roadLevel: 1,
          gpATreasury: 0,
          gpAStockpileGold: 0,
        );
        final acc = TurnPipelineState(game: game);
        final config = TurnResolverConfig(
          topology: const MapTopology(nodes: [], edges: []),
          orders: const Orders(),
          tileMapByRegion: _tileMapByRegion(Resource.silver),
        );

        final next =
            (richesToTreasuryTurnPhaseHandler(acc, config, 3)
                    as TurnPhaseStepContinue)
                .pipeline
                .game;

        final gpA = next.players.firstWhere((p) => p.id == 'gpA');
        expect(gpA.treasury, equals(0));
      },
    );

    test(
      'AC purchased-tile riches handoff — post-conquest filter: when the '
      'purchased province is now owned by a Great Power, the riches '
      'handoff is skipped (the index filters it out)',
      () {
        const ow = 'oldWorld';
        const provinceId = '$ow|P1';
        const tileKey = '$ow|P1|0|0';
        final game = TestFixtures.minimalGame(
          players: const [
            Player(
              id: 'gpA',
              displayName: 'GP A',
              isHuman: true,
              treasury: 0,
            ),
            Player(
              id: 'gpB',
              displayName: 'GP B',
              isHuman: false,
              treasury: 0,
            ),
          ],
          oldWorld: const RegionData(
            provinces: [
              // Province now owned by gpB after a conquest.
              Province(id: provinceId, regionId: ow, ownerId: 'gpB'),
            ],
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
        final acc = TurnPipelineState(game: game);
        final config = TurnResolverConfig(
          topology: const MapTopology(nodes: [], edges: []),
          orders: const Orders(),
          tileMapByRegion: _tileMapByRegion(Resource.gold),
        );

        final next =
            (richesToTreasuryTurnPhaseHandler(acc, config, 3)
                    as TurnPhaseStepContinue)
                .pipeline
                .game;

        final gpA = next.players.firstWhere((p) => p.id == 'gpA');
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
        final game = _gameWithPurchasedGoldTile(
          gpATreasury: 0,
          gpAStockpileGold: 0,
        );
        final acc = TurnPipelineState(game: game);
        final config = TurnResolverConfig(
          topology: const MapTopology(nodes: [], edges: []),
          orders: const Orders(),
          tileMapByRegion: _tileMapByRegion(Resource.gold),
        );

        final next =
            (richesToTreasuryTurnPhaseHandler(acc, config, 3)
                    as TurnPhaseStepContinue)
                .pipeline
                .game;

        expect(
          next.players.where((p) => p.id == 'M1'),
          isEmpty,
          reason: 'Minors and Tribes are never represented as Player entries',
        );
        // The minor faction in `minorNations` is not mutated either.
        expect(next.minorNations, hasLength(1));
      },
    );

    test(
      'no `tileMapByRegion` on config — handler is a no-op for purchased '
      'tile credits and existing GP stockpile riches still convert',
      () {
        final game = _gameWithPurchasedGoldTile(
          gpATreasury: 100,
          gpAStockpileGold: 2,
        );
        final acc = TurnPipelineState(game: game);
        // No tileMapByRegion — handler should skip purchased-tile riches.
        final config = TurnResolverConfig(
          topology: const MapTopology(nodes: [], edges: []),
          orders: const Orders(),
        );

        final next =
            (richesToTreasuryTurnPhaseHandler(acc, config, 3)
                    as TurnPhaseStepContinue)
                .pipeline
                .game;

        final gpA = next.players.firstWhere((p) => p.id == 'gpA');
        expect(gpA.stockpile.quantityOf('gold'), equals(0));
        expect(
          gpA.treasury,
          equals(100 + 2 * richesBasePrice('gold')),
          reason:
              "without tileMapByRegion, only the GP's own stockpile riches "
              'cash in (no purchased-tile credit applied)',
        );
      },
    );

    test(
      'richesCashMultiplier > 1.0 applies to purchased-tile credits — '
      'matches the behaviour of regular riches-to-treasury cash-in',
      () {
        // El Dorado scenario uses 1.5×.
        final game = _gameWithPurchasedTileResource(
          resource: Resource.spices,
          improvementLevel: 1,
          roadLevel: 1,
          gpATreasury: 0,
          gpAStockpileGold: 0,
          richesCashMultiplier: 1.5,
        );
        final acc = TurnPipelineState(game: game);
        final config = TurnResolverConfig(
          topology: const MapTopology(nodes: [], edges: []),
          orders: const Orders(),
          tileMapByRegion: _tileMapByRegion(Resource.spices),
        );

        final next =
            (richesToTreasuryTurnPhaseHandler(acc, config, 3)
                    as TurnPhaseStepContinue)
                .pipeline
                .game;

        final gpA = next.players.firstWhere((p) => p.id == 'gpA');
        // 1 × basePrice('spices') = 50; × 1.5 = 75 truncated.
        expect(gpA.treasury, equals(75));
      },
    );

    test(
      'no purchased tiles + no own riches — handler is a complete no-op',
      () {
        final game = TestFixtures.minimalGame(
          players: const [
            Player(
              id: 'gpA',
              displayName: 'GP A',
              isHuman: true,
              treasury: 42,
            ),
          ],
        );
        final acc = TurnPipelineState(game: game);
        final config = TurnResolverConfig(
          topology: const MapTopology(nodes: [], edges: []),
          orders: const Orders(),
        );

        final next =
            (richesToTreasuryTurnPhaseHandler(acc, config, 3)
                    as TurnPhaseStepContinue)
                .pipeline
                .game;

        final gpA = next.players.firstWhere((p) => p.id == 'gpA');
        expect(gpA.treasury, equals(42));
      },
    );
  });

  group('applyPurchasedTileRichesHandoff — direct helper', () {
    test('null tileMapByRegion → identity (no-op)', () {
      final game = _gameWithPurchasedGoldTile(gpATreasury: 99);
      final result = applyPurchasedTileRichesHandoff(
        game,
        tileMapByRegion: null,
      );
      expect(identical(result, game), isTrue);
    });

    test('empty tileMapByRegion → identity (no-op)', () {
      final game = _gameWithPurchasedGoldTile(gpATreasury: 99);
      final result = applyPurchasedTileRichesHandoff(
        game,
        tileMapByRegion: const <String, TileMapResult>{},
      );
      expect(identical(result, game), isTrue);
    });

    test('empty purchased-tile index → identity (no-op)', () {
      // No purchasedTilesByTileKey, but tileMapByRegion is non-empty.
      final game = TestFixtures.minimalGame();
      final result = applyPurchasedTileRichesHandoff(
        game,
        tileMapByRegion: _tileMapByRegion(Resource.gold),
      );
      expect(identical(result, game), isTrue);
    });
  });
}

Game _gameWithPurchasedGoldTile({
  required int gpATreasury,
  int gpAStockpileGold = 0,
}) =>
    _gameWithPurchasedTileResource(
      resource: Resource.gold,
      improvementLevel: 1,
      roadLevel: 1,
      gpATreasury: gpATreasury,
      gpAStockpileGold: gpAStockpileGold,
    );

Game _gameWithPurchasedTileResource({
  required Resource resource,
  required int improvementLevel,
  required int roadLevel,
  required int gpATreasury,
  required int gpAStockpileGold,
  double richesCashMultiplier = 1.0,
}) {
  const ow = 'oldWorld';
  const minorProvinceId = '$ow|M1';
  const tileKey = '$ow|M1|0|0';
  TileMapState tileState = const TileMapState();
  if (improvementLevel > 0) {
    tileState = tileState.setImprovement(tileKey, improvementLevel);
  }
  if (roadLevel > 0) {
    tileState = tileState.setRoadLevel(tileKey, roadLevel);
  }
  return TestFixtures.minimalGame(
    players: [
      Player(
        id: 'gpA',
        displayName: 'GP A',
        isHuman: true,
        treasury: gpATreasury,
        stockpile: gpAStockpileGold > 0
            ? Stockpile(quantities: {'gold': gpAStockpileGold})
            : Stockpile.empty,
      ),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(id: minorProvinceId, regionId: ow, ownerId: 'M1'),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        minorProvinceId: [tileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    purchasedTilesByTileKey: const {tileKey: 'gpA'},
    tileState: tileState,
    richesCashMultiplier: richesCashMultiplier,
  );
}

Map<String, TileMapResult> _tileMapByRegion(Resource resource) {
  return {
    'oldWorld': TileMapResult(
      width: 1,
      height: 1,
      grid: [
        ['M1'],
      ],
      resourceGrid: [
        [resource],
      ],
    ),
  };
}
