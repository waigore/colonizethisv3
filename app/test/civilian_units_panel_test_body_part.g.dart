part of 'civilian_units_panel_test.dart';

void _defineTests() {
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
        final orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'b1',
                target: kWorkTargetBuildImprovement,
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
        final orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'e1',
                target: kWorkTargetExplore,
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
                  type: kUnitTypeMerchant,
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
                target: kWorkTargetPurchaseLand,
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
                  type: kUnitTypeMerchant,
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
                target: kWorkTargetPurchaseLand,
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
          (unitType: kUnitTypeExplorer, target: kWorkTargetExplore, turns: 3),
          (unitType: kUnitTypeExplorer, target: kWorkTargetProspect, turns: 1),
          (unitType: kUnitTypeBuilder, target: kWorkTargetBuildImprovement, turns: 1),
          (unitType: kUnitTypeBuilder, target: kWorkTargetUpgradeTown, turns: 1),
          (unitType: kUnitTypeEngineer, target: kWorkTargetBuildRoad, turns: 1),
          (unitType: kUnitTypeEngineer, target: kWorkTargetBuildPort, turns: 1),
          (unitType: kUnitTypeEngineer, target: kWorkTargetBuildFort, turns: 3),
          (unitType: kUnitTypeRailBuilder, target: kWorkTargetBuildRail, turns: 1),
          (unitType: kUnitTypeSpy, target: kWorkTargetStealTech, turns: 5),
          (unitType: kUnitTypeSpy, target: kWorkTargetCounterSpy, turns: 1),
          (unitType: kUnitTypeMerchant, target: kWorkTargetPurchaseLand, turns: 1),
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
            ),
            players: const [
              Player(id: human, displayName: 'Human', isHuman: true),
            ],
          );
          final orders = Orders(
            workOrdersByPlayerId: {
              human: [
                WorkOrder(
                  unitId: unitId,
                  target: c.target,
                  targetTileKey: targetTileKey,
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

          final lineFinder = find.textContaining('Assigned to:');
          expect(
            lineFinder,
            findsOneWidget,
            reason: 'Expected one Assigned to line for target ${c.target}',
          );
          final line = tester.widget<Text>(lineFinder).data ?? '';
          final singular = '${c.turns} turn';
          final plural = '${c.turns} turns';
          expect(
            line.contains(singular) || line.contains(plural),
            isTrue,
            reason:
                'Expected target ${c.target} to show $singular/$plural, got: $line',
          );
          expect(
            line.contains('# turn'),
            isFalse,
            reason: 'Target ${c.target} should not render placeholder text',
          );
        }
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
                type: kUnitTypeRailBuilder,
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
              target: kWorkTargetBuildRail,
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
                type: kUnitTypeBuilder,
                ownerId: human,
                locationProvinceId: 'oldWorld|p1',
                tileKey: tileKey,
                status: UnitStatus.working,
                currentWork: const CurrentWork(
                  workTarget: kWorkTargetBuildImprovement,
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
