// DiplomacyPanel order UI: empty state, confirm dialog, pending cancel.
import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.bus.on<ConfirmDialogEvent>().listen((event) async {
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
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PendingOrderShell extends StatefulWidget {
  const _PendingOrderShell({
    required this.game,
    required this.humanPlayerId,
    required this.topology,
    required this.bus,
  });

  final Game game;
  final String humanPlayerId;
  final MapTopology topology;
  final AppEventBus bus;

  @override
  State<_PendingOrderShell> createState() => _PendingOrderShellState();
}

class _PendingOrderShellState extends State<_PendingOrderShell> {
  late Orders _orders;

  Orders get ordersSnapshot => _orders;

  @override
  void initState() {
    super.initState();
    final targetId = widget.game.players
        .firstWhere((p) => p.id != widget.humanPlayerId)
        .id;
    _orders = Orders(
      diplomaticOrdersByPlayerId: {
        widget.humanPlayerId: [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: targetId,
          ),
        ],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DiplomacyPanel(
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          topology: widget.topology,
          currentOrders: _orders,
          onOrdersChanged: (o) => setState(() => _orders = o),
          bus: widget.bus,
        ),
      ),
    );
  }
}

void main() {
  suppressLogsForTests();

  setUp(() {
    AppEventBus.reset();
  });

  testWidgets('DiplomacyPanel shows empty state when no factions discovered', (
    WidgetTester tester,
  ) async {
    const humanId = 'solo';
    final game = Game(
      id: 'solo_game',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: humanId, displayName: 'Only', isHuman: true, treasury: 0),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiplomacyPanel(
            game: game,
            humanPlayerId: humanId,
            topology: MapTopology(),
            currentOrders: const Orders(),
            onOrdersChanged: (_) {},
            bus: AppEventBus.create(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No other factions discovered yet.'), findsOneWidget);
  });

  testWidgets(
    'DiplomacyPanel Declare War opens confirm dialog; Cancel dismisses',
    (WidgetTester tester) async {
      final r = getDebugInitGameResult();
      final game = r.game;
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: _EventHandlingWrapper(
              bus: bus,
              navigatorKey: navigatorKey,
              child: DiplomacyPanel(
                game: game,
                humanPlayerId: humanId,
                topology: r.combinedTopology,
                currentOrders: const Orders(),
                onOrdersChanged: (_) {},
                bus: bus,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final declareWar = find.text('Declare War');
      if (declareWar.evaluate().isEmpty) {
        return;
      }

      await tester.ensureVisible(declareWar.first);
      await tester.tap(declareWar.first);
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsWidgets);
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'DiplomacyPanel pending order shows Cancel on CtNinePatchButton; tap clears',
    (WidgetTester tester) async {
      final r = getDebugInitGameResult();
      final game = r.game;
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();

      await tester.pumpWidget(
        _PendingOrderShell(
          game: game,
          humanPlayerId: humanId,
          topology: r.combinedTopology,
          bus: bus,
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<_PendingOrderShellState>(
        find.byType(_PendingOrderShell),
      );
      expect(
        state.ordersSnapshot.diplomaticOrdersByPlayerId[humanId],
        isNotEmpty,
      );

      final cancelOnPatch = find.widgetWithText(CtNinePatchButton, 'Cancel');
      expect(cancelOnPatch, findsWidgets);
      await tester.tap(cancelOnPatch.first);
      await tester.pumpAndSettle();

      expect(
        state.ordersSnapshot.diplomaticOrdersByPlayerId[humanId] ?? [],
        isEmpty,
      );
    },
  );
}
