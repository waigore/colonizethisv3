// Development shell map pause hold + CtRegionMap engine pause (Refs #4734 Slice G).
// Mount/unmount cycles: development_panel_lifecycle_test.dart.

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/flame/region_map/ct_region_map_game.dart';
import 'package:colonizethis_app/features/game/screens/development/development_shell_map_pause_scope.dart';
import 'package:colonizethis_app/providers/shell_main_map_pause_provider.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_region_map_test_support_core.dart';
import 'development_panel_lifecycle_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'DevelopmentShellMapPauseScope acquires and releases shell map pause hold (Refs #4687)',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(shellMainMapPauseHoldProvider), 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DevelopmentShellMapPauseScope(
            child: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      expect(container.read(shellMainMapPauseHoldProvider), 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(container.read(shellMainMapPauseHoldProvider), 0);
    },
  );

  testWidgets(
    'shell CtRegionMap pauses while shellMainMapPauseHoldProvider is held (Refs #4687)',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: SizedBox(
            width: 400,
            height: 300,
            child: CtRegionMap(
              region: ctRegionMapTestOldWorldRegion(),
              visibilityMode: CtMapVisibilityMode.playerConstrained,
              playerViewForResources: ctRegionMapTestPlayerView,
              enginePaused: container.read(shellMainMapPauseHoldProvider) > 0,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final CtRegionMapGame runningGame =
          developmentPanelSingleRegionMapGame(tester) as CtRegionMapGame;
      expect(runningGame.paused, isFalse);

      container.read(shellMainMapPauseHoldProvider.notifier).acquire();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: SizedBox(
            width: 400,
            height: 300,
            child: CtRegionMap(
              region: ctRegionMapTestOldWorldRegion(),
              visibilityMode: CtMapVisibilityMode.playerConstrained,
              playerViewForResources: ctRegionMapTestPlayerView,
              enginePaused: container.read(shellMainMapPauseHoldProvider) > 0,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        (developmentPanelSingleRegionMapGame(tester) as CtRegionMapGame).paused,
        isTrue,
      );

      container.read(shellMainMapPauseHoldProvider.notifier).release();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: SizedBox(
            width: 400,
            height: 300,
            child: CtRegionMap(
              region: ctRegionMapTestOldWorldRegion(),
              visibilityMode: CtMapVisibilityMode.playerConstrained,
              playerViewForResources: ctRegionMapTestPlayerView,
              enginePaused: container.read(shellMainMapPauseHoldProvider) > 0,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        (developmentPanelSingleRegionMapGame(tester) as CtRegionMapGame).paused,
        isFalse,
      );
    },
  );
}
