// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'support/naval_units_panel_test_support.dart';
import 'support/panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

Future<void> _pumpNaval(
  WidgetTester tester, {
  required Game game,
  required String humanPlayerId,
  AppEventBus? bus,
  MapTopology topology = const MapTopology(),
  Orders draftOrders = const Orders(),
  String? locationScopeKey,
}) async {
  await tester.pumpWidget(
    buildNavalPanel(
      game: game,
      humanPlayerId: humanPlayerId,
      bus: bus,
      topology: topology,
      draftOrders: draftOrders,
      locationScopeKey: locationScopeKey,
    ),
  );
  await tester.pumpAndSettle();
}

(AppEventBus bus, List<ClosePanelEvent> events) _wireCloseCapture() {
  final events = <ClosePanelEvent>[];
  final bus = AppEventBus.create();
  final sub = bus.on<ClosePanelEvent>().listen(events.add);
  addTearDown(sub.cancel);
  return (bus, events);
}

Future<void> _pumpScopedHarness(
  WidgetTester tester, {
  required Game game,
  required String humanPlayerId,
  required AppEventBus bus,
  required MapTopology topology,
  required String? locationScopeKey,
  bool removeFleetOnNextFrame = false,
}) async {
  await tester.pumpWidget(
    _ScopedNavalPanelHarness(
      game: game,
      humanPlayerId: humanPlayerId,
      bus: bus,
      topology: topology,
      locationScopeKey: locationScopeKey,
      removeFleetOnNextFrame: removeFleetOnNextFrame,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _emitScopedMove(
  WidgetTester tester,
  AppEventBus bus,
  String humanId,
) async {
  bus.emit(
    NavalMoveFleetRequestedEvent(
      humanPlayerId: humanId,
      moveOrder: const NavalMoveOrder(
        fleetId: 'f1',
        destinationSeaZoneId: 'oldWorld|s2',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game game;
  late String humanPlayerIdWithFleets;

  setUpAll(() async {
    await setUpNinePatchAssets();

    game = buildNavalPanelTestGame();
    humanPlayerIdWithFleets = kPanelTestHumanPlayerId;
  });

  group('NavalUnitsPanel', () {
    testWidgets('AC: Beachhead mission appears in status line', (
      WidgetTester tester,
    ) async {
      const playerId = 'p_beach';
      final gameBeach = buildNavalPanelBeachheadMissionGame(humanId: playerId);

      await _pumpNaval(tester, game: gameBeach, humanPlayerId: playerId);

      expect(find.textContaining('Beachhead'), findsWidgets);
    });

    testWidgets('AC: No fleets and no capital shows empty naval message', (
      WidgetTester tester,
    ) async {
      const playerId = 'p_empty';
      final emptyGame = buildNavalPanelEmptyHumanGame(humanId: playerId);

      await _pumpNaval(tester, game: emptyGame, humanPlayerId: playerId);

      expect(find.text('No naval units'), findsOneWidget);
    });

    testWidgets(
      'AC: Marker-scoped capital port view shows Home Fleet and not empty state',
      (WidgetTester tester) async {
        const humanId = 'gp_marker_scope';
        const capitalPrefixedId = 'oldWorld|p1';
        final homeId = homeFleetIdFor(humanId);
        final markerScope = 'port:oldWorld|p1';

        final markerScopeGame = buildNavalPanelOwFleetsGame(
          gameId: 'g_marker_scope',
          humanId: humanId,
          displayName: 'Scope Test',
          capitalProvinceId: capitalPrefixedId,
          oldWorldProvinces: const [
            Province(
              id: capitalPrefixedId,
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Capital Port',
            ),
          ],
          fleets: [
            Fleet(
              id: homeId,
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: capitalPrefixedId,
              ships: const [ShipInstance(id: 'home_ship_1', typeId: 'carrack')],
            ),
          ],
          tileKeysByProvince: const {
            capitalPrefixedId: ['oldWorld|p1|0|0'],
          },
        );

        await _pumpNaval(
          tester,
          game: markerScopeGame,
          humanPlayerId: humanId,
          locationScopeKey: markerScope,
        );

        expect(
          find.widgetWithText(ExpansionTile, 'Home Fleet'),
          findsOneWidget,
        );
        expect(find.text('No naval units'), findsNothing);
      },
    );

    testWidgets(
      'AC: Cross-region projected marker scope shows destination region rows',
      (WidgetTester tester) async {
        const humanId = 'gp_cross_region_scope';
        final scopedGame = buildNavalPanelSingleSeaFleetGame(
          humanId: humanId,
          gameId: 'g_cross_region_scope',
          displayName: 'Cross Scope',
        );
        const draftOrders = Orders(
          navalMoveOrdersByPlayerId: {
            humanId: [
              NavalMoveOrder(
                fleetId: 'f1',
                destinationSeaZoneId: 'newWorld|s2',
              ),
            ],
          },
        );
        final topology = buildNavalTwoSeaZonesTopology(
          fromZoneId: 'oldWorld|s1',
          toZoneId: 'newWorld|s2',
        );

        await _pumpNaval(
          tester,
          game: scopedGame,
          humanPlayerId: humanId,
          topology: topology,
          draftOrders: draftOrders,
          locationScopeKey: 'sea:newWorld|s2',
        );

        expect(find.text('NEW WORLD'), findsOneWidget);
        expect(find.text('OLD WORLD'), findsNothing);
        expect(find.textContaining('Fleet f1'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: Scoped panel auto-closes after confirmed move empties scope',
      (WidgetTester tester) async {
        const humanId = 'gp_scope_autoclose_yes';
        final (bus, closeEvents) = _wireCloseCapture();
        await _pumpScopedHarness(
          tester,
          game: buildNavalPanelSingleSeaFleetGame(
            humanId: humanId,
            gameId: 'g_scope_autoclose_yes',
            displayName: 'Scoped AutoClose',
          ),
          humanPlayerId: humanId,
          bus: bus,
          topology: buildNavalTwoSeaZonesTopology(),
          locationScopeKey: 'sea:oldWorld|s1',
        );
        expect(find.textContaining('Fleet f1'), findsOneWidget);
        await _emitScopedMove(tester, bus, humanId);
        expect(closeEvents.length, 1);
      },
    );

    testWidgets(
      'AC: Full-list mode move confirm does not emit scoped auto-close event',
      (WidgetTester tester) async {
        const humanId = 'gp_scope_autoclose_no_full';
        final (bus, closeEvents) = _wireCloseCapture();
        await _pumpScopedHarness(
          tester,
          game: buildNavalPanelSingleSeaFleetGame(
            humanId: humanId,
            gameId: 'g_scope_autoclose_no_full',
            displayName: 'Full List',
          ),
          humanPlayerId: humanId,
          bus: bus,
          topology: buildNavalTwoSeaZonesTopology(),
          locationScopeKey: null,
        );
        await _emitScopedMove(tester, bus, humanId);
        expect(closeEvents, isEmpty);
      },
    );

    testWidgets(
      'AC: Scoped empty state without move confirm does not auto-close',
      (WidgetTester tester) async {
        const humanId = 'gp_scope_autoclose_no_external';
        final (bus, closeEvents) = _wireCloseCapture();
        await _pumpScopedHarness(
          tester,
          game: buildNavalPanelSingleSeaFleetGame(
            humanId: humanId,
            gameId: 'g_scope_autoclose_no_external',
            displayName: 'Scoped External',
          ),
          humanPlayerId: humanId,
          bus: bus,
          topology: const MapTopology(),
          locationScopeKey: 'sea:oldWorld|s1',
          removeFleetOnNextFrame: true,
        );
        expect(closeEvents, isEmpty);
      },
    );

    testWidgets('AC: Home Fleet collapsed row does not show Move action', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_move_home';

      final moveHomeGame = buildNavalPanelCapitalHomeAndPeersGame(
        humanId: humanId,
        gameId: 'g_move_home',
        displayName: 'Move Home Test',
        peerFleets: const [],
        homeShips: const [ShipInstance(id: 'home_ship', typeId: 'carrack')],
      );

      await _pumpNaval(tester, game: moveHomeGame, humanPlayerId: humanId);

      final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
      expect(homeTile, findsOneWidget);

      expect(
        find.descendant(of: homeTile, matching: find.byTooltip('Move')),
        findsNothing,
      );
    });

    testWidgets(
      'AC: Non-home collapsed Move action opens MoveFleetDialog without expansion',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        final nonHomeFleets = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanId &&
                  f.shipTypeIds.isNotEmpty &&
                  f.id != homeFleetIdFor(humanId),
            )
            .toList();
        if (nonHomeFleets.isEmpty) return;
        final targetFleet = nonHomeFleets.first;

        await _pumpNaval(tester, game: game, humanPlayerId: humanId);

        final fleetTile = find.widgetWithText(
          ExpansionTile,
          'Fleet ${targetFleet.id}',
        );
        expect(fleetTile, findsOneWidget);
        await tester.ensureVisible(fleetTile);

        final moveButton = find.descendant(
          of: fleetTile,
          matching: find.byTooltip('Move'),
        );
        expect(moveButton, findsOneWidget);
        await tester.ensureVisible(moveButton);
        await tester.tap(moveButton);
        await tester.pumpAndSettle();

        expect(find.byType(MoveFleetDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('AC: Narrow row switches inline actions to icon-only mode', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 800));

      final humanId = humanPlayerIdWithFleets;
      final nonHomeFleets = game.worldState.fleets
          .where(
            (f) =>
                f.ownerId == humanId &&
                f.shipTypeIds.isNotEmpty &&
                f.id != homeFleetIdFor(humanId),
          )
          .toList();
      if (nonHomeFleets.isEmpty) return;
      final targetFleet = nonHomeFleets.first;

      await _pumpNaval(tester, game: game, humanPlayerId: humanId);

      final fleetTile = find.widgetWithText(
        ExpansionTile,
        'Fleet ${targetFleet.id}',
      );
      expect(fleetTile, findsOneWidget);

      expect(
        find.descendant(of: fleetTile, matching: find.byIcon(Icons.route)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: fleetTile, matching: find.byIcon(Icons.call_split)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: fleetTile, matching: find.text('Move')),
        findsNothing,
      );
    });

    testWidgets(
      'AC: Home Fleet is never deleted even when empty after combine',
      (WidgetTester tester) async {
        const humanId = 'gp_home_never_deleted';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        final homeNeverDeleteGame = buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_home_never_deleted',
          displayName: 'Home never deleted tester',
          nextShipInstanceSeq: 3,
          homeShips: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
          peerFleets: [
            Fleet(
              id: 'donor',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: capProvince,
              ships: const [ShipInstance(id: 'ship_d', typeId: 'fluyte')],
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        final subTransferNeverDelete = wireNavalTransferForWidgetTest(
          bus: bus,
          gameSnapshot: () => homeNeverDeleteGame,
        );
        addTearDown(sub.cancel);
        addTearDown(subTransferNeverDelete.cancel);

        await _pumpNaval(
          tester,
          game: homeNeverDeleteGame,
          humanPlayerId: humanId,
          bus: bus,
        );

        final homeFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final donorFinder = find.widgetWithText(ExpansionTile, 'Fleet donor');
        expect(homeFinder, findsOneWidget);
        expect(donorFinder, findsOneWidget);

        await tester.tap(
          find.descendant(of: homeFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: donorFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
        await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('fluyte')));
        await tester.pumpAndSettle();
        final confirmTransfer = find.widgetWithText(
          CtNinePatchButton,
          'Transfer',
        );
        expect(confirmTransfer, findsOneWidget);
        expect(
          tester.widget<CtNinePatchButton>(confirmTransfer).enabled,
          isTrue,
        );
        final confirmTransferButton = tester.widget<CtNinePatchButton>(
          confirmTransfer,
        );
        expect(confirmTransferButton.onPressed, isNotNull);
        confirmTransferButton.onPressed!.call();
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        final homeFleet = fleetsAfter.where((f) => f.id == homeId);
        expect(homeFleet, isNotEmpty);
        final shipIds = homeFleet.first.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ship_d', 'ship_h']);
        expect(fleetsAfter.any((f) => f.id == 'donor'), isFalse);
      },
    );

    testWidgets(
      'AC: Non-Home fleet split cannot empty original (Confirm Split disabled)',
      (WidgetTester tester) async {
        const humanId = 'gp_nonhome_removed';
        const capProvince = 'oldWorld|cap1';

        final nonHomeSplitGame = buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_nonhome_removed',
          displayName: 'Non-home removed tester',
          nextShipInstanceSeq: 3,
          homeShips: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
          peerFleets: [
            Fleet(
              id: 'split_me',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: capProvince,
              ships: const [ShipInstance(id: 'ship_s1', typeId: 'fluyte')],
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        final subSplit = wireNavalSplitForWidgetTest(
          bus: bus,
          gameSnapshot: () => nonHomeSplitGame,
        );
        addTearDown(sub.cancel);
        addTearDown(subSplit.cancel);

        await _pumpNaval(
          tester,
          game: nonHomeSplitGame,
          humanPlayerId: humanId,
          bus: bus,
        );

        final fleetFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet split_me',
        );
        expect(fleetFinder, findsOneWidget);

        await tester.ensureVisible(fleetFinder);
        await tester.tap(fleetFinder);
        await tester.pumpAndSettle();

        final splitButton = find.descendant(
          of: fleetFinder,
          matching: find.byTooltip('Split'),
        );
        expect(splitButton, findsOneWidget);
        await tester.ensureVisible(splitButton);
        await tester.tap(splitButton);
        await tester.pumpAndSettle();

        final fleet = nonHomeSplitGame.worldState.fleets.firstWhere(
          (f) => f.id == 'split_me',
        );
        expect(fleet.ships.length, 1);

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveOne(fleet.ships.first.typeId)),
        );
        await tester.pumpAndSettle();

        final confirmBtn = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Confirm Split'),
        );
        expect(confirmBtn.enabled, isFalse);
        expect(updated, isNull);
      },
    );
  });
}

class _ScopedNavalPanelHarness extends StatefulWidget {
  const _ScopedNavalPanelHarness({
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    required this.locationScopeKey,
    this.removeFleetOnNextFrame = false,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;
  final String? locationScopeKey;
  final bool removeFleetOnNextFrame;

  @override
  State<_ScopedNavalPanelHarness> createState() =>
      _ScopedNavalPanelHarnessState();
}

class _ScopedNavalPanelHarnessState extends State<_ScopedNavalPanelHarness> {
  late Orders _draftOrders;
  late Game _game;
  StreamSubscription<NavalMoveFleetRequestedEvent>? _moveSub;

  @override
  void initState() {
    super.initState();
    _draftOrders = const Orders();
    _game = widget.game;
    _moveSub = widget.bus.on<NavalMoveFleetRequestedEvent>().listen((event) {
      if (!mounted) return;
      setState(() {
        _draftOrders = Orders(
          navalMoveOrdersByPlayerId: {
            event.humanPlayerId: [
              NavalMoveOrder(
                fleetId: event.moveOrder.fleetId,
                destinationSeaZoneId: event.moveOrder.destinationSeaZoneId,
                destinationPortProvinceId:
                    event.moveOrder.destinationPortProvinceId,
              ),
            ],
          },
        );
      });
    });
    if (widget.removeFleetOnNextFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _game = _game.copyWith(
            worldState: _game.worldState.copyWith(fleets: const []),
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _moveSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NavalUnitsPanel(
          game: _game,
          humanPlayerId: widget.humanPlayerId,
          bus: widget.bus,
          topology: widget.topology,
          draftOrders: _draftOrders,
          locationScopeKey: widget.locationScopeKey,
        ),
      ),
    );
  }
}
