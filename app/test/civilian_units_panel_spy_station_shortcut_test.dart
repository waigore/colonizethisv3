// UNIT10001 Station spy Relocate shortcut (Refs #4439).
// SPEC: SPEC/ui/civilian-units-panel.md

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'civilian_units_panel_test_support.dart';

const _human = 'h1';
const _homeTile = 'oldWorld|p1|0|0';
const _rivalTile = 'oldWorld|p2|0|0';

void main() {
  suppressLogsForTests();

  testWidgets('spyOnly filters the roster to Spies', (tester) async {
    final game = buildCivilianOwUnitsGame(
      id: 'g_spy_only_filter',
      extraProvinces: [
        const Province(
          id: 'oldWorld|p2',
          regionId: 'oldWorld',
          displayName: 'Rival Land',
        ),
      ],
      units: [
        civilianIdleUnit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: _human,
          provinceId: 'oldWorld|p1',
          tileKey: _homeTile,
        ),
        civilianIdleUnit(
          id: 'spy1',
          type: kUnitTypeSpy,
          ownerId: _human,
          provinceId: 'oldWorld|p1',
          tileKey: _homeTile,
        ),
      ],
    );
    await tester.pumpWidget(
      buildCivilianPanel(
        game: game,
        humanPlayerId: _human,
        spyOnly: true,
        relocateShortcutTargetTileKey: _rivalTile,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Spy'), findsWidgets);
    expect(find.text('Explorer'), findsNothing);
  });

  testWidgets('Relocate shortcut commits move without map pick', (
    tester,
  ) async {
    final bus = AppEventBus.create();
    final relocateStarts = <StartCivilianRelocateSelectionEvent>[];
    final moves = <CivilianMoveRequestedEvent>[];
    bus.on<StartCivilianRelocateSelectionEvent>().listen(relocateStarts.add);
    bus.on<CivilianMoveRequestedEvent>().listen(moves.add);
    final game = buildCivilianSpyFixtureGame(id: 'g_spy_shortcut_commit');
    await tester.pumpWidget(
      buildCivilianPanel(
        game: game,
        humanPlayerId: _human,
        bus: bus,
        spyOnly: true,
        relocateShortcutTargetTileKey: _rivalTile,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relocate'));
    await tester.pumpAndSettle();
    expect(relocateStarts, isEmpty);
    expect(moves, hasLength(1));
    expect(moves.single.moveOrder.unitId, 'spy1');
    expect(moves.single.moveOrder.destinationTileKey, _rivalTile);
  });

  testWidgets('leave-intel dismiss leaves orders unchanged', (tester) async {
    final bus = AppEventBus.create();
    final moves = <CivilianMoveRequestedEvent>[];
    bus.on<CivilianMoveRequestedEvent>().listen(moves.add);
    final game = buildCivilianSpyFixtureGame(
      id: 'g_spy_shortcut_intel',
      foreignStation: true,
    );
    await tester.pumpWidget(
      buildCivilianPanel(
        game: game,
        humanPlayerId: _human,
        bus: bus,
        spyOnly: true,
        relocateShortcutTargetTileKey: _homeTile,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relocate'));
    await tester.pumpAndSettle();
    expect(find.text('Leave intel?'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(moves, isEmpty);
  });

  testWidgets('invalid shortcut Relocate is a silent no-op', (tester) async {
    final bus = AppEventBus.create();
    final relocateStarts = <StartCivilianRelocateSelectionEvent>[];
    final moves = <CivilianMoveRequestedEvent>[];
    bus.on<StartCivilianRelocateSelectionEvent>().listen(relocateStarts.add);
    bus.on<CivilianMoveRequestedEvent>().listen(moves.add);
    final game = buildCivilianSpyFixtureGame(id: 'g_spy_shortcut_noop');
    final orders = civilianSpyPendingMoveOrder(
      humanId: _human,
      spyId: 'spy1',
      destinationTileKey: _rivalTile,
    );
    await tester.pumpWidget(
      buildCivilianPanel(
        game: game,
        humanPlayerId: _human,
        bus: bus,
        currentOrders: orders,
        spyOnly: true,
        relocateShortcutTargetTileKey: _rivalTile,
      ),
    );
    await tester.pumpAndSettle();
    final relocate = find.text('Relocate');
    if (relocate.evaluate().isNotEmpty) {
      await tester.tap(relocate);
      await tester.pumpAndSettle();
    }
    expect(relocateStarts, isEmpty);
    expect(moves, isEmpty);
  });
}
