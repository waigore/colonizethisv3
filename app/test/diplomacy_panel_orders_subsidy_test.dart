// DiplomacyPanel minor subsidy / grant-aid order pins (Refs #4352).
// SPEC: SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show grantOrSubsidyDialogId;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_panel_orders_pump_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  setUp(() {
    AppEventBus.reset();
  });

  group('Minor subsidy / grant aid (Refs #3753 S15 / R2)', () {
    testWidgets('pending setSubsidy shows percent line and Cancel', (
      WidgetTester tester,
    ) async {
      const percent = 15;
      final bus = AppEventBus.create();
      final removeFuture =
          awaitDiplomacyBusEvent<RemoveDiplomaticOrderRequestedEvent>(bus);

      await pumpDiplomacyOrdersPanel(
        tester,
        game: buildDiplomacyRichPanelTestGame(),
        bus: bus,
        tall: true,
        minorsTab: true,
        currentOrders: diplomacyPendingOrders(
          DiplomaticOrder(
            type: DiplomaticOrderType.setSubsidy,
            targetFactionId: diplomacyOrdersMinorId,
            amount: percent,
          ),
        ),
      );

      expect(
        find.text('Pending subsidy: $percent% (resolves end of turn)'),
        findsOneWidget,
      );
      expect(find.text('Set Subsidy ($percent%)'), findsNothing);

      await tapVisibleDiplomacy(tester, find.text('Cancel').first);
      final event = await removeFuture;
      expect(event.playerId, diplomacyOrdersHumanId);
      expect(event.type, DiplomaticOrderType.setSubsidy);
      expect(event.targetFactionId, diplomacyOrdersMinorId);
    });

    testWidgets('active subsidy shows outgoing percent line', (
      WidgetTester tester,
    ) async {
      const percent = 10;
      await pumpDiplomacyOrdersPanel(
        tester,
        game: diplomacyMinorEmbassyGame(
          subsidies: const [
            SubsidyState(
              payerId: diplomacyOrdersHumanId,
              targetId: diplomacyOrdersMinorId,
              percent: percent,
            ),
          ],
        ),
        tall: true,
        minorsTab: true,
      );

      expect(
        find.text('Outgoing subsidy: $percent% to Free City'),
        findsOneWidget,
      );
    });

    testWidgets('pending grantAid shows amount line and Cancel', (
      WidgetTester tester,
    ) async {
      const amount = 2000;
      final bus = AppEventBus.create();
      final removeFuture =
          awaitDiplomacyBusEvent<RemoveDiplomaticOrderRequestedEvent>(bus);

      await pumpDiplomacyOrdersPanel(
        tester,
        game: buildDiplomacyRichPanelTestGame(),
        bus: bus,
        tall: true,
        minorsTab: true,
        currentOrders: diplomacyPendingOrders(
          DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: diplomacyOrdersMinorId,
            amount: amount,
          ),
        ),
      );

      final minorRow = diplomacyMinorRow();
      expect(
        find.descendant(
          of: minorRow,
          matching: find.text(
            'Pending grant aid: £$amount (resolves end of turn)',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: minorRow, matching: find.text('Grant Aid')),
        findsNothing,
      );

      await tapVisibleDiplomacy(
        tester,
        find.descendant(of: minorRow, matching: find.text('Cancel')),
      );
      final event = await removeFuture;
      expect(event.playerId, diplomacyOrdersHumanId);
      expect(event.type, DiplomaticOrderType.grantAid);
      expect(event.targetFactionId, diplomacyOrdersMinorId);
    });

    for (final c in <({String name, String buttonLabel, bool isSubsidy})>[
      (
        name: 'Grant Aid emits grantOrSubsidy dialog',
        buttonLabel: 'Grant Aid',
        isSubsidy: false,
      ),
      (
        name: 'Set Subsidy emits grantOrSubsidy dialog',
        buttonLabel: 'Set Subsidy (5%)',
        isSubsidy: true,
      ),
    ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final openFuture = awaitDiplomacyBusEvent<OpenDialogEvent>(bus);

        await pumpDiplomacyOrdersPanel(
          tester,
          game: diplomacyMinorEmbassyGame(),
          bus: bus,
          tall: true,
          minorsTab: true,
        );

        await tapVisibleDiplomacy(
          tester,
          find.descendant(
            of: diplomacyMinorRow(),
            matching: find.text(c.buttonLabel),
          ),
        );

        final event = await openFuture;
        expect(event.dialogId, grantOrSubsidyDialogId);
        expect(event.params?['isSubsidy'], c.isSubsidy);
        expect(event.params?['targetFactionId'], diplomacyOrdersMinorId);
      });
    }
  });
}
