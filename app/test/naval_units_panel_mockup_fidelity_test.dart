// Pins the five naval-units mockup-fidelity behaviors closed by Refs #2866 S8
// (R25–R29) against `SPEC/ui/mockups/UNIT30001-naval-units-panel.html` and
// `SPEC/ui/naval-units-panel.md`. Each `group` corresponds to one R-item so
// regressions point straight at the spec line they broke.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/fleet_expansion_tile.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_circular_locate_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_card.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

const _humanId = 'gp_naval_fidelity';
const _capitalLocalId = 'cap1';
const _capitalProvinceId = 'oldWorld|$_capitalLocalId';
const _portLocalId = 'port1';
const _portProvinceId = 'oldWorld|$_portLocalId';
const _localSeaZoneId = 'zone_alpha';
const _zonePrefixedId = 'oldWorld|$_localSeaZoneId';

Game _buildFidelityGame() {
  final homeId = homeFleetIdFor(_humanId);
  return Game(
    id: 'naval-fidelity',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: _capitalLocalId,
            regionId: 'oldWorld',
            ownerId: _humanId,
            displayName: 'London',
          ),
          Province(
            id: _portLocalId,
            regionId: 'oldWorld',
            ownerId: _humanId,
            displayName: 'Portsmouth',
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: [
        // Home Fleet (in port at capital) — drives R26 HOME chip and R29
        // Home-Fleet cargo line.
        Fleet(
          id: homeId,
          ownerId: _humanId,
          regionId: 'oldWorld',
          inPortAtProvinceId: _capitalProvinceId,
          ships: const [
            ShipInstance(id: 'h1', typeId: 'carrack'),
            ShipInstance(id: 'h2', typeId: 'frigate'),
          ],
        ),
        // In-port sea-going fleet — drives R25 dense pills, R27 locate
        // alignment, R28 `(in port)` qualifier.
        Fleet(
          id: 'channel_fleet',
          ownerId: _humanId,
          regionId: 'oldWorld',
          inPortAtProvinceId: _portProvinceId,
          ships: const [
            ShipInstance(id: 'p1', typeId: 'frigate'),
            ShipInstance(id: 'p2', typeId: 'frigate'),
          ],
        ),
        // At-sea fleet — drives R28 `(at sea)` qualifier.
        Fleet(
          id: 'atlantic_fleet',
          ownerId: _humanId,
          regionId: 'oldWorld',
          seaZoneId: _localSeaZoneId,
          ships: const [ShipInstance(id: 's1', typeId: 'galleon')],
        ),
      ],
      seaZoneDisplayNameById: const {_zonePrefixedId: 'Bay of Biscay'},
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          _capitalProvinceId: ['oldWorld|$_capitalLocalId|0|0'],
          _portProvinceId: ['oldWorld|$_portLocalId|0|0'],
        },
      },
    ),
    players: const [
      Player(
        id: _humanId,
        displayName: 'Fidelity Tester',
        isHuman: true,
        capitalProvinceId: _capitalProvinceId,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: _capitalProvinceId,
          x: 0,
          y: 0,
        ),
      ),
    ],
  );
}

