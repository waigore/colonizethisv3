// Panel-open availability latency for games_provider (Refs #2133 AC6 / #4720 Slice G).

import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:hive/hive.dart';

import 'games_provider_test_support.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await openAppTestHiveBox(suiteId: 'games_provider_latency');
  });

  tearDownAll(() async {
    await Hive.box<dynamic>(HiveBoxNames.games).clear();
    await Hive.close();
    final dir = Directory('./.dart_tool/test_hive_games_provider_latency');
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  test(
    'panel-open provider latency median stays within 1.5x from early to late fixture',
    () {
      const explorerId = 'explorer_1';
      const humanId = 'gp1';
      const startTileKey = 'oldWorld|p0|0|0';
      final earlyGame = gamesProviderExplorerFixture(
        id: 'games_provider_perf_early',
        provinceCount: 5,
        tilesPerProvince: 4,
      );
      final lateGame = gamesProviderExplorerFixture(
        id: 'games_provider_perf_late',
        provinceCount: 30,
        tilesPerProvince: 12,
      );

      final earlyContainer = gamesProviderTestContainer();
      earlyContainer.read(currentGameProvider.notifier).setGame(earlyGame);
      earlyContainer
          .read(currentOrdersProvider.notifier)
          .replaceAll(
            const Orders(
              workOrdersByPlayerId: {
                humanId: [
                  WorkOrder(
                    unitId: explorerId,
                    target: kWorkTargetExplore,
                    targetTileKey: startTileKey,
                  ),
                ],
              },
            ),
          );

      final lateContainer = gamesProviderTestContainer();
      lateContainer.read(currentGameProvider.notifier).setGame(lateGame);
      lateContainer
          .read(currentOrdersProvider.notifier)
          .replaceAll(
            const Orders(
              workOrdersByPlayerId: {
                humanId: [
                  WorkOrder(
                    unitId: explorerId,
                    target: kWorkTargetExplore,
                    targetTileKey: startTileKey,
                  ),
                ],
              },
            ),
          );

      for (var i = 0; i < 5; i++) {
        earlyContainer.read(availableWorkTargetIdsForUnitProvider(explorerId));
        lateContainer.read(availableWorkTargetIdsForUnitProvider(explorerId));
      }

      final earlyDurations = <Duration>[];
      final lateDurations = <Duration>[];
      for (var i = 0; i < 25; i++) {
        var sw = Stopwatch()..start();
        earlyContainer.read(availableWorkTargetIdsForUnitProvider(explorerId));
        sw.stop();
        earlyDurations.add(sw.elapsed);

        sw = Stopwatch()..start();
        lateContainer.read(availableWorkTargetIdsForUnitProvider(explorerId));
        sw.stop();
        lateDurations.add(sw.elapsed);
      }

      final earlyMedian = gamesProviderMedianDuration(earlyDurations);
      final lateMedian = gamesProviderMedianDuration(lateDurations);
      final denominator = earlyMedian.inMicroseconds == 0
          ? 1
          : earlyMedian.inMicroseconds;
      final ratio = lateMedian.inMicroseconds / denominator;

      expect(
        ratio,
        lessThanOrEqualTo(1.5),
        reason:
            'Late fixture panel-open availability should remain <=1.5x early '
            'fixture median latency (Refs #2133 AC6).',
      );
    },
  );
}
