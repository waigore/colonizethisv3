// Pin the 320 dp minimum-viewport contract for the in-game train dialogs
// (`TrainCiviliansDialog`, `TrainMilitaryDialog`, `TrainNavalDialog`) —
// extending the existing
// in-game dialog pins (`dialogs_320dp_min_viewport_test.dart`) to the two
// CtDialogShell-hosted train dialogs opened from the empire-overview
// Civilian / Military panels.
//
// Both dialogs render their chrome via [CtDialogShell] with the shared
// [TrainDialogHeader] (centered Cinzel accent title, no `×` close button —
// #3568 parity), `SizedBox` section gaps (no brass dividers), a `Wrap`-based
// resource bar (treasury / paper for civilians; treasury / peasants / six
// commodity chips for military), a column of per-unit-type rows, and a trailing
// right-aligned Reset action row. At `kMinViewportWidth` (320 dp) the
// shell collapses to the same ~288 dp content width as the shells pinned
// in `dialogs_320dp_min_viewport_test.dart` — `Dialog.insetPadding`
// (16 dp each side) dominates whenever the viewport is narrower than the
// configured `maxWidth`, so the wider resource-chip set on the military
// dialog (six commodity chips inside the `Wrap`) and the per-row stepper
// surfaces must still wrap within that budget.
//
// Each test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception (which Flutter surfaces via
//    `FlutterError.onError`) escapes the framework — the contract the
//    other `*_320dp_min_viewport_test.dart` files rely on.
//  * The localized title text still renders end-to-end so the layout
//    actually exercises the dialog body at 320 dp rather than no-op'ing.
//  * The trailing `Reset` action label renders so the bottom action row
//    layout (right-aligned `CtNinePatchButton` inside a `MainAxisAlignment.end`
//    `Row`) is exercised at the narrow width.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the host overflow
//    contract upstream of the dialog itself would be caught.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/train-civilians-dialog.md`.
// SPEC: `SPEC/ui/train-military-dialog.md`.
// SPEC: `SPEC/ui/train-naval-dialog.md`.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_naval_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same dialog renders its default layout. Mirrors
/// the contract used by `dialogs_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [dialog] at [size] under the running editorial-monocle theme.
///
/// Mirrors `_pumpDialogAtSize` in `dialogs_320dp_min_viewport_test.dart`
/// — sets the surface size (so the binding's render flex math sees the
/// minimum viewport) and overrides MediaQuery so dialog code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value.
///
/// Embeds [dialog] directly in the Scaffold body rather than driving the
/// real `showDialog` flow because the contract under test is the
/// dialog's own [CtDialogShell] layout at the narrow viewport, not the
/// barrier / overlay route plumbing.
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
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: Center(child: dialog)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Resolves the human player id from the lightweight train fixture.
String _humanPlayerId(Game game) {
  return game.players.firstWhere((p) => p.isHuman).id;
}

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — TrainCiviliansDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    testWidgets(
      'AC (positive) TrainCiviliansDialog @ 320×640: no RenderFlex '
      'overflow exception, "Train Civilians" title + Reset action render',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        final humanPlayerId = _humanPlayerId(game);
        await _pumpDialogAtSize(
          tester,
          TrainCiviliansDialog(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: TrainCiviliansDialog must '
              'not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The CtDialogShell chrome — '
              'TrainDialogHeader (Cinzel accent title + 32 dp close ×), '
              'the Wrap-based TrainDialogResourceBar (Treasury + Paper '
              'lines), the per-civilian-unit rows '
              '(`builder`, `farmer`, `craftsman`, `paperMaker`, '
              '`bookbinder`, `clerk`) with name + cost header + +/- '
              'stepper, and the trailing right-aligned Reset action — '
              'must all fit within the ~288 dp CtDialogShell content '
              'column at 320 dp.',
        );
        expect(find.text('Train Civilians'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      },
    );

    testWidgets('Negative control: TrainCiviliansDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      final game = buildTrainPanelTestGame();
      final humanPlayerId = _humanPlayerId(game);
      await _pumpDialogAtSize(
        tester,
        TrainCiviliansDialog(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: const Orders(),
          bus: AppEventBus.create(),
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Train Civilians'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — TrainMilitaryDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    testWidgets(
      'AC (positive) TrainMilitaryDialog @ 320×640: no RenderFlex '
      'overflow exception, "Train Military" title + Reset action render',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        final humanPlayerId = _humanPlayerId(game);
        await _pumpDialogAtSize(
          tester,
          TrainMilitaryDialog(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: TrainMilitaryDialog must '
              'not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The CtDialogShell chrome — '
              'TrainDialogHeader, the Wrap-based military resource bar '
              '(Treasury + Peasants + six commodity chips: fabric, '
              'castIron, lumber, horses, steel, bronze), the per-regiment '
              'rows with name + cost header + +/- stepper, and the '
              'trailing right-aligned Reset action — must all wrap '
              'within the ~288 dp CtDialogShell content column at '
              '320 dp. The military resource Wrap (more chips than the '
              'civilian dialog) must flow onto extra runs without '
              'overflowing horizontally.',
        );
        expect(find.text('Train Military'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      },
    );

    testWidgets('Negative control: TrainMilitaryDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      final game = buildTrainPanelTestGame();
      final humanPlayerId = _humanPlayerId(game);
      await _pumpDialogAtSize(
        tester,
        TrainMilitaryDialog(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: const Orders(),
          bus: AppEventBus.create(),
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Train Military'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — TrainNavalDialog @ 320 dp '
      '(Refs #3601 S15 / #2870 S8/S10)', () {
    testWidgets(
      'AC (positive) TrainNavalDialog @ 320×640: no RenderFlex '
      'overflow exception, "Train Naval" title + Reset action render',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        final humanPlayerId = _humanPlayerId(game);
        await _pumpDialogAtSize(
          tester,
          TrainNavalDialog(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: TrainNavalDialog must '
              'not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The CtDialogShell chrome — '
              'TrainDialogHeader, the Wrap-based naval resource bar '
              '(Treasury + Peasants + four commodity chips: lumber, '
              'fabric, castIron, coal), the per-ship rows with name + '
              'cost header + +/- stepper, and the trailing right-aligned '
              'Reset action — must all wrap within the ~288 dp '
              'CtDialogShell content column at 320 dp.',
        );
        expect(find.text('Train Naval'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      },
    );

    testWidgets('Negative control: TrainNavalDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      final game = buildTrainPanelTestGame();
      final humanPlayerId = _humanPlayerId(game);
      await _pumpDialogAtSize(
        tester,
        TrainNavalDialog(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: const Orders(),
          bus: AppEventBus.create(),
        ),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Train Naval'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });
  });
}
