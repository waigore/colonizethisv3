// GAME30001 Intelligence trailing. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'Given last-turn digest When Diplomacy opens Then Intelligence emits route',
    (WidgetTester tester) async {
      final base = buildDiplomacyScreenTestGame();
      final game = base.copyWith(
        lastTurnIntelligenceDigest: const LastTurnIntelligenceDigest(
          resolvedTurnNumber: 1,
          worldLines: [
            IntelligenceWorldLine(
              kind: IntelligenceWorldKind.war,
              factionIdA: 'gp2',
              factionIdB: 'gp1',
            ),
          ],
        ),
      );
      final humanId = game.players.first.id;
      final bus = AppEventBus.create();
      NavigateToRouteEvent? nav;
      bus.on<NavigateToRouteEvent>().listen((e) => nav = e);

      await pumpAppShell(
        tester,
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        overrides: [
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          appEventBusProvider.overrideWith((ref) => bus),
        ],
        child: DiplomacyScreen(game: game, humanPlayerId: humanId),
      );
      await pumpSettleCapped(tester);

      expect(find.text('Intelligence'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      await tester.tap(find.byKey(DiplomacyIntelligenceTrailing.buttonKey));
      await tester.pump();
      expect(nav?.route, Routes.intelligence);
    },
  );
}
