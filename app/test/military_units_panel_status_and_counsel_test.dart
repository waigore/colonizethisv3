// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'military_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  // ignore: unused_local_variable
  late String humanPlayerIdWithUnits;

  setUpAll(() {
    game = buildMilitaryPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
  });

  group('Unit status display', () {
    testWidgets('shows Working status when any unit is working', (
      WidgetTester tester,
    ) async {
      const playerId = 'working_status_player';
      final gameWithWorkingUnit = buildMilitaryArmyAtLisbonDisplayGame(
        id: 'working_test',
        playerId: playerId,
        armyId: 'army_w',
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
      );

      await pumpMilitaryPanel(
        tester,
        game: gameWithWorkingUnit,
        humanPlayerId: playerId,
      );
      await tester.tap(find.text('Army army_w'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: Working'), findsOneWidget);
    });

    testWidgets('shows Idle status when units are idle and none working', (
      WidgetTester tester,
    ) async {
      const playerId = 'idle_status_player';
      final gameWithIdleUnit = buildMilitaryArmyAtLisbonDisplayGame(
        id: 'idle_test',
        playerId: playerId,
        armyId: 'army_d',
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
      );

      await pumpMilitaryPanel(
        tester,
        game: gameWithIdleUnit,
        humanPlayerId: playerId,
      );
      await tester.tap(find.text('Army army_d'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: Idle'), findsOneWidget);
    });
  });

  group('Counsel entry (Refs #4307)', () {
    testWidgets(
      'header Counsel emits NavigateToRouteEvent for Military tab on GAME90001',
      (WidgetTester tester) async {
        const playerId = 'gp_counsel_entry';
        final bus = AppEventBus.create();
        NavigateToRouteEvent? navigateEvent;
        bus.on<NavigateToRouteEvent>().listen((event) {
          navigateEvent = event;
        });

        final panelGame = buildMilitaryArmyAtLisbonDisplayGame(
          id: 'counsel_entry',
          playerId: playerId,
          armyId: 'army_counsel',
          units: [
            Unit(
              id: 'u_counsel',
              type: 'musketeers',
              ownerId: playerId,
              locationProvinceId: 'oldWorld|lisbon',
            ),
          ],
        );

        await pumpMilitaryPanel(
          tester,
          game: panelGame,
          humanPlayerId: playerId,
          bus: bus,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('military_units_counsel_button')),
        );
        await tester.pumpAndSettle();

        expect(navigateEvent, isNotNull);
        expect(navigateEvent!.route, Routes.counsel);
        final args = navigateEvent!.arguments as Map<String, Object?>?;
        expect(args?['counselTab'], 'military');
        expect(args?['humanPlayerId'], playerId);
      },
    );
  });
}
