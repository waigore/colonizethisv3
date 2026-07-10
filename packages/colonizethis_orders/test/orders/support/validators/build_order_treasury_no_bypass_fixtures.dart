// Shared fixtures for build-order treasury no-bypass guard (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Cheapest regiment in the catalog; treasury gate exercised by these guards.
final buildOrderTreasuryNoBypassCheapest = RegimentEconomyCatalog.peasantLevies;

const buildOrderTreasuryNoBypassProvinceId = 'oldWorld|p1';

Game buildOrderTreasuryNoBypassGame({
  required int treasury,
  required bool isHuman,
}) => TestFixtures.minimalGame(
  players: [
    Player(
      id: 'gp1',
      displayName: 'P',
      isHuman: isHuman,
      capitalProvinceId: buildOrderTreasuryNoBypassProvinceId,
      treasury: treasury,
      stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 1}),
      workerPool: const WorkerPool(peasants: 1),
    ),
  ],
  oldWorld: const RegionData(
    provinces: [
      Province(
        id: buildOrderTreasuryNoBypassProvinceId,
        regionId: 'oldWorld',
        ownerId: 'gp1',
      ),
    ],
  ),
);

BuildUnitOrder buildOrderTreasuryNoBypassRegimentOrder() => BuildUnitOrder(
  unitType: buildOrderTreasuryNoBypassCheapest.id,
  isMilitary: true,
  spawnProvinceId: buildOrderTreasuryNoBypassProvinceId,
);

OrderValidationResult validateBuildOrderTreasuryNoBypassRegiment(Game game) =>
    BuildOrderValidator(game: game, player: game.players.first).validate(
      buildOrderTreasuryNoBypassRegimentOrder(),
      previousRejected: false,
    );
