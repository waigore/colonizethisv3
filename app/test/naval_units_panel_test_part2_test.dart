// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        applyNavalSplitFleet,
        applyNavalTransferShipsBetweenFleets,
        homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

/// Mirrors shell handling of [NavalSplitFleetRequestedEvent] for widget tests.
StreamSubscription<NavalSplitFleetRequestedEvent> wireNavalSplitForWidgetTest({
  required AppEventBus bus,
  required Game Function() gameSnapshot,
}) {
  return bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
    final next = applyNavalSplitFleet(
      game: gameSnapshot(),
      humanPlayerId: e.humanPlayerId,
      originalFleetId: e.originalFleetId,
      shipInstanceIdsToNewFleet: e.shipInstanceIdsToNewFleet,
    );
    bus.emit(NavalFleetsUpdatedEvent(game: next));
  });
}

/// Mirrors shell handling of [NavalTransferShipsRequestedEvent] for widget tests.
StreamSubscription<NavalTransferShipsRequestedEvent>
wireNavalTransferForWidgetTest({
  required AppEventBus bus,
  required Game Function() gameSnapshot,
}) {
  return bus.on<NavalTransferShipsRequestedEvent>().listen((e) {
    final next = applyNavalTransferShipsBetweenFleets(
      game: gameSnapshot(),
      humanPlayerId: e.humanPlayerId,
      sourceFleetId: e.sourceFleetId,
      targetFleetId: e.targetFleetId,
      shipInstanceIdsToTransfer: e.shipInstanceIdsToTransfer,
    );
    bus.emit(NavalFleetsUpdatedEvent(game: next));
  });
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game game;
  late String humanPlayerIdWithFleets;
  const String humanPlayerIdWithNoFleets = 'no-such-player';

  // Fallback 1x1 transparent PNG if the real asset cannot be read.
  final ninePatchFallbackPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=',
  );
  Uint8List ninePatchBytes = ninePatchFallbackPng;

  setUpAll(() async {
    final assetCandidates = <String>[
      'app/assets/images/ui_button_nine_patch.png',
      'assets/images/ui_button_nine_patch.png',
    ];
    for (final candidate in assetCandidates) {
      final file = File(candidate);
      if (await file.exists()) {
        ninePatchBytes = await file.readAsBytes();
        break;
      }
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = const StringCodec().decodeMessage(message);
          if (key == 'assets/images/ui_button_nine_patch.png') {
            return ByteData.view(ninePatchBytes.buffer);
          }
          return null;
        });

    // Preload panel nine-patch image into Flame cache so widget tests are
    // stable regardless of invocation directory.
    try {
      final bytes = await rootBundle.load(
        'assets/images/ui_button_nine_patch.png',
      );
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      Flame.images.add('ui_button_nine_patch.png', frame.image);
      Flame.images.add('assets/images/ui_button_nine_patch.png', frame.image);
    } catch (_) {
      // Keep tests resilient when asset prewarm fails; individual tests can
      // still validate behavior where possible.
    }

    game = getDebugInitGameResult().game;
    humanPlayerIdWithFleets = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    AppEventBus? bus,
    MapTopology topology = const MapTopology(),
    Orders draftOrders = const Orders(),
    String? locationScopeKey,
  }) {
    final resolvedBus = bus ?? AppEventBus.create();
    return MaterialApp(
      home: Scaffold(
        body: NavalUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          bus: resolvedBus,
          topology: topology,
          draftOrders: draftOrders,
          locationScopeKey: locationScopeKey,
        ),
      ),
    );
  }

  group('NavalUnitsPanel', () {
    testWidgets(
      'AC: Header checkbox selects all fleets then second interaction clears',
      (WidgetTester tester) async {
        const humanId = 'gp_select_all';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final selectAllGame = Game(
          id: 'g_select_all',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'a',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'b',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ship_2', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Select-all tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: selectAllGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final headerCheckboxFinder = find.descendant(
          of: find.byType(NavalUnitsPanel),
          matching: find.byWidgetPredicate(
            (w) => w is Checkbox && w.tristate == true,
          ),
        );
        expect(headerCheckboxFinder, findsOneWidget);

        await tester.tap(headerCheckboxFinder);
        await tester.pumpAndSettle();

        final checkboxes = find.byType(Checkbox);
        final cbCount = checkboxes.evaluate().length;
        expect(cbCount, greaterThanOrEqualTo(2));
        for (var i = 0; i < cbCount; i++) {
          expect(tester.widget<Checkbox>(checkboxes.at(i)).value, isTrue);
        }

        await tester.tap(headerCheckboxFinder);
        await tester.pumpAndSettle();

        for (var i = 0; i < cbCount; i++) {
          expect(tester.widget<Checkbox>(checkboxes.at(i)).value, isFalse);
        }
      },
    );

    testWidgets('AC: Combining fleets creates correct ship counts', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_combine_count';
      const capProvince = 'oldWorld|cap1';
      const mergePort = 'oldWorld|mergeport';

      final combineGame = Game(
        id: 'g_combine_count',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'cap1',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Capital',
              ),
              Province(
                id: 'mergeport',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Merge Port',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'test_fleet_1',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
            ),
            Fleet(
              id: 'test_fleet_2',
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ship_2', typeId: 'fluyte')],
            ),
          ],
          // Capital only: merge-port fleets intentionally have no tile key so the
          // panel does not wrap them in a locate InkWell (that would swallow taps
          // and prevent ExpansionTile from expanding in widget tests).
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              capProvince: ['oldWorld|cap1|0|0'],
            },
          },
          nextShipInstanceSeq: 3,
        ),
        players: [
          Player(
            id: humanId,
            displayName: 'Combine tester',
            isHuman: true,
            capitalProvinceId: capProvince,
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: capProvince,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );

      final bus = AppEventBus.create();
      NavalFleetsUpdatedEvent? updated;
      final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
        updated = e;
      });
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        buildPanel(game: combineGame, humanPlayerId: humanId, bus: bus),
      );
      await tester.pumpAndSettle();

      final fleet1Finder = find.widgetWithText(
        ExpansionTile,
        'Fleet test_fleet_1',
      );
      expect(fleet1Finder, findsOneWidget);

      final fleet2Finder = find.widgetWithText(
        ExpansionTile,
        'Fleet test_fleet_2',
      );
      expect(fleet2Finder, findsOneWidget);

      final cb1 = find.descendant(
        of: fleet1Finder,
        matching: find.byType(Checkbox),
      );
      final cb2 = find.descendant(
        of: fleet2Finder,
        matching: find.byType(Checkbox),
      );
      await tester.ensureVisible(cb1);
      await tester.tap(cb1);
      await tester.pumpAndSettle();
      await tester.ensureVisible(cb2);
      await tester.tap(cb2);
      await tester.pumpAndSettle();

      final combineFinder = find.widgetWithText(CtActionTextButton, 'Combine');
      await tester.ensureVisible(combineFinder);
      await tester.tap(combineFinder);
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      final fleetsAfter = updated!.game.worldState.fleets;
      final merged = fleetsAfter.firstWhere((f) => f.id == 'test_fleet_1');
      final mergedIds = merged.ships.map((s) => s.id).toList()..sort();
      expect(mergedIds, ['ship_1', 'ship_2']);
      expect(fleetsAfter.any((f) => f.id == 'test_fleet_2'), isFalse);
    });

    testWidgets(
      'AC: Fleets at different locations keep Combine disabled when both checked',
      (WidgetTester tester) async {
        const humanId = 'gp_diff_loc';
        const capProvince = 'oldWorld|cap1';
        const portA = 'oldWorld|port_a';
        const portB = 'oldWorld|port_b';

        final diffLocGame = Game(
          id: 'g_diff_loc',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'port_a',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Port A',
                ),
                Province(
                  id: 'port_b',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Port B',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fa',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: portA,
                ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'fb',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: portB,
                ships: const [ShipInstance(id: 'ship_2', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Diff-loc tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: diffLocGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final fleetAFinder = find.widgetWithText(ExpansionTile, 'Fleet fa');
        final fleetBFinder = find.widgetWithText(ExpansionTile, 'Fleet fb');
        expect(fleetAFinder, findsOneWidget);
        expect(fleetBFinder, findsOneWidget);

        await tester.tap(
          find.descendant(of: fleetAFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: fleetBFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Combining into Home Fleet merges ships into home id when Home is selected',
      (WidgetTester tester) async {
        const humanId = 'gp_home_combine';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        final homeCombineGame = Game(
          id: 'g_home_combine',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: homeId,
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
                mission: FleetMission.patrol,
              ),
              Fleet(
                id: 'at_capital',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'ship_v', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Home combine tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        final subTransfer = wireNavalTransferForWidgetTest(
          bus: bus,
          gameSnapshot: () => homeCombineGame,
        );
        addTearDown(sub.cancel);
        addTearDown(subTransfer.cancel);

        await tester.pumpWidget(
          buildPanel(game: homeCombineGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final homeFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final otherFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet at_capital',
        );
        expect(homeFinder, findsOneWidget);
        expect(otherFinder, findsOneWidget);

        await tester.tap(
          find.descendant(of: homeFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: otherFinder, matching: find.byType(Checkbox)),
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
        expect(fleetsAfter.where((f) => f.id == 'at_capital'), isEmpty);

        final home = fleetsAfter.firstWhere((f) => f.id == homeId);
        final shipIds = home.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ship_h', 'ship_v']);
        expect(home.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Combining three fleets at same port merges all ships into first in panel order',
      (WidgetTester tester) async {
        const humanId = 'gp_three_combine';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final threeGame = Game(
          id: 'g_three_combine',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'c1',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'c2',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 's2', typeId: 'fluyte')],
              ),
              Fleet(
                id: 'c3',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 's3', typeId: 'carrack')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 4,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Three combine tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: threeGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        for (final label in ['Fleet c1', 'Fleet c2', 'Fleet c3']) {
          final tile = find.widgetWithText(ExpansionTile, label);
          expect(tile, findsOneWidget);
          final cb = find.descendant(of: tile, matching: find.byType(Checkbox));
          await tester.scrollUntilVisible(cb, 120);
          await tester.pumpAndSettle();
          await tester.ensureVisible(cb);
          await tester.tap(cb);
          await tester.pumpAndSettle();
        }

        final combineBtnFinder = find.widgetWithText(
          CtActionTextButton,
          'Combine',
        );
        await tester.scrollUntilVisible(combineBtnFinder, 120);
        await tester.pumpAndSettle();
        await tester.tap(combineBtnFinder);
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.length, 1);
        final survivor = fleetsAfter.single;
        expect(survivor.id, 'c1');
        final ids = survivor.ships.map((s) => s.id).toList();
        expect(ids, ['s1', 's2', 's3']);
        expect(survivor.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Fleets in different sea zones keep Combine disabled when both checked',
      (WidgetTester tester) async {
        const humanId = 'gp_two_seas';
        const capProvince = 'oldWorld|cap1';

        final twoSeaGame = Game(
          id: 'g_two_seas',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'coast',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Coast',
                ),
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'sea_a',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_alpha',
                inPortAtProvinceId: null,
                ships: const [ShipInstance(id: 'a1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'sea_b',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_beta',
                inPortAtProvinceId: null,
                ships: const [ShipInstance(id: 'b1', typeId: 'fluyte')],
              ),
            ],
            portsByProvinceSeaboard: {
              'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
              'oldWorld|coast|zone_beta': 'oldWorld|coast|1|0',
            },
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
                'oldWorld|coast': ['oldWorld|coast|0|0'],
              },
            },
            nextShipInstanceSeq: 2,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Two seas tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: twoSeaGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final finderA = find.widgetWithText(ExpansionTile, 'Fleet sea_a');
        final finderB = find.widgetWithText(ExpansionTile, 'Fleet sea_b');
        expect(finderA, findsOneWidget);
        expect(finderB, findsOneWidget);

        await tester.tap(
          find.descendant(of: finderA, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: finderB, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Fleet at sea and fleet in port keep Combine disabled when both checked',
      (WidgetTester tester) async {
        const humanId = 'gp_sea_port';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final seaPortGame = Game(
          id: 'g_sea_port',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
                Province(
                  id: 'coast',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Coast',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'at_sea',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_alpha',
                inPortAtProvinceId: null,
                ships: const [ShipInstance(id: 's_sea', typeId: 'carrack')],
              ),
              Fleet(
                id: 'in_port',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 's_port', typeId: 'fluyte')],
              ),
            ],
            portsByProvinceSeaboard: {
              'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
            },
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
                'oldWorld|coast': ['oldWorld|coast|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Sea-port tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: seaPortGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final seaFinder = find.widgetWithText(ExpansionTile, 'Fleet at_sea');
        final portFinder = find.widgetWithText(ExpansionTile, 'Fleet in_port');
        expect(seaFinder, findsOneWidget);
        expect(portFinder, findsOneWidget);

        await tester.tap(
          find.descendant(of: seaFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: portFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Home Fleet and adjacent sea source enable selected-ship transfer',
      (WidgetTester tester) async {
        const humanId = 'gp_home_adjacent';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        final gameAdj = Game(
          id: 'g_home_adjacent_transfer',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: homeId,
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'home_1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'sea_source',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_alpha',
                ships: const [
                  ShipInstance(id: 'src_1', typeId: 'fluyte'),
                  ShipInstance(id: 'src_2', typeId: 'carrack'),
                ],
              ),
            ],
          ),
          players: const [
            Player(
              id: humanId,
              displayName: 'Home adjacent tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|cap1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'zone_alpha',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'oldWorld|cap1', id2: 'zone_alpha')],
        );

        await tester.pumpWidget(
          buildPanel(game: gameAdj, humanPlayerId: humanId, topology: topology),
        );
        await tester.pumpAndSettle();

        final homeFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final sourceFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet sea_source',
        );
        expect(homeFinder, findsOneWidget);
        expect(sourceFinder, findsOneWidget);

        await tester.tap(
          find.descendant(of: homeFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: sourceFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isTrue);

        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
      },
    );
  });
}
