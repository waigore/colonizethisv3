// DiplomacyPanel order UI + bus command emission coverage.
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show grantOrSubsidyDialogId;
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/diplomacy_panel_test_support.dart';
import 'support/panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

const _humanId = kPanelTestHumanPlayerId;
const _gp2 = 'gp2';
const _minorId = 'm1';

Game _colonyGame({List<BoycottState> boycotts = const []}) {
  return buildDiplomacyPanelTestGame().copyWith(
    colonyStates: const [
      ColonyState(tribeId: 't1', colonyOfGpId: _humanId, sinceTurn: 1),
    ],
    tribes: const [Tribe(id: 't1', displayName: 'Aztec')],
    boycottStates: boycotts,
  );
}

Game _minorEmbassyGame({List<SubsidyState> subsidies = const []}) {
  return buildDiplomacyRichPanelTestGame().copyWith(
    overtureStates: const [
      OvertureState(
        gpId: _humanId,
        targetId: _minorId,
        stage: OvertureStage.embassy,
      ),
    ],
    subsidyStates: subsidies,
  );
}

Orders _pendingOrders(DiplomaticOrder order) {
  return Orders(
    diplomaticOrdersByPlayerId: {
      _humanId: [order],
    },
  );
}

void _autoConfirm(AppEventBus bus) {
  final sub = bus.on<ConfirmDialogEvent>().listen((event) {
    event.result(true);
  });
  addTearDown(sub.cancel);
}

