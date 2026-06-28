// Widget tests pinning the wood-panel button hover state in the
// `CtMainMenu` `pixelArt` variant (Refs #2860 AC 7). Verifies the
// SPEC/ui/main-menu.md § Variant rendering hover ACs:
//
//   - On pointer enter: surface border shifts to `--accent`, brass corner
//     brackets brighten to `--accent-bright` × 1.0 alpha, engraved label
//     color resolves to `--accent-bright` while retaining the canonical
//     1 px downward `--surface` engrave shadow.
//   - On pointer exit: every property reverts to the rest variant
//     (`--border`, `--accent` × 0.75 alpha, label `--accent`).
//
// Mirrors the hover-state pinning already in
// `app/test/widgets/ct_nine_patch_button_dark_test.dart` for the bare
// `CtNinePatchButton`, but exercises the wood-panel call site so the AC
// is anchored at the screen contract level (`CtMainMenu`).
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';

/// Pumps a `CtMainMenu` configured for the `pixelArt` variant under the shared
/// editorial-monocle app shell so the wood-panel button hover state can be
/// inspected through the inner `CtNinePatchButton` widget.
Future<void> _pumpPixelArtMainMenu(WidgetTester tester) async {
  await pumpAppShell(
    tester,
    settle: true,
    child: CtMainMenu(
      variant: MainMenuVariant.pixelArt,
      state: MainMenuState.default_,
      version: 'v1.0.0',
      onNewGame: () {},
      onLoadGame: () {},
      onSettings: () {},
      onQuit: () {},
    ),
  );
}

/// Returns the `CtNinePatchButton` ancestor of the menu label [label].
Finder _woodPanelButtonFor(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(CtNinePatchButton),
  );
}

/// Returns the gradient-painting `DecoratedBox` painted by the
/// `CtNinePatchButton` whose label is [label]. The button paints exactly
/// one such box (the surface), so the finder is unambiguous.
DecoratedBox _findSurfaceBoxFor(WidgetTester tester, String label) {
  final Finder boxes = find.descendant(
    of: _woodPanelButtonFor(label),
    matching: find.byWidgetPredicate(
      (Widget w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).gradient != null,
    ),
  );
  expect(
    boxes,
    findsAtLeastNWidgets(1),
    reason:
        'Wood-panel button "$label" must paint a gradient surface DecoratedBox',
  );
  return tester.widget<DecoratedBox>(boxes.first);
}

/// Returns the engraved label `RichText` rendered inside the
/// `CtNinePatchButton` whose label is [label].
RichText _findLabelRichTextFor(WidgetTester tester, String label) {
  return tester.widget<RichText>(
    find.descendant(of: find.text(label), matching: find.byType(RichText)),
  );
}

/// Returns the `_BrassCornerBracketsPainter` instance currently driving the
/// brass-bracket overlay of the `CtNinePatchButton` whose label is [label].
/// The painter is private; we identify it by its `runtimeType` string so the
/// test does not need to import the symbol.
CustomPainter _findBrassPainterFor(WidgetTester tester, String label) {
  final Finder painters = find.descendant(
    of: _woodPanelButtonFor(label),
    matching: find.byWidgetPredicate(
      (Widget w) =>
          w is CustomPaint &&
          w.painter != null &&
          w.painter.runtimeType.toString() == '_BrassCornerBracketsPainter',
    ),
  );
  expect(
    painters,
    findsOneWidget,
    reason:
        'Wood-panel button "$label" must paint a single brass-corner-brackets '
        'overlay (CustomPaint with _BrassCornerBracketsPainter).',
  );
  final CustomPaint paint = tester.widget<CustomPaint>(painters);
  return paint.painter!;
}

/// Reads the `color` field off the brass-bracket painter via `toString()`.
/// The painter is private (`_BrassCornerBracketsPainter` in
/// `ct_nine_patch_button.dart`) and exposes its color only through its
/// `paint(...)` call; we parse the painter's debug string which embeds the
/// `color: Color(...)` value the painter holds. Falls back to the painted
/// canvas only if the debug string does not encode the color.
///
/// Returning a `Color?` lets the test assert the color shifted, even though
/// we cannot reach the private field directly.
Color? _brassColorFromPainter(CustomPainter painter) {
  // The painter's runtimeType already pins the class identity above; we now
  // inspect the painter's `toString()` debug representation, which Dart
  // generates from the class name. Since `_BrassCornerBracketsPainter`
  // overrides `shouldRepaint` but not `toString`, the default representation
  // is just the class name — which means we cannot extract the color this
  // way. Instead, paint into a recording canvas and capture the first paint
  // call's color via a tiny shim.
  final _ColorRecordingCanvas canvas = _ColorRecordingCanvas();
  painter.paint(canvas, const Size(120, 48));
  return canvas.firstColor;
}

