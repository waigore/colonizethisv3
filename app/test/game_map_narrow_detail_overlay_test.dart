import 'package:colonizethis_app/features/game/flame/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  testWidgets('GameMapNarrowDetailOverlay builds and close button calls onClose',
      (WidgetTester tester) async {
    final game = demoGameForOverlay;
    final region = demoRegionForOverlay;
    final selectedId = sampleProvinceIdForOverlay;

    var closed = false;

    const viewportHeight = 600.0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(400, viewportHeight)),
        child: MaterialApp(
          home: Scaffold(
            body: GameMapNarrowDetailOverlay(
              game: game,
              region: region,
              selectedId: selectedId,
              displayId: selectedId,
              humanPlayerId: game.players.first.id,
              hoveredTileKey: null,
              onHighlightTile: (_) {},
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GameMapNarrowDetailOverlay), findsOneWidget);
    expect(find.text('Province'), findsOneWidget);
    expect(find.byKey(const Key('overlay_close')), findsOneWidget);

    await tester.tap(find.byKey(const Key('overlay_close')));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('GameMapNarrowDetailOverlay is height constrained (narrow)',
      (WidgetTester tester) async {
    final game = demoGameForOverlay;
    final region = demoRegionForOverlay;
    final selectedId = sampleProvinceIdForOverlay;

    const viewportHeight = 600.0;
    final expectedMaxHeight = viewportHeight * 0.33;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(400, viewportHeight)),
        child: MaterialApp(
          home: Scaffold(
            body: GameMapNarrowDetailOverlay(
              game: game,
              region: region,
              selectedId: selectedId,
              displayId: selectedId,
              humanPlayerId: game.players.first.id,
              hoveredTileKey: null,
              onHighlightTile: (_) {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // The inner ProvinceSeaZoneDetailOverlay sets maxHeight based on MediaQuery width,
    // and GameMapNarrowDetailOverlay wraps it in a SizedBox at the same 0.33 factor.
    final constrained = find.byWidgetPredicate(
      (w) =>
          w is ConstrainedBox &&
          (w.constraints.maxHeight - expectedMaxHeight).abs() < 0.01,
    );
    expect(constrained, findsAtLeastNWidgets(1));
  });
}

