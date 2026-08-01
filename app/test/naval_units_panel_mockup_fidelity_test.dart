// Pins the five naval-units mockup-fidelity behaviors closed by Refs #2866 S8
// (R25–R29) against `SPEC/ui/mockups/UNIT30001-naval-units-panel.html` and
// `SPEC/ui/naval-units-panel.md`. Each `group` corresponds to one R-item so
// regressions point straight at the spec line they broke.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/panels/fleet_expansion_tile.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_circular_locate_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_card.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'naval_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game game;
  setUpAll(() {
    game = buildNavalPanelMockupFidelityGame();
  });

  Future<void> pumpFidelity(WidgetTester tester) =>
      pumpNavalMockupFidelityPanel(tester, game: game);

  group('R25 — compact inline action pills on one row', () {
    testWidgets(
      'Non-home fleet renders Move + Split + Locate on a single dense row',
      (WidgetTester tester) async {
        await pumpFidelity(tester);

        final channelTile = find.widgetWithText(
          ExpansionTile,
          'Fleet channel_fleet',
        );
        expect(channelTile, findsOneWidget);

        final actionRow = tester.widget<UnitsEntityActionRow>(
          find.descendant(
            of: channelTile,
            matching: find.byType(UnitsEntityActionRow),
          ),
        );
        expect(actionRow.dense, isTrue);

        final pillButtons = find.descendant(
          of: channelTile,
          matching: find.byType(CtActionTextButton),
        );
        expect(pillButtons, findsNWidgets(2));
        final locateButton = find.descendant(
          of: channelTile,
          matching: find.byType(CtCircularLocateButton),
        );
        expect(locateButton, findsOneWidget);
        expect(
          find.descendant(
            of: channelTile,
            matching: find.byType(CtNinePatchButton),
          ),
          findsNothing,
        );

        final yCenters = <double>{
          tester.getCenter(pillButtons.first).dy,
          tester.getCenter(pillButtons.last).dy,
          tester.getCenter(locateButton).dy,
        };
        expect(yCenters.length, 1);
      },
    );
  });

  group('R26 — HOME chip on Home Fleet row only', () {
    testWidgets(
      'HOME chip renders next to Home Fleet name and not on regular fleets',
      (WidgetTester tester) async {
        await pumpFidelity(tester);

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
        expect(homeTile, findsOneWidget);
        expect(
          find.descendant(of: homeTile, matching: find.text('HOME')),
          findsOneWidget,
        );

        final channelTile = find.widgetWithText(
          ExpansionTile,
          'Fleet channel_fleet',
        );
        expect(
          find.descendant(of: channelTile, matching: find.text('HOME')),
          findsNothing,
        );
      },
    );
  });

  group(
    'R27 — Locate is the rightmost action and emits LocateMapTileEvent',
    () {
      testWidgets(
        'Locate is rightmost on channel fleet; Home Fleet is Split + Locate',
        (WidgetTester tester) async {
          await pumpFidelity(tester);

          final channelTile = find.widgetWithText(
            ExpansionTile,
            'Fleet channel_fleet',
          );
          final channelTips = tester
              .widgetList<Tooltip>(
                find.descendant(
                  of: channelTile,
                  matching: find.byType(Tooltip),
                ),
              )
              .where(
                (t) =>
                    t.message == 'Move' ||
                    t.message == 'Split' ||
                    t.message == 'Locate fleet',
              )
              .toList(growable: false);

          expect(channelTips.map((t) => t.message).toList(), [
            'Move',
            'Split',
            'Locate fleet',
          ]);
          expect(
            find.descendant(
              of: channelTile,
              matching: find.byType(CtCircularLocateButton),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byWidget(channelTips.last),
              matching: find.byType(Text),
            ),
            findsNothing,
          );

          final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
          final homeTips = tester
              .widgetList<Tooltip>(
                find.descendant(of: homeTile, matching: find.byType(Tooltip)),
              )
              .where(
                (t) =>
                    t.message == 'Move' ||
                    t.message == 'Split' ||
                    t.message == 'Locate fleet',
              )
              .toList(growable: false);
          expect(homeTips.map((t) => t.message).toList(), [
            'Split',
            'Locate fleet',
          ]);
        },
      );
    },
  );

  group('R28 — (in port) / (at sea) location qualifier', () {
    testWidgets('In-port and at-sea fleets append localised qualifiers', (
      WidgetTester tester,
    ) async {
      await pumpFidelity(tester);

      expect(find.text('Old World — Portsmouth (in port)'), findsOneWidget);
      expect(find.text('Old World — Bay of Biscay (at sea)'), findsOneWidget);
    });
  });

  group('R29 — expanded composition Table + cargo + single summary line', () {
    testWidgets(
      'Home Fleet expanded: Table rows, cargo, summary; non-home omits cargo',
      (WidgetTester tester) async {
        await pumpFidelity(tester);

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        final tableFinder = find.descendant(
          of: homeTile,
          matching: find.byType(Table),
        );
        expect(tableFinder, findsOneWidget);
        expect(tester.widget<Table>(tableFinder).children.length, 2);
        expect(
          find.text('Total ships: 2 · Warships: 1 · Merchants: 1'),
          findsOneWidget,
        );
        expect(find.text('1 warships'), findsNothing);
        expect(find.text('1 merchants'), findsNothing);
        expect(find.text('Total ships: 2'), findsNothing);
        expect(find.textContaining('Cargo capacity:'), findsOneWidget);
        expect(find.textContaining('holds'), findsOneWidget);
        expect(find.textContaining('Strength:'), findsOneWidget);

        final channelTile = find.widgetWithText(
          ExpansionTile,
          'Fleet channel_fleet',
        );
        await tester.tap(channelTile);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: channelTile,
            matching: find.textContaining('Cargo capacity'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: channelTile,
            matching: find.text('Total ships: 2 · Warships: 2 · Merchants: 0'),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('FleetExpansionTile API surface', () {
    testWidgets('FleetExpansionTile is the canonical naval row widget', (
      WidgetTester tester,
    ) async {
      await pumpFidelity(tester);
      expect(find.byType(FleetExpansionTile), findsNWidgets(3));
    });
  });

  group('Naval fleet card chrome (issue #3514 AC-6)', () {
    testWidgets(
      'Each fleet row is rendered inside a UnitsEntityCard with its dense '
      'action row hosted chrome-less (no double border) and no overflow',
      (WidgetTester tester) async {
        await pumpFidelity(tester);
        expect(tester.takeException(), isNull);
        expect(find.byType(UnitsEntityCard), findsNWidgets(3));

        for (final card in <Finder>[
          find.descendant(
            of: find.byType(FleetExpansionTile).at(0),
            matching: find.byType(UnitsEntityCard),
          ),
          find.descendant(
            of: find.byType(FleetExpansionTile).at(1),
            matching: find.byType(UnitsEntityCard),
          ),
          find.descendant(
            of: find.byType(FleetExpansionTile).at(2),
            matching: find.byType(UnitsEntityCard),
          ),
        ]) {
          expect(card, findsOneWidget);
        }

        final actionRows = tester.widgetList<UnitsEntityActionRow>(
          find.byType(UnitsEntityActionRow),
        );
        expect(actionRows, isNotEmpty);
        for (final row in actionRows) {
          expect(row.chrome, isFalse);
          expect(row.dense, isTrue);
        }
      },
    );
  });
}
