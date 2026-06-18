// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_circular_locate_button.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_danger_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement, kWorkTargetExplore;

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
    return ProviderScope(
      overrides: [
        availableWorkTargetIdsForUnitProvider.overrideWith(
          (ref, unitId) => availableWorkTargets[unitId] ?? const [],
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: _EventHandlingWrapper(
            bus: resolvedBus,
            navigatorKey: navigatorKey,
            child: CivilianUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              currentOrders: currentOrders,
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
      ),
    );
  }

  group('CivilianUnitsPanel', () {
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
                  type: kUnitTypeBuilder,
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

        // R30 (#3514): Locate is the rightmost circular CtCircularLocateButton
        // (icon-only) in the action cluster per SPEC/ui/civilian-units-panel.md.
        final locateBtn = find.byType(CtCircularLocateButton);
        expect(locateBtn, findsOneWidget);
        final locatePressed = tester
            .widget<CtCircularLocateButton>(locateBtn.first)
            .onPressed;
        expect(locatePressed, isNotNull);
        locatePressed!();
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
                  type: kUnitTypeBuilder,
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
                Unit(
                  id: 'civ_b',
                  type: kUnitTypeEngineer,
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
          ProviderScope(
            overrides: [
              availableWorkTargetIdsForUnitProvider.overrideWith(
                (ref, _) => const <String>[],
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: CivilianUnitsPanel(
                  game: miniGame,
                  humanPlayerId: human,
                  currentOrders: const Orders(),
                  bus: bus,
                  tileScopeTileKey: tileKey,
                  initialSelectedUnitId: 'civ_a',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // R30 (#3514): every visible row exposes a circular
        // CtCircularLocateButton in the action cluster (per
        // SPEC/ui/civilian-units-panel.md), even rows that are not the
        // tile-scope selection.
        final locateIcons = find.byType(CtCircularLocateButton);
        expect(locateIcons, findsNWidgets(2));
        final locatePressed = tester
            .widget<CtCircularLocateButton>(locateIcons.at(1))
            .onPressed;
        expect(locatePressed, isNotNull);
        locatePressed!();
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
                  type: kUnitTypeBuilder,
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
                target: kWorkTargetBuildImprovement,
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
        await tester.tap(find.byType(CivilianUnitRowCard).first);
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

        // Work-target menu rows render through InkWell over palette-token
        // chrome (Refs #2914 S8 — no Material ListTile); an enabled row has a
        // non-null onTap.
        final enabledTargetRow = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byWidgetPredicate(
            (w) => w is InkWell && w.onTap != null,
          ),
        );
        if (enabledTargetRow.evaluate().isEmpty) return;
        final targetRow = tester.widget<InkWell>(enabledTargetRow.first);
        expect(targetRow.onTap, isNotNull);
        targetRow.onTap!();
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
          target: kWorkTargetExplore,
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

        // Scope to the row with our pending order via the stable ValueKey
        // exposed by CivilianUnitRowCard (`civilian-unit-card-<unitId>`).
        // `find.text(...)` can miss offstage rows in scrollable lists, so the
        // keyed finder is more robust than ancestor lookup by unit-type text.
        final pendingRow = find.byKey(
          ValueKey('civilian-unit-card-${idleCivilian.id}'),
          skipOffstage: false,
        );
        expect(pendingRow, findsOneWidget);
        // R30 (#3514): pending rows expose the destructive Cancel pill
        // (CtDangerTextButton, mockup `.u-actions .cancel-btn`) + circular
        // Locate in the action cluster.
        final cancelOnPendingRow = find.descendant(
          of: pendingRow,
          matching: find.byType(CtDangerTextButton, skipOffstage: false),
        );
        expect(cancelOnPendingRow, findsOneWidget);
        // Invoke the callback directly to assert confirm + bus emission without
        // depending on headless-Linux hit-test geometry.
        final cancelBtn = tester.widget<CtDangerTextButton>(cancelOnPendingRow);
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
          target: kWorkTargetExplore,
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

        final pendingRow = find.byKey(
          ValueKey('civilian-unit-card-${idleCivilian.id}'),
          skipOffstage: false,
        );
        expect(pendingRow, findsOneWidget);
        final cancelOnPendingRow = find.descendant(
          of: pendingRow,
          matching: find.byType(CtDangerTextButton, skipOffstage: false),
        );
        expect(cancelOnPendingRow, findsOneWidget);
        final cancelBtn = tester.widget<CtDangerTextButton>(cancelOnPendingRow);
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
          target: kWorkTargetExplore,
          targetTileKey:
              '${idleCivilian.tileKey!.split('|').take(2).join('|')}|0|0',
        );
        final ordersWithOne = Orders(
          workOrdersByPlayerId: {
            humanPlayerIdWithUnits: [pendingOrder],
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              availableWorkTargetIdsForUnitProvider.overrideWith(
                (ref, _) => const <String>[],
              ),
            ],
            child: MaterialApp(
              navigatorKey: navigatorKey,
              home: Scaffold(
                body: Column(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: observedRemovals,
                      builder: (_, count, _) =>
                          Text('observed-removals:$count'),
                    ),
                    Expanded(
                      child: _EventHandlingWrapper(
                        bus: bus,
                        navigatorKey: navigatorKey,
                        child: CivilianUnitsPanel(
                          game: game,
                          humanPlayerId: humanPlayerIdWithUnits,
                          currentOrders: ordersWithOne,
                          bus: bus,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('observed-removals:0'), findsOneWidget);

        final pendingRow = find.byKey(
          ValueKey('civilian-unit-card-${idleCivilian.id}'),
          skipOffstage: false,
        );
        expect(pendingRow, findsOneWidget);
        final cancelOnPendingRow = find.descendant(
          of: pendingRow,
          matching: find.byType(CtDangerTextButton, skipOffstage: false),
        );
        final cancelBtn = tester.widget<CtDangerTextButton>(cancelOnPendingRow);
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
          ProviderScope(
            overrides: [
              availableWorkTargetIdsForUnitProvider.overrideWith(
                (ref, _) => const <String>[],
              ),
            ],
            child: MaterialApp(
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
                          bus: bus,
                        ),
                      ),
                    ),
                  ],
                ),
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
  });
}

bool _isCivilian(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}
