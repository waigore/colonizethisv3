// Tests for CtTabStrip. lib/widgets/ct_tab_strip.dart.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_tab_strip.dart';

/// Locates the inner [Container] widget that paints the tab chrome for
/// the tab labelled [label]. Each tab in the strip is `Padding > Container`
/// — `find.text(label)` returns the inner [Text]; we walk back up to the
/// nearest enclosing [Container].
Container _tabContainerForLabel(WidgetTester tester, String label) {
  final Finder labelFinder = find.text(label);
  final Element labelElement = tester.element(labelFinder);
  Container? container;
  labelElement.visitAncestorElements((Element ancestor) {
    final Widget widget = ancestor.widget;
    if (widget is Container) {
      container = widget;
      return false;
    }
    return true;
  });
  if (container == null) {
    throw StateError('No Container ancestor for tab label "$label"');
  }
  return container!;
}

BoxDecoration _tabDecoration(WidgetTester tester, String label) {
  final Container container = _tabContainerForLabel(tester, label);
  final Decoration? decoration = container.decoration;
  if (decoration is! BoxDecoration) {
    throw StateError(
      'Tab container for "$label" decoration is not BoxDecoration (got '
      '${decoration.runtimeType})',
    );
  }
  return decoration;
}

void main() {
  suppressLogsForTests();

  testWidgets('CtTabStrip builds and shows first tab label and content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: CtTabStrip(
              tabLabels: const ['A', 'B', 'C'],
              tabViews: const [
                Text('Content A'),
                Text('Content B'),
                Text('Content C'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('Content A'), findsOneWidget);
  });

  testWidgets('CtTabStrip tap switches to second tab content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: CtTabStrip(
              tabLabels: const ['First', 'Second'],
              tabViews: const [
                Text('View 1'),
                Text('View 2'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('View 1'), findsOneWidget);

    await tester.tap(find.text('Second'));
    await tester.pump();

    expect(find.text('View 2'), findsOneWidget);
  });

  testWidgets('CtTabStrip applies contentPadding', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: CtTabStrip(
              tabLabels: const ['X'],
              tabViews: const [Text('Padded')],
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Padded'), findsOneWidget);
  });

  group('CtTabStrip dark editorial-monocle palette (Refs #2865 S3)', () {
    Widget harness({required List<String> labels}) {
      final List<Widget> views = labels
          .map((String l) => Text('Body $l', key: ValueKey<String>('body-$l')))
          .toList(growable: false);
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: CtTabStrip(tabLabels: labels, tabViews: views),
          ),
        ),
      );
    }

    testWidgets(
      'selected tab paints accent border, accentDim background, accentBright label',
      (WidgetTester tester) async {
        await tester.pumpWidget(harness(labels: const ['First', 'Second']));

        final BoxDecoration selected = _tabDecoration(tester, 'First');
        expect(
          selected.color,
          EditorialMonoclePalette.accentDim
              .withValues(alpha: CtTabStrip.selectedBackgroundAlpha),
          reason: 'Selected tab background must resolve to '
              '--accent-dim at ${CtTabStrip.selectedBackgroundAlpha} alpha.',
        );
        expect(
          selected.border?.top.color,
          EditorialMonoclePalette.accent,
          reason: 'Selected tab border colour must resolve to --accent.',
        );
        expect(
          selected.border?.top.width,
          CtTabStrip.tabBorderWidth,
          reason: 'Selected tab border width must be 1 px.',
        );

        final Text label = tester.widget<Text>(find.text('First'));
        final DefaultTextStyle defaultStyle =
            DefaultTextStyle.of(tester.element(find.text('First')));
        expect(
          (label.style ?? defaultStyle.style).color,
          EditorialMonoclePalette.accentBright,
          reason: 'Selected tab label colour must resolve to --accent-bright.',
        );
      },
    );

    testWidgets(
      'unselected tab paints accentDim border, surface background, muted label',
      (WidgetTester tester) async {
        await tester.pumpWidget(harness(labels: const ['First', 'Second']));

        final BoxDecoration unselected = _tabDecoration(tester, 'Second');
        expect(
          unselected.color,
          EditorialMonoclePalette.surface
              .withValues(alpha: CtTabStrip.unselectedBackgroundAlpha),
          reason: 'Unselected tab background must resolve to '
              '--surface at ${CtTabStrip.unselectedBackgroundAlpha} alpha.',
        );
        expect(
          unselected.border?.top.color,
          EditorialMonoclePalette.accentDim,
          reason: 'Unselected tab border colour must resolve to --accent-dim.',
        );
        expect(
          unselected.border?.top.width,
          CtTabStrip.tabBorderWidth,
          reason: 'Unselected tab border width must be 1 px.',
        );

        final DefaultTextStyle defaultStyle =
            DefaultTextStyle.of(tester.element(find.text('Second')));
        expect(
          defaultStyle.style.color,
          EditorialMonoclePalette.muted,
          reason: 'Unselected tab label colour must resolve to --muted.',
        );
      },
    );

    testWidgets(
      'negative: tabs avoid Material colorScheme primary/outline/surface defaults',
      (WidgetTester tester) async {
        await tester.pumpWidget(harness(labels: const ['First', 'Second']));

        final BoxDecoration selected = _tabDecoration(tester, 'First');
        final BoxDecoration unselected = _tabDecoration(tester, 'Second');
        final ColorScheme materialScheme =
            Theme.of(tester.element(find.text('First'))).colorScheme;

        for (final BoxDecoration deco in <BoxDecoration>[selected, unselected]) {
          expect(
            deco.color == materialScheme.primary.withValues(alpha: 0.25) ||
                deco.color == materialScheme.surface.withValues(alpha: 0.5),
            isFalse,
            reason:
                'Tab background must not resolve to a Material colorScheme '
                'lookup; expected EditorialMonoclePalette tokens.',
          );
          expect(
            deco.border?.top.color == materialScheme.primary ||
                deco.border?.top.color == materialScheme.outline,
            isFalse,
            reason: 'Tab border must not resolve to a Material colorScheme '
                'lookup; expected EditorialMonoclePalette tokens.',
          );
        }
      },
    );

    testWidgets(
      'selection swap: tapping the second tab swaps the selected/unselected palettes',
      (WidgetTester tester) async {
        await tester.pumpWidget(harness(labels: const ['First', 'Second']));

        await tester.tap(find.text('Second'));
        await tester.pump();

        final BoxDecoration newlySelected = _tabDecoration(tester, 'Second');
        final BoxDecoration newlyUnselected = _tabDecoration(tester, 'First');

        expect(
          newlySelected.border?.top.color,
          EditorialMonoclePalette.accent,
          reason: 'After tap, the second tab must paint the selected '
              '--accent border colour.',
        );
        expect(
          newlySelected.color,
          EditorialMonoclePalette.accentDim
              .withValues(alpha: CtTabStrip.selectedBackgroundAlpha),
          reason: 'After tap, the second tab must paint the selected '
              '--accent-dim background.',
        );

        expect(
          newlyUnselected.border?.top.color,
          EditorialMonoclePalette.accentDim,
          reason: 'After tap, the previously selected first tab must '
              'paint the unselected --accent-dim border colour.',
        );
        expect(
          newlyUnselected.color,
          EditorialMonoclePalette.surface
              .withValues(alpha: CtTabStrip.unselectedBackgroundAlpha),
          reason: 'After tap, the previously selected first tab must '
              'paint the unselected --surface background.',
        );
      },
    );
  });
}
