// Widget tests pinning the CtDropdown picker selected-row visual contract
// (Refs #2859 R5c / S6) per SPEC/ui/pixel-art-ui-catalog.md § CtDropdown
// "picker selected-row highlight".
//
// The R5c contract states: inside the modal picker, when a row's value
// equals the trigger's current `value`, the outer row paints an
// `--accent-dim` background tint and a 1 dp `--accent` left-edge border;
// non-selected rows paint the same-width left edge transparent with no
// background tint so the layout stays stable across selection changes.
// The selected row is keyed by `CtDropdown.kCtDropdownPickerSelectedRowKey`.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  group('CtDropdown picker selected-row highlight (Refs #2859 R5c / S6)', () {
    Widget hostDropdown({
      required String? value,
      required ValueChanged<String?> onChanged,
      List<String> items = const ['England', 'France', 'Spain'],
    }) {
      return buildAppShell(
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              child: CtDropdown<String>(
                value: value,
                items: items,
                hint: 'Select nation',
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      );
    }

    Future<void> openPicker(WidgetTester tester) async {
      final triggerFinder = find.descendant(
        of: find.byType(CtDropdown<String>),
        matching: find.byType(InkWell),
      );
      // Fallback when the trigger surface is not an InkWell: tap by text.
      if (triggerFinder.evaluate().isEmpty) {
        await tester.tap(find.text('Select nation'));
      } else {
        await tester.tap(triggerFinder.first);
      }
      await tester.pumpAndSettle();
    }

    DecoratedBox findSelectedRowBox(WidgetTester tester) {
      final finder = find.byKey(CtDropdown.kCtDropdownPickerSelectedRowKey);
      expect(finder, findsOneWidget);
      return tester.widget<DecoratedBox>(finder);
    }

    testWidgets(
      'AC positive — selected row paints --accent-dim tint and 1 dp --accent '
      'left edge when value matches the row',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostDropdown(value: 'France', onChanged: (_) {}),
        );
        await tester.pumpAndSettle();

        await openPicker(tester);

        final selected = findSelectedRowBox(tester);
        final decoration = selected.decoration as BoxDecoration;
        expect(
          decoration.color,
          equals(EditorialMonoclePalette.accentDim),
          reason: 'Selected row background tint must resolve to --accent-dim.',
        );
        final border = decoration.border as Border;
        expect(
          border.left.color,
          equals(EditorialMonoclePalette.accent),
          reason: 'Selected row left-edge must resolve to --accent.',
        );
        expect(
          border.left.width,
          equals(kCtDropdownPickerSelectedLeftEdgeWidth),
          reason:
              'Selected row left-edge width must equal '
              'kCtDropdownPickerSelectedLeftEdgeWidth (1 dp) so unselected '
              'rows can share the same width and the layout stays stable.',
        );

        // Drain the open picker so the test does not leak a route.
        await tester.tap(find.text('France').last);
        await tester.pumpAndSettle();
      },
    );

    /// Returns the outer per-row DecoratedBoxes added by the picker
    /// itemBuilder — i.e. the DecoratedBoxes that are the **direct** child
    /// of each per-row [Padding] under the picker [ListView]. This avoids
    /// matching DecoratedBoxes painted by inner CtNinePatchButton chrome.
    List<DecoratedBox> findPickerRowOuterBoxes(WidgetTester tester) {
      final paddings = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Padding),
      );
      final List<DecoratedBox> rowBoxes = <DecoratedBox>[];
      for (final element in paddings.evaluate()) {
        final padding = element.widget as Padding;
        // itemBuilder wraps each row as: Padding(child: DecoratedBox(...)).
        // ListView itself can nest other Paddings — accept only those
        // whose direct child is a DecoratedBox.
        final child = padding.child;
        if (child is DecoratedBox) {
          rowBoxes.add(child);
        }
      }
      return rowBoxes;
    }

    testWidgets(
      'AC negative — non-selected rows paint a transparent same-width left '
      'edge and no background tint',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostDropdown(value: 'France', onChanged: (_) {}),
        );
        await tester.pumpAndSettle();

        await openPicker(tester);

        final rowBoxes = findPickerRowOuterBoxes(tester);
        expect(
          rowBoxes.length,
          equals(3),
          reason:
              'Picker should render exactly one outer DecoratedBox per '
              'option (3 items in this host).',
        );
        int nonSelectedSeen = 0;
        for (final box in rowBoxes) {
          if (box.key == CtDropdown.kCtDropdownPickerSelectedRowKey) {
            continue;
          }
          final decoration = box.decoration as BoxDecoration;
          expect(
            decoration.color,
            isNull,
            reason: 'Non-selected rows must not paint a background tint.',
          );
          final border = decoration.border as Border;
          expect(
            border.left.color,
            equals(Colors.transparent),
            reason:
                'Non-selected rows must paint a transparent left edge so '
                'the layout matches the selected row.',
          );
          expect(
            border.left.width,
            equals(kCtDropdownPickerSelectedLeftEdgeWidth),
            reason:
                'Non-selected rows must share the same left-edge width '
                'as the selected row so the layout never shifts.',
          );
          nonSelectedSeen++;
        }
        expect(
          nonSelectedSeen,
          equals(2),
          reason:
              'With three items (England/France/Spain) and value=France, '
              'two rows must report as non-selected.',
        );

        await tester.tap(find.text('France').last);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AC negative — no row is keyed selected when value is null',
      (WidgetTester tester) async {
        await tester.pumpWidget(hostDropdown(value: null, onChanged: (_) {}));
        await tester.pumpAndSettle();

        await openPicker(tester);

        expect(
          find.byKey(CtDropdown.kCtDropdownPickerSelectedRowKey),
          findsNothing,
          reason:
              'When the trigger has no value, no picker row should report '
              'as selected via the test key.',
        );

        // Drain the open picker.
        await tester.tap(find.text('England').last);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AC tap — tapping the selected row still emits the chosen value and '
      'closes the picker (selection chrome does not block the tap)',
      (WidgetTester tester) async {
        String? chosen;
        await tester.pumpWidget(
          hostDropdown(value: 'France', onChanged: (v) => chosen = v),
        );
        await tester.pumpAndSettle();

        await openPicker(tester);

        // Tap the selected row.
        final selectedFinder = find.byKey(
          CtDropdown.kCtDropdownPickerSelectedRowKey,
        );
        expect(selectedFinder, findsOneWidget);
        await tester.tap(selectedFinder);
        await tester.pumpAndSettle();

        expect(
          chosen,
          equals('France'),
          reason:
              'Tapping the selected row should still emit the row value '
              '— the DecoratedBox highlight wraps but does not absorb '
              'the inner CtNinePatchButton tap.',
        );

        // Picker closed: selected-row key is no longer in the tree.
        expect(
          find.byKey(CtDropdown.kCtDropdownPickerSelectedRowKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC stability — selected row left-edge width matches non-selected '
      'rows so the layout does not shift between selection changes',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostDropdown(value: 'France', onChanged: (_) {}),
        );
        await tester.pumpAndSettle();

        await openPicker(tester);

        final selectedBox = findSelectedRowBox(tester);
        final selectedBorder = (selectedBox.decoration as BoxDecoration).border
            as Border;

        for (final box in findPickerRowOuterBoxes(tester)) {
          if (box.key == CtDropdown.kCtDropdownPickerSelectedRowKey) {
            continue;
          }
          final border = (box.decoration as BoxDecoration).border as Border;
          expect(
            border.left.width,
            equals(selectedBorder.left.width),
            reason:
                'All picker rows must share the same left-edge width so '
                'switching the selected row never shifts the layout.',
          );
        }

        await tester.tap(find.text('France').last);
        await tester.pumpAndSettle();
      },
    );
  });
}
