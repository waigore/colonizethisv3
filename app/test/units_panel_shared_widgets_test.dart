import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/shared/location_section_header.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/region_section_header.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_region_label.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';

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
