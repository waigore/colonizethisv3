import 'package:colonizethis_app/features/game/widgets/train/train_military_regiment_role_display.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'train_military_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  final harness = TrainMilitaryDialogTestHarness();

  group('benefit vs cost row copy (#4324)', () {
    testWidgets('culverin row shows category gist and food upkeep', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        harness.buildDialog(
          panelGame: harness.gameWithMilitaryResources(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heavy artillery · Siege guns'), findsWidgets);
      expect(
        find.text(
          '${RegimentEconomyCatalog.culverin.foodUpkeep} food / turn',
        ),
        findsWidgets,
      );
    });

    testWidgets('pikemen and arquebusiers show distinct benefit lines', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        harness.buildDialog(
          panelGame: harness.gameWithMilitaryResources(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Regular infantry · Melee line'), findsWidgets);
      expect(find.text('Heavy infantry · Ranged firepower'), findsWidgets);
    });

    testWidgets('locked row still shows benefit and food upkeep', (
      WidgetTester tester,
    ) async {
      final base = harness.gameWithMilitaryResources();
      final player = base.players.firstWhere((p) => p.id == harness.humanPlayerId);
      final lockedRegimentId = RegimentEconomyCatalog.musketeers.id;
      final lockedStats = regimentStatsById(lockedRegimentId)!;
      final lockedEconomy = RegimentEconomyCatalog.musketeers;
      final game = base.copyWith(
        players: [
          player.copyWith(techUnlocked: {}),
          ...base.players.where((p) => p.id != harness.humanPlayerId),
        ],
      );

      await tester.pumpWidget(
        harness.buildDialog(panelGame: game),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          TrainMilitaryRegimentRoleDisplay.categoryRoleLine(
            lookupAppLocalizations(const Locale('en')),
            lockedStats.category,
          ),
        ),
        findsWidgets,
      );
      expect(
        find.text('${lockedEconomy.foodUpkeep} food / turn'),
        findsWidgets,
      );
      expect(find.textContaining('Requires:'), findsWidgets);
    });

    testWidgets('default rows do not dump tactical stat labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        harness.buildDialog(
          panelGame: harness.gameWithMilitaryResources(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('FPN'), findsNothing);
      expect(find.textContaining('FPM'), findsNothing);
      expect(find.textContaining('RNG'), findsNothing);
      expect(find.textContaining('DEF'), findsNothing);
      expect(find.textContaining('MVR'), findsNothing);
    });
  });
}
