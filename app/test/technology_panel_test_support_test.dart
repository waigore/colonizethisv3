// Smoke tests for shared TechnologyPanel widget-test scaffolding (Refs #4035).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';

import 'support/panel_test_fixtures.dart';
import 'support/technology_panel_test_support.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'buildTechnologyPanel hosts TechnologyPanel inside editorial app shell',
    (WidgetTester tester) async {
      final game = buildTechnologyPanelTestGame();
      await tester.pumpWidget(
        buildTechnologyPanel(game: game, player: game.players.first),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(TechnologyPanel), findsOneWidget);
    },
  );

  testWidgets('pumpTechnologyPanel hosts and settles TechnologyPanel', (
    WidgetTester tester,
  ) async {
    final game = buildTechnologyPanelTestGame();
    await pumpTechnologyPanel(tester, game: game, player: game.players.first);
    expect(find.byType(TechnologyPanel), findsOneWidget);
  });
}
