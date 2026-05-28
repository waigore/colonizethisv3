import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/location_section_header.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/region_section_header.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_region_label.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';

void main() {
  suppressLogsForTests();

  group('unitsPanelRegionLabel', () {
    test('maps known region ids', () {
      expect(unitsPanelRegionLabel('oldWorld'), 'Old World');
      expect(unitsPanelRegionLabel('newWorld'), 'New World');
    });

    test('passes through unknown ids', () {
      expect(unitsPanelRegionLabel('custom'), 'custom');
    });
  });

  group('RegionSectionHeader', () {
    testWidgets('shows label text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RegionSectionHeader(label: 'Old World')),
        ),
      );
      expect(find.text('Old World'), findsOneWidget);
    });
  });

  group('LocationSectionHeader', () {
    testWidgets('shows label and region', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationSectionHeader(
              label: 'Province A',
              regionLabel: 'New World',
            ),
          ),
        ),
      );
      expect(find.text('Province A — New World'), findsOneWidget);
    });
  });

  group('UnitsPanelShell', () {
    testWidgets('shows title and empty message when no content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnitsPanelShell(
              title: 'Test Panel',
              hasContent: false,
              listChildren: [],
              emptyMessage: 'Nothing here',
            ),
          ),
        ),
      );
      expect(find.text('Test Panel'), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('shows list children when hasContent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitsPanelShell(
              title: 'With rows',
              hasContent: true,
              listChildren: [
                const ListTile(title: Text('Row one')),
                const ListTile(title: Text('Row two')),
              ],
              emptyMessage: 'ignored',
            ),
          ),
        ),
      );
      expect(find.text('Row one'), findsOneWidget);
      expect(find.text('Row two'), findsOneWidget);
      expect(find.text('ignored'), findsNothing);
    });

    testWidgets('forwards trailing actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitsPanelShell(
              title: 'T',
              actions: [
                TextButton(onPressed: () {}, child: const Text('Action')),
              ],
              hasContent: false,
              listChildren: const [],
              emptyMessage: 'E',
            ),
          ),
        ),
      );
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets(
      'renders title via CtTopBar (showBackButton: false; #2866 S1 chrome)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UnitsPanelShell(
                title: 'Civilian Units',
                hasContent: false,
                listChildren: [],
                emptyMessage: 'No civilian units',
              ),
            ),
          ),
        );

        final Finder topBarFinder = find.byType(CtTopBar);
        expect(topBarFinder, findsOneWidget);
        final CtTopBar topBar = tester.widget(topBarFinder);
        expect(topBar.title, 'Civilian Units');
        expect(topBar.showBackButton, isFalse);
        expect(topBar.trailing, isNull);

        // showBackButton: false MUST suppress the chevron + label so the
        // bottom-sheet panel does not surface a navigator back affordance.
        expect(find.byType(CtBackButton), findsNothing);

        // The chrome SizedBox sits inside the DecoratedBox surface and is
        // pinned to CtTopBar.height (36 px per #2859 R11).
        final Finder topBarSizedBoxFinder = find.descendant(
          of: topBarFinder,
          matching: find.byWidgetPredicate(
            (Widget w) => w is SizedBox && w.height == CtTopBar.height,
          ),
        );
        expect(topBarSizedBoxFinder, findsOneWidget);

        // Title text colour resolves to the canonical --accent token.
        final Text titleText = tester.widget(
          find.descendant(of: topBarFinder, matching: find.text('Civilian Units')),
        );
        expect(titleText.style?.color, EditorialMonoclePalette.accent);
      },
    );

    testWidgets(
      'wraps multiple trailing actions in a Row inside CtTopBar trailing slot',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UnitsPanelShell(
                title: 'Civilian Units',
                actions: [
                  TextButton(onPressed: () {}, child: const Text('Tile')),
                  TextButton(onPressed: () {}, child: const Text('Train')),
                ],
                hasContent: false,
                listChildren: const [],
                emptyMessage: 'E',
              ),
            ),
          ),
        );

        final CtTopBar topBar = tester.widget(find.byType(CtTopBar));
        expect(topBar.trailing, isA<Row>());
        final Row trailingRow = topBar.trailing! as Row;
        // 2 actions + 1 spacer between them => 3 children.
        expect(trailingRow.mainAxisSize, MainAxisSize.min);
        expect(trailingRow.children.length, 3);
        final Widget spacer = trailingRow.children[1];
        expect(spacer, isA<SizedBox>());
        expect((spacer as SizedBox).width, isNonZero);

        // Both action labels remain in the tree.
        expect(find.text('Tile'), findsOneWidget);
        expect(find.text('Train'), findsOneWidget);
      },
    );

    testWidgets(
      'passes a single trailing action through unchanged (no Row wrapper)',
      (WidgetTester tester) async {
        final TextButton soloAction = TextButton(
          onPressed: () {},
          child: const Text('Train'),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UnitsPanelShell(
                title: 'Civilian Units',
                actions: [soloAction],
                hasContent: false,
                listChildren: const [],
                emptyMessage: 'E',
              ),
            ),
          ),
        );

        final CtTopBar topBar = tester.widget(find.byType(CtTopBar));
        expect(topBar.trailing, same(soloAction));
      },
    );

    testWidgets(
      'renders empty message in italic --muted (#2866 S1 dark-theme palette)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UnitsPanelShell(
                title: 'Civilian Units',
                hasContent: false,
                listChildren: [],
                emptyMessage: 'No civilian units',
              ),
            ),
          ),
        );

        final Text emptyText = tester.widget(find.text('No civilian units'));
        expect(emptyText.style?.color, EditorialMonoclePalette.muted);
        expect(emptyText.style?.fontStyle, FontStyle.italic);
      },
    );

    testWidgets(
      'omits the empty message when hasContent is true',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UnitsPanelShell(
                title: 'Civilian Units',
                hasContent: true,
                listChildren: const [
                  ListTile(title: Text('Row one')),
                ],
                emptyMessage: 'No civilian units',
              ),
            ),
          ),
        );

        expect(find.text('Row one'), findsOneWidget);
        expect(find.text('No civilian units'), findsNothing);
      },
    );
  });

  group('UnitsEntityActionRow', () {
    testWidgets('renders details with text action label on wide width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: UnitsEntityActionRow(
                details: const Text('Left details'),
                actions: [
                  UnitsEntityAction(
                    tooltip: 'Move',
                    icon: Icons.route,
                    label: 'Move',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Left details'), findsOneWidget);
      expect(find.text('Move'), findsOneWidget);
    });

    testWidgets('switches action button to icon-only on narrow width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              child: UnitsEntityActionRow(
                details: const Text('Left details'),
                actions: [
                  UnitsEntityAction(
                    tooltip: 'Move',
                    icon: Icons.route,
                    label: 'Move',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.route), findsOneWidget);
      expect(find.text('Move'), findsNothing);
    });
  });
}
