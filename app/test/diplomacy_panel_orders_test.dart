// DiplomacyPanel order UI + bus command emission coverage.
// Table-driven pending/cancel + dialog pins densify mid-size suite (Refs #4021).
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show grantOrSubsidyDialogId;
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_panel_orders_pump_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

Game _colonyGame({List<BoycottState> boycotts = const []}) {
  return buildDiplomacyPanelTestGame().copyWith(
    colonyStates: const [
      ColonyState(tribeId: 't1', colonyOfGpId: diplomacyOrdersHumanId, sinceTurn: 1),
    ],
    tribes: const [Tribe(id: 't1', displayName: 'Aztec')],
    boycottStates: boycotts,
  );
}

Game _minorEmbassyGame({List<SubsidyState> subsidies = const []}) {
  return buildDiplomacyRichPanelTestGame().copyWith(
    overtureStates: const [
      OvertureState(
        gpId: diplomacyOrdersHumanId,
        targetId: diplomacyOrdersMinorId,
        stage: OvertureStage.embassy,
      ),
    ],
    subsidyStates: subsidies,
  );
}

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
    'DiplomacyPanel shows always-visible section headings + tribe placeholder '
    'when no factions discovered',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelGameWithNoDiscoveredFactions();
      await pumpDiplomacyOrdersPanel(
        tester,
        game: game,
        humanId: game.players.first.id,
        settle: true,
      );

      // SPEC/ui/diplomacy-panel.md § Section headings (Refs #3341).
      expect(find.text('Great Powers'), findsOneWidget);
      expect(find.text('Minor Nations'), findsOneWidget);
      expect(find.text('Tribes'), findsOneWidget);
      expect(find.text('No tribes contacted yet.'), findsOneWidget);
    },
  );

  testWidgets(
    'DiplomacyPanel confirm action emits AppendDiplomaticOrderRequestedEvent',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelTestGame();
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      final appendFuture = awaitDiplomacyBusEvent<AppendDiplomaticOrderRequestedEvent>(
        bus,
      );
      autoConfirmDiplomacyDialogs(bus);

      await pumpDiplomacyOrdersPanel(tester, game: game, humanId: humanId, bus: bus);

      const actionLabels = <String>['Declare War', 'Offer Peace', 'Alliance'];
      Finder? actionFinder;
      for (final label in actionLabels) {
        final candidate = find.text(label);
        if (candidate.evaluate().isNotEmpty) {
          actionFinder = candidate.first;
          break;
        }
      }
      expect(
        actionFinder,
        isNotNull,
        reason: 'Expected at least one non-parameter diplomacy action button',
      );

      await tapVisibleDiplomacy(tester, actionFinder!);
      final event = await appendFuture;
      expect(event.playerId, humanId);
    },
  );

  testWidgets(
    'DiplomacyPanel Break Alliance confirm emits BreakAllianceImmediatelyEvent',
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
      final breakFuture = awaitDiplomacyBusEvent<BreakAllianceImmediatelyEvent>(bus);
      autoConfirmDiplomacyDialogs(bus);

      await pumpDiplomacyOrdersPanel(tester, game: game, humanId: humanId, bus: bus);
      await tapVisibleDiplomacy(tester, find.text('Break Alliance'));

      final event = await breakFuture;
      expect(event.playerId, humanId);
      expect(event.targetFactionId, 'gp2');
    },
  );

  testWidgets(
    'DiplomacyPanel pending cancel emits RemoveDiplomaticOrderRequestedEvent',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelTestGame();
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final target = game.players.firstWhere((p) => p.id != humanId).id;
      final bus = AppEventBus.create();
      final removeFuture = awaitDiplomacyBusEvent<RemoveDiplomaticOrderRequestedEvent>(
        bus,
      );

      await pumpDiplomacyOrdersPanel(
        tester,
        game: game,
        humanId: humanId,
        bus: bus,
        currentOrders: diplomacyPendingOrders(
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: target,
          ),
        ),
      );
      await tapVisibleDiplomacy(tester, find.text('Cancel').first);

      final event = await removeFuture;
      expect(event.playerId, humanId);
      expect(event.type, DiplomaticOrderType.declareWar);
      expect(event.targetFactionId, target);
    },
  );

  group('Boycott controls (Refs #3753 S14)', () {
    testWidgets(
      'colony holder shows Boycott enabled on GP row',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final appendFuture =
            awaitDiplomacyBusEvent<AppendDiplomaticOrderRequestedEvent>(bus);
        autoConfirmDiplomacyDialogs(bus);

        await pumpDiplomacyOrdersPanel(tester, game: _colonyGame(), bus: bus);
        expect(find.text('Boycott'), findsOneWidget);
        // Revoke Boycott is disabled until a boycott is active (Refs #4265 More).
        expect(find.text('Revoke Boycott'), findsNothing);

        await tapVisibleDiplomacy(tester, find.text('Boycott'));
        final event = await appendFuture;
        expect(event.playerId, diplomacyOrdersHumanId);
        expect(event.order.type, DiplomaticOrderType.boycott);
        expect(event.order.targetFactionId, diplomacyOrdersGp2);
      },
    );

    testWidgets(
      'active boycott shows Revoke Boycott enabled on GP row',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final appendFuture =
            awaitDiplomacyBusEvent<AppendDiplomaticOrderRequestedEvent>(bus);
        autoConfirmDiplomacyDialogs(bus);

        await pumpDiplomacyOrdersPanel(
          tester,
          game: _colonyGame(
            boycotts: const [
              BoycottState(
                gpId: diplomacyOrdersHumanId,
                targetGpId: diplomacyOrdersGp2,
                sinceTurn: 1,
              ),
            ],
          ),
          bus: bus,
        );
        expect(find.text('Revoke Boycott'), findsOneWidget);

        await tapVisibleDiplomacy(tester, find.text('Revoke Boycott'));
        final event = await appendFuture;
        expect(event.playerId, diplomacyOrdersHumanId);
        expect(event.order.type, DiplomaticOrderType.revokeBoycott);
        expect(event.order.targetFactionId, diplomacyOrdersGp2);
      },
    );

    for (final c in <({
      String name,
      Game Function() game,
      DiplomaticOrderType type,
      String hiddenLabel,
    })>[
      (
        name: 'pending boycott shows Cancel and removes on tap',
        game: _colonyGame,
        type: DiplomaticOrderType.boycott,
        hiddenLabel: 'Boycott',
      ),
      (
        name: 'pending revokeBoycott shows Cancel and removes on tap',
        game: () => _colonyGame(
          boycotts: const [
            BoycottState(
              gpId: diplomacyOrdersHumanId,
              targetGpId: diplomacyOrdersGp2,
              sinceTurn: 1,
            ),
          ],
        ),
        type: DiplomaticOrderType.revokeBoycott,
        hiddenLabel: 'Revoke Boycott',
      ),
    ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final removeFuture =
            awaitDiplomacyBusEvent<RemoveDiplomaticOrderRequestedEvent>(bus);

        await pumpDiplomacyOrdersPanel(
          tester,
          game: c.game(),
          bus: bus,
          currentOrders: diplomacyPendingOrders(
            DiplomaticOrder(type: c.type, targetFactionId: diplomacyOrdersGp2),
          ),
        );
        expect(find.text(c.hiddenLabel), findsNothing);
        await tapVisibleDiplomacy(tester, find.text('Cancel').first);

        final event = await removeFuture;
        expect(event.playerId, diplomacyOrdersHumanId);
        expect(event.type, c.type);
        expect(event.targetFactionId, diplomacyOrdersGp2);
      });
    }

    testWidgets(
      'Boycott disabled when human holds no colony',
      (WidgetTester tester) async {
        await pumpDiplomacyOrdersPanel(tester, game: buildDiplomacyPanelTestGame());

        await tapVisibleDiplomacy(tester, find.text('More actions'));
        final boycottButton = find.widgetWithText(CtNinePatchButton, 'Boycott');
        expect(boycottButton, findsOneWidget);
        expect(tester.widget<CtNinePatchButton>(boycottButton).enabled, isFalse);
      },
    );

    testWidgets(
      'Minor row omits Boycott controls (negative)',
      (WidgetTester tester) async {
        await pumpDiplomacyOrdersPanel(
          tester,
          game: buildDiplomacyRichPanelTestGame(),
          tall: true,
          minorsTab: true,
        );

        expect(find.text('Free City'), findsOneWidget);
        expect(find.text('Boycott'), findsNothing);
        expect(find.text('Revoke Boycott'), findsNothing);
      },
    );
  });

  group('Minor subsidy / grant aid (Refs #3753 S15 / R2)', () {
    testWidgets(
      'pending setSubsidy shows percent line and Cancel',
      (WidgetTester tester) async {
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
      },
    );

    testWidgets(
      'active subsidy shows outgoing percent line',
      (WidgetTester tester) async {
        const percent = 10;
        await pumpDiplomacyOrdersPanel(
          tester,
          game: _minorEmbassyGame(
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
      },
    );

    testWidgets(
      'pending grantAid shows amount line and Cancel',
      (WidgetTester tester) async {
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
      },
    );

    for (final c in <({
      String name,
      String buttonLabel,
      bool isSubsidy,
    })>[
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
          game: _minorEmbassyGame(),
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
