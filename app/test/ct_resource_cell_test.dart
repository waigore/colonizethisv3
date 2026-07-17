import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpCell(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: 240, child: child),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Widget tinyIcon(BuildContext context) => const SizedBox(
        key: Key('test-icon'),
        width: 20,
        height: 20,
      );

  group('CtResourceCell delta colour + prefix rules (R10)', () {
    testWidgets('positive delta renders +N in --success', (tester) async {
      await pumpCell(
        tester,
        CtResourceCell(
          iconBuilder: tinyIcon,
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
      await pumpCell(
        tester,
        CtResourceCell(
          iconBuilder: tinyIcon,
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
      await pumpCell(
        tester,
        CtResourceCell(
          iconBuilder: tinyIcon,
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
      await pumpCell(
        tester,
        CtResourceCell(
          iconBuilder: tinyIcon,
          name: 'Coal',
          quantity: 170,
          // ignore: avoid_redundant_argument_values
          delta: null,
        ),
      );
      // 170 is the quantity, not a delta. Verify that no extra Text widget is
      // present beyond the name and quantity.
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
      await pumpCell(
        tester,
        CtResourceCell(
          iconBuilder: tinyIcon,
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
        await pumpCell(
          tester,
          CtResourceCell(
            iconBuilder: tinyIcon,
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
      await pumpCell(
        tester,
        CtResourceCell(
          iconBuilder: tinyIcon,
          name: 'Wool',
          quantity: 380,
        ),
      );
      final Text name = tester.widget<Text>(find.text('Wool'));
      expect(name.style?.color, EditorialMonoclePalette.fg);
    });

    testWidgets('name truncates with ellipsis under tight width', (tester) async {
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 80,
                child: CtResourceCell(
                  iconBuilder: tinyIcon,
                  name: 'Refined Sugar — Long Label',
                  quantity: 50,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
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
    Future<void> pumpFixedWidth(
      WidgetTester tester,
      Widget cell, {
      required double width,
    }) async {
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: cell),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    RenderParagraph paragraphFor(WidgetTester tester, String text) {
      return tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(CtResourceCell),
          matching: find.text(text),
        ),
      );
    }

    testWidgets(
      'name + quantity render at the compact ~10 px mockup size; delta at ~9 px',
      (tester) async {
        await pumpFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: tinyIcon,
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
        // The delta is one step smaller than the quantity per the mockup.
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
          await pumpFixedWidth(
            tester,
            CtResourceCell(
              iconBuilder: tinyIcon,
              name: name,
              quantity: 430,
              delta: -20,
            ),
            // Wide enough that the compact name + intrinsic qty/delta cluster
            // all fit; the legacy flex-share trailing cluster would have
            // squeezed the name into ellipsis at this width.
            width: 320,
          );

          expect(
            paragraphFor(tester, name).didExceedMaxLines,
            isFalse,
            reason: '"$name" must render in full without ellipsis clipping '
                'per #2862 C9.',
          );
        }
      },
    );

    testWidgets(
      'name keeps the same width and visibility with vs without a delta '
      '(delta-stable name column, C10)',
      (tester) async {
        const name = 'Iron';
        const width = 220.0;

        await pumpFixedWidth(
          tester,
          CtResourceCell(iconBuilder: tinyIcon, name: name, quantity: 430),
          width: width,
        );
        final noDeltaParagraph = paragraphFor(tester, name);
        final noDeltaExceeded = noDeltaParagraph.didExceedMaxLines;
        final noDeltaGlyphWidth = noDeltaParagraph.getMaxIntrinsicWidth(
          double.infinity,
        );

        await pumpFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: tinyIcon,
            name: name,
            quantity: 430,
            delta: -20,
          ),
          width: width,
        );
        final withDeltaParagraph = paragraphFor(tester, name);
        final withDeltaExceeded = withDeltaParagraph.didExceedMaxLines;
        final withDeltaGlyphWidth = withDeltaParagraph.getMaxIntrinsicWidth(
          double.infinity,
        );

        // The name is fully visible (no ellipsis) whether or not a delta is
        // present, and the laid-out glyph width is identical — adding a delta
        // does not push the name into ellipsis (C10).
        expect(noDeltaExceeded, isFalse);
        expect(withDeltaExceeded, isFalse);
        expect(
          withDeltaGlyphWidth,
          noDeltaGlyphWidth,
          reason: 'Adding a +N / -N delta must not shrink the rendered name '
              'per #2862 C10.',
        );
      },
    );
  });

  group('CtResourceCell panel-wide amount alignment (#3999)', () {
    /// Representative Available 3-column cell width (~800 dp wide Production
    /// with side-by-side subpanels → ~120–130 dp slots).
    const double gridCellWidth = 120;

    Future<void> pumpFixedWidth(
      WidgetTester tester,
      Widget cell, {
      required double width,
    }) async {
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: cell),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> pumpAlignedColumn(
      WidgetTester tester,
      List<Widget> cells, {
      required double cellWidth,
    }) async {
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: cellWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: cells,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    double quantityRight(WidgetTester tester, Finder cellFinder) {
      final Finder qty = find.descendant(
        of: cellFinder,
        matching: find.byKey(CtResourceCell.quantityTextKey),
      );
      expect(qty, findsOneWidget);
      return tester.getTopRight(qty).dx;
    }

    double quantityWidth(WidgetTester tester, Finder cellFinder) {
      final Finder qty = find.descendant(
        of: cellFinder,
        matching: find.byKey(CtResourceCell.quantityTextKey),
      );
      expect(qty, findsOneWidget);
      return tester.getSize(qty).width;
    }

    testWidgets(
      'quantity 0 with null delta stays visible at grid width',
      (tester) async {
        await pumpFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: tinyIcon,
            name: 'Grain',
            quantity: 0,
          ),
          width: gridCellWidth,
        );
        expect(find.text('0'), findsOneWidget);
        expect(
          quantityWidth(tester, find.byType(CtResourceCell)),
          greaterThan(1),
        );
      },
    );

    testWidgets(
      'quantity 0 with negative delta shows both values at grid width',
      (tester) async {
        await pumpFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: tinyIcon,
            name: 'Grain',
            quantity: 0,
            delta: -16,
          ),
          width: gridCellWidth,
        );
        expect(find.text('0'), findsOneWidget);
        expect(find.text('-16'), findsOneWidget);
        expect(
          quantityWidth(tester, find.byType(CtResourceCell)),
          greaterThan(1),
        );
      },
    );

    testWidgets(
      'quantity 0 with positive delta shows both values at grid width',
      (tester) async {
        await pumpFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: tinyIcon,
            name: 'Grain',
            quantity: 0,
            delta: 12,
          ),
          width: gridCellWidth,
        );
        expect(find.text('0'), findsOneWidget);
        expect(find.text('+12'), findsOneWidget);
      },
    );

    testWidgets(
      'different label lengths share the same quantity right-edge x',
      (tester) async {
        const Key tinKey = ValueKey<String>('cell_tin');
        const Key sugarKey = ValueKey<String>('cell_sugar');
        const Key refinedKey = ValueKey<String>('cell_refined');
        await pumpAlignedColumn(
          tester,
          <Widget>[
            CtResourceCell(
              key: tinKey,
              iconBuilder: tinyIcon,
              name: 'Tin',
              quantity: 4,
            ),
            CtResourceCell(
              key: sugarKey,
              iconBuilder: tinyIcon,
              name: 'Sugar Cane',
              quantity: 4,
            ),
            CtResourceCell(
              key: refinedKey,
              iconBuilder: tinyIcon,
              name: 'Refined Sugar',
              quantity: 4,
            ),
          ],
          cellWidth: gridCellWidth,
        );
        final double tinX = quantityRight(tester, find.byKey(tinKey));
        final double sugarX = quantityRight(tester, find.byKey(sugarKey));
        final double refinedX = quantityRight(tester, find.byKey(refinedKey));
        expect(tinX, closeTo(sugarX, 0.5));
        expect(sugarX, closeTo(refinedX, 0.5));
      },
    );

    testWidgets(
      'quantity right-edge is delta-stable (null vs non-zero delta)',
      (tester) async {
        const Key noDeltaKey = ValueKey<String>('cell_no_delta');
        const Key withDeltaKey = ValueKey<String>('cell_with_delta');
        await pumpAlignedColumn(
          tester,
          <Widget>[
            CtResourceCell(
              key: noDeltaKey,
              iconBuilder: tinyIcon,
              name: 'Meat',
              quantity: 0,
            ),
            CtResourceCell(
              key: withDeltaKey,
              iconBuilder: tinyIcon,
              name: 'Grain',
              quantity: 0,
              delta: -16,
            ),
          ],
          cellWidth: gridCellWidth,
        );
        expect(
          quantityRight(tester, find.byKey(noDeltaKey)),
          closeTo(quantityRight(tester, find.byKey(withDeltaKey)), 0.5),
        );
      },
    );

    testWidgets(
      'worker counts follow the same quantity alignment rule',
      (tester) async {
        const Key shortKey = ValueKey<String>('worker_short');
        const Key longKey = ValueKey<String>('worker_long');
        await pumpAlignedColumn(
          tester,
          <Widget>[
            CtResourceCell(
              key: shortKey,
              iconBuilder: tinyIcon,
              name: 'Masters',
              quantity: 6,
            ),
            CtResourceCell(
              key: longKey,
              iconBuilder: tinyIcon,
              name: 'Journeymen',
              quantity: 6,
            ),
          ],
          cellWidth: 160,
        );
        expect(
          quantityRight(tester, find.byKey(shortKey)),
          closeTo(quantityRight(tester, find.byKey(longKey)), 0.5),
        );
      },
    );

    testWidgets(
      'magnitude matrix A–H: visibility + alignment at grid width',
      (tester) async {
        const List<({String id, int qty, int? delta, String qtyText})> cases =
            <({String id, int qty, int? delta, String qtyText})>[
          (id: 'A', qty: 0, delta: null, qtyText: '0'),
          (id: 'B', qty: 0, delta: -16, qtyText: '0'),
          (id: 'C', qty: 0, delta: 12, qtyText: '0'),
          (id: 'D', qty: 4, delta: null, qtyText: '4'),
          (id: 'E', qty: 999, delta: null, qtyText: '999'),
          (id: 'F', qty: 9999, delta: null, qtyText: '9,999'),
          (id: 'G', qty: 9999, delta: -999, qtyText: '9,999'),
          (id: 'H', qty: -5, delta: null, qtyText: '-5'),
        ];

        for (final case_ in cases) {
          const Key refKey = ValueKey<String>('matrix_ref');
          final Key caseKey = ValueKey<String>('matrix_${case_.id}');
          await pumpAlignedColumn(
            tester,
            <Widget>[
              CtResourceCell(
                key: refKey,
                iconBuilder: tinyIcon,
                name: 'Tin',
                quantity: case_.qty,
                delta: case_.delta,
              ),
              CtResourceCell(
                key: caseKey,
                iconBuilder: tinyIcon,
                name: 'Refined Sugar',
                quantity: case_.qty,
                delta: case_.delta,
              ),
            ],
            cellWidth: gridCellWidth,
          );

          final Finder caseCell = find.byKey(caseKey);
          expect(
            find.descendant(of: caseCell, matching: find.text(case_.qtyText)),
            findsOneWidget,
            reason: 'Case ${case_.id}: quantity ${case_.qtyText} must be visible',
          );
          expect(
            quantityWidth(tester, caseCell),
            greaterThan(1),
            reason: 'Case ${case_.id}: quantity must have non-zero layout width',
          );
          if (case_.delta != null) {
            final String? deltaText =
                CtResourceCell.formattedDeltaText(case_.delta);
            expect(
              find.descendant(of: caseCell, matching: find.text(deltaText!)),
              findsOneWidget,
              reason: 'Case ${case_.id}: delta $deltaText must be visible',
            );
          }
          expect(
            quantityRight(tester, find.byKey(refKey)),
            closeTo(quantityRight(tester, caseCell), 0.5),
            reason: 'Case ${case_.id}: quantity anchors must align',
          );
        }
      },
    );

    testWidgets(
      'delta sits immediately to the right of quantity without shifting '
      'the quantity anchor vs a null-delta peer',
      (tester) async {
        const Key peerKey = ValueKey<String>('adj_peer');
        const Key deltaKey = ValueKey<String>('adj_delta');
        await pumpAlignedColumn(
          tester,
          <Widget>[
            CtResourceCell(
              key: peerKey,
              iconBuilder: tinyIcon,
              name: 'Wool',
              quantity: 4,
            ),
            CtResourceCell(
              key: deltaKey,
              iconBuilder: tinyIcon,
              name: 'Wool',
              quantity: 4,
              delta: -40,
            ),
          ],
          cellWidth: gridCellWidth,
        );
        final Finder deltaCell = find.byKey(deltaKey);
        final double qtyRight = quantityRight(tester, deltaCell);
        final double deltaLeft =
            tester.getTopLeft(find.descendant(
              of: deltaCell,
              matching: find.text('-40'),
            )).dx;
        expect(deltaLeft - qtyRight, closeTo(CtResourceCell.quantityToDeltaGap, 1.0));
        expect(
          quantityRight(tester, find.byKey(peerKey)),
          closeTo(qtyRight, 0.5),
        );
      },
    );

    testWidgets(
      'trailing cluster right edge remains within card inner-right bounds',
      (tester) async {
        await pumpFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: tinyIcon,
            name: 'Timber',
            quantity: 920,
            delta: -40,
          ),
          width: 240,
        );
        final double cardRight =
            tester.getTopRight(find.byType(CtResourceCell)).dx;
        final double innerRight = cardRight - CtSpacing.s;
        final double clusterRight = tester
            .getTopRight(find.byKey(CtResourceCell.deltaTextKey))
            .dx;
        expect(clusterRight, lessThanOrEqualTo(innerRight + 0.5));
        expect(
          innerRight - clusterRight,
          lessThan(CtResourceCell.reservedDeltaSlotWidth + 1),
        );
      },
    );
  });
}
