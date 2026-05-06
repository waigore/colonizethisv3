import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show demoGameForOverlay;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_games_provider');
    await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  tearDownAll(() async {
    await Hive.box<dynamic>(HiveBoxNames.games).clear();
    await Hive.close();
    final dir = Directory('./.dart_tool/test_hive_games_provider');
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  test('gameListIdsProvider returns empty list when no games saved', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ids = await container.read(gameListIdsProvider.future);
    expect(ids, isEmpty);
  });

  test('availableWorkTargetIdsForUnitProvider returns empty when no current game', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(availableWorkTargetIdsForUnitProvider('u1')), isEmpty);
  });

  test('devExclusiveReservedWorkTileKeysProvider empty when no current game', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(devExclusiveReservedWorkTileKeysProvider), isEmpty);
  });

  test('derived providers compute with a real current game', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final gameService = container.read(gameServiceProvider);
    expect(gameService, isA<GameService>());

    final game = gameService.createNewGame(
      id: 'games_provider_derived',
      config: GameSetupConfig(
        selectedGreatPowerIds: const ['england', 'france'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 4,
        numProvincesNewWorld: 2,
      ),
    );
    container.read(currentGameProvider.notifier).setGame(game);

    final humanId = game.players.firstWhere((p) => p.isHuman).id;
    var anyUnitId = '';
    for (final u in game.worldState.oldWorld.units) {
      if (u.ownerId == humanId) {
        anyUnitId = u.id;
        break;
      }
    }
    if (anyUnitId.isNotEmpty) {
      expect(
        container.read(availableWorkTargetIdsForUnitProvider(anyUnitId)),
        isA<List<String>>(),
      );
    }
    final reserved = container.read(devExclusiveReservedWorkTileKeysProvider);
    expect(reserved, isA<Set<String>>());
  });

  test('gameIdsWithIntroShownProvider defaults empty and can be updated', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(gameIdsWithIntroShownProvider);
    expect(initial, isEmpty);

    container.read(gameIdsWithIntroShownProvider.notifier).markShown('game_1');

    final updated = container.read(gameIdsWithIntroShownProvider);
    expect(updated, contains('game_1'));
  });

  test('pendingDiplomacyProvider defaults null and can set overtures', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(pendingDiplomacyProvider), isNull);

    container.read(pendingDiplomacyProvider.notifier).setOvertures(const []);

    final updated = container.read(pendingDiplomacyProvider);
    expect(updated, isA<PendingDiplomacyOvertures>());
    expect((updated! as PendingDiplomacyOvertures).offers, isEmpty);
  });

  test('currentGameProvider setGame and clear update the state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(currentGameProvider.notifier);
    expect(container.read(currentGameProvider), isNull);

    notifier.setGame(demoGameForOverlay);
    expect(container.read(currentGameProvider)?.id, demoGameForOverlay.id);

    notifier.clear();
    expect(container.read(currentGameProvider), isNull);
  });

  test('currentOrdersProvider replaceAll and clear update the state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(currentOrdersProvider.notifier);
    expect(container.read(currentOrdersProvider), const Orders());

    const next = Orders(
      buildUnitOrdersByPlayerId: {
        'p1': [
          BuildUnitOrder(
            unitType: 'builder',
            isMilitary: false,
            spawnProvinceId: 'oldWorld|p1',
          ),
        ],
      },
    );
    notifier.replaceAll(next);
    expect(container.read(currentOrdersProvider), next);

    notifier.clear();
    expect(container.read(currentOrdersProvider), const Orders());
  });

  test('pendingDiplomacyProvider clear resets to null', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(pendingDiplomacyProvider.notifier);
    notifier.setOvertures(const []);
    expect(container.read(pendingDiplomacyProvider), isNotNull);

    notifier.clear();
    expect(container.read(pendingDiplomacyProvider), isNull);
  });

  test('setIntervention replaces overtures state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pendingDiplomacyProvider.notifier).setOvertures(const []);
    container.read(pendingDiplomacyProvider.notifier).setIntervention(const [
      InterventionPrompt(
        aggressorGpId: 'a',
        defenderMinorOrTribeId: 'm',
        interveningGpId: 'b',
      ),
    ]);
    final s = container.read(pendingDiplomacyProvider);
    expect(s, isA<PendingDiplomacyIntervention>());
    expect((s! as PendingDiplomacyIntervention).prompts, hasLength(1));
  });
}

