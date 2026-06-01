// Pin the 320 dp minimum-viewport contract for the SHEL30001 Game
// Initializing surfaces — the [NewGameSetupProgressView] dialog body
// (one phase label per coarse setup step `0..4` plus the generic
// fallback title) and the [NewGameErrorCard] failure-state card hosted
// inside [CtDialogShell] by the shell error dialog.
//
// These pins live in a dedicated file (sibling to
// `dialogs_320dp_min_viewport_test.dart` and
// `call_to_arms_dialogue_overlay_320dp_min_viewport_test.dart`) so the
// existing dialog host stays under the `repo.dart_file_non_comment_line_size`
// 1000 non-comment-line budget (`SPEC/program/repo-lint.md`) as new
// surfaces continue to land. The contract under test is the same as the
// existing dialogs:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception escapes the framework at
//    `kMinViewportWidth × 640` (320 × 640 dp).
//  * The localised title + phase label (progress view) or the title +
//    body + Retry / Close action labels (error card) all render at
//    320 dp so the layout actually exercises the dialog body at the
//    narrow viewport rather than no-op'ing.
//  * Wide negative controls at 1024 × 768 dp pump without exception
//    against the same fixtures so a regression in the overflow contract
//    upstream of the dialog itself would still be caught.
//
// SHEL30001 ([NewGameSetupProgressView]) paints an indeterminate
// `CtLoadingIndicator` whose `CircularProgressIndicator` ticker never
// settles; the progress pumps therefore drive a single layout frame
// instead of `pumpAndSettle`, mirroring the
// `TurnResolutionProcessingDialog` and `widgetbook_dlg60001_shel30001_stories_test.dart`
// pumping strategy.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/game-initializing.md` § Dark-theme visual contract +
// § Failure and retry.
// Refs #2870 S8 (dialogs scale at narrow widths) + S10 (no horizontal
// overflow at 320 dp on every covered surface).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_flow.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_loading_indicator.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _kMinViewport = Size(kMinViewportWidth, 640);

const Size _kWideRegressionViewport = Size(1024, 768);

/// Canonical English labels for the [NewGameErrorCard] sentinel — mirror
/// the production l10n values from `app/lib/l10n/arb/app_en.arb`
/// (`shell_newGameError_title` / `shell_newGameError_retry` /
/// `common_close`) so the pin breaks in lock-step if those strings drift
/// without the SPEC + 320 dp contract being refreshed together.
const String _kErrorTitle = 'Could not create game';
const String _kErrorMessage =
    'StateError: provincial assigner failed to lock the requested coastal seed';
const String _kErrorCloseLabel = 'Close';
const String _kErrorRetryLabel = 'Retry';

/// Canonical English phase labels for [NewGameSetupProgressView] — mirror
/// the production l10n values from `app/lib/l10n/arb/app_en.arb`
/// (`shell_newGameProgress_step*`) so the SHEL30001 R33 phase mapping
/// regressions surface immediately at the 320 dp viewport.
const String _kProgressTitle = 'Creating game';
const List<String> _kProgressPhaseLabels = <String>[
  'Generating Old World map…',
  'Generating New World map…',
  'Linking Old World and New World…',
  'Building world…',
  'Saving game…',
];

/// Pumps [child] inside a [MaterialApp] using `AppThemes.editorialMonocle`
/// and the app localisation delegates at exactly [size].
///
/// When [settle] is `true` the helper drives `pumpAndSettle()`. When
/// `false` it pumps a single layout frame instead — the progress view
/// hosts a `CircularProgressIndicator` ticker that never settles, so
/// `pumpAndSettle` would time out without adding overflow signal.
Future<void> _pumpSurfaceAtSize(
  WidgetTester tester,
  Widget child, {
  required Size size,
  bool settle = true,
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
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // A single frame is enough for the layout pass to surface a
    // `RenderFlex` overflow through `WidgetTester.takeException()`
    // without waiting on the indeterminate spinner ticker.
    await tester.pump();
  }
}

