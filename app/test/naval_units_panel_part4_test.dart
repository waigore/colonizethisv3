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
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'support/app_shell_harness.dart';
import 'support/naval_units_panel_test_support.dart';
import 'support/panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

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

Future<(AppEventBus, List<ClosePanelEvent>)> _pumpAutocloseCase(
  WidgetTester tester, {
  required String humanId,
  required String gameId,
  required String displayName,
  String? locationScopeKey = 'sea:oldWorld|s1',
  MapTopology? topology,
  bool removeFleetOnNextFrame = false,
}) async {
  final (bus, closeEvents) = _wireCloseCapture();
  await _pumpScopedHarness(
    tester,
    game: buildNavalPanelSingleSeaFleetGame(
      humanId: humanId,
      gameId: gameId,
      displayName: displayName,
    ),
    humanPlayerId: humanId,
    bus: bus,
    topology: topology ?? buildNavalTwoSeaZonesTopology(),
    locationScopeKey: locationScopeKey,
    removeFleetOnNextFrame: removeFleetOnNextFrame,
  );
  return (bus, closeEvents);
}

List<Fleet> _nonHomeFleetsWithShips(Game game, String humanId) {
  return game.worldState.fleets
      .where(
        (f) =>
            f.ownerId == humanId &&
            f.shipTypeIds.isNotEmpty &&
            f.id != homeFleetIdFor(humanId),
      )
      .toList();
}

Fleet _portPeer({
  required String id,
  required String humanId,
  required List<ShipInstance> ships,
  String port = 'oldWorld|cap1',
}) => Fleet(
  id: id,
  ownerId: humanId,
  regionId: 'oldWorld',
  inPortAtProvinceId: port,
  ships: ships,
);

Game _capPeers({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<Fleet> peerFleets,
  List<ShipInstance> homeShips = const [
    ShipInstance(id: 'ship_h', typeId: 'carrack'),
  ],
  int? nextShipInstanceSeq,
}) => buildNavalPanelCapitalHomeAndPeersGame(
  humanId: humanId,
  gameId: gameId,
  displayName: displayName,
  nextShipInstanceSeq: nextShipInstanceSeq,
  homeShips: homeShips,
  peerFleets: peerFleets,
);

(AppEventBus, NavalFleetsUpdatedEvent? Function()) _wireFleetBus({
  required StreamSubscription<dynamic> Function(AppEventBus bus) wire,
}) {
  NavalFleetsUpdatedEvent? updated;
  final bus = AppEventBus.create();
  addTearDown(
    bus.on<NavalFleetsUpdatedEvent>().listen((e) {
      updated = e;
    }).cancel,
  );
  addTearDown(wire(bus).cancel);
  return (bus, () => updated);
}

