import 'package:colonizethis_app/features/game/flame/game_map_area.dart';
import 'package:colonizethis_app/features/game/flame/game_region_minimap.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show
        kRegionMinimapCustomPaintKey,
        kRegionMinimapGestureKey,
        kRegionMinimapToggleKey,
        kRegionMinimapZoomSliderKey;
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  testWidgets('region minimap: toggle visibility and minimap bus pan', (
    WidgetTester tester,
  ) async {
    final init = getDebugInitGameResult();
    final game = init.game;
    final bus = AppEventBus.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEventBusProvider.overrideWith((ref) => bus),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GameMapArea(game: game, mapViewData: init.mapViewData),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byKey(kRegionMinimapCustomPaintKey), findsOneWidget);

    final minimap = tester.widget<GameRegionMinimap>(find.byType(GameRegionMinimap));
    expect(
      minimap.cellSizePx,
      init.mapViewData.oldWorld.cellSize.toDouble(),
      reason: 'minimap world scale must match CtRegionMap / RegionMapViewportSnapshot',
    );

    await tester.tap(find.byKey(kRegionMinimapToggleKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kRegionMinimapCustomPaintKey), findsNothing);

    await tester.tap(find.byKey(kRegionMinimapToggleKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kRegionMinimapCustomPaintKey), findsOneWidget);

    expect(tester.takeException(), isNull);
    bus.emit(
      const RequestRegionMapCameraPanWorldDeltaEvent(
        regionId: 'oldWorld',
        worldDx: 24,
        worldDy: 0,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byKey(kRegionMinimapGestureKey), findsOneWidget);
    expect(find.byKey(kRegionMinimapZoomSliderKey), findsOneWidget);

    bus.dispose();
  });
}
