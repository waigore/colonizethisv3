// Smoke tests for shared TradeScreen test hosts (Refs #3952).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('pumpTradeScreen mounts TradeScreen under editorial-monocle', (
    WidgetTester tester,
  ) async {
    await pumpTradeScreen(tester, game: buildTradeTestGame());

    expect(find.byType(TradeScreen), findsOneWidget);
    expect(find.byKey(TradeScreen.topBarKey), findsOneWidget);
    final CtTopBar topBar = tester.widget<CtTopBar>(
      find.byKey(TradeScreen.topBarKey),
    );
    expect(topBar.title, TradeScreen.topBarTitle);

    final ThemeData observedTheme = Theme.of(
      tester.element(find.byType(TradeScreen)),
    );
    expect(observedTheme.colorScheme, AppThemes.editorialMonocle.colorScheme);
  });

  testWidgets('pumpTradeScreenWithContainer returns a readable container', (
    WidgetTester tester,
  ) async {
    final container = await pumpTradeScreenWithContainer(
      tester,
      game: buildTradeTestGame(treasury: 100),
    );
    expect(find.byType(TradeScreen), findsOneWidget);
    expect(container.read, isNotNull);
  });

  test('buildTradeTestGame seeds cargo-10 home fleet when requested', () {
    final game = buildTradeTestGame(tradeCargoCapacityOverride: 10);
    expect(game.worldState.fleets, isNotEmpty);
    expect(game.worldState.oldWorld.provinces, isNotEmpty);
  });
}
