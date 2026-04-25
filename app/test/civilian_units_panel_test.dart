// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';

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
  StreamSubscription? _closeSub;

  @override
  void initState() {
    super.initState();
    _closeSub = widget.bus.on<ClosePanelEvent>().listen((_) {
      widget.navigatorKey.currentState?.maybePop();
    });
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
  }

  @override
  void dispose() {
    _confirmSub?.cancel();
    _closeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = getDebugInitGameResult().game;
    humanPlayerIdWithUnits = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    Orders currentOrders = const Orders(),
    Map<String, List<String>> availableWorkTargets = const {},
    AppEventBus? bus,
    bool explorerOnly = false,
    String? prospectShortcutTargetTileKey,
  }) {
    final resolvedBus = bus ?? AppEventBus.create();
    final navigatorKey = GlobalKey<NavigatorState>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: _EventHandlingWrapper(
          bus: resolvedBus,
          navigatorKey: navigatorKey,
          child: CivilianUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: currentOrders,
            availableWorkTargets: availableWorkTargets,
            bus: resolvedBus,
            explorerOnly: explorerOnly,
            prospectShortcutTargetTileKey: prospectShortcutTargetTileKey,
          ),
        ),
      ),
    );
  }

  group('CivilianUnitsPanel', () {
    testWidgets('AC: Panel shows title Civilian Units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('Civilian Units'), findsOneWidget);
    });

    testWidgets('AC: full-list mode has Train only in header (no Tile)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('Train'), findsOneWidget);
      expect(find.text('Tile'), findsNothing);
    });

    testWidgets('AC: Empty state when human player has zero civilian units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithNoUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('No civilian units'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets(
      'AC: When player has civilians, list shows units with status, location, assigned-to',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        final listTiles = find.byType(ListTile);
        if (listTiles.evaluate().isEmpty) {
          return;
        }
        expect(listTiles, findsAtLeastNWidgets(1));
        expect(find.byType(UnitsEntityActionRow), findsAtLeastNWidgets(1));
        expect(find.textContaining('Status:'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Location:'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Assigned to:'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'work targets not in availableWorkTargets are grayed out (disabled)',
      (WidgetTester tester) async {
        // Find an idle civilian unit
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;
        final idleCivilian = idleCivilians.first;

        // Get allowed work targets for this unit type
        final allowed = workOrderTargetsByUnitType[idleCivilian.type] ?? [];
        if (allowed.isEmpty) return;

        // Provide empty availableWorkTargets - ALL items should be disabled
        final availableWorkTargets = <String, List<String>>{};

        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            availableWorkTargets: availableWorkTargets,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Assign').first);
        await tester.pumpAndSettle();

        expect(find.textContaining('Assign work'), findsOneWidget);

        // Get all ListTiles - all should be disabled
        final listTiles = find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(ListTile),
            )
            .evaluate();

        expect(listTiles, isNotEmpty);

        // All items should be disabled when availableWorkTargets is empty
        for (final tile in listTiles) {
          final widget = tile.widget as ListTile;
          expect(
            widget.enabled,
            isFalse,
            reason: 'All items should be disabled when no available targets',
          );
        }

        final scaffoldCtx = tester.element(find.byType(Scaffold));
        Navigator.of(scaffoldCtx, rootNavigator: true).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Assign button shown for idle unit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isEmpty) return;
      expect(find.text('Assign'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Assign opens order menu', (WidgetTester tester) async {
      // Find an idle civilian unit
      final units = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ];
      final idleCivilians = units.where(
        (u) =>
            u.ownerId == humanPlayerIdWithUnits &&
            u.tileKey != null &&
            _isCivilian(u) &&
            u.currentWork == null,
      );
      // Skip if no idle civilians in test game
      if (idleCivilians.isEmpty) return;

      await tester.pumpWidget(
        buildPanel(
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
          // Pass empty availableWorkTargets - all options will be disabled
          // This tests the UI renders but callback won't fire on disabled items
          availableWorkTargets: const {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assign').first);
      await tester.pumpAndSettle();

      // Menu opens but all items are disabled since no available targets provided
      expect(find.textContaining('Assign work'), findsOneWidget);
      // Note: selectedUnit/selectedTarget remain null because items are disabled

      final scaffoldCtx = tester.element(find.byType(Scaffold));
      Navigator.of(scaffoldCtx, rootNavigator: true).pop();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'prospect shortcut mode filters explorers and directly commits pending prospect on selected tile',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_prospect_shortcut',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'e1',
                  type: 'Explorer',
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
                Unit(
                  id: 'b1',
                  type: 'Builder',
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        final bus = AppEventBus.create();
        final events = <Type>[];
        UpsertPendingCivilianWorkOrderRequestedEvent? upsertEvent;
        bus.stream.listen((e) => events.add(e.runtimeType));
        bus.on<UpsertPendingCivilianWorkOrderRequestedEvent>().listen(
          (event) => upsertEvent = event,
        );
        await tester.pumpWidget(
          buildPanel(
            game: miniGame,
            humanPlayerId: human,
            bus: bus,
            explorerOnly: true,
            prospectShortcutTargetTileKey: tileKey,
            availableWorkTargets: const {
              'e1': ['prospect'],
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Explorer'), findsOneWidget);
        expect(find.text('Builder'), findsNothing);

        await tester.tap(find.text('Assign'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.textContaining('Assign work'), findsNothing);
        expect(upsertEvent, isNotNull);
        expect(upsertEvent!.playerId, human);
        expect(upsertEvent!.workOrder.unitId, 'e1');
        expect(upsertEvent!.workOrder.target, 'prospect');
        expect(upsertEvent!.workOrder.targetTileKey, tileKey);
        expect(events.contains(StartCivilianWorkTargetSelectionEvent), isFalse);
        expect(
          events.indexOf(ClosePanelEvent),
          lessThan(
            events.indexOf(UpsertPendingCivilianWorkOrderRequestedEvent),
          ),
        );
      },
    );

    testWidgets('Train button emits train-civilians dialog open event', (
      WidgetTester tester,
    ) async {
      OpenDialogEvent? openDialogEvent;
      final bus = AppEventBus.create();
      bus.on<OpenDialogEvent>().listen((e) => openDialogEvent = e);

      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits, bus: bus),
      );
      await tester.pumpAndSettle();

      final trainButton = find.text('Train');
      expect(trainButton, findsOneWidget);
      await tester.tap(trainButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(openDialogEvent, isNotNull);
      expect(openDialogEvent!.dialogId, trainCiviliansDialogId);
    });

    testWidgets(
      'AC: tapping civilian row emits ClosePanelEvent before LocateMapTileEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final sequence = <Type>[];
        bus.stream.listen((e) => sequence.add(e.runtimeType));

        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final listTiles = find.byType(ListTile);
        if (listTiles.evaluate().isEmpty) return;
        await tester.tap(listTiles.first);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          sequence.indexOf(ClosePanelEvent),
          lessThan(sequence.indexOf(LocateMapTileEvent)),
        );
      },
    );

    testWidgets(
      'AC: per-row locate icon emits LocateMapTileEvent without ClosePanelEvent',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_locate_icon',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'civ1',
                  type: 'Builder',
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        var closeCount = 0;
        LocateMapTileEvent? locateEvent;
        final bus = AppEventBus.create();
        bus.on<ClosePanelEvent>().listen((_) => closeCount++);
        bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);

        await tester.pumpWidget(
          buildPanel(game: miniGame, humanPlayerId: human, bus: bus),
        );
        await tester.pumpAndSettle();

        final locateBtn = find.byTooltip('Locate');
        expect(locateBtn, findsOneWidget);
        final iconButtons = find.byType(IconButton);
        expect(iconButtons, findsOneWidget);
        final iconBtn = tester.widget<IconButton>(iconButtons.first);
        expect(iconBtn.iconSize, 18);
        expect(iconBtn.visualDensity, VisualDensity.compact);

        await tester.tap(locateBtn);
        await tester.pump();

        expect(closeCount, 0);
        expect(locateEvent, isNotNull);
        expect(locateEvent!.tileKey, tileKey);
        expect(locateEvent!.regionId, 'oldWorld');
      },
    );

    testWidgets(
      'AC: tile-scoped locate icon on non-selected row emits LocateMapTileEvent',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_locate_tile_scope',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'civ_a',
                  type: 'Builder',
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
                Unit(
                  id: 'civ_b',
                  type: 'Engineer',
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        var closeCount = 0;
        LocateMapTileEvent? locateEvent;
        final bus = AppEventBus.create();
        bus.on<ClosePanelEvent>().listen((_) => closeCount++);
        bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CivilianUnitsPanel(
                game: miniGame,
                humanPlayerId: human,
                currentOrders: const Orders(),
                availableWorkTargets: const {},
                bus: bus,
                tileScopeTileKey: tileKey,
                initialSelectedUnitId: 'civ_a',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final locateIcons = find.byTooltip('Locate');
        expect(locateIcons, findsNWidgets(2));

        await tester.tap(locateIcons.at(1));
        await tester.pump();

        expect(closeCount, 0);
        expect(locateEvent, isNotNull);
        expect(locateEvent!.tileKey, tileKey);
        expect(locateEvent!.regionId, 'oldWorld');
      },
    );

    testWidgets(
      'uses pending target tile for Location and locate event in full-list mode',
      (WidgetTester tester) async {
        const human = 'gp1';
        const standingTile = 'oldWorld|p1|0|0';
        const pendingTile = 'oldWorld|p2|0|0';
        final gameWithPending = Game(
          id: 'g_pending_projection',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
                Province(
                  id: 'oldWorld|p2',
                  regionId: 'oldWorld',
                  displayName: 'Beta',
                ),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'Builder',
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: standingTile,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        final orders = const Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'u1',
                target: 'build_improvement',
                targetTileKey: pendingTile,
              ),
            ],
          },
        );
        LocateMapTileEvent? locateEvent;
        final bus = AppEventBus.create();
        bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);

        await tester.pumpWidget(
          buildPanel(
            game: gameWithPending,
            humanPlayerId: human,
            currentOrders: orders,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Location: Old World — Beta'),
          findsOneWidget,
        );
        await tester.tap(find.byType(ListTile).first);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(locateEvent, isNotNull);
        expect(locateEvent!.tileKey, pendingTile);
      },
    );

    testWidgets(
      'AC: assign target emits ClosePanelEvent before StartCivilianWorkTargetSelectionEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final sequence = <Type>[];
        bus.stream.listen((e) => sequence.add(e.runtimeType));

        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;

        final availableWorkTargets = <String, List<String>>{};
        for (final u in idleCivilians) {
          final allowed =
              workOrderTargetsByUnitType[u.type] ?? const <String>[];
          if (allowed.isNotEmpty) {
            availableWorkTargets[u.id] = [allowed.first];
          }
        }
        if (availableWorkTargets.isEmpty) return;

        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            bus: bus,
            availableWorkTargets: availableWorkTargets,
          ),
        );
        await tester.pumpAndSettle();

        final assignButton = find.text('Assign');
        if (assignButton.evaluate().isEmpty) return;
        await tester.tap(assignButton.first);
        await tester.pumpAndSettle();

        final enabledTargetTile = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byWidgetPredicate(
            (w) => w is ListTile && w.enabled == true,
          ),
        );
        if (enabledTargetTile.evaluate().isEmpty) return;
        final targetTile = tester.widget<ListTile>(enabledTargetTile.first);
        expect(targetTile.onTap, isNotNull);
        targetTile.onTap!();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          sequence.indexOf(ClosePanelEvent),
          lessThan(sequence.indexOf(StartCivilianWorkTargetSelectionEvent)),
        );
      },
    );

    testWidgets(
      'Cancel on pending row shows confirm dialog; Yes emits RemovePendingWorkOrderRequestedEvent',
      (WidgetTester tester) async {
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;
        final idleCivilian = idleCivilians.first;

        RemovePendingWorkOrderRequestedEvent? removeEvent;
        final bus = AppEventBus.create();
        bus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
          removeEvent = e;
        });
        final pendingOrder = WorkOrder(
          unitId: idleCivilian.id,
          target: 'explore',
          targetTileKey:
              '${idleCivilian.tileKey!.split('|').take(2).join('|')}|0|0',
        );
        final ordersWithOne = Orders(
          workOrdersByPlayerId: {
            humanPlayerIdWithUnits: [pendingOrder],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            bus: bus,
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            currentOrders: ordersWithOne,
          ),
        );
        await tester.pumpAndSettle();

        // Scope to the row with our pending order — avoid `.first` on "Cancel"
        // (debug game may show multiple Cancel buttons; first may be off-stage / obscured).
        final pendingRow = find.ancestor(
          of: find.text(idleCivilian.type),
          matching: find.byType(ListTile),
        );
        expect(pendingRow, findsOneWidget);
        // Tap the nine-patch control (InkWell), not the Text center — avoids
        // hit-test misses when the label sits off the interactive region.
        final cancelOnPendingRow = find.descendant(
          of: pendingRow,
          matching: find.byType(CtNinePatchButton),
        );
        expect(cancelOnPendingRow, findsOneWidget);
        await tester.ensureVisible(cancelOnPendingRow);
        // CtNinePatchButton + Flame nine-patch often fail widget hit tests at the
        // label center; invoke the callback to assert confirm + bus emission.
        final cancelBtn = tester.widget<CtNinePatchButton>(cancelOnPendingRow);
        expect(cancelBtn.onPressed, isNotNull);
        cancelBtn.onPressed!();
        await tester.pumpAndSettle();

        expect(find.text('Cancel work order?'), findsOneWidget);
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(removeEvent, isNotNull);
        expect(removeEvent!.playerId, humanPlayerIdWithUnits);
        expect(removeEvent!.index, 0);
      },
    );

    testWidgets(
      'Cancel on pending row then No dismisses dialog without RemovePendingWorkOrder event',
      (WidgetTester tester) async {
        RemovePendingWorkOrderRequestedEvent? removeEvent;
        final bus = AppEventBus.create();
        bus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
          removeEvent = e;
        });
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;
        final idleCivilian = idleCivilians.first;

        final pendingOrder = WorkOrder(
          unitId: idleCivilian.id,
          target: 'explore',
          targetTileKey:
              '${idleCivilian.tileKey!.split('|').take(2).join('|')}|0|0',
        );
        final ordersWithOne = Orders(
          workOrdersByPlayerId: {
            humanPlayerIdWithUnits: [pendingOrder],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            bus: bus,
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            currentOrders: ordersWithOne,
          ),
        );
        await tester.pumpAndSettle();

        final pendingRow = find.ancestor(
          of: find.text(idleCivilian.type),
          matching: find.byType(ListTile),
        );
        expect(pendingRow, findsOneWidget);
        final cancelOnPendingRow = find.descendant(
          of: pendingRow,
          matching: find.byType(CtNinePatchButton),
        );
        expect(cancelOnPendingRow, findsOneWidget);
        await tester.ensureVisible(cancelOnPendingRow);
        final cancelBtn = tester.widget<CtNinePatchButton>(cancelOnPendingRow);
        expect(cancelBtn.onPressed, isNotNull);
        cancelBtn.onPressed!();
        await tester.pumpAndSettle();
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        expect(removeEvent, isNull);
      },
    );

    testWidgets(
      'pending cancel event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final navigatorKey = GlobalKey<NavigatorState>();
        final observedRemovals = ValueNotifier<int>(0);
        final sub = bus.on<RemovePendingWorkOrderRequestedEvent>().listen((_) {
          observedRemovals.value = observedRemovals.value + 1;
        });
        addTearDown(() async {
          await sub.cancel();
          observedRemovals.dispose();
        });

        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;
        final idleCivilian = idleCivilians.first;

        final pendingOrder = WorkOrder(
          unitId: idleCivilian.id,
          target: 'explore',
          targetTileKey:
              '${idleCivilian.tileKey!.split('|').take(2).join('|')}|0|0',
        );
        final ordersWithOne = Orders(
          workOrdersByPlayerId: {
            humanPlayerIdWithUnits: [pendingOrder],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: Scaffold(
              body: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: observedRemovals,
                    builder: (_, count, _) => Text('observed-removals:$count'),
                  ),
                  Expanded(
                    child: _EventHandlingWrapper(
                      bus: bus,
                      navigatorKey: navigatorKey,
                      child: CivilianUnitsPanel(
                        game: game,
                        humanPlayerId: humanPlayerIdWithUnits,
                        currentOrders: ordersWithOne,
                        availableWorkTargets: const {},
                        bus: bus,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('observed-removals:0'), findsOneWidget);

        final pendingRow = find.ancestor(
          of: find.text(idleCivilian.type),
          matching: find.byType(ListTile),
        );
        expect(pendingRow, findsOneWidget);
        final cancelOnPendingRow = find.descendant(
          of: pendingRow,
          matching: find.byType(CtNinePatchButton),
        );
        final cancelBtn = tester.widget<CtNinePatchButton>(cancelOnPendingRow);
        cancelBtn.onPressed!();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('observed-removals:1'), findsOneWidget);
      },
    );

    testWidgets(
      'in-progress cancel event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final navigatorKey = GlobalKey<NavigatorState>();
        final observedCancels = ValueNotifier<int>(0);
        final sub = bus.on<CancelInProgressCivilianWorkRequestedEvent>().listen(
          (_) {
            observedCancels.value = observedCancels.value + 1;
          },
        );
        addTearDown(() async {
          await sub.cancel();
          observedCancels.dispose();
        });

        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final workingCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork != null,
        );
        if (workingCivilians.isEmpty) return;

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: Scaffold(
              body: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: observedCancels,
                    builder: (_, count, _) => Text('observed-cancels:$count'),
                  ),
                  Expanded(
                    child: _EventHandlingWrapper(
                      bus: bus,
                      navigatorKey: navigatorKey,
                      child: CivilianUnitsPanel(
                        game: game,
                        humanPlayerId: humanPlayerIdWithUnits,
                        currentOrders: const Orders(),
                        availableWorkTargets: const {},
                        bus: bus,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('observed-cancels:0'), findsOneWidget);

        final cancelButtons = find.text('Cancel');
        if (cancelButtons.evaluate().isEmpty) return;
        await tester.tap(cancelButtons.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('observed-cancels:1'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: pending build_improvement shows ResourceIcons and omits (pending)',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_pending_build',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'b1',
                  type: 'Builder',
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'b1',
                target: 'build_improvement',
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            game: miniGame,
            humanPlayerId: human,
            currentOrders: orders,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Assigned to:'), findsOneWidget);
        expect(find.textContaining('(pending)'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (w) => w is ResourceIcon && w.commodityId == 'lumber',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is ResourceIcon && w.commodityId == 'castIron',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC: pending explore shows inline turns and no ResourceIcon strip',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_pending_explore',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'e1',
                  type: 'Explorer',
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'e1',
                target: 'explore',
                targetTileKey: 'oldWorld|p1|0|0',
              ),
            ],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            game: miniGame,
            humanPlayerId: human,
            currentOrders: orders,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('(pending)'), findsNothing);
        expect(find.textContaining('Assigned to: Explore'), findsOneWidget);
        expect(find.textContaining('turn'), findsAtLeastNWidgets(1));
        expect(find.byType(ResourceIcon), findsNothing);
      },
    );

    testWidgets(
      'AC: pending purchase_land shows treasury chip not ResourceIcon',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_pending_land',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'm1',
                  type: 'Merchant',
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: {tileKey: 'grain'},
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'm1',
                target: 'purchase_land',
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            game: miniGame,
            humanPlayerId: human,
            currentOrders: orders,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Treasury:'), findsOneWidget);
        expect(find.textContaining('(pending)'), findsNothing);
        expect(find.byType(ResourceIcon), findsNothing);
      },
    );

    testWidgets(
      'AC: pending purchase_land without tile resource still shows inline turns',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_pending_land_nores',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Alpha',
                ),
              ],
              units: [
                Unit(
                  id: 'm1',
                  type: 'Merchant',
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: human, displayName: 'Human', isHuman: true),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'm1',
                target: 'purchase_land',
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            game: miniGame,
            humanPlayerId: human,
            currentOrders: orders,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('(pending)'), findsNothing);
        expect(
          find.textContaining('Assigned to: Purchase land'),
          findsOneWidget,
        );
        expect(find.textContaining('turn'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Treasury:'), findsNothing);
      },
    );

    testWidgets('AC: pending build_rail shows steel and lumber icons', (
      WidgetTester tester,
    ) async {
      const human = 'h1';
      const tileKey = 'oldWorld|p1|0|0';
      final miniGame = Game(
        id: 'g_civ_pending_rail',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'Alpha',
              ),
            ],
            units: [
              Unit(
                id: 'r1',
                type: 'Rail Builder',
                ownerId: human,
                locationProvinceId: 'oldWorld|p1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: human, displayName: 'Human', isHuman: true)],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          human: [
            WorkOrder(
              unitId: 'r1',
              target: 'build_rail',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      await tester.pumpWidget(
        buildPanel(game: miniGame, humanPlayerId: human, currentOrders: orders),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('(pending)'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is ResourceIcon && w.commodityId == 'lumber',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is ResourceIcon && w.commodityId == 'steel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('AC: in-progress work row has no pending cost ResourceIcons', (
      WidgetTester tester,
    ) async {
      const human = 'h1';
      const tileKey = 'oldWorld|p1|0|0';
      final miniGame = Game(
        id: 'g_civ_working',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'Alpha',
              ),
            ],
            units: [
              Unit(
                id: 'b1',
                type: 'Builder',
                ownerId: human,
                locationProvinceId: 'oldWorld|p1',
                tileKey: tileKey,
                status: UnitStatus.working,
                currentWork: const CurrentWork(
                  workTarget: 'build_improvement',
                  tileKey: tileKey,
                  totalTurns: 5,
                  remainingTurns: 2,
                ),
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: human, displayName: 'Human', isHuman: true)],
      );
      await tester.pumpWidget(buildPanel(game: miniGame, humanPlayerId: human));
      await tester.pumpAndSettle();

      expect(find.textContaining('2/5'), findsOneWidget);
      expect(find.byType(ResourceIcon), findsNothing);
    });

    testWidgets(
      'tile-scoped mode: Tile then Train in header; no Tile on ListTiles',
      (WidgetTester tester) async {
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final civilianWithTile = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u),
        );
        if (civilianWithTile.isEmpty) return;
        final scopedTileKey = civilianWithTile.first.tileKey!;
        final scopedUnitId = civilianWithTile.first.id;
        final bus = AppEventBus.create();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CivilianUnitsPanel(
                game: game,
                humanPlayerId: humanPlayerIdWithUnits,
                currentOrders: const Orders(),
                availableWorkTargets: const {},
                bus: bus,
                tileScopeTileKey: scopedTileKey,
                initialSelectedUnitId: scopedUnitId,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Civilian Units (Tile)'), findsOneWidget);
        expect(find.text('Tile'), findsOneWidget);

        final shellButtons = find.descendant(
          of: find.byType(UnitsPanelShell),
          matching: find.byType(CtNinePatchButton),
        );
        expect(
          find.descendant(of: shellButtons.at(0), matching: find.text('Tile')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: shellButtons.at(1), matching: find.text('Train')),
          findsOneWidget,
        );

        expect(
          find.descendant(
            of: find.byType(ListTile),
            matching: find.text('Tile'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('tile-scoped empty list: header Tile is disabled', (
      WidgetTester tester,
    ) async {
      final bus = AppEventBus.create();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivilianUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerIdWithUnits,
              bus: bus,
              tileScopeTileKey:
                  'oldWorld|no_civilian_units_on_this_province|0|0',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Civilian Units (Tile)'), findsOneWidget);
      expect(find.text('No civilian units'), findsOneWidget);
      final tileButton = find.ancestor(
        of: find.text('Tile'),
        matching: find.byType(CtNinePatchButton),
      );
      expect(tester.widget<CtNinePatchButton>(tileButton).enabled, isFalse);
    });

    testWidgets(
      'tile-scoped header Tile emits OpenMapTileDetailEvent for rendered tile',
      (WidgetTester tester) async {
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final civilian = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u),
        );
        if (civilian.isEmpty) return;
        final u = civilian.first;
        final rendered = u.assignedTileKey?.isNotEmpty == true
            ? u.assignedTileKey!
            : u.tileKey!;

        final bus = AppEventBus.create();
        OpenMapTileDetailEvent? captured;
        final sub = bus.on<OpenMapTileDetailEvent>().listen((e) {
          captured = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CivilianUnitsPanel(
                game: game,
                humanPlayerId: humanPlayerIdWithUnits,
                bus: bus,
                tileScopeTileKey: rendered,
                initialSelectedUnitId: u.id,
              ),
            ),
          ),
        );
        // Avoid pumpAndSettle: nine-patch buttons may not settle in widget tests.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        captured = null;
        await tester.tap(find.text('Tile'));
        await tester.pump();
        await tester.pump();
        expect(captured, isNotNull);
        expect(captured?.tileKey, rendered);
      },
    );
  });
}

bool _isCivilian(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}
