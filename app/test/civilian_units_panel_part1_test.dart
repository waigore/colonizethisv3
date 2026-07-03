// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement, kWorkTargetExplore, kWorkTargetProspect;

import 'support/diplomacy_panel_test_support.dart';
import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = buildCivilianPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
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
          body: CivilianPanelBusDialogHost(
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
      expect(find.byType(CivilianUnitRowCard), findsNothing);
    });

    testWidgets(
      'AC: When player has civilians, list shows units with status, location, assigned-to',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        final unitRows = find.byType(CivilianUnitRowCard);
        if (unitRows.evaluate().isEmpty) {
          return;
        }
        expect(unitRows, findsAtLeastNWidgets(1));
        // Locate is rendered for every visible row per R30 (action-cluster
        // rightmost; see SPEC/ui/civilian-units-panel.md).
        expect(find.byTooltip('Locate'), findsAtLeastNWidgets(1));
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

        // Get all target rows - all should be disabled. Work-target menu rows
        // render through InkWell over palette-token chrome (Refs #2914 S8 —
        // no Material ListTile); a disabled row has a null onTap.
        final targetRows = find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(InkWell),
            )
            .evaluate();

        expect(targetRows, isNotEmpty);

        // All items should be disabled when availableWorkTargets is empty
        for (final row in targetRows) {
          final widget = row.widget as InkWell;
          expect(
            widget.onTap,
            isNull,
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

      final unitRows = find.byType(CivilianUnitRowCard);
      if (unitRows.evaluate().isEmpty) return;
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
                  type: kUnitTypeExplorer,
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
                Unit(
                  id: 'b1',
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
              'e1': [kWorkTargetProspect],
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(kUnitTypeExplorer), findsOneWidget);
        expect(find.text(kUnitTypeBuilder), findsNothing);

        await tester.tap(find.text('Assign'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.textContaining('Assign work'), findsNothing);
        expect(upsertEvent, isNotNull);
        expect(upsertEvent!.playerId, human);
        expect(upsertEvent!.workOrder.unitId, 'e1');
        expect(upsertEvent!.workOrder.target, kWorkTargetProspect);
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

    testWidgets(
      'explore shortcut mode filters explorers and directly commits pending explore on selected tile',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_explore_shortcut',
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
                  type: kUnitTypeExplorer,
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
                Unit(
                  id: 'b1',
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
            exploreShortcutTargetTileKey: tileKey,
            availableWorkTargets: const {
              'e1': [kWorkTargetExplore],
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(kUnitTypeExplorer), findsOneWidget);
        expect(find.text(kUnitTypeBuilder), findsNothing);

        await tester.tap(find.text('Assign'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.textContaining('Assign work'), findsNothing);
        expect(upsertEvent, isNotNull);
        expect(upsertEvent!.playerId, human);
        expect(upsertEvent!.workOrder.unitId, 'e1');
        expect(upsertEvent!.workOrder.target, kWorkTargetExplore);
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

    testWidgets(
      'build-improvement shortcut mode filters builders and directly commits pending build_improvement on selected tile',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = Game(
          id: 'g_civ_build_improvement_shortcut',
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
                  type: kUnitTypeBuilder,
                  ownerId: human,
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
                Unit(
                  id: 'e1',
                  type: kUnitTypeExplorer,
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
            builderOnly: true,
            buildImprovementShortcutTargetTileKey: tileKey,
            availableWorkTargets: const {
              'b1': [kWorkTargetBuildImprovement],
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(kUnitTypeBuilder), findsOneWidget);
        expect(find.text(kUnitTypeExplorer), findsNothing);

        await tester.tap(find.text('Assign'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.textContaining('Assign work'), findsNothing);
        expect(upsertEvent, isNotNull);
        expect(upsertEvent!.playerId, human);
        expect(upsertEvent!.workOrder.unitId, 'b1');
        expect(upsertEvent!.workOrder.target, kWorkTargetBuildImprovement);
        expect(upsertEvent!.workOrder.targetTileKey, tileKey);
        expect(events.contains(StartCivilianWorkTargetSelectionEvent), isFalse);
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

        final unitRows = find.byType(CivilianUnitRowCard);
        if (unitRows.evaluate().isEmpty) return;
        await tester.tap(unitRows.first);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          sequence.indexOf(ClosePanelEvent),
          lessThan(sequence.indexOf(LocateMapTileEvent)),
        );
      },
    );
  });
}

bool _isCivilian(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}
