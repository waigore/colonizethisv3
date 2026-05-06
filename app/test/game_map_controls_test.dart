import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/flame/game_map_controls.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey;
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Widget _host({
    required bool nextTurnEnabled,
    required Future<void> Function() onNextTurn,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: GameMapControls(
          sideMenuOpen: false,
          onToggleSideMenu: () {},
          onNextTurn: onNextTurn,
          nextTurnEnabled: nextTurnEnabled,
          regionIndex: 0,
          onRegionIndexChanged: (_) {},
          nextTurnText: 'Next turn',
          cargoUsed: 0,
          cargoCapacity: 0,
          treasury: 0,
          treasuryDelta: 0,
          playerTurnEventsFeedCount: 0,
          showPlayerTurnEventsFeed: false,
          onTogglePlayerTurnEventsFeed: () {},
        ),
      ),
    );
  }

  testWidgets('next turn button is disabled when nextTurnEnabled is false', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      _host(
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
