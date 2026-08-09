// Smoke tests for the shared 320 dp dialog pump harness (Refs #4117 slice F).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('pumpDialogs320At hosts dialog in editorial-monocle shell', (
    WidgetTester tester,
  ) async {
    late ThemeData observedTheme;

    await pumpDialogs320At(
      tester,
      size: kDialogs320MinViewport,
      Builder(
        builder: (context) {
          observedTheme = Theme.of(context);
          return const Text('dialog-body');
        },
      ),
    );

    expect(find.text('dialog-body'), findsOneWidget);
    expect(observedTheme.colorScheme, AppThemes.editorialMonocle.colorScheme);
    expect(tester.takeException(), isNull);
  });

  test('buildThreeGpDialogueOverlayGame resolves human and ally names', () {
    final game = buildThreeGpDialogueOverlayGame();

    expect(game.players.length, 3);
    expect(game.players.firstWhere((p) => p.isHuman).displayName, 'Player');
    expect(
      game.players.firstWhere((p) => p.id == 'gp_portugal').displayName,
      'Portugal',
    );
  });
}