Widget _hostPanel(Game game) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: NavalUnitsPanel(
          game: game,
          humanPlayerId: _humanId,
          bus: AppEventBus.create(),
          topology: const MapTopology(),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game game;
  setUpAll(() {
    // Build the deterministic fidelity scenario directly. Refs #3656: the panel
    // renders entirely from this hand-built fixture, so the prior ~11s
    // `getDebugInitGameResult()` warm call (which generated a full map this
    // suite never reads) is removed.
    game = _buildFidelityGame();
  });

  group('R25 — compact inline action pills on one row', () {
    testWidgets(
      'Non-home fleet renders Move + Split + Locate on a single dense row',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostPanel(game));
        await tester.pumpAndSettle();

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
        expect(
          actionRow.dense,
          isTrue,
          reason: 'Naval fleet rows must use the dense pill footprint (R25)',
        );

        // Move + Split render as mockup compact-pill CtActionTextButtons and
        // Locate as the circular CtCircularLocateButton (issue #3514 owner
        // decision #6); the row must mount no CtNinePatchButton action chrome.
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
          reason: 'Naval fleet row actions must use pills, not nine-patch (R25)',
        );

        // All three controls render on a single horizontal line (no wrap).
        final yCenters = <double>{
          tester.getCenter(pillButtons.first).dy,
          tester.getCenter(pillButtons.last).dy,
          tester.getCenter(locateButton).dy,
        };
        expect(
          yCenters.length,
          1,
          reason: 'Move/Split/Locate must share one row (R25)',
        );
      },
    );
  });

  group('R26 — HOME chip on Home Fleet row only', () {
    testWidgets(
      'HOME chip renders next to Home Fleet name and not on regular fleets',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostPanel(game));
        await tester.pumpAndSettle();

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
        expect(homeTile, findsOneWidget);

        expect(
          find.descendant(of: homeTile, matching: find.text('HOME')),
          findsOneWidget,
          reason: 'Home Fleet row must render the uppercase HOME chip (R26)',
        );

        final channelTile = find.widgetWithText(
          ExpansionTile,
          'Fleet channel_fleet',
        );
        expect(
          find.descendant(of: channelTile, matching: find.text('HOME')),
          findsNothing,
          reason: 'Regular fleet rows must NOT render the HOME chip (R26)',
        );
      },
    );
  });

  group(
    'R27 — Locate is the rightmost action and emits LocateMapTileEvent',
    () {
      testWidgets(
        'Locate icon-only button is the rightmost child of the actions cluster',
        (WidgetTester tester) async {
          await tester.pumpWidget(_hostPanel(game));
          await tester.pumpAndSettle();

          final channelTile = find.widgetWithText(
            ExpansionTile,
            'Fleet channel_fleet',
          );

          final tooltips = tester
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

          // Move, Split, Locate.
          expect(tooltips.length, 3);
          expect(tooltips.first.message, 'Move');
          expect(tooltips[1].message, 'Split');
          expect(
            tooltips.last.message,
            'Locate fleet',
            reason: 'Locate must be the rightmost action (R27)',
          );

          // Locate renders as the circular icon-only CtCircularLocateButton
          // (R27 mockup `.locate-btn`; issue #3514). Its internal Tooltip
          // ('Locate fleet') subtree contains no Text label.
          expect(
            find.descendant(
              of: channelTile,
              matching: find.byType(CtCircularLocateButton),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byWidget(tooltips.last),
              matching: find.byType(Text),
            ),
            findsNothing,
            reason: 'Locate must be icon-only (R27 mockup `.locate-btn`)',
          );
        },
      );

      testWidgets('Home Fleet shows Split + Locate (no Move)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_hostPanel(game));
        await tester.pumpAndSettle();

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final tooltips = tester
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

        expect(tooltips.map((t) => t.message).toList(), [
          'Split',
          'Locate fleet',
        ]);
      });
    },
  );

  group('R28 — (in port) / (at sea) location qualifier', () {
    testWidgets('In-port fleet appends localised `(in port)` qualifier', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostPanel(game));
      await tester.pumpAndSettle();

      expect(
        find.text('Old World — Portsmouth (in port)'),
        findsOneWidget,
        reason:
            'R28: in-port fleet location must end with the localised '
            '`(in port)` qualifier',
      );
    });

    testWidgets('At-sea fleet appends localised `(at sea)` qualifier', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostPanel(game));
      await tester.pumpAndSettle();

      expect(
        find.text('Old World — Bay of Biscay (at sea)'),
        findsOneWidget,
        reason:
            'R28: at-sea fleet location must end with the localised '
            '`(at sea)` qualifier',
      );
    });
  });

  group('R29 — expanded composition Table + cargo + single summary line', () {
    testWidgets(
      'Home Fleet expanded view renders a Table, cargo line, and a single summary',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostPanel(game));
        await tester.pumpAndSettle();

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        // Composition table widget (one per expanded row).
        expect(
          find.descendant(of: homeTile, matching: find.byType(Table)),
          findsOneWidget,
          reason: 'R29: expanded view must render a Table widget',
        );

        // Single composition summary line.
        expect(
          find.text('Total ships: 2 · Warships: 1 · Merchants: 1'),
          findsOneWidget,
          reason:
              'R29: composition summary must be a single Text widget, not '
              'three separate ListTiles',
        );
        // Verify the legacy per-stat lines are gone (no `Warships: 1` /
        // `Merchants: 1` standalone Text widgets).
        expect(find.text('1 warships'), findsNothing);
        expect(find.text('1 merchants'), findsNothing);
        expect(find.text('Total ships: 2'), findsNothing);

        // Home Fleet cargo line uses the `_holds` localisation key.
        expect(
          find.textContaining('Cargo capacity:'),
          findsOneWidget,
          reason: 'R29: Home Fleet expanded view must render the cargo line',
        );
        expect(
          find.textContaining('holds'),
          findsOneWidget,
          reason: 'R29: cargo line uses the `holds` localisation key',
        );

        // Strength line retained.
        expect(find.textContaining('Strength:'), findsOneWidget);
      },
    );

    testWidgets(
      'Non-home fleet expanded view does NOT render a cargo capacity line',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostPanel(game));
        await tester.pumpAndSettle();

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
          reason:
              'R29: per mockup, non-home fleets do not render a cargo line '
              'in the expanded view',
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

    testWidgets('Composition Table row count matches ship-type count', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostPanel(game));
      await tester.pumpAndSettle();

      final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
      await tester.tap(homeTile);
      await tester.pumpAndSettle();

      final tableFinder = find.descendant(
        of: homeTile,
        matching: find.byType(Table),
      );
      final Table table = tester.widget<Table>(tableFinder);
      // Two ship types in the Home Fleet (carrack + frigate).
      expect(table.children.length, 2);
    });
  });

  group('FleetExpansionTile API surface', () {
    testWidgets('FleetExpansionTile is the canonical naval row widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hostPanel(game));
      await tester.pumpAndSettle();
      // 1 Home Fleet + 2 regular fleets in the deterministic fixture.
      expect(find.byType(FleetExpansionTile), findsNWidgets(3));
    });
  });

  // Issue #3514 AC-6 (naval card migration): fleet rows render the shared
  // UnitsEntityCard mockup `.fleet-row` bordered gradient card chrome (the
  // same migration delivered for military army rows), not the bare Material
  // ExpansionTile chrome. The deferred-from-#3532 dense-action overflow under
  // the card chrome is also pinned (no RenderFlex exception at the default
  // 480-dp host).
  group('Naval fleet card chrome (issue #3514 AC-6)', () {
    testWidgets(
      'Each fleet row is rendered inside a UnitsEntityCard with its dense '
      'action row hosted chrome-less (no double border) and no overflow',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostPanel(game));
        await tester.pumpAndSettle();

        // No RenderFlex overflow exception escapes when the dense Move /
        // Split / Locate cluster lays out under the card chrome (the gap
        // PR #3532 deferred for naval).
        expect(tester.takeException(), isNull);

        // One UnitsEntityCard per fleet row (Home + 2 regular fleets).
        expect(find.byType(UnitsEntityCard), findsNWidgets(3));

        // Each FleetExpansionTile hosts its card chrome.
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

        // The dense title action row is hosted chrome-less so the card border
        // is not double-painted (issue #3514 AC-6 — `chrome: false`).
        final actionRows = tester.widgetList<UnitsEntityActionRow>(
          find.byType(UnitsEntityActionRow),
        );
        expect(actionRows, isNotEmpty);
        for (final row in actionRows) {
          expect(
            row.chrome,
            isFalse,
            reason:
                'Naval fleet action rows must be hosted chrome-less inside '
                'the UnitsEntityCard (issue #3514 AC-6)',
          );
          expect(
            row.dense,
            isTrue,
            reason: 'Naval fleet action rows stay dense (R25)',
          );
        }
      },
    );
  });
}
