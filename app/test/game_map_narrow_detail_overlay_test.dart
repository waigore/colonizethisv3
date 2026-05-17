import 'package:colonizethis_app/features/game/flame/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'GameMapNarrowDetailOverlaySlot builds and close button closes via provider',
    (WidgetTester tester) async {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;

      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(400, 600));

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(400, 600)),
            child: MaterialApp(
              home: Scaffold(
                body: GameMapNarrowDetailOverlaySlot(
                  game: game,
                  region: region,
                  humanPlayerId: game.players.first.id,
                  playerView: demoHumanPlayerViewForOverlay,
                  workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
                ),
              ),
            ),
          ),
        ),
      );
      final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
      final container = ProviderScope.containerOf(ctx);
      container
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
      await tester.pumpAndSettle();

      expect(find.byType(GameMapNarrowDetailOverlaySlot), findsOneWidget);
      expect(find.text('Province'), findsOneWidget);
      expect(find.byKey(const Key('overlay_close')), findsOneWidget);

      await tester.tap(find.byKey(const Key('overlay_close')));
      await tester.pumpAndSettle();

      expect(container.read(mapProvincePanelProvider).overlayOpen, isFalse);
    },
  );

  testWidgets('GameMapNarrowDetailOverlaySlot is height constrained (narrow)', (
    WidgetTester tester,
  ) async {
    final game = demoGameForOverlay;
    final region = demoRegionForOverlay;

    const viewportHeight = 600.0;
    final expectedMaxHeight = viewportHeight * 0.33;

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, viewportHeight));

    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(size: Size(400, viewportHeight)),
          child: MaterialApp(
            home: Scaffold(
              body: GameMapNarrowDetailOverlaySlot(
                game: game,
                region: region,
                humanPlayerId: game.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
                workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
              ),
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
    final container = ProviderScope.containerOf(ctx);
    container
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
    await tester.pumpAndSettle();

    final constrained = find.byWidgetPredicate(
      (w) => w is SizedBox && (w.height! - expectedMaxHeight).abs() < 0.01,
    );
    expect(constrained, findsOneWidget);
  });
}
