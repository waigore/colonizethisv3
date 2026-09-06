// Train Naval role and capability gist pins (#4300).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'train_naval_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  late TrainNavalDialogTestHarness harness;

  setUpAll(() {
    harness = TrainNavalDialogTestHarness();
  });

  group('Train Naval role and capability gist (#4300)', () {
    testWidgets('AC: Carrack row shows Merchant and cargo holds', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(tester, panelGame: harness.gameWithNavalResources());
      expect(
        find.text(
          'Merchant · +${NavalStatsCatalog.carrack.cargoHold} cargo holds',
        ),
        findsWidgets,
      );
    });

    testWidgets('AC: Sloop row shows Warship and fast interceptor gist', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(tester, panelGame: harness.gameWithNavalResources());
      expect(find.text('Warship · Fast interceptor'), findsWidgets);
      expect(find.textContaining('+0 cargo holds'), findsNothing);
    });

    testWidgets('AC: Ship of the Line row shows battle ship gist', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(tester, panelGame: harness.gameWithNavalResources());
      expect(find.text('Warship · Battle ship'), findsWidgets);
    });

    testWidgets('AC: locked row keeps muted role/capability with Requires tech', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithPlayer(
          (player) => player.copyWith(
            treasury: 1000000,
            techUnlocked: const <String, bool>{},
          ),
        ),
      );
      expect(find.textContaining('Requires:'), findsWidgets);
      expect(find.text('Warship · Fast interceptor'), findsWidgets);
    });

    testWidgets('AC (negative): default row omits full combat stat dump', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(tester, panelGame: harness.gameWithNavalResources());
      expect(find.textContaining('FRP'), findsNothing);
      expect(find.textContaining('RNG'), findsNothing);
      expect(find.text('Details'), findsNothing);
    });
  });
}
