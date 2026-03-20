import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
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

  test('mapViewData and availableWorkTargets populate after createNewGame', () {
    final service = GameService(box, GameSaveAdapter());
    final game = service.createNewGame(id: 'wf_map', config: _tinyProviderConfig());

    final container = ProviderContainer(
      overrides: [
        gamesBoxProvider.overrideWith((ref) => box),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentGameProvider.notifier).state = game;

    expect(container.read(mapViewDataProvider), isNotNull);
    expect(container.read(availableWorkTargetsProvider), isA<Map<String, List<String>>>());
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

    container.read(currentGameProvider.notifier).state = allAi;

    expect(container.read(mapViewDataProvider), isNotNull);
  });
}
