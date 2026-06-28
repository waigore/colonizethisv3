// Pins the dark editorial-monocle chrome contract for [CtPanel] per
// Refs #2859 R2 / S3.
//
// SPEC: SPEC/ui/pixel-art-ui-catalog.md § CtPanel
// (Visual contract: panelGradient background + 1.5 px --accent-dim top/bottom
// border strips; no nine-patch asset dependency; no four-sided frame).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';

import 'support/app_shell_harness.dart';

Widget _hostedPanel({
  Widget child = const SizedBox.shrink(),
  EdgeInsetsGeometry padding = const EdgeInsets.all(12),
}) {
  return buildAppShell(
    child: Scaffold(
      body: SizedBox(
        width: 200,
        height: 80,
        child: CtPanel(padding: padding, child: child),
      ),
    ),
  );
}

DecoratedBox _firstDecoratedBox(WidgetTester tester) {
  return tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(CtPanel),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
}

void main() {
  suppressLogsForTests();

  group('CtPanel dark editorial-monocle visual contract (#2859 R2 / S3)', () {
    testWidgets(
      'renders 1.5 px --accent-dim top and bottom border strips with no left/right border',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostedPanel());
        await tester.pumpAndSettle();

        final BoxDecoration decoration =
            _firstDecoratedBox(tester).decoration as BoxDecoration;
        final Border border = decoration.border! as Border;

        expect(border.top.color, EditorialMonoclePalette.accentDim);
        expect(border.top.width, CtPanel.accentEdgeWidth);
        expect(border.top.width, 1.5);

        expect(border.bottom.color, EditorialMonoclePalette.accentDim);
        expect(border.bottom.width, CtPanel.accentEdgeWidth);
        expect(border.bottom.width, 1.5);

        expect(border.left, BorderSide.none);
        expect(border.right, BorderSide.none);
      },
    );

    testWidgets(
      'paints CtGradients.panelGradient (--surface → --bg) as background',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostedPanel());
        await tester.pumpAndSettle();

        final BoxDecoration decoration =
            _firstDecoratedBox(tester).decoration as BoxDecoration;
        final LinearGradient gradient = decoration.gradient! as LinearGradient;
        final LinearGradient expected =
            CtGradients.panelGradient;

        expect(gradient.begin, expected.begin);
        expect(gradient.end, expected.end);
        expect(gradient.colors, expected.colors);
        expect(gradient.colors.first, EditorialMonoclePalette.surface);
        expect(gradient.colors.last, EditorialMonoclePalette.bg);
      },
    );

    testWidgets('honors the supplied padding around the child', (
      WidgetTester tester,
    ) async {
      const Widget marker = SizedBox(key: Key('panel_marker'), height: 4);
      await tester.pumpWidget(
        _hostedPanel(padding: const EdgeInsets.all(20), child: marker),
      );
      await tester.pumpAndSettle();

      final Padding padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(CtPanel),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(20));
    });

    testWidgets(
      'EdgeInsets.zero padding still keeps the 1.5 px top/bottom strips drawn',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostedPanel(padding: EdgeInsets.zero));
        await tester.pumpAndSettle();

        final BoxDecoration decoration =
            _firstDecoratedBox(tester).decoration as BoxDecoration;
        final Border border = decoration.border! as Border;
        expect(border.top.width, 1.5);
        expect(border.bottom.width, 1.5);
      },
    );

    testWidgets(
      'negative: does not draw a four-sided frame (left/right strips must remain none — owned by CtDialogShell per R3 / S4)',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostedPanel());
        await tester.pumpAndSettle();

        final BoxDecoration decoration =
            _firstDecoratedBox(tester).decoration as BoxDecoration;
        final Border border = decoration.border! as Border;
        expect(
          border.left,
          BorderSide.none,
          reason:
              'CtPanel owns horizontally-banded chrome only; full frames are owned by CtDialogShell (#2859 R3).',
        );
        expect(border.right, BorderSide.none);
      },
    );

    testWidgets(
      'negative: does not introduce hard-coded black87 fallback border colour from the legacy nine-patch chrome',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostedPanel());
        await tester.pumpAndSettle();

        final BoxDecoration decoration =
            _firstDecoratedBox(tester).decoration as BoxDecoration;
        final Border border = decoration.border! as Border;
        expect(
          border.top.color,
          isNot(Colors.black87),
          reason:
              'Legacy parchment _FallbackPanel chrome (black87 border) must not leak into the dark editorial-monocle CtPanel.',
        );
        expect(border.bottom.color, isNot(Colors.black87));
      },
    );

    testWidgets(
      'negative: does not embed the legacy nine-patch asset widget anywhere in the panel subtree',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hostedPanel());
        await tester.pumpAndSettle();

        final Iterable<Widget> nineTileWidgets = tester
            .widgetList(find.byType(Image))
            .where(
              (Widget w) =>
                  w.runtimeType.toString().contains('NineTileBoxWidget'),
            );
        expect(
          nineTileWidgets,
          isEmpty,
          reason:
              'CtPanel must paint chrome programmatically per #2859 R2 / S3; no asset-backed nine-patch chrome.',
        );
      },
    );
  });
}
