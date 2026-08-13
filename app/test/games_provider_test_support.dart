// Shared fixtures for games_provider_test (Refs #4352).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart';

Duration gamesProviderMedianDuration(List<Duration> values) {
  final sorted = List<Duration>.from(values)..sort();
  return sorted[sorted.length ~/ 2];
}

ProviderContainer gamesProviderTestContainer({List<Override>? overrides}) {
  final container = ProviderContainer(overrides: overrides ?? const []);
  addTearDown(container.dispose);
  return container;
}

GameSetupConfig get gamesProviderStandardSetup => GameSetupConfig(
      selectedGreatPowerIds: const ['england', 'france'],
      continentCount: 1,
      minorNationCount: 0,
      tribeCount: 1,
      numProvincesOldWorld: 4,
      numProvincesNewWorld: 2,
    );

Game gamesProviderCreateStandardGame(GameService gameService, String id) =>
    gameService.createNewGame(id: id, config: gamesProviderStandardSetup);

String? gamesProviderFirstHumanUnitId(Game game, String humanId) {
  for (final unit in [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ]) {
    if (unit.ownerId == humanId) return unit.id;
  }
  return null;
}

Game gamesProviderExplorerFixture({
  required String id,
  required int provinceCount,
  required int tilesPerProvince,
}) {
  const playerId = 'gp1';
  const tribeId = 'tribe1';
  const regionId = 'oldWorld';
  const explorerId = 'explorer_1';

  final provinces = <Province>[];
  final byProvince = <String, List<String>>{};
  final visibility = <String, String>{};

  for (var p = 0; p < provinceCount; p++) {
    final provinceId = '$regionId|p$p';
    final ownerId = p == 0 ? playerId : tribeId;
    provinces.add(
      Province(id: provinceId, regionId: regionId, ownerId: ownerId),
    );
    final tiles = <String>[];
    for (var t = 0; t < tilesPerProvince; t++) {
      final tileKey = '$regionId|p$p|$t|0';
      tiles.add(tileKey);
      visibility[tileKey] = p == 0 && t == 0
          ? 'fullyVisible'
          : t == 0
          ? 'fogged'
          : 'unknown';
    }
    byProvince[provinceId] = tiles;
  }

  return Game(
    id: id,
    players: const [Player(id: playerId, displayName: 'Human', isHuman: true)],
    tribes: const [Tribe(id: tribeId, displayName: 'Tribe')],
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: provinces,
        units: [
          Unit(
            id: explorerId,
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: '$regionId|p0',
            tileKey: '$regionId|p0|0|0',
            status: UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {regionId: byProvince},
      playerVisibilityByTile: {playerId: visibility},
    ),
  );
}