/// Renders [NewGameErrorCard] inside the same [CtDialogShell] chrome the
/// production `_showNewGameErrorDialog` flow wraps it in, so the 320 dp
/// pin exercises the actual shell layout (1 px `--danger` border inside
/// the regular dialog shell) rather than a bare card.
Widget _hostedErrorCard() {
  return const CtDialogShell(
    child: NewGameErrorCard(
      title: _kErrorTitle,
      message: _kErrorMessage,
      closeLabel: _kErrorCloseLabel,
      retryLabel: _kErrorRetryLabel,
    ),
  );
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — NewGameSetupProgressView @ 320 dp '
    '(Refs #2870 S8/S10; SHEL30001)',
    () {
      for (var index = 0; index < _kProgressPhaseLabels.length; index++) {
        final int stepIndex = index;
        final String phaseLabel = _kProgressPhaseLabels[index];
        testWidgets(
          'AC (positive) NewGameSetupProgressView (phase $stepIndex) @ '
          '320×640: no RenderFlex overflow exception, "Creating game" title '
          '+ "$phaseLabel" phase label + 48 dp accent spinner all render '
          'inside the CtDialogShell content column',
          (WidgetTester tester) async {
            await _pumpSurfaceAtSize(
              tester,
              NewGameSetupProgressView(stepIndex: stepIndex),
              size: _kMinViewport,
              settle: false,
            );

            expect(
              tester.takeException(),
              isNull,
              reason:
                  'SPEC/ui/mobile-adaptation.md § 7: NewGameSetupProgressView '
                  '(phase $stepIndex) must not emit a RenderFlex overflow '
                  'exception at kMinViewportWidth (320 dp). The CtDialogShell '
                  '`maxWidth: 400` is dominated by `Dialog.insetPadding` at '
                  '320 dp — the centered Column (title / spinner / phase '
                  'label) must wrap within the ~288 dp shell content width.',
            );
            expect(find.byType(CtDialogShell), findsOneWidget);
            expect(find.byType(CtLoadingIndicator), findsOneWidget);
            expect(find.text(_kProgressTitle), findsOneWidget);
            expect(
              find.text(phaseLabel),
              findsOneWidget,
              reason:
                  'SPEC/ui/game-initializing.md § Dark-theme visual contract '
                  '(R33): phase $stepIndex must surface its localised label '
                  '"$phaseLabel" at the narrow viewport.',
            );
          },
        );
      }

      testWidgets(
        'AC (positive) NewGameSetupProgressView (out-of-range fallback '
        'stepIndex = 7) @ 320×640: no RenderFlex overflow exception, '
        'localised "Creating game" generic title is used as the body '
        'fallback per `_stepLabel` so the dialog still renders within the '
        '~288 dp CtDialogShell content column',
        (WidgetTester tester) async {
          await _pumpSurfaceAtSize(
            tester,
            const NewGameSetupProgressView(stepIndex: 7),
            size: _kMinViewport,
            settle: false,
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(CtDialogShell), findsOneWidget);
          // Fallback path uses `shell_newGameProgress_title` for both the
          // header and the body label, so the canonical "Creating game"
          // string surfaces at least twice (header + fallback body).
          expect(find.text(_kProgressTitle), findsAtLeastNWidgets(2));
        },
      );

      testWidgets(
        'Negative control: NewGameSetupProgressView (phase 0) @ 1024×768 '
        'also pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pins meaningful)',
        (WidgetTester tester) async {
          await _pumpSurfaceAtSize(
            tester,
            const NewGameSetupProgressView(stepIndex: 0),
            size: _kWideRegressionViewport,
            settle: false,
          );

          expect(tester.takeException(), isNull);
          expect(find.text(_kProgressTitle), findsOneWidget);
          expect(find.text(_kProgressPhaseLabels[0]), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — NewGameErrorCard @ 320 dp '
    '(Refs #2870 S8/S10; SHEL30001 § Failure and retry)',
    () {
      testWidgets(
        'AC (positive) NewGameErrorCard @ 320×640: no RenderFlex overflow '
        'exception, error title + body message + Retry + Close render — '
        'the end-aligned Close + 8 dp gap + Retry CtNinePatchButton pair '
        'must fit within the ~288 dp CtDialogShell content column at '
        'kMinViewportWidth (320 dp)',
        (WidgetTester tester) async {
          await _pumpSurfaceAtSize(
            tester,
            _hostedErrorCard(),
            size: _kMinViewport,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: NewGameErrorCard must not '
                'emit a RenderFlex overflow exception at kMinViewportWidth '
                '(320 dp). The 1 px `--danger` framed Column (title + '
                'SelectableText body + trailing Close / Retry '
                'CtNinePatchButton Row) from SPEC/ui/game-initializing.md '
                '§ Failure and retry must wrap within the ~288 dp '
                'CtDialogShell content column without horizontal overflow.',
          );
          expect(find.byType(CtDialogShell), findsOneWidget);
          expect(find.byType(NewGameErrorCard), findsOneWidget);
          expect(find.byType(CtNinePatchButton), findsNWidgets(2));
          expect(find.text(_kErrorTitle), findsOneWidget);
          expect(find.text(_kErrorCloseLabel), findsOneWidget);
          expect(find.text(_kErrorRetryLabel), findsOneWidget);
          // The exception body (SelectableText) renders the full message so
          // the narrow pin exercises the body wrap path rather than a
          // truncated string. Without horizontal overflow the long
          // `StateError: …` line must wrap onto multiple lines instead of
          // overflowing the shell.
          expect(find.text(_kErrorMessage), findsOneWidget);
        },
      );

      testWidgets(
        'Negative control: NewGameErrorCard @ 1024×768 also pumps without '
        'exception (regression sentinel for the overflow contract — keeps '
        'the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await _pumpSurfaceAtSize(
            tester,
            _hostedErrorCard(),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text(_kErrorTitle), findsOneWidget);
          expect(find.text(_kErrorRetryLabel), findsOneWidget);
          expect(find.text(_kErrorCloseLabel), findsOneWidget);
        },
      );
    },
  );
}
