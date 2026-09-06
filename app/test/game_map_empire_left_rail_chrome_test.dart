import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'panel_test_fixtures.dart';
import 'app_test_hive_harness.dart';
import 'game_map_empire_left_rail_test_support.dart';

/// Tests for the dark editorial-monocle chrome contract on
/// [GameMapEmpireLeftRail] (issue #2861 S3 / R4).
void main() {
  suppressLogsForTests();

  late Game game;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    game = buildPanelTestGame();
    gamesBox = await openAppTestHiveBox(suiteId: 'empire_rail_chrome');
  });

  testWidgets('Rail buttons paint a 36 x 36 dp surface', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(game: game, gamesBox: gamesBox),
    );
    await tester.pumpAndSettle();

    expect(GameMapEmpireLeftRail.buttonSize, 36.0);
    for (final key in empireLeftRailButtonKeys) {
      final size = tester.getSize(find.byKey(key));
      expect(
        size.width,
        36.0,
        reason: 'Rail button $key must paint a 36 dp wide tap target',
      );
      expect(
        size.height,
        36.0,
        reason: 'Rail button $key must paint a 36 dp tall tap target',
      );
    }
  });

  testWidgets('Rail buttons paint a 24 x 24 dp icon glyph', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(game: game, gamesBox: gamesBox),
    );
    await tester.pumpAndSettle();

    expect(GameMapEmpireLeftRail.iconSize, 24.0);
    for (final key in empireLeftRailButtonKeys) {
      final iconFinder = find.descendant(
        of: find.byKey(key),
        matching: find.byType(StrictAssetIcon),
      );
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<StrictAssetIcon>(iconFinder);
      expect(icon.width, 24.0, reason: 'Rail icon for $key must be 24 dp wide');
      expect(
        icon.height,
        24.0,
        reason: 'Rail icon for $key must be 24 dp tall',
      );
    }
  });

  testWidgets(
    'Idle rail button paints the dark surfaceLite -> bgDeep gradient and 1 dp border',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        empireLeftRailScaffold(game: game, gamesBox: gamesBox),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byKey(kEmpireProductionButtonKey),
        matching: find.byType(AnimatedContainer),
      );
      expect(containerFinder, findsOneWidget);
      final container = tester.widget<AnimatedContainer>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      final expectedGradient = CtGradients.railButtonGradient;
      final actualGradient = decoration.gradient as LinearGradient;
      expect(actualGradient.colors[0], expectedGradient.colors[0]);
      expect(actualGradient.colors[1], expectedGradient.colors[1]);
      expect(actualGradient.colors[0], EditorialMonoclePalette.surfaceLite);
      expect(actualGradient.colors[1], EditorialMonoclePalette.bgDeep);

      final border = decoration.border as Border;
      expect(border.top.color, EditorialMonoclePalette.border);
      expect(border.top.width, 1.0);
      expect(border.bottom.color, EditorialMonoclePalette.border);
      expect(border.left.color, EditorialMonoclePalette.border);
      expect(border.right.color, EditorialMonoclePalette.border);
    },
  );

  testWidgets('Hover lifts border color from --border to --accent-dim', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(game: game, gamesBox: gamesBox),
    );
    await tester.pumpAndSettle();

    final containerFinder = find.descendant(
      of: find.byKey(kEmpireProductionButtonKey),
      matching: find.byType(AnimatedContainer),
    );
    expect(containerFinder, findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(kEmpireProductionButtonKey)),
    );
    await tester.pumpAndSettle();

    final hovered = tester.widget<AnimatedContainer>(containerFinder);
    final border = (hovered.decoration as BoxDecoration).border as Border;
    expect(
      border.top.color,
      EditorialMonoclePalette.accentDim,
      reason: 'Hover should lift the border color to --accent-dim',
    );
  });

  testWidgets(
    'Rail button icon glyphs render without srcIn ColorFiltered tint',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        empireLeftRailScaffold(game: game, gamesBox: gamesBox),
      );
      await tester.pumpAndSettle();

      for (final key in empireLeftRailButtonKeys) {
        final filterFinder = find.descendant(
          of: find.byKey(key),
          matching: find.byType(ColorFiltered),
        );
        expect(
          filterFinder,
          findsNothing,
          reason: 'Rail button $key must not apply a srcIn tint over the icon',
        );
        final iconFinder = find.descendant(
          of: find.byKey(key),
          matching: find.byType(StrictAssetIcon),
        );
        expect(iconFinder, findsOneWidget);
      }
    },
  );

  testWidgets('Hover lifts border but does not add icon glyph tint', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(game: game, gamesBox: gamesBox),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(kEmpireProductionButtonKey)),
    );
    await tester.pumpAndSettle();

    final filterFinder = find.descendant(
      of: find.byKey(kEmpireProductionButtonKey),
      matching: find.byType(ColorFiltered),
    );
    expect(
      filterFinder,
      findsNothing,
      reason:
          'Hover affordance must not recolour the icon glyph via srcIn tint',
    );
    final containerFinder = find.descendant(
      of: find.byKey(kEmpireProductionButtonKey),
      matching: find.byType(AnimatedContainer),
    );
    final border =
        (tester.widget<AnimatedContainer>(containerFinder).decoration
                    as BoxDecoration)
                .border
            as Border;
    expect(border.top.color, EditorialMonoclePalette.accentDim);
  });
}
