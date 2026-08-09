import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  Widget host({
    required bool nextTurnEnabled,
    required Future<void> Function() onNextTurn,
  }) {
    return buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      child: Scaffold(
        body: GameMapControls(
          sideMenuOpen: false,
          onToggleSideMenu: () {},
          onPausePressed: () {},
          onNextTurn: onNextTurn,
          nextTurnEnabled: nextTurnEnabled,
          regionIndex: 0,
          onRegionIndexChanged: (_) {},
          turnDisplayText: 'Turn 1 / Year 1600',
          nextTurnText: 'Next turn',
          cargoUsed: 0,
          cargoCapacity: 0,
          treasury: 0,
          treasuryDelta: 0,
          playerTurnEventsFeedCount: 0,
          showPlayerTurnEventsFeed: false,
          onTogglePlayerTurnEventsFeed: () {},
          showPlayersBar: true,
          onTogglePlayersBar: () {},
        ),
      ),
    );
  }

  testWidgets('next turn button is disabled when nextTurnEnabled is false', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      host(
        nextTurnEnabled: false,
        onNextTurn: () async {
          pressed = true;
        },
      ),
    );

    final nextTurnButton = tester.widget<Widget>(
      find.byKey(kGameMapNextTurnButtonKey),
    );
    expect(nextTurnButton, isNotNull);

    await tester.tap(find.byKey(kGameMapNextTurnButtonKey));
    await tester.pump();
    expect(pressed, isFalse);
  });
}
