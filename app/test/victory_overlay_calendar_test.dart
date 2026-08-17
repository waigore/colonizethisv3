import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic_shell.dart';
import 'package:colonizethis_app/features/game/flame/overlays/victory_overlay.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late ct_models.AppEventBus bus;

  setUp(() {
    ct_models.AppEventBus.reset();
    bus = ct_models.AppEventBus.create();
  });

  tearDown(() {
    ct_models.AppEventBus.reset();
  });

  Widget hostOverlay(ct_models.Game game) {
    return buildAppShell(
      child: Scaffold(
        body: Stack(
          children: [
            VictoryOverlay(game: game, bus: bus),
          ],
        ),
      ),
    );
  }

  testWidgets(
    'calendar-complete overlay shows Campaign complete + declared winner',
    (WidgetTester tester) async {
      final game = buildVictoryCalendarDeclaredWinnerTestGame();
      await tester.pumpWidget(hostOverlay(game));
      await tester.pumpAndSettle();

      expect(find.text('CAMPAIGN COMPLETE'), findsOneWidget);
      expect(find.text('MILITARY VICTORY'), findsNothing);
      expect(
        find.textContaining('had the strongest overall realm when play stopped'),
        findsOneWidget,
      );
      expect(find.textContaining('Test Human'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsNWidgets(2));
    },
  );

  testWidgets(
    'calendar-complete overlay shows tie / no-winner body',
    (WidgetTester tester) async {
      final game = buildVictoryCalendarTieTestGame();
      await tester.pumpWidget(hostOverlay(game));
      await tester.pumpAndSettle();

      expect(find.text('CAMPAIGN COMPLETE'), findsOneWidget);
      expect(
        find.textContaining('no declared winner (tied overall strength)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'View Final State dismisses calendar overlay; halt gate remains',
    (WidgetTester tester) async {
      final game = buildVictoryCalendarDeclaredWinnerTestGame();
      expect(game.victory, isNull);
      expect(game.calendarCampaignHalted, isTrue);
      expect(
        GameMapAreaStateLogicShell.allowsFullTurnResolution(game),
        isFalse,
      );

      await tester.pumpWidget(hostOverlay(game));
      await tester.pumpAndSettle();
      expect(find.text('CAMPAIGN COMPLETE'), findsOneWidget);

      await tester.tap(find.text('View final state'));
      await tester.pumpAndSettle();
      expect(find.text('CAMPAIGN COMPLETE'), findsNothing);
      expect(game.victory, isNull);
      expect(game.calendarCampaignHalted, isTrue);
      expect(
        GameMapAreaStateLogicShell.allowsFullTurnResolution(game),
        isFalse,
      );
    },
  );

  testWidgets(
    'Return to main menu emits NavigateToShellEvent (calendar)',
    (WidgetTester tester) async {
      final game = buildVictoryCalendarTieTestGame();
      ct_models.NavigateToShellEvent? emitted;
      final sub = bus.on<ct_models.NavigateToShellEvent>().listen(
        (e) => emitted = e,
      );
      addTearDown(sub.cancel);

      await tester.pumpWidget(hostOverlay(game));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return to main menu'));
      await tester.pump();

      expect(emitted, isA<ct_models.NavigateToShellEvent>());
    },
  );

  testWidgets(
    'military victory still uses military title when victory is set',
    (WidgetTester tester) async {
      final game = buildVictoryPanelTestGame().copyWith(
        calendarCampaignHalted: true,
        victory: ct_models.VictoryState(
          winnerPlayerId: kPanelTestHumanPlayerId,
          type: ct_models.VictoryType.military,
          turnNumber: 9,
        ),
      );

      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Stack(
              children: [
                VictoryOverlay(
                  game: game,
                  victory: game.victory,
                  bus: bus,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MILITARY VICTORY'), findsOneWidget);
      expect(find.text('CAMPAIGN COMPLETE'), findsNothing);
    },
  );
}
