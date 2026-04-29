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
    bool builderOnly = false,
    String? prospectShortcutTargetTileKey,
    String? exploreShortcutTargetTileKey,
    String? buildImprovementShortcutTargetTileKey,
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
            builderOnly: builderOnly,
            prospectShortcutTargetTileKey: prospectShortcutTargetTileKey,
            exploreShortcutTargetTileKey: exploreShortcutTargetTileKey,
            buildImprovementShortcutTargetTileKey:
                buildImprovementShortcutTargetTileKey,
          ),
        ),
      ),
    );
  }

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

    testWidgets(
      'AC: pending rows show faithful remaining-turn number for each work target',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        const targetTileKey = 'oldWorld|p1|1|0';
        final cases = <({String unitType, String target, int turns})>[
          (unitType: 'Explorer', target: 'explore', turns: 3),
          (unitType: 'Explorer', target: 'prospect', turns: 1),
          (unitType: 'Builder', target: 'build_improvement', turns: 1),
          (unitType: 'Builder', target: 'upgrade_town', turns: 1),
          (unitType: 'Engineer', target: 'build_road', turns: 1),
          (unitType: 'Engineer', target: 'build_port', turns: 1),
          (unitType: 'Engineer', target: 'build_fort', turns: 3),
          (unitType: 'Rail Builder', target: 'build_rail', turns: 1),
          (unitType: 'Spy', target: 'steal_tech', turns: 5),
          (unitType: 'Spy', target: 'counter_spy', turns: 1),
          (unitType: 'Merchant', target: 'purchase_land', turns: 1),
        ];

        for (var i = 0; i < cases.length; i++) {
          final c = cases[i];
          final unitId = 'u_$i';
          final miniGame = Game(
            id: 'g_civ_pending_turns_${c.target}_$i',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: RegionData(
                provinces: const [
                  Province(
                    id: 'oldWorld|p1',
                    regionId: 'oldWorld',
                    displayName: 'Alpha',
                    fortLevel: 2,
                  ),
                ],
                units: [
                  Unit(
                    id: unitId,
                    type: c.unitType,
                    ownerId: human,
                    locationProvinceId: 'oldWorld|p1',
                    tileKey: tileKey,
                  ),
                ],
              ),
              newWorld: const RegionData(),
              resourceByTileKey: const {targetTileKey: 'grain'},
              tileKeysByRegionAndProvince: const {
                'oldWorld': {
                  'oldWorld|p1': [tileKey, targetTileKey],
                },
              },
  });
}
