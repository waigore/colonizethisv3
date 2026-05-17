import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

GameSetupConfig _tinyProviderConfig() => GameSetupConfig(
      selectedGreatPowerIds: ['england', 'france'],
      continentCount: 1,
      minorNationCount: 0,
      tribeCount: 1,
      numProvincesOldWorld: 4,
      numProvincesNewWorld: 2,
    );

void main() {
  suppressLogsForTests();

  late Directory dir;
  late Box<dynamic> box;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ct_app_provider_wf_');
    Hive.init(dir.path);
    box = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('mapViewData and per-unit work targets populate after createNewGame', () {
    final service = GameService(box, GameSaveAdapter());
    final game = service.createNewGame(id: 'wf_map', config: _tinyProviderConfig());

    final container = ProviderContainer(
      overrides: [
        gamesBoxProvider.overrideWith((ref) => box),
        gameServiceProvider.overrideWith((ref) => service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentGameProvider.notifier).setGame(game);

    expect(container.read(mapViewDataProvider), isNotNull);
    final humanId = game.players.firstWhere((p) => p.isHuman).id;
    Unit? ownedUnit;
    for (final u in game.worldState.oldWorld.units) {
      if (u.ownerId == humanId) {
        ownedUnit = u;
        break;
      }
    }
    if (ownedUnit != null) {
      expect(
        container.read(availableWorkTargetIdsForUnitProvider(ownedUnit.id)),
        isA<List<String>>(),
      );
    }
  });

  test('mapViewData uses first player when no human is flagged', () {
    final service = GameService(box, GameSaveAdapter());
    final game = service.createNewGame(id: 'wf_ai', config: _tinyProviderConfig());
    final allAi = game.copyWith(
      players: [
        for (final p in game.players) p.copyWith(isHuman: false),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        gamesBoxProvider.overrideWith((ref) => box),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentGameProvider.notifier).setGame(allAi);

    expect(container.read(mapViewDataProvider), isNotNull);
  });
}
