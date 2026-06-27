// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/utils/map_location_resolver.dart';
import 'package:colonizethis_app/features/game/widgets/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'support/panel_test_fixtures.dart';

/// Applies [ArmySplitRequestedEvent] like [AppEventHandlerScope] and rebuilds
/// the panel with updated [Game] (widget tests do not mount full shell).
class _ArmySplitTestHarness extends StatefulWidget {
  const _ArmySplitTestHarness({
    required this.initialGame,
    required this.humanPlayerId,
    required this.bus,
  });

  final Game initialGame;
  final String humanPlayerId;
  final AppEventBus bus;

  @override
  State<_ArmySplitTestHarness> createState() => _ArmySplitTestHarnessState();
}

class _ArmySplitTestHarnessState extends State<_ArmySplitTestHarness> {
  late Game _game;
  StreamSubscription<ArmySplitRequestedEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame;
    _sub = widget.bus.on<ArmySplitRequestedEvent>().listen((e) {
      final next = applyArmySplit(
        game: _game,
        playerId: e.humanPlayerId,
        sourceArmyId: e.sourceArmyId,
        unitIdsToMove: e.unitIdsToMove,
      );
      setState(() => _game = next);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MilitaryUnitsPanel(
      game: _game,
      humanPlayerId: widget.humanPlayerId,
      bus: widget.bus,
      topology: const MapTopology(),
      draftOrders: const Orders(),
    );
  }
}

Future<void> expandFirstArmyExpansion(WidgetTester tester) async {
  final tiles = find.byType(ExpansionTile);
  if (tiles.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tiles.first);
  await tester.pumpAndSettle();
}

Future<void> expandAllArmyExpansions(WidgetTester tester) async {
  final finder = find.byType(ExpansionTile);
  final n = finder.evaluate().length;
  for (var i = 0; i < n; i++) {
    await tester.tap(finder.at(i));
    await tester.pumpAndSettle();
  }
}

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = buildMilitaryPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
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

}
