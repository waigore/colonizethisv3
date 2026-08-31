// Diplomacy confirm dialog first-order preview pins (Refs #4181).

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_panel_confirm_preview_test_fixtures.dart';
import 'diplomacy_panel_orders_pump_support.dart';
import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'diplomacy_panel_confirm_preview_cases.dart';
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

  testWidgets(
    'DiplomacyPanel confirm body includes first-order preview lines',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelTestGame().copyWith(
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 90,
            formalAlliance: true,
          ),
        ],
      );
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      final confirmFuture = bus
          .on<ConfirmDialogEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      await pumpDiplomacyOrdersPanel(tester, game: game, humanId: humanId, bus: bus);
      await tapVisibleDiplomacy(tester, find.text('Break Alliance'));

      final confirm = await confirmFuture;
      expect(confirm.message, contains('When:'));
      expect(confirm.message.toLowerCase(), contains('immediately'));
      expect(confirm.message, isNot(contains('Confirm Break Alliance against')));
    },
  );

  testWidgets(
    'DiplomacyPanel Declare War confirm includes first-order preview (Refs #4181)',
    (WidgetTester tester) async {
      final confirm = await awaitConfirmOnDiplomacyActionTap(
        tester,
        game: buildDiplomacyPanelTestGame(),
        actionFinder: find.text('Declare War'),
        tall: true,
      );
      final body = confirm.message;
      expect(body.toLowerCase(), contains('war'));
      expect(body.toLowerCase(), contains('overtures'));
      expect(body, isNot(contains('When:')));
      expect(body, isNot(contains('Confirm Declare War against')));
    },
  );

  testWidgets(
    'DiplomacyPanel Consulate confirm shows paid overture preview (Refs #4181)',
    (WidgetTester tester) async {
      final eventBus = AppEventBus.create();
      final confirmFuture = eventBus
          .on<ConfirmDialogEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      await pumpDiplomacyOrdersPanel(
        tester,
        game: diplomacyConfirmPreviewMinorConsulateGame(),
        bus: eventBus,
        minorsTab: true,
        tall: true,
      );
      final consulateInMinorRow = find.descendant(
        of: diplomacyMinorRow(),
        matching: find.text('Consulate'),
      );
      await tapVisibleDiplomacy(tester, consulateInMinorRow);
      final confirm = await confirmFuture;
      final body = confirm.message;
      expect(body, contains('£$overtureConsulateCost'));
      expect(body.toLowerCase(), contains(kWorkTargetExplore));
      expect(body.toLowerCase(), contains(kWorkTargetProspect));
      expect(body, isNot(contains('Confirm Consulate against')));
    },
  );

  testWidgets(
    'DiplomacyPanel Join Empire minor confirm shows absorb preview (Refs #4181)',
    (WidgetTester tester) async {
      final confirm = await awaitConfirmOnDiplomacyActionTap(
        tester,
        game: diplomacyConfirmPreviewMinorJoinEmpireGame(),
        actionFinder: find.text('Join Empire').first,
        minorsTab: true,
        tall: true,
      );
      final body = confirm.message.toLowerCase();
      expect(body, contains('join your realm'));
      expect(body, isNot(contains('province')));
    },
  );

  testWidgets(
    'DiplomacyPanel Join Empire tribe confirm shows colony preview (Refs #4181)',
    (WidgetTester tester) async {
      final confirm = await awaitConfirmOnDiplomacyActionTap(
        tester,
        game: diplomacyConfirmPreviewTribeJoinEmpireGame(),
        actionFinder: find.text('Join Empire').last,
        tall: true,
      );
      expect(confirm.message.toLowerCase(), contains('colony'));
      expect(confirm.message, isNot(contains('Confirm Join Empire against')));
    },
  );

  testWidgets(
    'DiplomacyPanel Join Empire GP confirm shows absorption preview (Refs #4181)',
    (WidgetTester tester) async {
      final eventBus = AppEventBus.create();
      final confirmFuture = eventBus
          .on<ConfirmDialogEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      await pumpDiplomacyOrdersPanel(
        tester,
        game: diplomacyConfirmPreviewGpJoinEmpireGame(),
        bus: eventBus,
        tall: true,
      );
      final gpRow = find.byKey(
        ValueKey('$kDiplomacyRowBodyKeyPrefix$diplomacyOrdersGp2'),
      );
      final joinEmpireInGpRow = find.descendant(
        of: gpRow,
        matching: find.text('Join Empire'),
      );
      await tapVisibleDiplomacy(tester, joinEmpireInGpRow);
      final confirm = await confirmFuture;
      final body = confirm.message;
      expect(body.toLowerCase(), contains('nearly defeated'));
      expect(body.toLowerCase(), contains('absorbed'));
      expect(body, isNot(contains('Confirm Join Empire against')));
      expect(body, isNot(contains('£')));
    },
  );

  for (final c in diplomacyConfirmPreviewCases()) {
    testWidgets(c.name, (WidgetTester tester) async {
      final eventBus = AppEventBus.create();
      final confirmFuture = eventBus
          .on<ConfirmDialogEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      await pumpDiplomacyOrdersPanel(
        tester,
        game: c.game(),
        bus: eventBus,
        minorsTab: c.minorsTab,
        tall: true,
      );
      await tapVisibleDiplomacy(tester, c.actionFinder());
      final confirm = await confirmFuture;
      c.assertBody(confirm.message);
      expect(confirm.message, isNot(startsWith('Confirm ')));
    });
  }

  testWidgets(
    'Non-goal: disabled Offer Peace reachable under More (Refs #4181 / #4265)',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelTestGame();
      final rows = buildDiplomacyRows(
        game,
        const MapTopology(),
        diplomacyOrdersHumanId,
        const Orders(),
      );
      final gpRow = rows.firstWhere((r) => r.factionId == diplomacyOrdersGp2);
      final offerPeace = gpRow.actions.firstWhere(
        (a) => a.order.type == DiplomaticOrderType.offerPeace,
      );
      expect(offerPeace.enabled, isFalse);
      expect(offerPeace.rejectionReason, isNotEmpty);

      await pumpDiplomacyOrdersPanel(tester, game: game, tall: true);
      await tapVisibleDiplomacy(tester, find.text('More actions').first);
      await tester.pumpAndSettle();
      final offerPeaceButton = find.widgetWithText(
        CtNinePatchButton,
        'Offer Peace',
      );
      expect(tester.widget<CtNinePatchButton>(offerPeaceButton).enabled, isFalse);
    },
  );
}
