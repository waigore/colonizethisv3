import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_dropdown_picker_selected_state_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtDropdown picker selected-row highlight (Refs #2859 R5c / S6)', () {
    testWidgets(
      'AC positive — selected row paints --accent-dim tint and 1 dp --accent '
      'left edge when value matches the row',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ctDropdownPickerHost(value: 'France', onChanged: (_) {}),
        );
        await tester.pumpAndSettle();
        await openCtDropdownPicker(tester);

        final selected = ctDropdownSelectedRowBox(tester);
        final decoration = selected.decoration as BoxDecoration;
        expect(decoration.color, equals(EditorialMonoclePalette.accentDim));
        final border = decoration.border as Border;
        expect(border.left.color, equals(EditorialMonoclePalette.accent));
        expect(
          border.left.width,
          equals(kCtDropdownPickerSelectedLeftEdgeWidth),
        );

        await tester.tap(find.text('France').last);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AC negative — non-selected rows paint a transparent same-width left '
      'edge and no background tint',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ctDropdownPickerHost(value: 'France', onChanged: (_) {}),
        );
        await tester.pumpAndSettle();
        await openCtDropdownPicker(tester);

        final rowBoxes = ctDropdownPickerRowOuterBoxes(tester);
        expect(rowBoxes.length, equals(3));
        var nonSelectedSeen = 0;
        for (final box in rowBoxes) {
          if (box.key == CtDropdown.kCtDropdownPickerSelectedRowKey) {
            continue;
          }
          final decoration = box.decoration as BoxDecoration;
          expect(decoration.color, isNull);
          final border = decoration.border as Border;
          expect(border.left.color, equals(Colors.transparent));
          expect(
            border.left.width,
            equals(kCtDropdownPickerSelectedLeftEdgeWidth),
          );
          nonSelectedSeen++;
        }
        expect(nonSelectedSeen, equals(2));

        await tester.tap(find.text('France').last);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AC negative — no row is keyed selected when value is null',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ctDropdownPickerHost(value: null, onChanged: (_) {}),
        );
        await tester.pumpAndSettle();
        await openCtDropdownPicker(tester);

        expect(
          find.byKey(CtDropdown.kCtDropdownPickerSelectedRowKey),
          findsNothing,
        );

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
          ctDropdownPickerHost(value: 'France', onChanged: (v) => chosen = v),
        );
        await tester.pumpAndSettle();
        await openCtDropdownPicker(tester);

        final selectedFinder = find.byKey(
          CtDropdown.kCtDropdownPickerSelectedRowKey,
        );
        expect(selectedFinder, findsOneWidget);
        await tester.tap(selectedFinder);
        await tester.pumpAndSettle();

        expect(chosen, equals('France'));
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
          ctDropdownPickerHost(value: 'France', onChanged: (_) {}),
        );
        await tester.pumpAndSettle();
        await openCtDropdownPicker(tester);

        final selectedBorder =
            (ctDropdownSelectedRowBox(tester).decoration as BoxDecoration)
                .border as Border;

        for (final box in ctDropdownPickerRowOuterBoxes(tester)) {
          if (box.key == CtDropdown.kCtDropdownPickerSelectedRowKey) {
            continue;
          }
          final border = (box.decoration as BoxDecoration).border as Border;
          expect(border.left.width, equals(selectedBorder.left.width));
        }

        await tester.tap(find.text('France').last);
        await tester.pumpAndSettle();
      },
    );
  });
}
