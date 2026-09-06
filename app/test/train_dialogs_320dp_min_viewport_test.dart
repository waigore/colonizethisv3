// Pin the 320 dp minimum-viewport contract for in-game train dialogs (Refs #2870).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';
import 'panel_test_fixtures.dart';
import 'train_dialogs_320dp_min_viewport_cases.dart';

void main() {
  suppressLogsForTests();

  for (final case_ in trainDialogs320Cases()) {
    group(case_.groupLabel, () {
      testWidgets(case_.positiveName, (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        final humanPlayerId = trainDialogs320HumanPlayerId(game);
        await pumpDialogs320At(
          tester,
          case_.buildDialog(game: game, humanPlayerId: humanPlayerId),
          size: kTrainDialogs320MinViewport,
        );

        expect(tester.takeException(), isNull, reason: case_.overflowReason);
        expect(find.text(case_.title), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      });

      testWidgets(case_.negativeName, (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        final humanPlayerId = trainDialogs320HumanPlayerId(game);
        await pumpDialogs320At(
          tester,
          case_.buildDialog(game: game, humanPlayerId: humanPlayerId),
          size: kTrainDialogs320WideViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(case_.title), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      });
    });
  }
}