Future<void> _tapCbs(WidgetTester tester, List<Finder> tiles) async {
  for (final tile in tiles) {
    await tester.tap(
      find.descendant(of: tile, matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();
  }
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
    testWidgets('AC: Beachhead status and empty-naval empty-state pins', (
      WidgetTester tester,
    ) async {
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelBeachheadMissionGame(humanId: 'p_beach'),
        humanPlayerId: 'p_beach',
      );
      expect(find.textContaining('Beachhead'), findsWidgets);

      await pumpNavalPanel(
        tester,
        game: buildNavalPanelEmptyHumanGame(humanId: 'p_empty'),
        humanPlayerId: 'p_empty',
      );
      expect(find.text('No naval units'), findsOneWidget);
    });

    testWidgets(
      'AC: Marker-scoped capital port view shows Home Fleet and not empty state',
      (WidgetTester tester) async {
        const humanId = 'gp_marker_scope';
        const capital = 'oldWorld|p1';
        await pumpNavalPanel(
          tester,
          game: buildNavalPanelOwFleetsGame(
            gameId: 'g_marker_scope',
            humanId: humanId,
            displayName: 'Scope Test',
            capitalProvinceId: capital,
            oldWorldProvinces: const [
              Province(
                id: capital,
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Capital Port',
              ),
            ],
            fleets: [
              Fleet(
                id: homeFleetIdFor(humanId),
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capital,
                ships: const [
                  ShipInstance(id: 'home_ship_1', typeId: 'carrack'),
                ],
              ),
            ],
            tileKeysByProvince: const {
              capital: ['oldWorld|p1|0|0'],
            },
          ),
          humanPlayerId: humanId,
          locationScopeKey: 'port:$capital',
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
        await pumpNavalPanel(
          tester,
          game: buildNavalPanelSingleSeaFleetGame(
            humanId: humanId,
            gameId: 'g_cross_region_scope',
            displayName: 'Cross Scope',
          ),
          humanPlayerId: humanId,
          topology: buildNavalTwoSeaZonesTopology(
            fromZoneId: 'oldWorld|s1',
            toZoneId: 'newWorld|s2',
          ),
          draftOrders: const Orders(
            navalMoveOrdersByPlayerId: {
              humanId: [
                NavalMoveOrder(
                  fleetId: 'f1',
                  destinationSeaZoneId: 'newWorld|s2',
                ),
              ],
            },
          ),
          locationScopeKey: 'sea:newWorld|s2',
        );
        expect(find.text('NEW WORLD'), findsOneWidget);
        expect(find.text('OLD WORLD'), findsNothing);
        expect(find.textContaining('Fleet f1'), findsOneWidget);
      },
    );

    testWidgets('AC: scoped auto-close emits only when move empties scope', (
      WidgetTester tester,
    ) async {
      Future<void> runCase({
        required String humanId,
        required String gameId,
        required String displayName,
        String? locationScopeKey = 'sea:oldWorld|s1',
        MapTopology? topology,
        bool removeFleetOnNextFrame = false,
        bool emitMove = false,
        bool expectFleetRow = false,
        required int closeCount,
      }) async {
        final (bus, closeEvents) = await _pumpAutocloseCase(
          tester,
          humanId: humanId,
          gameId: gameId,
          displayName: displayName,
          locationScopeKey: locationScopeKey,
          topology: topology,
          removeFleetOnNextFrame: removeFleetOnNextFrame,
        );
        if (expectFleetRow) {
          expect(find.textContaining('Fleet f1'), findsOneWidget);
        }
        if (emitMove) await _emitScopedMove(tester, bus, humanId);
        expect(closeEvents.length, closeCount);
      }

      await runCase(
        humanId: 'gp_scope_autoclose_yes',
        gameId: 'g_scope_autoclose_yes',
        displayName: 'Scoped AutoClose',
        emitMove: true,
        expectFleetRow: true,
        closeCount: 1,
      );
      await runCase(
        humanId: 'gp_scope_autoclose_no_full',
        gameId: 'g_scope_autoclose_no_full',
        displayName: 'Full List',
        locationScopeKey: null,
        emitMove: true,
        closeCount: 0,
      );
      await runCase(
        humanId: 'gp_scope_autoclose_no_external',
        gameId: 'g_scope_autoclose_no_external',
        displayName: 'Scoped External',
        topology: const MapTopology(),
        removeFleetOnNextFrame: true,
        closeCount: 0,
      );
    });

    testWidgets(
      'AC: Move/narrow actions — Home no Move; non-home opens dialog',
      (WidgetTester tester) async {
        const homeId = 'gp_move_home';
        await pumpNavalPanel(
          tester,
          game: _capPeers(
            humanId: homeId,
            gameId: 'g_move_home',
            displayName: 'Move Home Test',
            peerFleets: const [],
            homeShips: const [ShipInstance(id: 'home_ship', typeId: 'carrack')],
          ),
          humanPlayerId: homeId,
        );
        expect(
          find.descendant(
            of: find.widgetWithText(ExpansionTile, 'Home Fleet'),
            matching: find.byTooltip('Move'),
          ),
          findsNothing,
        );

        final humanId = humanPlayerIdWithFleets;
        final nonHomeFleets = _nonHomeFleetsWithShips(game, humanId);
        if (nonHomeFleets.isEmpty) return;
        final fleetTile = find.widgetWithText(
          ExpansionTile,
          'Fleet ${nonHomeFleets.first.id}',
        );

        await pumpNavalPanel(tester, game: game, humanPlayerId: humanId);
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

        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(320, 800));
        await pumpNavalPanel(tester, game: game, humanPlayerId: humanId);
        expect(fleetTile, findsOneWidget);
        expect(
          find.descendant(of: fleetTile, matching: find.byIcon(Icons.route)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: fleetTile,
            matching: find.byIcon(Icons.call_split),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: fleetTile, matching: find.text('Move')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC: Home Fleet is never deleted even when empty after combine',
      (WidgetTester tester) async {
        const humanId = 'gp_home_never_deleted';
        final homeId = homeFleetIdFor(humanId);
        final g = _capPeers(
          humanId: humanId,
          gameId: 'g_home_never_deleted',
          displayName: 'Home never deleted tester',
          nextShipInstanceSeq: 3,
          peerFleets: [
            _portPeer(
              id: 'donor',
              humanId: humanId,
              ships: const [ShipInstance(id: 'ship_d', typeId: 'fluyte')],
            ),
          ],
        );
        final (bus, updated) = _wireFleetBus(
          wire: (b) =>
              wireNavalTransferForWidgetTest(bus: b, gameSnapshot: () => g),
        );
        await pumpNavalPanel(tester, game: g, humanPlayerId: humanId, bus: bus);
        await _tapCbs(tester, [
          find.widgetWithText(ExpansionTile, 'Home Fleet'),
          find.widgetWithText(ExpansionTile, 'Fleet donor'),
        ]);
        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
        await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('fluyte')));
        await tester.pumpAndSettle();
        final confirm = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Transfer'),
        );
        expect(confirm.enabled, isTrue);
        confirm.onPressed!.call();
        await tester.pumpAndSettle();
        final fleets = updated()!.game.worldState.fleets;
        final homeFleet = fleets.where((f) => f.id == homeId);
        expect(homeFleet, isNotEmpty);
        expect((homeFleet.first.ships.map((s) => s.id).toList()..sort()), [
          'ship_d',
          'ship_h',
        ]);
        expect(fleets.any((f) => f.id == 'donor'), isFalse);
      },
    );

    testWidgets(
      'AC: Non-Home fleet split cannot empty original (Confirm Split disabled)',
      (WidgetTester tester) async {
        const humanId = 'gp_nonhome_removed';
        final g = _capPeers(
          humanId: humanId,
          gameId: 'g_nonhome_removed',
          displayName: 'Non-home removed tester',
          nextShipInstanceSeq: 3,
          peerFleets: [
            _portPeer(
              id: 'split_me',
              humanId: humanId,
              ships: const [ShipInstance(id: 'ship_s1', typeId: 'fluyte')],
            ),
          ],
        );
        final (bus, updated) = _wireFleetBus(
          wire: (b) =>
              wireNavalSplitForWidgetTest(bus: b, gameSnapshot: () => g),
        );
        await pumpNavalPanel(tester, game: g, humanPlayerId: humanId, bus: bus);
        final fleetTile = find.widgetWithText(ExpansionTile, 'Fleet split_me');
        await tester.ensureVisible(fleetTile);
        await tester.tap(fleetTile);
        await tester.pumpAndSettle();
        final split = find.descendant(
          of: fleetTile,
          matching: find.byTooltip('Split'),
        );
        await tester.ensureVisible(split);
        await tester.tap(split);
        await tester.pumpAndSettle();
        final typeId = g.worldState.fleets
            .firstWhere((f) => f.id == 'split_me')
            .ships
            .single
            .typeId;
        await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne(typeId)));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CtNinePatchButton>(
                find.widgetWithText(CtNinePatchButton, 'Confirm Split'),
              )
              .enabled,
          isFalse,
        );
        expect(updated(), isNull);
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
    return buildAppShell(
      child: Scaffold(
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
