// Pins the dark editorial-monocle chrome contract for
// GameMapCornerControls (Refs #2861 R5 / S4). SPEC: SPEC/ui/empire-overview.md
// § Corner controls chrome (dark editorial-monocle).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_map_corner_controls_dark_chrome_disabled_test.dart'
    show gameMapCornerControlsWrap;

void main() {
  suppressLogsForTests();

  group('GameMapCornerControls dark editorial-monocle chrome (Refs #2861 S4)', () {
    testWidgets(
      'positive: default state — gradient surface + 32 dp size + 1 px border + full-colour glyph (no srcIn tint)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          gameMapCornerControlsWrap(
            child: GameMapCornerControls(
              onCycleBaseLayerDisplayMode: () {},
              onCenterOnHomeCapital: () {},
              onOpenMapDisplayOptions: () {},
            ),
          ),
        );
        await tester.pump();

        final baseFinder = find.byKey(kBaseLayerCycleButtonKey);
        expect(baseFinder, findsOneWidget);

        final size = tester.getSize(baseFinder);
        expect(size.width, GameMapCornerControls.buttonSize);
        expect(size.height, GameMapCornerControls.buttonSize);

        final AnimatedContainer container = tester.widget(
          find.descendant(
            of: baseFinder,
            matching: find.byType(AnimatedContainer),
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, CtGradients.railButtonGradient);
        final border = decoration.border as Border;
        expect(border.top.color, EditorialMonoclePalette.border);
        expect(border.top.width, 1);
        expect(border.bottom.color, EditorialMonoclePalette.border);
        expect(border.left.color, EditorialMonoclePalette.border);
        expect(border.right.color, EditorialMonoclePalette.border);

        expect(
          find.descendant(of: baseFinder, matching: find.byType(ColorFiltered)),
          findsNothing,
        );

        final StrictAssetIcon icon = tester.widget(
          find.descendant(
            of: baseFinder,
            matching: find.byType(StrictAssetIcon),
          ),
        );
        expect(icon.width, GameMapCornerControls.iconSize);
        expect(icon.height, GameMapCornerControls.iconSize);
      },
    );

    testWidgets(
      'positive: hover lifts border to --accent-dim and leaves the full-colour glyph unrecoloured',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          gameMapCornerControlsWrap(
            child: GameMapCornerControls(
              onCycleBaseLayerDisplayMode: () {},
              onCenterOnHomeCapital: () {},
              onOpenMapDisplayOptions: () {},
            ),
          ),
        );
        await tester.pump();

        final baseFinder = find.byKey(kBaseLayerCycleButtonKey);
        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(baseFinder));
        await tester.pumpAndSettle();

        final AnimatedContainer hoveredContainer = tester.widget(
          find.descendant(
            of: baseFinder,
            matching: find.byType(AnimatedContainer),
          ),
        );
        final hoveredDecoration = hoveredContainer.decoration as BoxDecoration;
        final hoveredBorder = hoveredDecoration.border as Border;
        expect(hoveredBorder.top.color, EditorialMonoclePalette.accentDim);

        expect(
          find.descendant(of: baseFinder, matching: find.byType(ColorFiltered)),
          findsNothing,
        );

        await gesture.moveTo(Offset.zero);
        await tester.pumpAndSettle();

        final AnimatedContainer restoredContainer = tester.widget(
          find.descendant(
            of: baseFinder,
            matching: find.byType(AnimatedContainer),
          ),
        );
        final restoredBorder =
            (restoredContainer.decoration as BoxDecoration).border as Border;
        expect(restoredBorder.top.color, EditorialMonoclePalette.border);
      },
    );

    testWidgets(
      'negative regression guard: no Material(color: Colors.white …) and no Material button chrome inside the row',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          gameMapCornerControlsWrap(
            child: GameMapCornerControls(
              onCycleBaseLayerDisplayMode: () {},
              onCenterOnHomeCapital: () {},
              onOpenMapDisplayOptions: () {},
            ),
          ),
        );
        await tester.pump();

        final row = find.byType(GameMapCornerControls);
        final List<Material> materials = tester
            .widgetList<Material>(
              find.descendant(of: row, matching: find.byType(Material)),
            )
            .toList();
        expect(materials.isNotEmpty, isTrue);
        for (final m in materials) {
          expect(m.color, isNot(Colors.white));
          if (m.color != null) {
            expect(m.color, Colors.transparent);
          }
        }

        expect(
          find.descendant(of: row, matching: find.byType(ElevatedButton)),
          findsNothing,
        );
        expect(
          find.descendant(of: row, matching: find.byType(FilledButton)),
          findsNothing,
        );
        expect(
          find.descendant(of: row, matching: find.byType(OutlinedButton)),
          findsNothing,
        );
        expect(
          find.descendant(of: row, matching: find.byType(IconButton)),
          findsNothing,
        );
      },
    );
  });
}
