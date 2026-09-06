// Tests for CtTabStrip. lib/widgets/ct_tab_strip.dart.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_tab_strip.dart';

import 'ct_tab_strip_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('CtTabStrip builds, switches tabs, and applies contentPadding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ctTabStripBasicHarness(
        tabLabels: const ['A', 'B'],
        tabViews: const [Text('Content A'), Text('Content B')],
      ),
    );
    expect(find.text('Content A'), findsOneWidget);
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(find.text('Content B'), findsOneWidget);

    await tester.pumpWidget(
      ctTabStripBasicHarness(
        tabLabels: const ['X'],
        tabViews: const [Text('Padded')],
        contentPadding: const EdgeInsets.all(16),
      ),
    );
    expect(find.text('Padded'), findsOneWidget);
  });

  group('CtTabStrip dark editorial-monocle palette (Refs #2865 S3)', () {
    testWidgets(
      'selected tab paints accent border, accentDim background, accentBright label',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ctTabStripPaletteHarness(labels: const ['First', 'Second']),
        );

        final BoxDecoration selected = ctTabStripDecoration(tester, 'First');
        expect(
          selected.color,
          EditorialMonoclePalette.accentDim
              .withValues(alpha: CtTabStrip.selectedBackgroundAlpha),
        );
        expect(selected.border?.top.color, EditorialMonoclePalette.accent);
        expect(selected.border?.top.width, CtTabStrip.tabBorderWidth);

        final Text label = tester.widget<Text>(find.text('First'));
        final DefaultTextStyle defaultStyle =
            DefaultTextStyle.of(tester.element(find.text('First')));
        expect(
          (label.style ?? defaultStyle.style).color,
          EditorialMonoclePalette.accentBright,
        );
      },
    );

    testWidgets(
      'unselected tab paints accentDim border, surface background, muted label',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ctTabStripPaletteHarness(labels: const ['First', 'Second']),
        );

        final BoxDecoration unselected = ctTabStripDecoration(tester, 'Second');
        expect(
          unselected.color,
          EditorialMonoclePalette.surface
              .withValues(alpha: CtTabStrip.unselectedBackgroundAlpha),
        );
        expect(unselected.border?.top.color, EditorialMonoclePalette.accentDim);
        expect(unselected.border?.top.width, CtTabStrip.tabBorderWidth);

        final DefaultTextStyle defaultStyle =
            DefaultTextStyle.of(tester.element(find.text('Second')));
        expect(defaultStyle.style.color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'negative: tabs avoid Material colorScheme primary/outline/surface defaults',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ctTabStripPaletteHarness(
            labels: const ['First', 'Second'],
            themeOverride: ThemeData.light(),
          ),
        );

        final BoxDecoration selected = ctTabStripDecoration(tester, 'First');
        final BoxDecoration unselected = ctTabStripDecoration(tester, 'Second');
        final ColorScheme materialScheme =
            Theme.of(tester.element(find.text('First'))).colorScheme;

        for (final BoxDecoration deco in <BoxDecoration>[selected, unselected]) {
          expect(
            deco.color == materialScheme.primary.withValues(alpha: 0.25) ||
                deco.color == materialScheme.surface.withValues(alpha: 0.5),
            isFalse,
          );
          expect(
            deco.border?.top.color == materialScheme.primary ||
                deco.border?.top.color == materialScheme.outline,
            isFalse,
          );
        }
      },
    );

    testWidgets(
      'selection swap: tapping the second tab swaps the selected/unselected palettes',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ctTabStripPaletteHarness(labels: const ['First', 'Second']),
        );

        await tester.tap(find.text('Second'));
        await tester.pump();

        final BoxDecoration newlySelected = ctTabStripDecoration(
          tester,
          'Second',
        );
        final BoxDecoration newlyUnselected = ctTabStripDecoration(
          tester,
          'First',
        );

        expect(
          newlySelected.border?.top.color,
          EditorialMonoclePalette.accent,
        );
        expect(
          newlySelected.color,
          EditorialMonoclePalette.accentDim
              .withValues(alpha: CtTabStrip.selectedBackgroundAlpha),
        );
        expect(
          newlyUnselected.border?.top.color,
          EditorialMonoclePalette.accentDim,
        );
        expect(
          newlyUnselected.color,
          EditorialMonoclePalette.surface
              .withValues(alpha: CtTabStrip.unselectedBackgroundAlpha),
        );
      },
    );
  });

  testWidgets(
    'lazyTabBodies defers off-tab body until first selection (Refs #4175 Slice E)',
    (WidgetTester tester) async {
      var secondaryBuilds = 0;
      await tester.pumpWidget(
        ctTabStripBasicHarness(
          tabLabels: const ['First', 'Second'],
          tabViews: [
            const Text('View 1'),
            Builder(
              builder: (context) {
                secondaryBuilds++;
                return const Text('View 2');
              },
            ),
          ],
          lazyTabBodies: true,
        ),
      );

      expect(secondaryBuilds, 0);
      expect(find.text('View 2'), findsNothing);

      await tester.tap(find.text('Second'));
      await tester.pump();

      expect(secondaryBuilds, greaterThan(0));
      expect(find.text('View 2'), findsOneWidget);
    },
  );

  testWidgets(
    'onTabIndexChanged fires when a different tab is selected',
    (WidgetTester tester) async {
      var lastIndex = -1;
      await tester.pumpWidget(
        ctTabStripBasicHarness(
          tabLabels: const ['First', 'Second'],
          tabViews: const [
            Text('View 1'),
            Text('View 2'),
          ],
          onTabIndexChanged: (index) => lastIndex = index,
        ),
      );

      await tester.tap(find.text('Second'));
      await tester.pump();

      expect(lastIndex, 1);
    },
  );
}
