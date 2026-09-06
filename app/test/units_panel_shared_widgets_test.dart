import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/location_section_header.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/region_section_header.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/region_labels.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';

import 'units_panel_shared_widgets_test_support.dart';

void main() {
  suppressLogsForTests();

  group('regionDisplayLabel', () {
    test('maps known region ids', () {
      expect(regionDisplayLabel('oldWorld'), 'Old World');
      expect(regionDisplayLabel('newWorld'), 'New World');
    });

    test('passes through unknown ids', () {
      expect(regionDisplayLabel('custom'), 'custom');
    });
  });

  group('RegionSectionHeader', () {
    testWidgets('renders label via CtSectionLabel (#2866)', (
      WidgetTester tester,
    ) async {
      await pumpUnitsSharedBody(
        tester,
        const RegionSectionHeader(label: 'Old World'),
      );
      expect(find.byType(CtSectionLabel), findsOneWidget);
      expect(find.text('OLD WORLD'), findsOneWidget);
    });

    testWidgets(
      'leftBar variant renders a left accent-dim bar without CtSectionLabel '
      '(Refs #3514)',
      (WidgetTester tester) async {
        await pumpUnitsSharedBody(
          tester,
          const RegionSectionHeader(
            label: 'New World',
            variant: RegionHeaderVariant.leftBar,
          ),
        );

        expect(find.text('NEW WORLD'), findsOneWidget);
        expect(find.byType(CtSectionLabel), findsNothing);
        expectRegionHeaderLeftBar(tester);
      },
    );

    testWidgets(
      'bottomBorderMuted variant renders a 1dp --border bottom border '
      'without CtSectionLabel (Refs #3514)',
      (WidgetTester tester) async {
        await pumpUnitsSharedBody(
          tester,
          const RegionSectionHeader(
            label: 'Old World',
            variant: RegionHeaderVariant.bottomBorderMuted,
          ),
        );

        expect(find.text('OLD WORLD'), findsOneWidget);
        expect(find.byType(CtSectionLabel), findsNothing);

        final Text label = tester.widget<Text>(find.text('OLD WORLD'));
        expect(label.style?.color, EditorialMonoclePalette.muted);
        expect(label.style?.fontWeight, FontWeight.w600);

        expectRegionHeaderBottomBorder(tester);
      },
    );
  });

  group('LocationSectionHeader', () {
    testWidgets('shows label and region', (WidgetTester tester) async {
      await pumpUnitsSharedBody(
        tester,
        const LocationSectionHeader(
          label: 'Province A',
          regionLabel: 'New World',
        ),
      );
      expect(find.text('Province A — New World'), findsOneWidget);
    });

    testWidgets('renders semi-bold fg-at-0.8 chrome per mockup .province-label '
        '(Refs #3514)', (WidgetTester tester) async {
      await pumpUnitsSharedBody(
        tester,
        const LocationSectionHeader(
          label: 'Province A',
          regionLabel: 'New World',
        ),
      );

      final Text text = tester.widget<Text>(
        find.text('Province A — New World'),
      );
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(
        text.style?.color,
        EditorialMonoclePalette.fg.withValues(
          alpha: LocationSectionHeader.labelOpacity,
        ),
      );
    });
  });
}
