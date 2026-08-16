import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kOldWorldRaceChipKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/old_world_race_chip.dart';
import 'package:colonizethis_app/features/game/widgets/shell/old_world_race_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/shell/players_bar_toggle_button.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

/// Widget contract for the MAP10001 Old World race chip (Refs #4451).
void main() {
  suppressLogsForTests();

  const humanAhead = OldWorldRaceSnapshot(
    focusPlayerId: 'gp1',
    focusCount: 18,
    threshold: 31,
  );
  const rivalAhead = OldWorldRaceSnapshot(
    focusPlayerId: 'gp1',
    focusCount: 12,
    threshold: 31,
    rivalLeaderName: 'Spain',
    rivalLeaderCount: 20,
  );

  Widget host({
    OldWorldRaceSnapshot? race,
    bool narrow = false,
    VoidCallback? onTap,
    bool showPlayersBar = false,
    double width = 800,
  }) {
    return buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      child: Scaffold(
        body: SizedBox(
          width: width,
          height: 80,
          child: GameTabBar(
            regionIndex: 0,
            onRegionIndexChanged: (_) {},
            oldWorldLabel: 'Old World',
            newWorldLabel: 'New World',
            treasury: 100,
            treasuryDelta: 0,
            treasuryNotDefined: false,
            cargoUsed: 1,
            cargoCapacity: 8,
            cargoNotDefined: false,
            isCargoUsedReliable: true,
            cargoHoldLabel: '1/8',
            oldWorldRace: race,
            onOldWorldRaceTap: onTap,
            oldWorldRaceNarrow: narrow,
            trailing: PlayersBarToggleButton(
              tooltip: 'Players bar',
              showPlayersBar: showPlayersBar,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows focus N / 31 and omits rival when human ahead', (
    tester,
  ) async {
    await tester.pumpWidget(host(race: humanAhead));
    await tester.pump();

    expect(find.byKey(kOldWorldRaceChipKey), findsOneWidget);
    expect(find.text('18 / 31'), findsOneWidget);
    expect(find.textContaining('Spain'), findsNothing);
  });

  testWidgets('names rival leader when that court is ahead', (tester) async {
    await tester.pumpWidget(host(race: rivalAhead));
    await tester.pump();

    expect(find.text('12 / 31'), findsOneWidget);
    expect(find.textContaining('Spain'), findsOneWidget);
    expect(find.textContaining('20 / 31'), findsOneWidget);
  });

  testWidgets('tap emits the host callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(race: humanAhead, onTap: () => taps++));
    await tester.pump();

    await tester.tap(find.byKey(kOldWorldRaceChipKey));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('hidden when snapshot is omitted (victory overlay)', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump();
    expect(find.byKey(kOldWorldRaceChipKey), findsNothing);
    expect(find.byType(OldWorldRaceChip), findsNothing);
  });

  testWidgets('stays visible when players bar toggle is off', (tester) async {
    await tester.pumpWidget(host(race: humanAhead, showPlayersBar: false));
    await tester.pump();
    expect(find.byKey(kOldWorldRaceChipKey), findsOneWidget);
    expect(find.byType(PlayersBarToggleButton), findsOneWidget);
  });

  testWidgets('320 dp compact copy does not overflow', (tester) async {
    await tester.pumpWidget(host(race: rivalAhead, narrow: true, width: 320));
    await tester.pump();
    expect(find.byKey(kOldWorldRaceChipKey), findsOneWidget);
    expect(find.text('12/31'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
