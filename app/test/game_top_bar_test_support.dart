// Shared GameTopBar host for chrome/layout widget tests (Refs #4352 Slice D).
// SPEC: SPEC/ui/game-screen.md; SPEC/ui/in-game-shell-narrow.md.

import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kNextTurnDisabledOpacity;
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void gameTopBarNoop() {}

Widget buildGameTopBarHost({
  required VoidCallback onToggleSideMenu,
  VoidCallback onPausePressed = gameTopBarNoop,
  required Future<void> Function() onNextTurn,
  required bool nextTurnEnabled,
  String turnDisplayText = 'Turn 42 / Year 1650',
  required String nextTurnText,
  String menuTooltip = 'Menu',
  String pauseTooltip = 'Pause menu',
  String? observeBannerLabel,
  double hostWidth = 600,
}) {
  return buildAppShell(
    viewport: Size(hostWidth, 200),
    child: Scaffold(
      body: SizedBox(
        width: hostWidth,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            GameTopBar(
              onToggleSideMenu: onToggleSideMenu,
              onPausePressed: onPausePressed,
              onNextTurn: onNextTurn,
              nextTurnEnabled: nextTurnEnabled,
              turnDisplayText: turnDisplayText,
              nextTurnText: nextTurnText,
              menuTooltip: menuTooltip,
              pauseTooltip: pauseTooltip,
              observeBannerLabel: observeBannerLabel,
            ),
          ],
        ),
      ),
    ),
  );
}

BoxDecoration gameTopBarSurfaceDecoration(WidgetTester tester) {
  final decoratedBox = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byKey(GameTopBar.surfaceKey),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return decoratedBox.decoration as BoxDecoration;
}

void expectGameTopBarGradientAndBorder(WidgetTester tester) {
  final decoration = gameTopBarSurfaceDecoration(tester);
  expect(decoration.gradient, isA<LinearGradient>());
  expect(
    (decoration.gradient! as LinearGradient).colors,
    CtGradients.topBarGradient.colors,
  );
  final border = decoration.border as Border;
  expect(border.bottom.width, GameTopBar.borderWidth);
  expect(border.bottom.color, EditorialMonoclePalette.accentDim);
  expect(border.top, BorderSide.none);
  expect(border.left, BorderSide.none);
  expect(border.right, BorderSide.none);
}

Finder gameTopBarNextTurnDisabledOpacityFinder() {
  return find.descendant(
    of: find.byKey(kGameMapNextTurnButtonKey),
    matching: find.byWidgetPredicate(
      (Widget w) => w is Opacity && w.opacity == kNextTurnDisabledOpacity,
    ),
  );
}

Finder gameTopBarNextTurnDimmingOpacityFinder() {
  return find.descendant(
    of: find.byKey(kGameMapNextTurnButtonKey),
    matching: find.byWidgetPredicate(
      (Widget w) =>
          w is Opacity &&
          (w.opacity == kNextTurnDisabledOpacity ||
              w.opacity == CtNinePatchButton.disabledOpacity),
    ),
  );
}
