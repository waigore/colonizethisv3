// DiplomacyPanel order UI + bus command emission coverage.
// Table-driven pending/cancel + dialog pins densify mid-size suite (Refs #4021).
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show grantOrSubsidyDialogId;
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

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

Game _minorConsulateConfirmGame() {
  const ow = 'oldWorld';
  return buildPanelTestGame(
    id: 'diplomacy-consulate-confirm-test',
    players: const [
      Player(
        id: _humanId,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
        techUnlocked: {kTechIdDiplomaticExpertise: true},
      ),
    ],
    minorNations: const [MinorNation(id: _minorId, displayName: 'Free City')],
    oldWorldProvinces: [
      Province(id: '$ow|p1', regionId: ow, ownerId: _humanId),
      Province(id: '$ow|m1', regionId: ow, ownerId: _minorId),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _humanId,
        factionId2: _minorId,
        state: RelationState.atPeace,
        score: 50,
      ),
    ],
  );
}

Game _minorJoinEmpireConfirmGame() {
  return buildDiplomacyRichPanelTestGame().copyWith(
    diplomacyRelations: [
      const DiplomacyRelation(
        factionId1: _humanId,
        factionId2: 'gp2',
        state: RelationState.atPeace,
        score: 50,
      ),
      const DiplomacyRelation(
        factionId1: _humanId,
        factionId2: 'gp3',
        state: RelationState.atWar,
        score: 20,
      ),
      const DiplomacyRelation(
        factionId1: _humanId,
        factionId2: _minorId,
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
      const DiplomacyRelation(
        factionId1: _humanId,
        factionId2: 't1',
        state: RelationState.atPeace,
        score: 50,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: _humanId,
        targetId: _minorId,
        stage: OvertureStage.nap,
      ),
    ],
  );
}

Game _tribeJoinEmpireConfirmGame() {
  return buildDiplomacyRichPanelTestGame().copyWith(
    diplomacyRelations: [
      const DiplomacyRelation(
        factionId1: _humanId,
        factionId2: 'gp2',
        state: RelationState.atPeace,
        score: 50,
      ),
      const DiplomacyRelation(
        factionId1: _humanId,
        factionId2: 'gp3',
        state: RelationState.atWar,
        score: 20,
      ),
      const DiplomacyRelation(
        factionId1: _humanId,
        factionId2: _minorId,
        state: RelationState.atPeace,
        score: 50,
      ),
      const DiplomacyRelation(
        factionId1: _humanId,
        factionId2: 't1',
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: _humanId,
        targetId: 't1',
        stage: OvertureStage.nap,
      ),
    ],
  );
}

Future<ConfirmDialogEvent> _awaitConfirmOnActionTap(
  WidgetTester tester, {
  required Game game,
  required Finder actionFinder,
  AppEventBus? bus,
  bool minorsTab = false,
  bool tall = false,
}) async {
  final eventBus = bus ?? AppEventBus.create();
  final confirmFuture = eventBus
      .on<ConfirmDialogEvent>()
      .first
      .timeout(const Duration(seconds: 2));
  await _pumpOrders(
    tester,
    game: game,
    bus: eventBus,
    minorsTab: minorsTab,
    tall: tall,
  );
  await _tapVisible(tester, actionFinder);
  return await confirmFuture;
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
    find.byKey(ValueKey('$kDiplomacyRowBodyKeyPrefix$_minorId'));

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Future<T> _awaitBusEvent<T extends AppEvent>(AppEventBus bus) {
  return bus.on<T>().first.timeout(const Duration(seconds: 2));
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
      final appendFuture = _awaitBusEvent<AppendDiplomaticOrderRequestedEvent>(
        bus,
      );
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

      await _pumpOrders(tester, game: game, humanId: humanId, bus: bus);
      await _tapVisible(tester, find.text('Break Alliance'));

      final confirm = await confirmFuture;
      expect(confirm.message, contains('When:'));
      expect(confirm.message.toLowerCase(), contains('immediately'));
      expect(confirm.message, isNot(contains('Confirm Break Alliance against')));
    },
  );

  testWidgets(
    'DiplomacyPanel Declare War confirm includes first-order preview (Refs #4181)',
    (WidgetTester tester) async {
      final confirm = await _awaitConfirmOnActionTap(
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
      await _pumpOrders(
        tester,
        game: _minorConsulateConfirmGame(),
        bus: eventBus,
        minorsTab: true,
        tall: true,
      );
      final consulateInMinorRow = find.descendant(
        of: _minorRow(),
        matching: find.text('Consulate'),
      );
      await _tapVisible(tester, consulateInMinorRow);
      final confirm = await confirmFuture;
      final body = confirm.message;
      expect(body, contains('£$overtureConsulateCost'));
      expect(body, contains('only on acceptance'));
      expect(body, isNot(contains('Confirm Consulate against')));
    },
  );

  testWidgets(
    'DiplomacyPanel Join Empire minor confirm shows absorb preview (Refs #4181)',
    (WidgetTester tester) async {
      final confirm = await _awaitConfirmOnActionTap(
        tester,
        game: _minorJoinEmpireConfirmGame(),
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
      final confirm = await _awaitConfirmOnActionTap(
        tester,
        game: _tribeJoinEmpireConfirmGame(),
        actionFinder: find.text('Join Empire').last,
        tall: true,
      );
      expect(confirm.message.toLowerCase(), contains('colony'));
      expect(confirm.message, isNot(contains('Confirm Join Empire against')));
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
      final breakFuture = _awaitBusEvent<BreakAllianceImmediatelyEvent>(bus);
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
      final removeFuture = _awaitBusEvent<RemoveDiplomaticOrderRequestedEvent>(
        bus,
      );

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

  group('Boycott controls (Refs #3753 S14)', () {
    testWidgets(
      'colony holder shows Boycott enabled on GP row',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final appendFuture =
            _awaitBusEvent<AppendDiplomaticOrderRequestedEvent>(bus);
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
      'active boycott shows Revoke Boycott enabled on GP row',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final appendFuture =
            _awaitBusEvent<AppendDiplomaticOrderRequestedEvent>(bus);
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
            BoycottState(gpId: _humanId, targetGpId: _gp2, sinceTurn: 1),
          ],
        ),
        type: DiplomaticOrderType.revokeBoycott,
        hiddenLabel: 'Revoke Boycott',
      ),
    ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final removeFuture =
            _awaitBusEvent<RemoveDiplomaticOrderRequestedEvent>(bus);

        await _pumpOrders(
          tester,
          game: c.game(),
          bus: bus,
          currentOrders: _pendingOrders(
            DiplomaticOrder(type: c.type, targetFactionId: _gp2),
          ),
        );
        expect(find.text(c.hiddenLabel), findsNothing);
        await _tapVisible(tester, find.text('Cancel').first);

        final event = await removeFuture;
        expect(event.playerId, _humanId);
        expect(event.type, c.type);
        expect(event.targetFactionId, _gp2);
      });
    }

    testWidgets(
      'Boycott disabled when human holds no colony',
      (WidgetTester tester) async {
        await _pumpOrders(tester, game: buildDiplomacyPanelTestGame());

        final boycottButton = find.widgetWithText(CtNinePatchButton, 'Boycott');
        expect(boycottButton, findsOneWidget);
        expect(tester.widget<CtNinePatchButton>(boycottButton).enabled, isFalse);
      },
    );

    testWidgets(
      'Minor row omits Boycott controls (negative)',
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
  });

  group('Minor subsidy / grant aid (Refs #3753 S15 / R2)', () {
    testWidgets(
      'pending setSubsidy shows percent line and Cancel',
      (WidgetTester tester) async {
        const percent = 15;
        final bus = AppEventBus.create();
        final removeFuture =
            _awaitBusEvent<RemoveDiplomaticOrderRequestedEvent>(bus);

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
      'active subsidy shows outgoing percent line',
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
      'pending grantAid shows amount line and Cancel',
      (WidgetTester tester) async {
        const amount = 2000;
        final bus = AppEventBus.create();
        final removeFuture =
            _awaitBusEvent<RemoveDiplomaticOrderRequestedEvent>(bus);

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
        final openFuture = _awaitBusEvent<OpenDialogEvent>(bus);

        await _pumpOrders(
          tester,
          game: _minorEmbassyGame(),
          bus: bus,
          tall: true,
          minorsTab: true,
        );

        await _tapVisible(
          tester,
          find.descendant(of: _minorRow(), matching: find.text(c.buttonLabel)),
        );

        final event = await openFuture;
        expect(event.dialogId, grantOrSubsidyDialogId);
        expect(event.params?['isSubsidy'], c.isSubsidy);
        expect(event.params?['targetFactionId'], _minorId);
      });
    }
  });
}
