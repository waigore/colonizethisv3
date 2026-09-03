// Widget goldens for tab-bar trailing cluster: players toggle before news
// (Refs #3898 AC3 / #4720 Slice G). Pixel baselines live under `app/test/goldens/`.
// SPEC: `SPEC/ui/empire-overview.md` § Players bar / § Players bar toggle.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'golden_capture_harness.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kPlayersBarToggleButtonKey, kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app/features/game/widgets/shell/players_bar_toggle_button.dart';

Widget _goldenHost({
  required Key boundaryKey,
  required Widget child,
  Size? surfaceSize,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: surfaceSize == null
        ? child
        : SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: child,
          ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: tab bar trailing cluster players toggle before news (Refs #3898 AC3)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('players_bar_tab_bar_trailing');
      const surfaceWidth = 420.0;

      await tester.pumpWidget(
        _goldenHost(
          boundaryKey: boundaryKey,
          surfaceSize: const Size(surfaceWidth, GameTabBar.height),
          child: GameTabBar(
            regionIndex: 0,
            onRegionIndexChanged: (_) {},
            oldWorldLabel: 'Old World',
            newWorldLabel: 'New World',
            treasury: 12_345,
            treasuryDelta: 100,
            treasuryNotDefined: false,
            cargoUsed: 2,
            cargoCapacity: 8,
            cargoNotDefined: false,
            isCargoUsedReliable: true,
            cargoHoldLabel: 'Cargo 2/8',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayersBarToggleButton(
                  tooltip: 'Show players bar',
                  showPlayersBar: true,
                  onPressed: () {},
                ),
                const SizedBox(width: GameTabBar.clusterTrailingGap),
                PlayerTurnEventsFeedToggleButton(
                  eventCount: 2,
                  tooltip: 'Turn events (2)',
                  showFeed: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await pumpForGolden(tester, settle: false);

      expect(find.byKey(kPlayersBarToggleButtonKey), findsOneWidget);
      expect(find.byKey(kPlayerTurnFeedToggleButtonKey), findsOneWidget);
      final playersOffset = tester.getTopLeft(
        find.byKey(kPlayersBarToggleButtonKey),
      );
      final newsOffset = tester.getTopLeft(
        find.byKey(kPlayerTurnFeedToggleButtonKey),
      );
      expect(playersOffset.dx, lessThan(newsOffset.dx));

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/players_bar_tab_bar_trailing_cluster.png'),
      );
    },
  );
}
