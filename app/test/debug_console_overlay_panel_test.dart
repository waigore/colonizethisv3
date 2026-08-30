import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'debug_console_overlay_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('DebugConsoleOverlayPanel', () {
    testWidgets('submitting valid command emits spawn event', (tester) async {
      final bus = debugConsoleBus();
      final events = listenDebugEvents<SpawnDebugCivilianAtCapitalEvent>(bus);
      final snackbars = listenDebugEvents<ShowSnackBarEvent>(bus);
      var closed = false;

      await pumpDebugConsolePanel(
        tester,
        bus: bus,
        onClose: () => closed = true,
      );
      await submitDebugCommand(tester, '/spawn_civilian explorer 2');

      expect(events, hasLength(1));
      expect(events.single.humanPlayerId, 'human_1');
      expect(events.single.unitType, kUnitTypeExplorer);
      expect(events.single.count, 2);
      expect(snackbars, isNotEmpty);
      expect(
        snackbars.last.message,
        'Queued debug spawn: 2x Explorer at capital.',
      );
      expect(closed, isFalse);
    });

    testWidgets('submitting valid add_money emits treasury credit event', (
      tester,
    ) async {
      final bus = debugConsoleBus();
      final events = listenDebugEvents<CreditDebugTreasuryEvent>(bus);
      final snackbars = listenDebugEvents<ShowSnackBarEvent>(bus);

      await pumpDebugConsolePanel(tester, bus: bus);
      await submitDebugCommand(tester, '/add_money 42');

      expect(events, hasLength(1));
      expect(events.single.humanPlayerId, 'human_1');
      expect(events.single.requestedAmount, 42);
      expect(events.single.creditedAmount, 42);
      expect(snackbars.last.message, contains('42'));
    });

    testWidgets('submitting valid spawn_regiment emits regiment event', (
      tester,
    ) async {
      final bus = debugConsoleBus();
      final events = listenDebugEvents<SpawnDebugRegimentAtCapitalEvent>(bus);

      await pumpDebugConsolePanel(tester, bus: bus);
      await submitDebugCommand(tester, '/spawn_regiment peasant_levies 2');

      expect(events, hasLength(1));
      expect(events.single.humanPlayerId, 'human_1');
      expect(events.single.regimentTypeId, 'peasant_levies');
      expect(events.single.count, 2);
    });

    testWidgets('submitting valid spawn_ship emits ship spawn event', (
      tester,
    ) async {
      final bus = debugConsoleBus();
      final events = listenDebugEvents<SpawnDebugShipAtCapitalHomeFleetEvent>(
        bus,
      );

      await pumpDebugConsolePanel(tester, bus: bus);
      await submitDebugCommand(tester, '/spawn_ship carrack 2');

      expect(events, hasLength(1));
      expect(events.single.humanPlayerId, 'human_1');
      expect(events.single.shipTypeId, 'carrack');
      expect(events.single.count, 2);
    });

    testWidgets('invalid command does not emit spawn event', (tester) async {
      final bus = debugConsoleBus();
      final events = listenDebugEvents<SpawnDebugCivilianAtCapitalEvent>(bus);

      await pumpDebugConsolePanel(tester, bus: bus);
      await submitDebugCommand(tester, '/spawn_civilian unknown_type');

      expect(events, isEmpty);
    });

    testWidgets('submitting flip_province emits ownership flip event', (
      tester,
    ) async {
      final bus = debugConsoleBus();
      final events = listenDebugEvents<FlipDebugProvinceOwnershipEvent>(bus);

      await pumpDebugConsolePanel(tester, bus: bus);
      await submitDebugCommand(tester, '/flip_province oldWorld New Bordeaux');

      expect(events, hasLength(1));
      expect(events.single.humanPlayerId, 'human_1');
      expect(events.single.regionId, 'oldWorld');
      expect(events.single.provinceDisplayName, 'New Bordeaux');
    });

    testWidgets(
      'submitting rail_builder command emits rail builder spawn event',
      (tester) async {
        final bus = debugConsoleBus();
        final events = listenDebugEvents<SpawnDebugCivilianAtCapitalEvent>(bus);

        await pumpDebugConsolePanel(tester, bus: bus);
        await submitDebugCommand(tester, '/spawn_civilian rail_builder 3');

        expect(events, hasLength(1));
        expect(events.single.unitType, kUnitTypeRailBuilder);
        expect(events.single.count, 3);
      },
    );

    testWidgets('invalid command emits deterministic snackbar message', (
      tester,
    ) async {
      final bus = debugConsoleBus();
      final snackbars = listenDebugEvents<ShowSnackBarEvent>(bus);

      await pumpDebugConsolePanel(tester, bus: bus);
      await submitDebugCommand(tester, '/spawn_civilian unknown_type');

      expect(snackbars, isNotEmpty);
      expect(
        snackbars.last.message,
        'Unknown civilian type. Use explorer, builder, engineer, spy, merchant, or rail_builder.',
      );
    });

    testWidgets('escape key triggers panel close callback', (tester) async {
      final bus = debugConsoleBus();
      var closeCount = 0;

      await pumpDebugConsolePanel(
        tester,
        bus: bus,
        onClose: () => closeCount += 1,
      );

      await tester.tap(find.byKey(debugConsoleInputKey));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(closeCount, 1);
    });

    testWidgets('arrow up and down navigate submitted command history', (
      tester,
    ) async {
      final bus = debugConsoleBus();

      await pumpDebugConsolePanel(tester, bus: bus);

      await submitDebugCommand(tester, '/spawn_civilian explorer 1');
      await submitDebugCommand(tester, '/spawn_civilian builder 2');

      await tester.tap(find.byKey(debugConsoleInputKey));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      EditableText editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.controller.text, '/spawn_civilian builder 2');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.controller.text, '/spawn_civilian explorer 1');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.controller.text, '/spawn_civilian builder 2');
    });

    testWidgets('/get_tile_basic_info reads selectedTileKey at submit-time', (
      tester,
    ) async {
      final bus = debugConsoleBus();
      final events = listenDebugEvents<SessionCommandEvent>(bus);
      final snackbars = listenDebugEvents<ShowSnackBarEvent>(bus);
      String? selectedTileKey = 'oldWorld|P12|34|21';

      await pumpDebugConsolePanel(
        tester,
        bus: bus,
        readOnlyContextProvider: () =>
            DebugConsoleReadOnlyContext(selectedTileKey: selectedTileKey),
      );

      await submitDebugCommand(tester, '/get_tile_basic_info');
      expect(snackbars.last.message, contains('tile_id: oldWorld|P12|34|21'));
      expect(snackbars.last.message, contains('province_id: oldWorld|P12'));
      expect(events, isEmpty);

      selectedTileKey = 'oldWorld|P1|2|3';
      await submitDebugCommand(tester, '/get_tile_basic_info');
      expect(snackbars.last.message, contains('tile_id: oldWorld|P1|2|3'));
      expect(snackbars.last.message, contains('province_id: oldWorld|P1'));
      expect(events, isEmpty);
    });

    testWidgets('/list_players appends output and emits no session events', (
      tester,
    ) async {
      final bus = debugConsoleBus();
      final events = listenDebugEvents<SessionCommandEvent>(bus);
      final snackbars = listenDebugEvents<ShowSnackBarEvent>(bus);

      await pumpDebugConsolePanel(
        tester,
        bus: bus,
        readOnlyContextProvider: () => DebugConsoleReadOnlyContext(
          players: [
            const DebugConsolePlayerSnapshot(
              id: 'p1',
              displayName: 'One',
              isHuman: true,
              capitalProvinceId: 'r|P9',
            ),
          ],
        ),
      );

      await submitDebugCommand(tester, '/list_players');

      expect(snackbars.last.message, contains('players_count: 1'));
      expect(snackbars.last.message, contains('player_id: p1'));
      expect(events, isEmpty);
    });
  });
}
