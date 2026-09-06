// Pin the 320 dp minimum-viewport contract for in-game unit panels (Refs #2870).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';
import 'unit_panels_320dp_min_viewport_cases.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late MapTopology topology;
  late String humanPlayerId;

  setUpAll(() async {
    await preloadNinePatchImage();
    game = buildUnitPanelsTestGame();
    topology = const MapTopology();
    expect(game.players, isNotEmpty);
    humanPlayerId = game.players.first.id;
  });

  setUp(() => AppEventBus.reset());

  for (final case_ in unitPanels320Cases()) {
    group(case_.groupLabel, () {
      testWidgets(case_.positiveName, (WidgetTester tester) async {
        await pumpUnitPanelAt320(
          tester,
          case_.buildPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
          size: kUnitPanels320MinViewport,
        );

        expect(tester.takeException(), isNull, reason: case_.overflowReason);
        expect(find.text(case_.title), findsOneWidget);
      });

      testWidgets(case_.negativeName, (WidgetTester tester) async {
        await pumpUnitPanelAt320(
          tester,
          case_.buildPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
          size: kUnitPanels320WideViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(case_.title), findsOneWidget);
      });
    });
  }
}
