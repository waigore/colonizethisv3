// Mockup-fidelity pins for UNIT30001 / naval-units-panel (Refs #2866 S8, #4224).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/panels/fleet_expansion_tile.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_card.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_circular_locate_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'naval_units_panel_test_support.dart';

Finder _navalTile(String label) => find.widgetWithText(ExpansionTile, label);

List<String> _navalTooltips(
  WidgetTester tester,
  Finder tile,
  Set<String> messages,
) =>
    tester
        .widgetList<Tooltip>(
          find.descendant(of: tile, matching: find.byType(Tooltip)),
        )
        .where((t) => messages.contains(t.message))
        .map((t) => t.message!)
        .toList(growable: false);

void registerNavalMockupFidelityTests(
  void Function(String description, Future<void> Function(WidgetTester) body)
      testWidgets,
  Game game,
) {
  Future<void> pump(WidgetTester tester) =>
      pumpNavalMockupFidelityPanel(tester, game: game);

  testWidgets('R25 — compact inline action pills on one row', (tester) async {
    await pump(tester);
    final channel = _navalTile('Fleet channel_fleet');
    final actionRow = tester.widget<UnitsEntityActionRow>(
      find.descendant(of: channel, matching: find.byType(UnitsEntityActionRow)),
    );
    expect(actionRow.dense, isTrue);
    final pills = find.descendant(
      of: channel,
      matching: find.byType(CtActionTextButton),
    );
    final locate = find.descendant(
      of: channel,
      matching: find.byType(CtCircularLocateButton),
    );
    expect(pills, findsNWidgets(2));
    expect(locate, findsOneWidget);
    expect(
      find.descendant(of: channel, matching: find.byType(CtNinePatchButton)),
      findsNothing,
    );
    expect(
      {
        tester.getCenter(pills.first).dy,
        tester.getCenter(pills.last).dy,
        tester.getCenter(locate).dy,
      }.length,
      1,
    );
  });

  testWidgets('R26 — HOME chip on Home Fleet row only', (tester) async {
    await pump(tester);
    final home = _navalTile('Home Fleet');
    expect(find.descendant(of: home, matching: find.text('HOME')), findsOneWidget);
    expect(
      find.descendant(of: _navalTile('Fleet channel_fleet'), matching: find.text('HOME')),
      findsNothing,
    );
  });

  testWidgets('R27 — Locate is rightmost action', (tester) async {
    await pump(tester);
    const tips = {'Move', 'Split', 'Locate fleet'};
    expect(
      _navalTooltips(tester, _navalTile('Fleet channel_fleet'), tips),
      ['Move', 'Split', 'Locate fleet'],
    );
    expect(
      _navalTooltips(tester, _navalTile('Home Fleet'), tips),
      ['Split', 'Locate fleet'],
    );
  });

  testWidgets('R28 — (in port) / (at sea) location qualifier', (tester) async {
    await pump(tester);
    expect(find.text('Old World — Portsmouth (in port)'), findsOneWidget);
    expect(find.text('Old World — Bay of Biscay (at sea)'), findsOneWidget);
  });

  testWidgets('R29 — expanded composition Table + cargo + summary line', (
    tester,
  ) async {
    await pump(tester);
    final home = _navalTile('Home Fleet');
    await tester.tap(home);
    await tester.pumpAndSettle();
    final table = find.descendant(of: home, matching: find.byType(Table));
    expect(table, findsOneWidget);
    expect(tester.widget<Table>(table).children.length, 2);
    expect(find.text('Total ships: 2 · Warships: 1 · Merchants: 1'), findsOneWidget);
    expect(find.textContaining('Cargo capacity:'), findsOneWidget);
    expect(find.textContaining('holds'), findsOneWidget);
    expect(find.textContaining('Strength:'), findsOneWidget);

    final channel = _navalTile('Fleet channel_fleet');
    await tester.tap(channel);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: channel, matching: find.textContaining('Cargo capacity')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: channel,
        matching: find.text('Total ships: 2 · Warships: 2 · Merchants: 0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('FleetExpansionTile is the canonical naval row widget', (tester) async {
    await pump(tester);
    expect(find.byType(FleetExpansionTile), findsNWidgets(3));
  });

  testWidgets('issue #3514 AC-6 — UnitsEntityCard chrome per fleet row', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(UnitsEntityCard), findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      expect(
        find.descendant(
          of: find.byType(FleetExpansionTile).at(i),
          matching: find.byType(UnitsEntityCard),
        ),
        findsOneWidget,
      );
    }
    for (final row in tester.widgetList<UnitsEntityActionRow>(
      find.byType(UnitsEntityActionRow),
    )) {
      expect(row.chrome, isFalse);
      expect(row.dense, isTrue);
    }
  });
}
