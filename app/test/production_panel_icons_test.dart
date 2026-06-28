// Tests for ResourceIcon / ResourceLabelInline / WorkerIcon used by the
// production panel. Split from production_panel_test.dart to keep each file
// within the repo non-comment line-size gate (SPEC/program/repo-lint.md).
// SPEC/ui/production-panel.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  group('ResourceIcon', () {
    testWidgets('ResourceIcon displays for known commodities', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ResourceIcon(commodityId: 'grain', size: 16),
                ResourceIcon(commodityId: 'timber', size: 16),
                ResourceIcon(commodityId: 'lumber', size: 16),
              ],
            ),
          ),
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(ResourceIcon), findsNWidgets(3));
    });

    testWidgets('ResourceIcon returns empty for unknown commodity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceIcon(commodityId: 'unknown_commodity', size: 16),
          ),
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(ResourceIcon), findsOneWidget);
    });

    testWidgets('ResourceLabelInline shows icon and label text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResourceLabelInline(commodityId: 'grain', label: 'grain'),
          ),
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(StrictAssetIcon), findsOneWidget);
      expect(find.text('grain'), findsOneWidget);
    });

    testWidgets(
      'ResourceLabelInline reserves space when commodity has no icon asset',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ResourceLabelInline(commodityId: 'no_ui_icon_commodity'),
            ),
          ),
        );
        await pumpSettleCapped(tester);

        expect(find.byType(StrictAssetIcon), findsNothing);
        expect(find.text('no_ui_icon_commodity'), findsOneWidget);
        expect(find.byType(ResourceIcon), findsOneWidget);
      },
    );
  });

  group('WorkerIcon', () {
    testWidgets('WorkerIcon displays for known worker types', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WorkerIcon(workerType: 'peasant', size: 16),
                WorkerIcon(workerType: 'apprentice', size: 16),
                WorkerIcon(workerType: 'journeyman', size: 16),
                WorkerIcon(workerType: 'master', size: 16),
              ],
            ),
          ),
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(WorkerIcon), findsNWidgets(4));
    });

    testWidgets('WorkerIcon returns empty for unknown type', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WorkerIcon(workerType: 'unknown', size: 16)),
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(WorkerIcon), findsOneWidget);
    });
  });
}