/// Minimal `Canvas` shim that records the color of the first `drawRect`
/// invocation. Sufficient for `_BrassCornerBracketsPainter.paint`, which
/// uses a single `Paint` instance for every rect.
class _ColorRecordingCanvas implements Canvas {
  Color? firstColor;

  @override
  void drawRect(Rect rect, Paint paint) {
    firstColor ??= paint.color;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<TestGesture> _addMousePointer(WidgetTester tester) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  addTearDown(gesture.removePointer);
  await gesture.addPointer(location: const Offset(-1000, -1000));
  await tester.pump();
  return gesture;
}

/// Pumps enough frames for [CtNinePatchButton.animationDuration] (120 ms)
/// hover color animation to finish. We intentionally avoid
/// `pumpAndSettle()` here because the `_PixelArtButton` wood-panel wrapper
/// drives an **infinite** bob animation (`_bobController.repeat(reverse:
/// true)`) on hover-enter, and `pumpAndSettle()` would block indefinitely
/// waiting for that infinite controller to stop.
Future<void> _settleHoverColorAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(CtNinePatchButton.animationDuration);
  await tester.pump(const Duration(milliseconds: 16));
}

/// Pumps frames after a hover-exit. The wood-panel bob controller is
/// `stop()` + `reset()`-ed inside the exit handler, so once the color
/// animation has run for [CtNinePatchButton.animationDuration]
/// `pumpAndSettle()` is safe again.
Future<void> _settleHoverExitAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(CtNinePatchButton.animationDuration);
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'CtMainMenu pixelArt wood-panel button hover state '
    '(SPEC/ui/main-menu.md § Variant rendering hover ACs; Refs #2860 AC 7)',
    () {
      testWidgets(
        'hovering the New Game wood-panel button shifts the surface border to '
        '--accent and brightens the brass corner brackets to --accent-bright '
        'at hover alpha (border accent strengthens + corners brighten)',
        (WidgetTester tester) async {
          await _pumpPixelArtMainMenu(tester);

          // Rest-state baseline: border resolves to --border, brass painter
          // paints --accent at the default 0.75 alpha.
          final DecoratedBox restSurface = _findSurfaceBoxFor(
            tester,
            'New Game',
          );
          final Border restBorder =
              (restSurface.decoration as BoxDecoration).border! as Border;
          expect(restBorder.top.color, EditorialMonoclePalette.border);

          final Color? restBrass = _brassColorFromPainter(
            _findBrassPainterFor(tester, 'New Game'),
          );
          expect(restBrass, isNotNull);
          expect(
            restBrass!.r,
            closeTo(EditorialMonoclePalette.accent.r, 0.001),
            reason: 'Rest brass-bracket red channel must match --accent',
          );
          expect(
            restBrass.a,
            closeTo(CtNinePatchButton.defaultCornerAlpha, 0.001),
            reason:
                'Rest brass-bracket alpha must equal '
                'CtNinePatchButton.defaultCornerAlpha (0.75)',
          );

          // Drive a mouse pointer into the center of the New Game button so
          // the inner CtNinePatchButton's MouseRegion fires onEnter.
          final TestGesture gesture = await _addMousePointer(tester);
          final Offset center = tester.getCenter(
            _woodPanelButtonFor('New Game'),
          );
          await gesture.moveTo(center);
          await _settleHoverColorAnimation(tester);

          final DecoratedBox hoverSurface = _findSurfaceBoxFor(
            tester,
            'New Game',
          );
          final Border hoverBorder =
              (hoverSurface.decoration as BoxDecoration).border! as Border;
          expect(
            hoverBorder.top.color,
            EditorialMonoclePalette.accent,
            reason:
                'Hover state must shift the surface border from --border to '
                '--accent (mockup .menu-btn:hover { border-color: var(--accent) })',
          );

          final Color? hoverBrass = _brassColorFromPainter(
            _findBrassPainterFor(tester, 'New Game'),
          );
          expect(hoverBrass, isNotNull);
          expect(
            hoverBrass!.r,
            closeTo(EditorialMonoclePalette.accentBright.r, 0.001),
            reason:
                'Hover brass-bracket red channel must match --accent-bright',
          );
          expect(
            hoverBrass.a,
            closeTo(CtNinePatchButton.hoverCornerAlpha, 0.001),
            reason:
                'Hover brass-bracket alpha must equal '
                'CtNinePatchButton.hoverCornerAlpha (1.0)',
          );
        },
      );

      testWidgets(
        'hovering the New Game wood-panel button brightens the engraved '
        'label color to --accent-bright while preserving the 1 px downward '
        '--surface engrave shadow',
        (WidgetTester tester) async {
          await _pumpPixelArtMainMenu(tester);

          // Rest-state baseline: engraved label resolves to --accent and
          // carries exactly one 1 px downward --surface shadow.
          final RichText restLabel = _findLabelRichTextFor(tester, 'New Game');
          final TextSpan restSpan = restLabel.text as TextSpan;
          expect(restSpan.style?.color, EditorialMonoclePalette.accent);
          final List<Shadow>? restShadows = restSpan.style?.shadows;
          expect(restShadows, isNotNull);
          expect(restShadows!.length, 1);
          expect(restShadows.first.offset, CtNinePatchButton.engravedShadowOffset);
          expect(restShadows.first.blurRadius, 0);
          expect(restShadows.first.color, EditorialMonoclePalette.surface);

          final TestGesture gesture = await _addMousePointer(tester);
          final Offset center = tester.getCenter(
            _woodPanelButtonFor('New Game'),
          );
          await gesture.moveTo(center);
          await _settleHoverColorAnimation(tester);

          final RichText hoverLabel = _findLabelRichTextFor(
            tester,
            'New Game',
          );
          final TextSpan hoverSpan = hoverLabel.text as TextSpan;
          expect(
            hoverSpan.style?.color,
            EditorialMonoclePalette.accentBright,
            reason:
                'Hover state must shift the engraved label color from '
                '--accent to --accent-bright (mockup .menu-btn:hover { '
                'color: var(--accent-bright) })',
          );

          final List<Shadow>? hoverShadows = hoverSpan.style?.shadows;
          expect(
            hoverShadows,
            isNotNull,
            reason:
                'Engraved label shadow must persist across hover (mockup '
                'retains the recessed 1 px downward shadow)',
          );
          expect(hoverShadows!.length, 1);
          expect(
            hoverShadows.first.offset,
            CtNinePatchButton.engravedShadowOffset,
          );
          expect(hoverShadows.first.blurRadius, 0);
          expect(
            hoverShadows.first.color,
            EditorialMonoclePalette.surface,
            reason:
                'Engrave shadow must remain --surface even when the label '
                'foreground brightens',
          );
        },
      );

      testWidgets(
        'hover state is strictly transient: moving the pointer off the '
        'wood-panel button reverts border to --border, brass corners to '
        '--accent × 0.75 alpha, and label color back to --accent',
        (WidgetTester tester) async {
          await _pumpPixelArtMainMenu(tester);

          final TestGesture gesture = await _addMousePointer(tester);
          final Offset center = tester.getCenter(
            _woodPanelButtonFor('New Game'),
          );
          await gesture.moveTo(center);
          await _settleHoverColorAnimation(tester);

          // Sanity: hover state was reached before we move off.
          final Border hoverBorder =
              (_findSurfaceBoxFor(tester, 'New Game').decoration
                      as BoxDecoration)
                  .border!
              as Border;
          expect(hoverBorder.top.color, EditorialMonoclePalette.accent);

          // Move the pointer well outside the menu. The bob controller is
          // stopped+reset on exit so pumpAndSettle() is safe again.
          await gesture.moveTo(const Offset(-1000, -1000));
          await _settleHoverExitAnimation(tester);

          final DecoratedBox restSurface = _findSurfaceBoxFor(
            tester,
            'New Game',
          );
          final Border restBorder =
              (restSurface.decoration as BoxDecoration).border! as Border;
          expect(
            restBorder.top.color,
            EditorialMonoclePalette.border,
            reason:
                'After the pointer leaves, the border must revert to '
                '--border (hover is strictly transient).',
          );

          final Color? restBrass = _brassColorFromPainter(
            _findBrassPainterFor(tester, 'New Game'),
          );
          expect(restBrass, isNotNull);
          expect(
            restBrass!.r,
            closeTo(EditorialMonoclePalette.accent.r, 0.001),
            reason:
                'After hover ends, brass-bracket red channel must revert '
                'to --accent',
          );
          expect(
            restBrass.a,
            closeTo(CtNinePatchButton.defaultCornerAlpha, 0.001),
            reason:
                'After hover ends, brass-bracket alpha must revert to '
                'CtNinePatchButton.defaultCornerAlpha (0.75)',
          );

          final RichText restLabel = _findLabelRichTextFor(tester, 'New Game');
          final TextSpan restSpan = restLabel.text as TextSpan;
          expect(
            restSpan.style?.color,
            EditorialMonoclePalette.accent,
            reason:
                'After hover ends, the engraved label color must revert '
                'to --accent',
          );
        },
      );
    },
  );
}
