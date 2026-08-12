import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Widget hostPlayerTurnFeedCard({
  required List<PlayerTurnEventFeedEntry> entries,
  String emptyLabel = 'No major events last turn.',
}) {
  return buildAppShell(
    child: Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            right: 0,
            child: PlayerTurnEventFeedCard(
              entries: entries,
              emptyLabel: emptyLabel,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget hostPlayerTurnFeedToggle({
  required int eventCount,
  required bool showFeed,
}) {
  return buildAppShell(
    child: Scaffold(
      body: Center(
        child: PlayerTurnEventsFeedToggleButton(
          eventCount: eventCount,
          tooltip: 'tooltip',
          showFeed: showFeed,
          onPressed: () {},
        ),
      ),
    ),
  );
}

Container playerTurnFeedToggleSurface(WidgetTester tester) {
  return tester
      .widgetList<Container>(
        find.descendant(
          of: find.byKey(kPlayerTurnFeedToggleButtonKey),
          matching: find.byType(Container),
        ),
      )
      .firstWhere(
        (Container c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).border != null,
      );
}
