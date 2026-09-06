// Development panel lifecycle test helpers (Refs #4734 Slice G).

import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'development_panel_map_game_service.dart';

int countDevelopmentPanelRegionMapGameWidgets(WidgetTester tester) {
  return tester
      .widgetList(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString().startsWith('GameWidget<'),
        ),
      )
      .length;
}

dynamic developmentPanelSingleRegionMapGame(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (w) => w.runtimeType.toString().startsWith('GameWidget<'),
  );
  expect(finder, findsOneWidget);
  final gameWidget = tester.widget(finder);
  return (gameWidget as dynamic).game;
}

List<Override> developmentPanelLifecycleOverrides(
  Box<dynamic> gamesBox,
  Game game,
) => [
  gamesBoxProvider.overrideWith((ref) => gamesBox),
  gameServiceProvider.overrideWith(
    (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
  ),
  currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
  currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(const Orders())),
];
