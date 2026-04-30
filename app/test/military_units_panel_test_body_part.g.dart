part of 'military_units_panel_test.dart';

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
    AppEventBus? bus,
    MapTopology? topology,
    Orders draftOrders = const Orders(),
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MilitaryUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          bus: bus ?? AppEventBus.create(),
          topology: topology ?? const MapTopology(),
          draftOrders: draftOrders,
        ),
      ),
    );
  }

  group('MilitaryUnitsPanel', () {
    testWidgets('AC: Panel shows title Military Units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('Military Units'), findsOneWidget);
    });

    testWidgets(
      'AC: Empty state when human player has zero regiments and no fleets',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithNoUnits),
        );
        await tester.pumpAndSettle();

        expect(find.text('No military units'), findsOneWidget);
        expect(find.byType(ListTile), findsNothing);
      },
    );

    testWidgets('naval location header uses sea-zone display name', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_mil_sea_label';
      const cap = 'oldWorld|c1';
      final miniGame = Game(
        id: 'g_mil_sea_label',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: 'c1',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Cap',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f_at_sea',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'zone_x',
              ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
            ),
          ],
          seaZoneDisplayNameById: const {'oldWorld|zone_x': 'Mil Named Sea'},
        ),
        players: const [
          Player(
            id: humanId,
            displayName: 'Mil Sea Tester',
            isHuman: true,
            capitalProvinceId: cap,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: cap,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        buildPanel(game: miniGame, humanPlayerId: humanId),
      );
      await tester.pump();
      expect(find.textContaining('Mil Named Sea'), findsWidgets);
    });

    testWidgets(
      'AC: When player has military units, tree shows regions and type rows',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        final militaryCount =
            game.worldState.oldWorld.units
                .where(
                  (u) =>
                      u.ownerId == humanPlayerIdWithUnits &&
                      isMilitaryUnit(u.type),
                )
                .length +
            game.worldState.newWorld.units
                .where(
                  (u) =>
                      u.ownerId == humanPlayerIdWithUnits &&
                      isMilitaryUnit(u.type),
                )
                .length;
        final fleetCount = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanPlayerIdWithUnits &&
                  f.shipTypeIds.isNotEmpty,
            )
            .length;
        if (militaryCount > 0 || fleetCount > 0) {
          expect(find.byType(ListTile), findsAtLeastNWidgets(1));
          expect(find.byType(UnitsEntityActionRow), findsAtLeastNWidgets(1));
          expect(
            find.text('Old World').evaluate().isNotEmpty ||
                find.text('New World').evaluate().isNotEmpty,
            isTrue,
          );
        }
      },
    );

    testWidgets(
      'AC: Army subtitle uses province display name; regiment titles use roster names',
      (WidgetTester tester) async {
        const playerId = 'gp_display_names';
        const provinceLocal = 'lisbon';
        const fullProvince = 'oldWorld|$provinceLocal';
        final miniGame = Game(
          id: 'g_display_mil',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              units: [
                Unit(
                  id: 'levy1',
                  type: 'peasant_levies',
                  ownerId: playerId,
                  locationProvinceId: fullProvince,
                  medals: 0,
                  status: UnitStatus.idle,
                ),
              ],
              provinces: [
                Province(
                  id: fullProvince,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Lisbon Harbor',
                  townTileKey: 'oldWorld|lisbon|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [],
            armies: [
              Army(
                id: 'army_field',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: fullProvince,
                regimentUnitIds: const ['levy1'],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                fullProvince: ['oldWorld|lisbon|0|0'],
              },
            },
          ),
          players: const [
            Player(
              id: playerId,
              displayName: 'Tester',
              isHuman: true,
              capitalProvinceId: fullProvince,
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: miniGame, humanPlayerId: playerId),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('regiments · Lisbon Harbor'), findsWidgets);
        await expandFirstArmyExpansion(tester);
        expect(find.textContaining('Peasant Levies: 1'), findsOneWidget);
        expect(find.textContaining('peasant_levies:'), findsNothing);
      },
    );

    testWidgets('AC: Regiment rows show type, count, medals, status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      final militaryCount =
          game.worldState.oldWorld.units
              .where(
                (u) =>
                    u.ownerId == humanPlayerIdWithUnits &&
                    isMilitaryUnit(u.type),
              )
              .length +
          game.worldState.newWorld.units
              .where(
                (u) =>
                    u.ownerId == humanPlayerIdWithUnits &&
                    isMilitaryUnit(u.type),
              )
              .length;
      if (militaryCount == 0) return;

      // Army entries use ExpansionTile; subtitle includes "regiments ·".
      expect(find.textContaining('regiments ·'), findsAtLeastNWidgets(1));
      await expandAllArmyExpansions(tester);
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'AC: When tree has content, location headers show region (name — region)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        if (find.byType(ListTile).evaluate().isEmpty) return;
        expect(find.textContaining(' — '), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('panel is wrapped in CtPanel', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtPanel), findsOneWidget);
    });

    testWidgets('AC: Tapping a row emits LocateMapTileEvent', (
      WidgetTester tester,
    ) async {
      LocateMapTileEvent? locateEvent;
      final bus = AppEventBus.create();
      bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits, bus: bus),
      );
      await tester.pumpAndSettle();

      final locateButtons = find.byIcon(Icons.my_location);
      if (locateButtons.evaluate().isEmpty) return;
      await tester.tap(locateButtons.first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(locateEvent, isNotNull);
      expect(
        locateEvent!.regionId == 'oldWorld' ||
            locateEvent!.regionId == 'newWorld',
        isTrue,
      );
    });

    testWidgets('builds without locate callback', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isNotEmpty) {
        await tester.tap(listTiles.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Train button emits train-military dialog open event', (
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
      expect(openDialogEvent!.dialogId, trainMilitaryDialogId);
    });

    testWidgets(
      'AC: Tapping locate emits ClosePanelEvent before LocateMapTileEvent',
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

        final locateButtons = find.byIcon(Icons.my_location);
        if (locateButtons.evaluate().isEmpty) return;
        await tester.tap(locateButtons.first);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          sequence.indexOf(ClosePanelEvent),
          lessThan(sequence.indexOf(LocateMapTileEvent)),
        );
      },
    );

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('tileKeyForProvinceLocation', () {
    test('returns townTileKey when province has it', () {
      final province = game.worldState.oldWorld.provinces.firstWhere(
        (p) => p.townTileKey != null && p.townTileKey!.isNotEmpty,
        orElse: () => game.worldState.oldWorld.provinces.first,
      );
      final key = tileKeyForProvinceLocation(game, province);
      if (province.townTileKey != null) {
        expect(key, province.townTileKey);
      }
    });

    test(
      'returns first tile from tileKeysByRegionAndProvince when townTileKey is null',
      () {
        const regionId = 'oldWorld';
        const provinceId = 'p1';
        const prefixedId = 'oldWorld|p1';
        const tileKey = 'oldWorld|p1|0|0';
        final minimalGame = Game(
          id: 'min',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: provinceId,
                  regionId: regionId,
                  ownerId: humanPlayerIdWithUnits,
                  townTileKey: null,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              regionId: {
                prefixedId: [tileKey],
              },
            },
          ),
          players: const [],
        );
        final province = minimalGame.worldState.oldWorld.provinces.first;
        final key = tileKeyForProvinceLocation(minimalGame, province);
        expect(key, tileKey);
      },
    );

    test(
      'returns null for province with no tiles in tileKeysByRegionAndProvince',
      () {
        final province = Province(
          id: 'nonexistent',
          regionId: 'oldWorld',
          ownerId: humanPlayerIdWithUnits,
        );
        final key = tileKeyForProvinceLocation(game, province);
        expect(key, isNull);
      },
    );
  });

  group('tileKeyForSeaZoneLocation', () {
    test(
      'returns port tile when sea zone has port in portsByProvinceSeaboard',
      () {
        if (game.worldState.portsByProvinceSeaboard.isEmpty) return;
        final entry = game.worldState.portsByProvinceSeaboard.entries.first;
        final parts = entry.key.split('|');
        final regionId = parts[0];
        final seaZoneId = parts.length >= 3
            ? parts.sublist(2).join('|')
            : parts[1];
        final key = tileKeyForSeaZoneLocation(game, regionId, seaZoneId);
        expect(key, isNotNull);
        expect(key, entry.value);
      },
    );

    test('returns null for unknown sea zone', () {
      final key = tileKeyForSeaZoneLocation(
        game,
        'oldWorld',
        'nonexistent_sea_zone',
      );
      expect(key, isNull);
    });
  });

  group('Sea zone fleet display', () {
    testWidgets('shows ship rows for fleet at sea', (
      WidgetTester tester,
    ) async {
      const playerId = 'test_player';
      const seaZoneId = 'atlantic';
      final gameWithSeaFleet = Game(
        id: 'sea_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            units: [],
            provinces: [
              Province(id: 'lisbon', regionId: 'oldWorld', ownerId: playerId),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fleet1',
              ownerId: playerId,
              regionId: 'oldWorld',
              seaZoneId: seaZoneId,
              shipTypeIds: ['galleon', 'carrack'],
              mission: FleetMission.patrol,
            ),
          ],
          portsByProvinceSeaboard: {
            'oldWorld|lisbon|atlantic': 'oldWorld|lisbon|0|0',
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildPanel(game: gameWithSeaFleet, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('atlantic — Old World'), findsOneWidget);
      expect(find.textContaining('Galleon: 1'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Carrack: 1'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Status: Patrol'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows multiple ships of same type aggregated', (
      WidgetTester tester,
    ) async {
      const playerId = 'test_player';
      final gameWithMultipleShips = Game(
        id: 'multi_ship_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(units: []),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fleet1',
              ownerId: playerId,
              regionId: 'oldWorld',
              seaZoneId: 'atlantic',
              shipTypeIds: ['galleon', 'galleon', 'galleon'],
              mission: FleetMission.blockade,
            ),
          ],
          portsByProvinceSeaboard: {
            'oldWorld|lisbon|atlantic': 'oldWorld|lisbon|0|0',
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildPanel(game: gameWithMultipleShips, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Galleon: 3'), findsOneWidget);
      expect(find.textContaining('Status: Blockade'), findsOneWidget);
    });

    testWidgets('fleet with defend mission shows Defend status', (
      WidgetTester tester,
    ) async {
      const playerId = 'test_player';
      final gameWithDefendFleet = Game(
        id: 'defend_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(units: []),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fleet1',
              ownerId: playerId,
              regionId: 'oldWorld',
              seaZoneId: 'atlantic',
              shipTypeIds: ['fluyte'],
              mission: FleetMission.defend,
            ),
          ],
          portsByProvinceSeaboard: {
            'oldWorld|lisbon|atlantic': 'oldWorld|lisbon|0|0',
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildPanel(game: gameWithDefendFleet, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: Defend'), findsOneWidget);
    });
  });

  group('Medals range display', () {
    testWidgets('shows medal range when regiment has multiple medal values', (
      WidgetTester tester,
    ) async {
      const playerId = 'multi_medal_player';
      final gameWithMixedMedals = Game(
        id: 'mixed_medals_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: 'oldWorld|lisbon',
                medals: 1,
                status: UnitStatus.idle,
              ),
              Unit(
                id: 'u2',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: 'oldWorld|lisbon',
                medals: 2,
                status: UnitStatus.idle,
              ),
              Unit(
                id: 'u3',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: 'oldWorld|lisbon',
                medals: 3,
                status: UnitStatus.idle,
              ),
            ],
            provinces: [
              Province(
                id: 'oldWorld|lisbon',
                regionId: 'oldWorld',
                ownerId: playerId,
                townTileKey: 'oldWorld|lisbon|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [],
          armies: [
            Army(
              id: 'army_mixed',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|lisbon',
              regimentUnitIds: const ['u1', 'u2', 'u3'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildPanel(game: gameWithMixedMedals, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Army army_mixed'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Medals: 1–3'), findsOneWidget);
    });
  });

  group('Unit status display', () {
    testWidgets('shows Working status when any unit is working', (
      WidgetTester tester,
    ) async {
      const playerId = 'working_status_player';
      final gameWithWorkingUnit = Game(
        id: 'working_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: 'oldWorld|lisbon',
                medals: 1,
                status: UnitStatus.idle,
              ),
              Unit(
                id: 'u2',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: 'oldWorld|lisbon',
                medals: 1,
                status: UnitStatus.working,
              ),
            ],
            provinces: [
              Province(
                id: 'oldWorld|lisbon',
                regionId: 'oldWorld',
                ownerId: playerId,
                townTileKey: 'oldWorld|lisbon|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [],
          armies: [
            Army(
              id: 'army_w',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|lisbon',
              regimentUnitIds: const ['u1', 'u2'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildPanel(game: gameWithWorkingUnit, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Army army_w'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: Working'), findsOneWidget);
    });

    testWidgets('shows Idle status when units are idle and none working', (
      WidgetTester tester,
    ) async {
      const playerId = 'idle_status_player';
      final gameWithIdleUnit = Game(
        id: 'idle_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: 'oldWorld|lisbon',
                medals: 1,
                status: UnitStatus.idle,
              ),
            ],
            provinces: [
              Province(
                id: 'oldWorld|lisbon',
                regionId: 'oldWorld',
                ownerId: playerId,
                townTileKey: 'oldWorld|lisbon|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [],
          armies: [
            Army(
              id: 'army_d',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|lisbon',
              regimentUnitIds: const ['u1'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildPanel(game: gameWithIdleUnit, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Army army_d'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: Idle'), findsOneWidget);
    });
  });

  group('Army management (bus events)', () {
    testWidgets('Home Army expansion does not show Move action', (
      WidgetTester tester,
    ) async {
      const playerId = 'gp_home_no_move';
      const cap = 'oldWorld|cap';
      final game = Game(
        id: 'ghm',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: playerId,
                townTileKey: 'tk',
              ),
            ],
            units: [
              Unit(
                id: 'u_home',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: cap,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'home_army',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const ['u_home'],
              isHomeArmy: true,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              cap: ['tk'],
            },
          },
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'Home',
            isHuman: true,
            capitalProvinceId: cap,
          ),
        ],
      );

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: playerId));
      await tester.pumpAndSettle();

      final homeTile = find.widgetWithText(ExpansionTile, 'Home Army');
      expect(homeTile, findsOneWidget);
      await tester.tap(homeTile);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: homeTile,
          matching: find.widgetWithText(ElevatedButton, 'Move'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: homeTile, matching: find.text('Move')),
        findsNothing,
      );
    });

    testWidgets(
      'Combine emits ArmyCombineRequestedEvent when two armies selected',
      (WidgetTester tester) async {
        ArmyCombineRequestedEvent? captured;
        final bus = AppEventBus.create();
        bus.on<ArmyCombineRequestedEvent>().listen((e) => captured = e);

        const playerId = 'gp_combine';
        const p = 'oldWorld|p2';
        final game = Game(
          id: 'gc',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: p,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  townTileKey: 'tk',
                ),
              ],
              units: [
                Unit(
                  id: 'uu1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: p,
                ),
                Unit(
                  id: 'uu2',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: p,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: 'ax',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: p,
                regimentUnitIds: const ['uu1'],
                isHomeArmy: false,
              ),
              Army(
                id: 'ay',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: p,
                regimentUnitIds: const ['uu2'],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                p: ['tk'],
              },
            },
          ),
          players: [
            Player(
              id: playerId,
              displayName: 'C',
              isHuman: true,
              capitalProvinceId: 'oldWorld|cap',
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: playerId, bus: bus),
        );
        await tester.pumpAndSettle();

        final checks = find.byType(Checkbox);
        expect(checks, findsNWidgets(3));
        await tester.tap(checks.at(1));
        await tester.tap(checks.at(2));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Combine'));
        await tester.pumpAndSettle();

        expect(captured, isNotNull);
        expect(captured!.armyIds.length, 2);
      },
    );

    testWidgets('Move confirms ArmyMoveRequestedEvent', (
      WidgetTester tester,
    ) async {
      ArmyMoveRequestedEvent? captured;
      final bus = AppEventBus.create();
      bus.on<ArmyMoveRequestedEvent>().listen((e) => captured = e);

      const playerId = 'gp_move';
      const p = 'oldWorld|p2';
      const p3 = 'oldWorld|p3';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p3',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'oldWorld|p2', id2: 'oldWorld|p3')],
      );
      final game = Game(
        id: 'gm',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: p,
                regionId: 'oldWorld',
                ownerId: playerId,
                townTileKey: 'tk',
              ),
              Province(id: p3, regionId: 'oldWorld', ownerId: playerId),
            ],
            units: [
              Unit(
                id: 'um1',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: p,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'amove',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: p,
              regimentUnitIds: const ['um1'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              p: ['oldWorld|p2|0|0'],
              p3: ['oldWorld|p3|0|0'],
            },
          },
          playerVisibilityByTile: {
            playerId: {
              'oldWorld|p2|0|0': 'fullyVisible',
              'oldWorld|p3|0|0': 'fullyVisible',
            },
          },
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'M',
            isHuman: true,
            capitalProvinceId: p,
          ),
        ],
      );

      await tester.pumpWidget(
        buildPanel(
          game: game,
          humanPlayerId: playerId,
          bus: bus,
          topology: topology,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Army amove'));
      await tester.pumpAndSettle();
      final armyTile = find.widgetWithText(ExpansionTile, 'Army amove');
      expect(armyTile, findsOneWidget);
      final moveButton = find.descendant(
        of: armyTile,
        matching: find.widgetWithText(CtNinePatchButton, 'Move'),
      );
      await tester.tap(moveButton.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.moveOrder.armyId, 'amove');
      expect(captured!.moveOrder.destinationProvinceId, p3);
    });

    testWidgets(
      'Move dialog groups by owning faction and cross-region owned move',
      (WidgetTester tester) async {
        ArmyMoveRequestedEvent? captured;
        final bus = AppEventBus.create();
        bus.on<ArmyMoveRequestedEvent>().listen((e) => captured = e);

        const playerId = 'gp_move_grouped';
        const from = 'oldWorld|p2';
        const oldDest = 'oldWorld|p3';
        const newDest = 'newWorld|n2';

        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|p3',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'oldWorld|p2', id2: 'oldWorld|p3')],
        );

        final game = Game(
          id: 'g_move_grouped',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: from,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'From',
                  townTileKey: 'tk_from',
                ),
                Province(
                  id: oldDest,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Old Port',
                ),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: from,
                ),
              ],
            ),
            newWorld: RegionData(
              provinces: [
                Province(
                  id: newDest,
                  regionId: 'newWorld',
                  ownerId: playerId,
                  displayName: 'New Port',
                ),
              ],
            ),
            armies: [
              Army(
                id: 'amove',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: from,
                regimentUnitIds: const ['u1'],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                from: ['oldWorld|p2|0|0'],
                oldDest: ['oldWorld|p3|0|0'],
              },
              'newWorld': {
                newDest: ['newWorld|n2|0|0'],
              },
            },
            playerVisibilityByTile: {
              playerId: {
                'oldWorld|p2|0|0': 'fullyVisible',
                'oldWorld|p3|0|0': 'fullyVisible',
                'newWorld|n2|0|0': 'fullyVisible',
              },
            },
          ),
          players: [
            Player(
              id: playerId,
              displayName: 'Grouped',
              isHuman: true,
              capitalProvinceId: from,
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: playerId,
            bus: bus,
            topology: topology,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Army amove'));
        await tester.pumpAndSettle();
        final armyTile = find.widgetWithText(ExpansionTile, 'Army amove');
        expect(armyTile, findsOneWidget);
        final moveButton = find.descendant(
          of: armyTile,
          matching: find.widgetWithText(CtNinePatchButton, 'Move'),
        );
        await tester.tap(moveButton.first);
        await tester.pumpAndSettle();

        expect(find.byType(MoveArmyDialog), findsOneWidget);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        expect(find.text('Your provinces'), findsWidgets);

        await tester.tap(find.text('New Port').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(captured, isNotNull);
        expect(captured!.moveOrder.armyId, 'amove');
        expect(captured!.moveOrder.destinationProvinceId, newDest);
      },
    );

    testWidgets('Army row shows Moving to when draft has army move', (
      WidgetTester tester,
    ) async {
      const playerId = 'gp_draft_mv';
      const p = 'oldWorld|p2';
      const dest = 'oldWorld|p3';
      final game = Game(
        id: 'g_draft',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: p,
                regionId: 'oldWorld',
                ownerId: playerId,
                displayName: 'Here',
              ),
              Province(
                id: dest,
                regionId: 'oldWorld',
                ownerId: playerId,
                displayName: 'There',
              ),
            ],
            units: [
              Unit(
                id: 'ux',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: p,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'amove',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: p,
              regimentUnitIds: const ['ux'],
              isHomeArmy: false,
            ),
          ],
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'D',
            isHuman: true,
            capitalProvinceId: p,
          ),
        ],
      );
      final draft = Orders(
        armyMoveOrdersByPlayerId: {
          playerId: [
            ArmyMoveOrder(armyId: 'amove', destinationProvinceId: dest),
          ],
        },
      );
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: playerId, draftOrders: draft),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Moving to: There'), findsOneWidget);
    });

    testWidgets('Invasion move emits declareWarTargetFactionId after confirm', (
      WidgetTester tester,
    ) async {
      ArmyMoveRequestedEvent? captured;
      final bus = AppEventBus.create();
      bus.on<ArmyMoveRequestedEvent>().listen((e) => captured = e);

      const playerId = 'gp_inv';
      const enemyId = 'gp_enemy';
      const loc1 = 'oldWorld|p2';
      const loc2 = 'oldWorld|p3';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p3',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'oldWorld|p2', id2: 'oldWorld|p3')],
      );
      final game = Game(
        id: 'g_inv',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: loc1, regionId: 'oldWorld', ownerId: playerId),
              Province(
                id: loc2,
                regionId: 'oldWorld',
                ownerId: enemyId,
                displayName: 'Hostile',
              ),
            ],
            units: [
              Unit(
                id: 'ui1',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: loc1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'ainv',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: loc1,
              regimentUnitIds: const ['ui1'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              loc1: ['oldWorld|p2|0|0'],
              loc2: ['oldWorld|p3|0|0'],
            },
          },
          playerVisibilityByTile: {
            playerId: {
              'oldWorld|p2|0|0': 'fullyVisible',
              'oldWorld|p3|0|0': 'fullyVisible',
            },
          },
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'Inv',
            isHuman: true,
            capitalProvinceId: loc1,
          ),
          Player(
            id: enemyId,
            displayName: 'Enemy',
            isHuman: true,
            capitalProvinceId: loc2,
          ),
        ],
        diplomacyRelations: const [],
      );

      await tester.pumpWidget(
        buildPanel(
          game: game,
          humanPlayerId: playerId,
          bus: bus,
          topology: topology,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Army ainv'));
      await tester.pumpAndSettle();
      final armyTile = find.widgetWithText(ExpansionTile, 'Army ainv');
      expect(armyTile, findsOneWidget);
      final moveButton = find.descendant(
        of: armyTile,
        matching: find.widgetWithText(CtNinePatchButton, 'Move'),
      );
      await tester.tap(moveButton.first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hostile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Declare war and move'), findsOneWidget);
      await tester.tap(find.text('Declare war and move'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.declareWarTargetFactionId, enemyId);
      expect(captured!.moveOrder.destinationProvinceId, loc2);
    });

    testWidgets(
      'split home army (all regiments): panel shows new army with regiment rows',
      (WidgetTester tester) async {
        const playerId = 'gp_split_ui_full';
        const cap = 'oldWorld|cap';
        final initial = Game(
          id: 'g_split_full',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: cap,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Capital',
                  townTileKey: 'tk_cap',
                ),
              ],
              units: [
                Unit(
                  id: 'r1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
                Unit(
                  id: 'r2',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: 'home_army',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: cap,
                regimentUnitIds: const ['r1', 'r2'],
                isHomeArmy: true,
              ),
            ],
            nextArmySeq: 1,
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                cap: ['tk_cap'],
              },
            },
          ),
          players: [
            Player(
              id: playerId,
              displayName: 'Splitter',
              isHuman: true,
              capitalProvinceId: cap,
            ),
          ],
        );

        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 900,
                width: 480,
                child: _ArmySplitTestHarness(
                  initialGame: initial,
                  humanPlayerId: playerId,
                  bus: bus,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Army');
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        final splitBtn = find.descendant(
          of: homeTile,
          matching: find.widgetWithText(CtNinePatchButton, 'Split'),
        );
        await tester.ensureVisible(splitBtn);
        await tester.tap(splitBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveAll('musketeers')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm Split'));
        // Broadcast bus delivers listeners asynchronously; flush like split_army_dialog_test.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('0 regiments · Capital'), findsOneWidget);
        expect(find.text('2 regiments · Capital'), findsOneWidget);

        await tester.tap(find.text('Army army_1'));
        await tester.pumpAndSettle();
        expect(find.text('Musketeers: 2'), findsOneWidget);
      },
    );

    testWidgets(
      'split home army (partial): panel shows correct counts on both armies',
      (WidgetTester tester) async {
        const playerId = 'gp_split_ui_partial';
        const cap = 'oldWorld|cap';
        final initial = Game(
          id: 'g_split_partial',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: cap,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Capital',
                  townTileKey: 'tk_cap',
                ),
              ],
              units: [
                Unit(
                  id: 'r1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
                Unit(
                  id: 'r2',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: 'home_army',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: cap,
                regimentUnitIds: const ['r1', 'r2'],
                isHomeArmy: true,
              ),
            ],
            nextArmySeq: 7,
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                cap: ['tk_cap'],
              },
            },
          ),
          players: [
            Player(
              id: playerId,
              displayName: 'Splitter',
              isHuman: true,
              capitalProvinceId: cap,
            ),
          ],
        );

        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 900,
                width: 480,
                child: _ArmySplitTestHarness(
                  initialGame: initial,
                  humanPlayerId: playerId,
                  bus: bus,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Army');
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        final splitBtn = find.descendant(
          of: homeTile,
          matching: find.widgetWithText(CtNinePatchButton, 'Split'),
        );
        await tester.ensureVisible(splitBtn);
        await tester.tap(splitBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveOne('musketeers')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm Split'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('1 regiments · Capital'), findsNWidgets(2));

        await tester.tap(find.text('Home Army'));
        await tester.pumpAndSettle();
        expect(find.text('Musketeers: 1'), findsOneWidget);

        await tester.tap(find.text('Army army_7'));
        await tester.pumpAndSettle();
        expect(find.text('Musketeers: 1'), findsNWidgets(2));
      },
    );
  });
}