Future<void> _pumpOrders(
  WidgetTester tester, {
  required Game game,
  String humanId = _humanId,
  AppEventBus? bus,
  Orders currentOrders = const Orders(),
  bool tall = false,
  bool minorsTab = false,
  bool settle = false,
}) async {
  if (tall) {
    await bindDiplomacyTallTestSurface(tester);
  }
  await tester.pumpWidget(
    buildDiplomacyPanelShell(
      game: game,
      humanPlayerId: humanId,
      topology: const MapTopology(),
      currentOrders: currentOrders,
      bus: bus ?? AppEventBus.create(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  if (minorsTab) {
    await tester.tap(find.text('Minors only'));
    await tester.pump();
  }
}

Finder _minorRow() =>
    find.byKey(ValueKey('${kDiplomacyRowBodyKeyPrefix}$_minorId'));

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
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
      await _pumpOrders(
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
      final appendFuture = bus
          .on<AppendDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      _autoConfirm(bus);

      await _pumpOrders(tester, game: game, humanId: humanId, bus: bus);

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

      await _tapVisible(tester, actionFinder!);
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
      final breakFuture = bus.on<BreakAllianceImmediatelyEvent>().first.timeout(
        const Duration(seconds: 2),
      );
      _autoConfirm(bus);

      await _pumpOrders(tester, game: game, humanId: humanId, bus: bus);
      await _tapVisible(tester, find.text('Break Alliance'));

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
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      await _pumpOrders(
        tester,
        game: game,
        humanId: humanId,
        bus: bus,
        currentOrders: _pendingOrders(
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: target,
          ),
        ),
      );
      await _tapVisible(tester, find.text('Cancel').first);

      final event = await removeFuture;
      expect(event.playerId, humanId);
      expect(event.type, DiplomaticOrderType.declareWar);
      expect(event.targetFactionId, target);
    },
  );

  testWidgets(
    'DiplomacyPanel colony holder shows Boycott enabled on GP row (Refs #3753 S14)',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final appendFuture = bus
          .on<AppendDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      _autoConfirm(bus);

      await _pumpOrders(tester, game: _colonyGame(), bus: bus);
      expect(find.text('Boycott'), findsOneWidget);
      expect(find.text('Revoke Boycott'), findsOneWidget);

      await _tapVisible(tester, find.text('Boycott'));
      final event = await appendFuture;
      expect(event.playerId, _humanId);
      expect(event.order.type, DiplomaticOrderType.boycott);
      expect(event.order.targetFactionId, _gp2);
    },
  );

  testWidgets(
    'DiplomacyPanel active boycott shows Revoke Boycott enabled on GP row (Refs #3753 S14)',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final appendFuture = bus
          .on<AppendDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      _autoConfirm(bus);

      await _pumpOrders(
        tester,
        game: _colonyGame(
          boycotts: const [
            BoycottState(gpId: _humanId, targetGpId: _gp2, sinceTurn: 1),
          ],
        ),
        bus: bus,
      );
      expect(find.text('Revoke Boycott'), findsOneWidget);

      await _tapVisible(tester, find.text('Revoke Boycott'));
      final event = await appendFuture;
      expect(event.playerId, _humanId);
      expect(event.order.type, DiplomaticOrderType.revokeBoycott);
      expect(event.order.targetFactionId, _gp2);
    },
  );

  testWidgets(
    'DiplomacyPanel pending boycott shows Cancel and removes on tap (Refs #3753 S14)',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      await _pumpOrders(
        tester,
        game: _colonyGame(),
        bus: bus,
        currentOrders: _pendingOrders(
          DiplomaticOrder(
            type: DiplomaticOrderType.boycott,
            targetFactionId: _gp2,
          ),
        ),
      );
      expect(find.text('Boycott'), findsNothing);
      await _tapVisible(tester, find.text('Cancel').first);

      final event = await removeFuture;
      expect(event.playerId, _humanId);
      expect(event.type, DiplomaticOrderType.boycott);
      expect(event.targetFactionId, _gp2);
    },
  );

  testWidgets(
    'DiplomacyPanel pending revokeBoycott shows Cancel and removes on tap (Refs #3753 S14)',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      await _pumpOrders(
        tester,
        game: _colonyGame(
          boycotts: const [
            BoycottState(gpId: _humanId, targetGpId: _gp2, sinceTurn: 1),
          ],
        ),
        bus: bus,
        currentOrders: _pendingOrders(
          DiplomaticOrder(
            type: DiplomaticOrderType.revokeBoycott,
            targetFactionId: _gp2,
          ),
        ),
      );
      expect(find.text('Revoke Boycott'), findsNothing);
      await _tapVisible(tester, find.text('Cancel').first);

      final event = await removeFuture;
      expect(event.playerId, _humanId);
      expect(event.type, DiplomaticOrderType.revokeBoycott);
      expect(event.targetFactionId, _gp2);
    },
  );

  testWidgets(
    'DiplomacyPanel Boycott disabled when human holds no colony (Refs #3753 S14)',
    (WidgetTester tester) async {
      await _pumpOrders(tester, game: buildDiplomacyPanelTestGame());

      final boycottButton = find.widgetWithText(CtNinePatchButton, 'Boycott');
      expect(boycottButton, findsOneWidget);
      expect(tester.widget<CtNinePatchButton>(boycottButton).enabled, isFalse);
    },
  );

  testWidgets(
    'DiplomacyPanel Minor row omits Boycott controls (Refs #3753 S14 negative)',
    (WidgetTester tester) async {
      await _pumpOrders(
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

  testWidgets(
    'DiplomacyPanel pending setSubsidy shows percent line and Cancel (Refs #3753 S15)',
    (WidgetTester tester) async {
      const percent = 15;
      final bus = AppEventBus.create();
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      await _pumpOrders(
        tester,
        game: buildDiplomacyRichPanelTestGame(),
        bus: bus,
        tall: true,
        minorsTab: true,
        currentOrders: _pendingOrders(
          DiplomaticOrder(
            type: DiplomaticOrderType.setSubsidy,
            targetFactionId: _minorId,
            amount: percent,
          ),
        ),
      );

      expect(
        find.text('Pending subsidy: $percent% (resolves end of turn)'),
        findsOneWidget,
      );
      expect(find.text('Set Subsidy ($percent%)'), findsNothing);

      await _tapVisible(tester, find.text('Cancel').first);
      final event = await removeFuture;
      expect(event.playerId, _humanId);
      expect(event.type, DiplomaticOrderType.setSubsidy);
      expect(event.targetFactionId, _minorId);
    },
  );

  testWidgets(
    'DiplomacyPanel active subsidy shows outgoing percent line (Refs #3753 S15)',
    (WidgetTester tester) async {
      const percent = 10;
      await _pumpOrders(
        tester,
        game: _minorEmbassyGame(
          subsidies: const [
            SubsidyState(
              payerId: _humanId,
              targetId: _minorId,
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
    'DiplomacyPanel pending grantAid shows amount line and Cancel (Refs #3753 R2)',
    (WidgetTester tester) async {
      const amount = 2000;
      final bus = AppEventBus.create();
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      await _pumpOrders(
        tester,
        game: buildDiplomacyRichPanelTestGame(),
        bus: bus,
        tall: true,
        minorsTab: true,
        currentOrders: _pendingOrders(
          DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: _minorId,
            amount: amount,
          ),
        ),
      );

      final minorRow = _minorRow();
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

      await _tapVisible(
        tester,
        find.descendant(of: minorRow, matching: find.text('Cancel')),
      );
      final event = await removeFuture;
      expect(event.playerId, _humanId);
      expect(event.type, DiplomaticOrderType.grantAid);
      expect(event.targetFactionId, _minorId);
    },
  );

  testWidgets(
    'DiplomacyPanel Grant Aid emits grantOrSubsidy dialog (Refs #3753 R2)',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final openFuture = bus.on<OpenDialogEvent>().first.timeout(
        const Duration(seconds: 2),
      );

      await _pumpOrders(
        tester,
        game: _minorEmbassyGame(),
        bus: bus,
        tall: true,
        minorsTab: true,
      );

      final grantAidButton = find.descendant(
        of: _minorRow(),
        matching: find.text('Grant Aid'),
      );
      await _tapVisible(tester, grantAidButton);

      final event = await openFuture;
      expect(event.dialogId, grantOrSubsidyDialogId);
      expect(event.params?['isSubsidy'], isFalse);
      expect(event.params?['targetFactionId'], _minorId);
    },
  );

  testWidgets(
    'DiplomacyPanel Set Subsidy emits grantOrSubsidy dialog (Refs #3753 S15)',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final openFuture = bus.on<OpenDialogEvent>().first.timeout(
        const Duration(seconds: 2),
      );

      await _pumpOrders(
        tester,
        game: _minorEmbassyGame(),
        bus: bus,
        tall: true,
        minorsTab: true,
      );

      final setSubsidyButton = find.descendant(
        of: _minorRow(),
        matching: find.text('Set Subsidy (5%)'),
      );
      await _tapVisible(tester, setSubsidyButton);

      final event = await openFuture;
      expect(event.dialogId, grantOrSubsidyDialogId);
      expect(event.params?['isSubsidy'], isTrue);
      expect(event.params?['targetFactionId'], _minorId);
    },
  );
}
