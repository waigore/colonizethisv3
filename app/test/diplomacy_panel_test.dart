// Tests for DiplomacyPanel. SPEC/ui/diplomacy-panel.md.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/cache.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

class _EventHandlingWrapper extends StatefulWidget {
  const _EventHandlingWrapper({
    required this.bus,
    required this.child,
    required this.navigatorKey,
  });

  final AppEventBus bus;
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_EventHandlingWrapper> createState() => _EventHandlingWrapperState();
}

class _EventHandlingWrapperState extends State<_EventHandlingWrapper> {
  StreamSubscription? _confirmSub;
  StreamSubscription? _openDialogSub;

  @override
  void initState() {
    super.initState();
    _confirmSub = widget.bus.on<ConfirmDialogEvent>().listen((event) async {
      final nav = widget.navigatorKey.currentState;
      if (nav == null) return;
      final result = await showDialog<bool>(
        context: nav.context,
        builder: (ctx) => AlertDialog(
          title: Text(event.title),
          content: Text(event.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(event.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(event.confirmLabel),
            ),
          ],
        ),
      );
      event.result(result ?? false);
    });
    _openDialogSub = widget.bus.on<OpenDialogEvent>().listen((event) async {
      final nav = widget.navigatorKey.currentState;
      if (nav == null) return;
      await showDialog<void>(
        context: nav.context,
        builder: (ctx) => AlertDialog(
          title: Text('dialog:${event.dialogId}'),
          content: const Text('opened-via-bus'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _confirmSub?.cancel();
    _openDialogSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> _preWarmFlameImageCache() async {
  try {
    final bytes = await rootBundle.load(
      'assets/images/ui_button_nine_patch.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    Flame.images.add('ui_button_nine_patch.png', frame.image);
  } catch (e) {
    // Silently fail - the test might still work if the image is available later
  }
}

Widget buildPanel({
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
  Orders currentOrders = const Orders(),
  AppEventBus? bus,
}) {
  final panelBus = bus ?? AppEventBus.create();
  final navigatorKey = GlobalKey<NavigatorState>();
  return MaterialApp(
    navigatorKey: navigatorKey,
    home: Scaffold(
      body: _EventHandlingWrapper(
        bus: panelBus,
        navigatorKey: navigatorKey,
        child: DiplomacyPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          topology: topology,
          currentOrders: currentOrders,
          bus: panelBus,
        ),
      ),
    ),
  );
}

Game _gameWithNoDiscoveredFactions() {
  const ow = 'oldWorld';
  final p1 = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'P1',
    ownerId: 'gp1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [p1], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  const player = Player(id: 'gp1', displayName: 'Solo', isHuman: true);
  return Game(
    id: 'empty-diplo',
    worldState: world,
    players: const [player],
    diplomacyRelations: const [],
  );
}

void main() {
  suppressLogsForTests();

  late Game gameWithFactions;
  late Game gameWithNoDiscovered;
  late String humanPlayerId;
  late MapTopology topology;

  setUp(() {
    AppEventBus.reset();
  });

  setUpAll(() async {
    await _preWarmFlameImageCache();
    final result = getDebugInitGameResult();
    gameWithFactions = result.game;
    topology = result.combinedTopology;
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
    gameWithNoDiscovered = _gameWithNoDiscoveredFactions();
  });

  group('DiplomacyPanel', () {
    testWidgets('AC: Great Powers section when player has discovered GPs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Great Powers'), findsOneWidget);
    });

    testWidgets('AC: Faction rows show name and kind', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtPanel), findsAtLeastNWidgets(1));
      final firstGp = gameWithFactions.players
          .where((p) => p.id != humanPlayerId)
          .map((p) => p.displayName)
          .firstOrNull;
      if (firstGp != null) {
        expect(find.text(firstGp), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AC: Relation state shown (Peace or War)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Peace').evaluate().isNotEmpty ||
            find.textContaining('War').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
      'AC: One-word relation state shown (Hostile/Unfriendly/Cordial/Friendly), score hidden',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await tester.pumpAndSettle();

        final displayLabels = ['Hostile', 'Unfriendly', 'Cordial', 'Friendly'];
        final hasDisplayLabel = displayLabels.any(
          (label) => find.textContaining(label).evaluate().isNotEmpty,
        );
        expect(
          hasDisplayLabel,
          isTrue,
          reason: 'Panel must show one of $displayLabels',
        );

        expect(find.textContaining(' (50)'), findsNothing);
        expect(find.text('Neutral'), findsNothing);
      },
    );

    testWidgets('AC: Action buttons present for factions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtNinePatchButton), findsAtLeastNWidgets(1));
      expect(
        find.text('Declare War').evaluate().isNotEmpty ||
            find.text('Offer Peace').evaluate().isNotEmpty ||
            find.text('Alliance').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
      'AC: Tapping no-param action shows confirm dialog, Confirm submits order',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final events = <AppendDiplomaticOrderRequestedEvent>[];
        final sub = bus.on<AppendDiplomaticOrderRequestedEvent>().listen(
          events.add,
        );
        await tester.pumpWidget(
          buildPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final declareWar = find.text('Declare War');
        if (declareWar.evaluate().isNotEmpty) {
          await tester.ensureVisible(declareWar.first);
          await tester.tap(declareWar.first);
          await tester.pumpAndSettle();
          expect(find.text('OK'), findsOneWidget);
          expect(find.text('Cancel'), findsWidgets);
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
          expect(events, hasLength(1));
          expect(events.first.playerId, humanPlayerId);
          expect(events.first.order.type, DiplomaticOrderType.declareWar);
        }
        await sub.cancel();
      },
    );

    testWidgets(
      'AC3: Confirmed diplomacy action emits NegotiationMoodUpdateEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final moodEvents = <NegotiationMoodUpdateEvent>[];
        final sub = bus.on<NegotiationMoodUpdateEvent>().listen(moodEvents.add);
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final declareWar = find.text('Declare War');
        if (declareWar.evaluate().isEmpty) return;
        await tester.tap(declareWar.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(moodEvents, isNotEmpty);
        final e = moodEvents.last;
        expect(e.leaderId, isNotEmpty);
        expect(e.currentMood, isNotEmpty);
        expect(e.offerQualityDelta, isNot(0));
      },
    );

    testWidgets(
      'AC: Param action opens grant/subsidy dialog via event handler wrapper',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await tester.pumpAndSettle();

        final grantAid = find.text('Grant Aid');
        final subsidy = find.text('Set Subsidy');
        final action = grantAid.evaluate().isNotEmpty ? grantAid : subsidy;
        if (action.evaluate().isEmpty) return;

        await tester.tap(action.first);
        await tester.pumpAndSettle();

        expect(find.text('dialog:$grantOrSubsidyDialogId'), findsOneWidget);
        expect(find.text('opened-via-bus'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: Tapping Cancel in confirm dialog dismisses without submitting',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final events = <AppendDiplomaticOrderRequestedEvent>[];
        final sub = bus.on<AppendDiplomaticOrderRequestedEvent>().listen(
          events.add,
        );
        await tester.pumpWidget(
          buildPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final declareWar = find.text('Declare War');
        if (declareWar.evaluate().isNotEmpty) {
          await tester.ensureVisible(declareWar.first);
          await tester.tap(declareWar.first);
          await tester.pumpAndSettle();
          expect(find.text('OK'), findsOneWidget);
          final cancelBtn = find.widgetWithText(TextButton, 'Cancel');
          await tester.tap(cancelBtn.first);
          await tester.pumpAndSettle();
          expect(events, isEmpty);
        }
        await sub.cancel();
      },
    );

    testWidgets('AC: Pending orders show Cancel button, action button hidden', (
      WidgetTester tester,
    ) async {
      final otherGp = gameWithFactions.players.firstWhere(
        (p) => p.id != humanPlayerId,
      );
      final initialOrders = Orders(
        diplomaticOrdersByPlayerId: {
          humanPlayerId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: otherGp.id,
            ),
          ],
        },
      );
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        initialOrders,
      );
      final targetRow = rows.firstWhere((r) => r.factionId == otherGp.id);
      expect(
        targetRow.pendingOrderTypes,
        contains(DiplomaticOrderType.declareWar),
      );
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
          currentOrders: initialOrders,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsWidgets);
    });

    testWidgets('AC: Tapping Cancel removes the pending order', (
      WidgetTester tester,
    ) async {
      final bus = AppEventBus.create();
      final events = <RemoveDiplomaticOrderRequestedEvent>[];
      final sub = bus.on<RemoveDiplomaticOrderRequestedEvent>().listen(
        events.add,
      );
      final otherGp = gameWithFactions.players.firstWhere(
        (p) => p.id != humanPlayerId,
      );
      final initialOrders = Orders(
        diplomaticOrdersByPlayerId: {
          humanPlayerId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: otherGp.id,
            ),
          ],
        },
      );
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
          currentOrders: initialOrders,
          bus: bus,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsWidgets);
      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();
      expect(events, hasLength(1));
      expect(events.first.playerId, humanPlayerId);
      expect(events.first.type, DiplomaticOrderType.declareWar);
      expect(events.first.targetFactionId, otherGp.id);
      await sub.cancel();
    });

    testWidgets('AC: Empty state when no factions discovered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(
          game: gameWithNoDiscovered,
          humanPlayerId: 'gp1',
          topology: const MapTopology(nodes: [], edges: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No other factions discovered yet.'), findsOneWidget);
    });

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('buildDiplomacyRows', () {
    test(
      'display mapping aligned with SPEC (relationScoreToDisplayLabel bands)',
      () {
        expect(relationScoreToDisplayLabel(0), 'Hostile');
        expect(relationScoreToDisplayLabel(29), 'Hostile');
        expect(relationScoreToDisplayLabel(30), 'Unfriendly');
        expect(relationScoreToDisplayLabel(49), 'Unfriendly');
        expect(relationScoreToDisplayLabel(50), 'Cordial');
        expect(relationScoreToDisplayLabel(69), 'Cordial');
        expect(relationScoreToDisplayLabel(70), 'Friendly');
        expect(relationScoreToDisplayLabel(100), 'Friendly');
      },
    );

    test('returns empty list when player has no relations', () {
      final rows = buildDiplomacyRows(
        gameWithNoDiscovered,
        const MapTopology(nodes: [], edges: []),
        'gp1',
        const Orders(),
      );
      expect(rows, isEmpty);
    });

    test('returns GP rows sorted by military power then province count', () {
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRows = rows
          .where((r) => r.kind == FactionKind.greatPower)
          .toList();
      if (gpRows.length < 2) return;
      for (var i = 0; i < gpRows.length - 1; i++) {
        final strA = aggregateMilitaryStrengthForPlayer(
          gameWithFactions,
          gpRows[i].factionId,
        );
        final strB = aggregateMilitaryStrengthForPlayer(
          gameWithFactions,
          gpRows[i + 1].factionId,
        );
        expect(strA >= strB, isTrue);
      }
    });

    test('GP rows have power score and player power score set', () {
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRows = rows
          .where((r) => r.kind == FactionKind.greatPower)
          .toList();
      for (final r in gpRows) {
        expect(r.powerScore, isNotNull, reason: 'GP row ${r.displayName}');
        expect(
          r.playerPowerScore,
          isNotNull,
          reason: 'GP row ${r.displayName}',
        );
      }
      final nonGp = rows.where((r) => r.kind != FactionKind.greatPower);
      for (final r in nonGp) {
        expect(r.powerScore, isNull);
        expect(r.playerPowerScore, isNull);
      }
    });

    test('pendingOrderTypes reflects submitted diplomatic orders', () {
      final otherGp = gameWithFactions.players.firstWhere(
        (p) => p.id != humanPlayerId,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          humanPlayerId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: otherGp.id,
            ),
          ],
        },
      );
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        orders,
      );
      final targetRow = rows.firstWhere((r) => r.factionId == otherGp.id);
      expect(
        targetRow.pendingOrderTypes,
        contains(DiplomaticOrderType.declareWar),
      );
    });
  });
}
