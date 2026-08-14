// Shared GameTopBar host for chrome/layout widget tests (Refs #4352 Slice D).
// SPEC: SPEC/ui/game-screen.md; SPEC/ui/in-game-shell-narrow.md.

import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
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
