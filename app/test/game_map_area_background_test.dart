import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area_background.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for [GameMapAreaBackground] (issue #2861 R3).
void main() {
  suppressLogsForTests();

  testWidgets('paints bg-deep surface and grid custom paint layer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 192,
            child: GameMapAreaBackground(),
          ),
        ),
      ),
    );
    await tester.pump();

    final DecoratedBox surface = tester.widget<DecoratedBox>(
      find.byKey(GameMapAreaBackground.surfaceKey),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.color, EditorialMonoclePalette.bgDeep);

    expect(
      find.descendant(
        of: find.byType(GameMapAreaBackground),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(GameMapAreaBackground),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('grid painter uses 48 dp cell size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: GameMapAreaBackground.gridCellSize * 2,
            height: GameMapAreaBackground.gridCellSize * 2,
            child: GameMapAreaBackground(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(GameMapAreaBackground.gridCellSize, 48);
    expect(GameMapAreaBackground.gridOpacity, 0.6);
    expect(
      GameMapAreaBackground.gridLineColor,
      EditorialMonoclePalette.border.withValues(alpha: 0.08),
    );
  });
}
