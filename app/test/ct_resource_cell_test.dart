import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_resource_cell_test_helpers.dart';

void main() {
  suppressLogsForTests();

  group('CtResourceCell delta colour + prefix rules (R10)', () {
    testWidgets('positive delta renders +N in --success', (tester) async {
      await pumpCtResourceCell(
        tester,
        CtResourceCell(
          iconBuilder: ctResourceCellTinyIcon,
          name: 'Grain',
          quantity: 1240,
          delta: 12,
        ),
      );
      expect(find.text('+12'), findsOneWidget);
      final Text delta = tester.widget<Text>(find.text('+12'));
      expect(delta.style?.color, EditorialMonoclePalette.success);
    });

    testWidgets('negative delta renders -N in --danger', (tester) async {
      await pumpCtResourceCell(
        tester,
        CtResourceCell(
          iconBuilder: ctResourceCellTinyIcon,
          name: 'Timber',
          quantity: 920,
          delta: -40,
        ),
      );
      expect(find.text('-40'), findsOneWidget);
      final Text delta = tester.widget<Text>(find.text('-40'));
      expect(delta.style?.color, EditorialMonoclePalette.danger);
    });

    testWidgets('zero delta renders 0 in --muted with no + prefix', (tester) async {
      await pumpCtResourceCell(
        tester,
        CtResourceCell(
          iconBuilder: ctResourceCellTinyIcon,
          name: 'Meat',
          quantity: 870,
          delta: 0,
        ),
      );
      expect(find.text('0'), findsOneWidget);
      expect(find.text('+0'), findsNothing);
      final Text delta = tester.widget<Text>(find.text('0'));
      expect(delta.style?.color, EditorialMonoclePalette.muted);
    });

    testWidgets('null delta is not laid out (negative path)', (tester) async {
      await pumpCtResourceCell(
        tester,
        CtResourceCell(
          iconBuilder: ctResourceCellTinyIcon,
          name: 'Coal',
          quantity: 170,
          // ignore: avoid_redundant_argument_values
          delta: null,
        ),
      );
      final Iterable<Text> texts = tester
          .widgetList<Text>(find.descendant(
            of: find.byType(CtResourceCell),
            matching: find.byType(Text),
          ));
      expect(texts, hasLength(2));
      expect(texts.map((t) => t.data), containsAll(<String>['Coal', '170']));
    });
  });

  group('CtResourceCell formatters (R10)', () {
    test('formattedDeltaText handles all sign branches', () {
      expect(CtResourceCell.formattedDeltaText(null), isNull);
      expect(CtResourceCell.formattedDeltaText(0), '0');
      expect(CtResourceCell.formattedDeltaText(7), '+7');
      expect(CtResourceCell.formattedDeltaText(-7), '-7');
    });

    test('deltaColor returns the token for each sign branch', () {
      expect(CtResourceCell.deltaColor(null), isNull);
      expect(CtResourceCell.deltaColor(0), EditorialMonoclePalette.muted);
      expect(CtResourceCell.deltaColor(7), EditorialMonoclePalette.success);
      expect(CtResourceCell.deltaColor(-7), EditorialMonoclePalette.danger);
    });

    test('formatQuantity inserts thousands separators (positive)', () {
      expect(CtResourceCell.formatQuantity(0), '0');
      expect(CtResourceCell.formatQuantity(999), '999');
      expect(CtResourceCell.formatQuantity(1240), '1,240');
      expect(CtResourceCell.formatQuantity(1234567), '1,234,567');
    });

    test('formatQuantity keeps the leading minus for negatives', () {
      expect(CtResourceCell.formatQuantity(-1240), '-1,240');
      expect(CtResourceCell.formatQuantity(-99), '-99');
    });
  });

  group('CtResourceCell layout (mockup parity)', () {
    testWidgets('renders icon + name + quantity in the documented order', (
      tester,
    ) async {
      await pumpCtResourceCell(
        tester,
        CtResourceCell(
          iconBuilder: ctResourceCellTinyIcon,
          name: 'Grain',
          quantity: 1240,
        ),
      );
      expect(find.byKey(const Key('test-icon')), findsOneWidget);
      expect(find.text('Grain'), findsOneWidget);
      expect(find.text('1,240'), findsOneWidget);

      final double iconX =
          tester.getTopLeft(find.byKey(const Key('test-icon'))).dx;
      final double nameX = tester.getTopLeft(find.text('Grain')).dx;
      final double qtyX = tester.getTopLeft(find.text('1,240')).dx;
      expect(iconX, lessThan(nameX));
      expect(nameX, lessThan(qtyX));
    });

    testWidgets(
      'quantity always uses --accent-dim regardless of delta sign',
      (tester) async {
        await pumpCtResourceCell(
          tester,
          CtResourceCell(
            iconBuilder: ctResourceCellTinyIcon,
            name: 'Iron',
            quantity: 430,
            delta: -20,
          ),
        );
        final Text qty = tester.widget<Text>(find.text('430'));
        expect(qty.style?.color, EditorialMonoclePalette.accentDim);
      },
    );

    testWidgets('name styles default to --fg body text', (tester) async {
      await pumpCtResourceCell(
        tester,
        CtResourceCell(
          iconBuilder: ctResourceCellTinyIcon,
          name: 'Wool',
          quantity: 380,
        ),
      );
      final Text name = tester.widget<Text>(find.text('Wool'));
      expect(name.style?.color, EditorialMonoclePalette.fg);
    });

    testWidgets('name truncates with ellipsis under tight width', (tester) async {
      await pumpCtResourceCellFixedWidth(
        tester,
        CtResourceCell(
          iconBuilder: ctResourceCellTinyIcon,
          name: 'Refined Sugar — Long Label',
          quantity: 50,
        ),
        width: 80,
      );
      final Text name = tester.widget<Text>(
        find.descendant(
          of: find.byType(CtResourceCell),
          matching: find.textContaining('Refined Sugar'),
        ),
      );
      expect(name.overflow, TextOverflow.ellipsis);
      expect(name.maxLines, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('CtResourceCell compact typography (Refs #2862 S9 / C9–C10)', () {
    testWidgets(
      'name + quantity render at the compact ~10 px mockup size; delta at ~9 px',
      (tester) async {
        await pumpCtResourceCellFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: ctResourceCellTinyIcon,
            name: 'Grain',
            quantity: 1240,
            delta: 45,
          ),
          width: 240,
        );

        final Text name = tester.widget<Text>(find.text('Grain'));
        final Text qty = tester.widget<Text>(find.text('1,240'));
        final Text delta = tester.widget<Text>(find.text('+45'));
        expect(name.style?.fontSize, CtResourceCell.nameFontSize);
        expect(qty.style?.fontSize, CtResourceCell.quantityFontSize);
        expect(delta.style?.fontSize, CtResourceCell.deltaFontSize);
        expect(
          CtResourceCell.deltaFontSize,
          lessThan(CtResourceCell.quantityFontSize),
        );
      },
    );

    testWidgets(
      'canonical commodity names render in full (no ellipsis clipping) at a '
      'representative grid cell width, even with a delta present',
      (tester) async {
        for (final name in const <String>[
          'Cast Iron',
          'Sugar Cane',
          'Refined Sugar',
        ]) {
          await pumpCtResourceCellFixedWidth(
            tester,
            CtResourceCell(
              iconBuilder: ctResourceCellTinyIcon,
              name: name,
              quantity: 430,
              delta: -20,
            ),
            width: 320,
          );

          expect(
            ctResourceCellParagraphFor(tester, name).didExceedMaxLines,
            isFalse,
            reason: '"$name" must render in full without ellipsis clipping '
                'per #2862 C9.',
          );
        }
      },
    );

    testWidgets(
      'name stays fully visible with vs without a delta (C10)',
      (tester) async {
        const name = 'Iron';
        const width = 220.0;

        await pumpCtResourceCellFixedWidth(
          tester,
          CtResourceCell(iconBuilder: ctResourceCellTinyIcon, name: name, quantity: 430),
          width: width,
        );
        final noDeltaExceeded =
            ctResourceCellParagraphFor(tester, name).didExceedMaxLines;

        await pumpCtResourceCellFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: ctResourceCellTinyIcon,
            name: name,
            quantity: 430,
            delta: -20,
          ),
          width: width,
        );
        final withDeltaExceeded =
            ctResourceCellParagraphFor(tester, name).didExceedMaxLines;

        expect(noDeltaExceeded, isFalse);
        expect(withDeltaExceeded, isFalse);
      },
    );
  });
}
