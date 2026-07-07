import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kPlayersBarToggleButtonKey, kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Widget host({
    required bool showPlayersBar,
    required VoidCallback onTogglePlayersBar,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: GameMapControls(
          sideMenuOpen: false,
          onToggleSideMenu: () {},
          onPausePressed: () {},
          onNextTurn: () async {},
          nextTurnEnabled: true,
          regionIndex: 0,
          onRegionIndexChanged: (_) {},
          turnDisplayText: 'Turn 1 / Year 1600',
          nextTurnText: 'Next turn',
          cargoUsed: 0,
          cargoCapacity: 0,
          treasury: 0,
          treasuryDelta: 0,
          playerTurnEventsFeedCount: 2,
          showPlayerTurnEventsFeed: false,
          onTogglePlayerTurnEventsFeed: () {},
          showPlayersBar: showPlayersBar,
          onTogglePlayersBar: onTogglePlayersBar,
        ),
      ),
    );
  }

  testWidgets('tab bar trailing mounts players toggle before news toggle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(showPlayersBar: true, onTogglePlayersBar: () {}),
    );
    await tester.pump();

    expect(find.byKey(kPlayersBarToggleButtonKey), findsOneWidget);
    expect(find.byKey(kPlayerTurnFeedToggleButtonKey), findsOneWidget);

    final playersOffset = tester.getTopLeft(find.byKey(kPlayersBarToggleButtonKey));
    final newsOffset = tester.getTopLeft(find.byKey(kPlayerTurnFeedToggleButtonKey));
    expect(playersOffset.dx, lessThan(newsOffset.dx));
  });

  testWidgets('players bar toggle invokes callback', (WidgetTester tester) async {
    var toggled = false;
    await tester.pumpWidget(
      host(
        showPlayersBar: true,
        onTogglePlayersBar: () => toggled = true,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kPlayersBarToggleButtonKey));
    await tester.pump();

    expect(toggled, isTrue);
  });
}
