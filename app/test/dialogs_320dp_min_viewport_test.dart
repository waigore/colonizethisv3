// Pin the 320 dp minimum-viewport contract for the in-game modal dialogs
// that share the [CtDialogShell] chrome — extending the existing screen-
// and panel-level pins (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`) to the simplest two dialogs that
// surface during in-game play:
//
//  * [GameParametersDialog]   — read-only campaign parameters opened from
//    the hamburger side menu (SPEC/ui/in-game-shell-narrow.md
//    § Game Parameters).
//  * [ExitConfirmDialog]      — Android back exit-to-main-menu confirm
//    (SPEC/ui/in-game-shell-narrow.md § Android back confirm).
//
// Both dialogs render their chrome via [CtDialogShell] (Dialog with
// `insetPadding: 16` and an inner `ConstrainedBox(maxWidth: 400|480)`).
// At `kMinViewportWidth` (320 dp) the available content width collapses
// to ~288 dp, which is the most constrained surface either dialog
// renders against in production. The pins assert:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework — the contract the other
//    `*_320dp_min_viewport_test.dart` files rely on.
//  * Dialog body labels (title + action labels) still render end-to-end
//    so the layout actually exercises the dialog body at 320 dp rather
//    than no-op'ing.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixtures so a regression in the host overflow
//    contract upstream of the dialog itself would be caught.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/in-game-shell-narrow.md` § Game Parameters and
// § Android back confirm.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/exit_confirm_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/game_parameters_dialog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen- and panel-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same dialog renders its default layout. Mirrors
/// the contract used by `mobile_320dp_min_viewport_test.dart` and
/// `panels_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [dialog] at [size] under the running editorial-monocle theme.
///
/// Sets the surface size (so the binding's render flex math sees the
/// minimum viewport) and overrides MediaQuery so dialog code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value — the
/// pattern already used by `mobile_320dp_min_viewport_test.dart` and
/// `victory_overlay_narrow_test.dart`.
///
/// Embeds [dialog] directly in the Scaffold body rather than driving the
/// real `showDialog` flow because the contract under test is the
/// dialog's own [CtDialogShell] layout at the narrow viewport, not the
/// barrier / overlay route plumbing (which is already covered by
/// `exit_confirm_dialog_test.dart`).
Future<void> _pumpDialogAtSize(
  WidgetTester tester,
  Widget dialog, {
  required Size size,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: Center(child: dialog)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — GameParametersDialog @ 320 dp '
    '(Refs #2870 S8/S10)',
    () {
      testWidgets(
        'AC (positive) GameParametersDialog (infiniteMode off) @ 320×640: '
        'no RenderFlex overflow exception, title + close action render',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(
            tester,
            const GameParametersDialog(infiniteMode: false),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: GameParametersDialog must '
                'not emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). CtDialogShell at 320 dp '
                'collapses to ~288 dp content width — title text, the '
                '"Infinite mode: …" line, and the trailing Close action must '
                'all wrap within that.',
          );
          expect(find.text('Game Parameters'), findsOneWidget);
          expect(find.text('Infinite mode: Off'), findsOneWidget);
          expect(find.text('Close'), findsOneWidget);
        },
      );

      testWidgets(
        'AC (positive) GameParametersDialog (infiniteMode on) @ 320×640: '
        'no exception, "Infinite mode: On" body line renders',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(
            tester,
            const GameParametersDialog(infiniteMode: true),
            size: _kMinViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Game Parameters'), findsOneWidget);
          expect(find.text('Infinite mode: On'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: GameParametersDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pins meaningful)',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(
            tester,
            const GameParametersDialog(infiniteMode: false),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Game Parameters'), findsOneWidget);
          expect(find.text('Close'), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — ExitConfirmDialog @ 320 dp '
    '(Refs #2870 S8/S10)',
    () {
      testWidgets(
        'AC (positive) ExitConfirmDialog @ 320×640: no RenderFlex '
        'overflow exception, title + body + Cancel + Exit all render',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(
            tester,
            const ExitConfirmDialog(),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: ExitConfirmDialog must '
                'not emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The Cancel + Exit Row '
                '(end-aligned, two CtNinePatchButtons + an 8 dp gap) must '
                'fit within the ~288 dp content width without overflow.',
          );
          expect(find.text('Exit game?'), findsOneWidget);
          expect(
            find.text('Your current progress will be lost if not saved.'),
            findsOneWidget,
          );
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Exit'), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: ExitConfirmDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract)',
        (WidgetTester tester) async {
          await _pumpDialogAtSize(
            tester,
            const ExitConfirmDialog(),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Exit game?'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Exit'), findsOneWidget);
        },
      );
    },
  );
}
