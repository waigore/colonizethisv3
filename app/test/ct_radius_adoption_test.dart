import 'dart:io' show File;

import 'package:colonizethis_app/features/game/widgets/train_dialog_chrome.dart';
import 'package:colonizethis_app/widgets/ct_radius.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pinning tests for `CtRadius` adoption in feature widgets that previously
/// hard-coded a `BorderRadius.circular(N)` magic number matching a SPEC
/// token (Refs #2914 S6).
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § *Radius tokens* —
/// authoritative table. The token scale (`small: 2`, `medium: 4`,
/// `large: 8`, `xl: 12`) is intentionally non-linear; the prose
/// explicitly calls out `1`, `6`, and `24` as out-of-scale per-component
/// overrides that adoption review (S6) leaves as literals. This slice
/// covers the two remaining feature-tree sites whose previous literal
/// (`2`, `4`) exactly matches a SPEC token (`CtRadius.small`,
/// `CtRadius.medium`) so the migration preserves the legacy visible
/// inset while routing through the canonical token.
///
/// Asserts both:
///   1. the rendered `BorderRadius.circular(CtRadius.*)` form, so
///      future refactors that rename or drop the token trip the test;
///   2. the equivalent literal form (`circular(2)` / `circular(4)`), so
///      visible layout is preserved and a future drift in the token
///      value also trips the test.
void main() {
  suppressLogsForTests();

  group('CtRadius constants pin the SPEC table', () {
    test('CtRadius.small == 2 (matches SPEC § Radius tokens row "small")', () {
      expect(CtRadius.small, 2);
    });

    test('CtRadius.medium == 4 (matches SPEC § Radius tokens row "medium")', () {
      expect(CtRadius.medium, 4);
    });
  });

  group(
    'TrainDialogResourceChip border resolves through CtRadius.medium '
    '(Refs #2914 S6 adoption)',
    () {
      testWidgets('uses BorderRadius.circular(CtRadius.medium)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TrainDialogResourceChip(child: Text('Wool')),
            ),
          ),
        );

        final DecoratedBox decorated = tester.widget(
          find.byType(DecoratedBox),
        );
        final BoxDecoration decoration =
            decorated.decoration as BoxDecoration;
        expect(
          decoration.borderRadius,
          BorderRadius.circular(CtRadius.medium),
        );
      });

      testWidgets(
        'preserves the legacy circular(4) inset so visible layout '
        'does not shift',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: TrainDialogResourceChip(child: Text('Wool')),
              ),
            ),
          );

          final DecoratedBox decorated = tester.widget(
            find.byType(DecoratedBox),
          );
          final BoxDecoration decoration =
              decorated.decoration as BoxDecoration;
          expect(decoration.borderRadius, BorderRadius.circular(4));
        },
      );
    },
  );

  group(
    '_DiplomacyModeButton border resolves through CtRadius.small '
    '(Refs #2914 S6 adoption; private widget — file-text guard)',
    () {
      // `_DiplomacyModeButton` is a library-private widget inside the
      // `diplomacy_panel.dart` part library, so it cannot be pumped from a
      // public-API test without exporting an internal symbol. A
      // file-text guard is the lightest-touch regression for this site:
      // the positive guard asserts the SPEC token is the active form;
      // the negative guard asserts the legacy literal `circular(2)`
      // does not reappear in the file (mirrors the "preserves legacy
      // inset" half of the widget-level pair).
      final File modeBarSource = File(
        'lib/features/game/widgets/diplomacy_panel_mode_bar.dart',
      );

      test(
        'diplomacy_panel_mode_bar.dart uses '
        'BorderRadius.circular(CtRadius.small)',
        () {
          expect(
            modeBarSource.existsSync(),
            isTrue,
            reason:
                'source file must remain at its canonical path so the '
                'regression guard keeps pinning the adoption.',
          );
          final source = modeBarSource.readAsStringSync();
          expect(
            source,
            contains('BorderRadius.circular(CtRadius.small)'),
            reason:
                'the SPEC-pinned token form must remain present so '
                'reverting it to a magic-number literal trips this guard.',
          );
        },
      );

      test(
        'diplomacy_panel_mode_bar.dart no longer hard-codes '
        'BorderRadius.circular(2)',
        () {
          final source = modeBarSource.readAsStringSync();
          expect(
            source,
            isNot(contains('BorderRadius.circular(2)')),
            reason:
                'legacy magic-number form must not reappear; the file '
                'must keep routing through CtRadius.small per Refs '
                '#2914 S6.',
          );
        },
      );
    },
  );
}
