import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_games_provider');
    await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  test('gameListIdsProvider returns empty list when no games saved', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ids = await container.read(gameListIdsProvider.future);
    expect(ids, isEmpty);
  });

  test('availableWorkTargetsProvider returns empty map when no current game', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final targets = container.read(availableWorkTargetsProvider);
    expect(targets, isEmpty);
  });

  test('gameIdsWithIntroShownProvider defaults empty and can be updated', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(gameIdsWithIntroShownProvider);
    expect(initial, isEmpty);

    container.read(gameIdsWithIntroShownProvider.notifier).state = {'game_1'};

    final updated = container.read(gameIdsWithIntroShownProvider);
    expect(updated, contains('game_1'));
  });

  test('pendingOverturesProvider defaults null and can be updated', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(pendingOverturesProvider);
    expect(initial, isNull);

    container.read(pendingOverturesProvider.notifier).state = const [];

    final updated = container.read(pendingOverturesProvider);
    expect(updated, isNotNull);
    expect(updated, isEmpty);
  });
}

