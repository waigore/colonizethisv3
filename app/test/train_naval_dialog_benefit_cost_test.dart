import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'train_naval_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  final harness = TrainNavalDialogTestHarness();

  group('benefit vs cost row copy (#4674)', () {
    testWidgets('carrack row shows role gist and food upkeep', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithNavalResources(),
      );

      expect(
        find.text(
          'Merchant · +${NavalStatsCatalog.carrack.cargoHold} cargo holds',
        ),
        findsWidgets,
      );
      expect(
        find.text(
          '${ShipEconomyCatalog.carrack.foodUpkeep} food / turn',
        ),
        findsWidgets,
      );
    });

    testWidgets('every catalog hull shows food upkeep from ShipEconomyCatalog', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithNavalResources(),
      );

      for (final entry in ShipEconomyCatalog.all) {
        expect(
          find.text('${entry.foodUpkeep} food / turn'),
          findsWidgets,
        );
      }
    });

    testWidgets('locked row still shows role gist and food upkeep', (
      WidgetTester tester,
    ) async {
      final base = harness.gameWithNavalResources();
      final player = base.players.firstWhere(
        (p) => p.id == harness.humanPlayerId,
      );
      final lockedShipId = 'sloop';
      final lockedEconomy = ShipEconomyCatalog.byId[lockedShipId]!;
      final game = base.copyWith(
        players: [
          player.copyWith(techUnlocked: {}),
          ...base.players.where((p) => p.id != harness.humanPlayerId),
        ],
      );

      await harness.pumpDialog(tester, panelGame: game);

      expect(
        find.text('Warship · Fast interceptor'),
        findsWidgets,
      );
      expect(
        find.text('${lockedEconomy.foodUpkeep} food / turn'),
        findsWidgets,
      );
      expect(find.textContaining('Requires:'), findsWidgets);
    });

    testWidgets('default rows do not dump feeding-order or grain/meat split', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithNavalResources(),
      );

      expect(find.textContaining('grain'), findsNothing);
      expect(find.textContaining('meat'), findsNothing);
      expect(find.textContaining('underfed'), findsNothing);
      expect(find.textContaining('strike'), findsNothing);
    });
  });
}
