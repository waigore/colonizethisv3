// Pins the dark editorial-monocle chrome contract for
// GameMapCornerControls (Refs #2861 R5 / S4). SPEC: SPEC/ui/empire-overview.md
// § Corner controls chrome (dark editorial-monocle).

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/game_map_corner_controls.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({
  required Widget child,
}) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: Align(alignment: Alignment.bottomLeft, child: child)),
  );
}

void main() {
  suppressLogsForTests();

  // Intentionally do not stub the asset bundle here: when the icon PNGs
  // are absent the inner StrictAssetIcon throws via its errorBuilder. We
  // assert chrome via the AnimatedContainer decoration and via the icon
  // tint (ColorFiltered + StrictAssetIcon args) without forcing image
  // decoding. The widget tree is still constructed end-to-end.
  group(
    'GameMapCornerControls dark editorial-monocle chrome (Refs #2861 S4)',
    () {
      testWidgets('positive: default state — gradient surface + 32 dp size + 1 px border in the canonical token', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
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

        // Glyph tint resolves through ColorFiltered to --accent-dim.
        final ColorFiltered tint = tester.widget(
          find.descendant(of: baseFinder, matching: find.byType(ColorFiltered)),
        );
        expect(
          tint.colorFilter,
          ColorFilter.mode(
            EditorialMonoclePalette.accentDim,
            BlendMode.srcIn,
          ),
        );

        // Icon size matches mockup `.corner-btn img { 22 × 22 }`.
        final StrictAssetIcon icon = tester.widget(
          find.descendant(
            of: baseFinder,
            matching: find.byType(StrictAssetIcon),
          ),
        );
        expect(icon.width, GameMapCornerControls.iconSize);
        expect(icon.height, GameMapCornerControls.iconSize);
      });

      testWidgets('positive: hover lifts border to --accent-dim and glyph to --accent-bright', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
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
        final hoveredDecoration =
            hoveredContainer.decoration as BoxDecoration;
        final hoveredBorder = hoveredDecoration.border as Border;
        expect(hoveredBorder.top.color, EditorialMonoclePalette.accentDim);

        final ColorFiltered hoveredTint = tester.widget(
          find.descendant(of: baseFinder, matching: find.byType(ColorFiltered)),
        );
        expect(
          hoveredTint.colorFilter,
          ColorFilter.mode(
            EditorialMonoclePalette.accentBright,
            BlendMode.srcIn,
          ),
        );

        // Move the pointer away — chrome returns to the default state.
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
      });

      testWidgets('positive: home-to-capital disabled wraps the surface in IgnorePointer + Opacity(0.4)', (
        WidgetTester tester,
      ) async {
        var homeCalls = 0;
        await tester.pumpWidget(
          _wrap(
            child: GameMapCornerControls(
              onCycleBaseLayerDisplayMode: () {},
              onCenterOnHomeCapital: () => homeCalls++,
              onOpenMapDisplayOptions: () {},
              homeToCapitalEnabled: false,
            ),
          ),
        );
        await tester.pump();

        final homeFinder = find.byKey(kHomeToCapitalButtonKey);
        expect(homeFinder, findsOneWidget);

        // The disabled chrome wraps the surface in IgnorePointer + Opacity(0.4).
        final Opacity opacity = tester.widget(
          find.ancestor(of: homeFinder, matching: find.byType(Opacity)).first,
        );
        expect(opacity.opacity, 0.4);
        expect(
          tester
              .widgetList<IgnorePointer>(
                find.ancestor(
                  of: homeFinder,
                  matching: find.byType(IgnorePointer),
                ),
              )
              .any((ip) => ip.ignoring),
          isTrue,
        );

        await tester.tap(homeFinder, warnIfMissed: false);
        await tester.pump();
        expect(homeCalls, 0);

        // The underlying border + tint still resolve in the default state.
        final AnimatedContainer container = tester.widget(
          find.descendant(
            of: homeFinder,
            matching: find.byType(AnimatedContainer),
          ),
        );
        final border = (container.decoration as BoxDecoration).border as Border;
        expect(border.top.color, EditorialMonoclePalette.border);
        final ColorFiltered tint = tester.widget(
          find.descendant(of: homeFinder, matching: find.byType(ColorFiltered)),
        );
        expect(
          tint.colorFilter,
          ColorFilter.mode(
            EditorialMonoclePalette.accentDim,
            BlendMode.srcIn,
          ),
        );
      });

      testWidgets('negative regression guard: no Material(color: Colors.white …) and no Material button chrome inside the row', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            child: GameMapCornerControls(
              onCycleBaseLayerDisplayMode: () {},
              onCenterOnHomeCapital: () {},
              onOpenMapDisplayOptions: () {},
            ),
          ),
        );
        await tester.pump();

        final row = find.byType(GameMapCornerControls);
        // No Material widget under the row paints with a hard-coded
        // light-theme background (Colors.white). Pointer plumbing still
        // uses InkWell under a transparent Material, which is allowed.
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

        // None of the banned Material button chrome widgets paint inside
        // the corner row (Material design ban per pixel-art-ui-catalog.md).
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
      });
    },
  );
}
