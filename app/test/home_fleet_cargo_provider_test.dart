import 'dart:io';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _ThrowingMapGameService extends GameService {
  _ThrowingMapGameService(super.box, super.adapter);

  @override
  getMapData(String gameId) {
    throw StateError('simulated getMapData failure for test');
  }
}

GameSetupConfig _tinyConfig() => GameSetupConfig(
  selectedGreatPowerIds: ['england', 'france'],
  continentCount: 1,
  minorNationCount: 0,
  tribeCount: 1,
  numProvincesOldWorld: 4,
  numProvincesNewWorld: 2,
);

void main() {
  suppressLogsForTests();

  test(
    'provider returns empty summary when currentGame is null without Hive',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final summary = container.read(homeFleetCargoSummaryProvider);
      expect(summary.used, 0);
      expect(summary.capacity, 0);
      expect(summary.notDefined, isFalse);
      expect(summary.isCargoUsedReliable, isTrue);
    },
  );

  group('with Hive games box', () {
    late Directory dir;
    late Box<dynamic> box;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('ct_home_fleet_cargo_');
      Hive.init(dir.path);
      box = await Hive.openBox<dynamic>(HiveBoxNames.games);
    });

    tearDown(() async {
      await box.close();
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test(
      'homeFleetCargoSummaryProvider matches extraction overseas sum and home fleet capacity',
      () {
        final container = ProviderContainer(
          overrides: [gamesBoxProvider.overrideWith((ref) => box)],
        );
        addTearDown(container.dispose);

        final service = container.read(gameServiceProvider);
        final game = service.createNewGame(
          id: 'cargo_summary',
          config: _tinyConfig(),
        );
        container.read(currentGameProvider.notifier).setGame(game);

        final summary = container.read(homeFleetCargoSummaryProvider);
        final humanPlayer =
            game.players.where((p) => p.isHuman).firstOrNull ??
            game.players.first;
        final mapData = service.getMapData(game.id)!;
        final connectivity = resolveConnectivity(
          game: game,
          tileMapByRegion: mapData.tileMapByRegion,
          topology: mapData.combinedTopology,
        );
        final extraction = computeExtraction(
          game: game,
          tileMapByRegion: mapData.tileMapByRegion,
          connectivityResult: connectivity,
          techCapForPlayer: (playerId) {
            final player = game.playerById(playerId);
            return extractionCapForUnlocked(player?.techUnlocked);
          },
        );
        final expectedUsed =
            extraction[humanPlayer.id]?.overseas.values.fold<int>(
              0,
              (sum, value) => sum + value,
            ) ??
            0;
        final expectedCapacity = _homeFleetCapacity(game, humanPlayer.id);

        expect(summary.used, expectedUsed);
        expect(summary.capacity, expectedCapacity);
        expect(summary.isCargoUsedReliable, isTrue);
      },
    );

    test('provider uses 0 used when map data is unavailable', () {
      final container = ProviderContainer(
        overrides: [gamesBoxProvider.overrideWith((ref) => box)],
      );
      addTearDown(container.dispose);

      final service = container.read(gameServiceProvider);
      final game = service.createNewGame(
        id: 'cargo_no_map',
        config: _tinyConfig(),
      );
      final gameWithoutCachedMap = game.copyWith(id: '${game.id}_missing_map');
      container
          .read(currentGameProvider.notifier)
          .setGame(gameWithoutCachedMap);

      final summary = container.read(homeFleetCargoSummaryProvider);
      final humanPlayer =
          gameWithoutCachedMap.players.where((p) => p.isHuman).firstOrNull ??
          gameWithoutCachedMap.players.first;
      expect(summary.used, 0);
      expect(
        summary.capacity,
        _homeFleetCapacity(gameWithoutCachedMap, humanPlayer.id),
      );
      expect(summary.isCargoUsedReliable, isTrue);
    });

    test(
      'provider marks cargo used unreliable and logs when map load throws',
      () {
        final adapter = GameSaveAdapter();
        final container = ProviderContainer(
          overrides: [
            gamesBoxProvider.overrideWith((ref) => box),
            gameSaveAdapterProvider.overrideWith((ref) => adapter),
            gameServiceProvider.overrideWith(
              (ref) => _ThrowingMapGameService(box, adapter),
            ),
          ],
        );
        addTearDown(container.dispose);

        final realService = GameService(box, adapter);
        final game = realService.createNewGame(
          id: 'cargo_throw',
          config: _tinyConfig(),
        );
        container.read(currentGameProvider.notifier).setGame(game);

        final summary = container.read(homeFleetCargoSummaryProvider);
        final humanPlayer =
            game.players.where((p) => p.isHuman).firstOrNull ??
            game.players.first;
        expect(summary.used, 0);
        expect(summary.capacity, _homeFleetCapacity(game, humanPlayer.id));
        expect(summary.isCargoUsedReliable, isFalse);
      },
    );
  });
}

int _homeFleetCapacity(Game game, String playerId) {
  final homeFleetId = homeFleetIdFor(playerId);
  final homeFleet = game.worldState.fleets
      .where((f) => f.id == homeFleetId && f.ownerId == playerId)
      .firstOrNull;
  if (homeFleet == null) return 0;
  var capacity = 0;
  for (final typeId in homeFleet.shipTypeIds) {
    capacity += NavalStatsCatalog.get(typeId).cargoHold;
  }
  return capacity;
}
