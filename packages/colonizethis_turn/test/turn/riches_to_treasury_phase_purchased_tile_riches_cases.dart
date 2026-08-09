// Shared fixtures for riches_to_treasury_phase_purchased_tile_riches_test (Refs #4252 slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import '../support/riches_to_treasury_phase_purchased_tile_riches_test_support.dart';
import '../support/turn_phase_test_harness.dart';

const purchasedTileRichesGpA = 'gpA';

TurnResolverConfig purchasedTileRichesConfig(Resource? resource) {
  return TurnResolverConfig(
    topology: const MapTopology(nodes: [], edges: []),
    orders: const Orders(),
    tileMapByRegion:
        resource == null ? null : tileMapByRegionForResource(resource),
  );
}

Game runPurchasedTileRichesHandler(Game game, TurnResolverConfig config) {
  return runTurnPhaseHandler(
    handler: richesToTreasuryTurnPhaseHandler,
    game: game,
    config: config,
  );
}

Player gpAFrom(Game game) =>
    game.players.firstWhere((p) => p.id == purchasedTileRichesGpA);

Game purchasedTileRichesPostConquestGame() {
  const ow = kRegionOldWorld;
  const provinceId = '$ow|P1';
  const tileKey = '$ow|P1|0|0';
  return TestFixtures.minimalGame(
    players: const [
      Player(
        id: purchasedTileRichesGpA,
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
        Province(id: provinceId, regionId: ow, ownerId: 'gpB'),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        provinceId: [tileKey],
      },
    },
    purchasedTilesByTileKey: const {tileKey: purchasedTileRichesGpA},
    tileState: TileMapState()
        .setImprovement(tileKey, 1)
        .setRoadLevel(tileKey, 1),
  );
}

Game purchasedTileRichesNoOpGame() {
  return TestFixtures.minimalGame(
    players: const [
      Player(
        id: purchasedTileRichesGpA,
        displayName: 'GP A',
        isHuman: true,
        treasury: 42,
      ),
    ],
  );
}

typedef PurchasedTileRichesTreasuryScenario = ({
  Game game,
  TurnResolverConfig config,
  int expectedTreasury,
  String? reason,
});

PurchasedTileRichesTreasuryScenario purchasedTileGoldCreditScenario({
  required int gpATreasury,
  int gpAStockpileGold = 0,
}) {
  final game = gameWithPurchasedGoldTile(
    gpATreasury: gpATreasury,
    gpAStockpileGold: gpAStockpileGold,
  );
  return (
    game: game,
    config: purchasedTileRichesConfig(Resource.gold),
    expectedTreasury: gpATreasury +
        (gpAStockpileGold > 0
            ? gpAStockpileGold * richesBasePrice('gold')
            : richesBasePrice('gold')),
    reason: null,
  );
}

PurchasedTileRichesTreasuryScenario purchasedTileNonRichesScenario() {
  final game = gameWithPurchasedTileResource(
    resource: Resource.timber,
    improvementLevel: 1,
    roadLevel: 1,
    gpATreasury: 100,
    gpAStockpileGold: 1,
  );
  return (
    game: game,
    config: purchasedTileRichesConfig(Resource.timber),
    expectedTreasury: 100 + 1 * richesBasePrice('gold'),
    reason: null,
  );
}

PurchasedTileRichesTreasuryScenario purchasedTileUnimprovedScenario() {
  final game = gameWithPurchasedTileResource(
    resource: Resource.silver,
    improvementLevel: 0,
    roadLevel: 1,
    gpATreasury: 0,
    gpAStockpileGold: 0,
  );
  return (
    game: game,
    config: purchasedTileRichesConfig(Resource.silver),
    expectedTreasury: 0,
    reason: null,
  );
}

PurchasedTileRichesTreasuryScenario purchasedTileNoTileMapScenario() {
  final game = gameWithPurchasedGoldTile(
    gpATreasury: 100,
    gpAStockpileGold: 2,
  );
  return (
    game: game,
    config: purchasedTileRichesConfig(null),
    expectedTreasury: 100 + 2 * richesBasePrice('gold'),
    reason:
        "without tileMapByRegion, only the GP's own stockpile riches "
        'cash in (no purchased-tile credit applied)',
  );
}

PurchasedTileRichesTreasuryScenario purchasedTileMultiplierScenario() {
  final game = gameWithPurchasedTileResource(
    resource: Resource.spices,
    improvementLevel: 1,
    roadLevel: 1,
    gpATreasury: 0,
    gpAStockpileGold: 0,
    richesCashMultiplier: 1.5,
  );
  return (
    game: game,
    config: purchasedTileRichesConfig(Resource.spices),
    expectedTreasury: 75,
    reason: null,
  );
}

void expectPurchasedTileRichesTreasury(
  PurchasedTileRichesTreasuryScenario scenario,
) {
  final next = runPurchasedTileRichesHandler(scenario.game, scenario.config);
  final gpA = gpAFrom(next);
  expect(gpA.treasury, equals(scenario.expectedTreasury), reason: scenario.reason);
}
