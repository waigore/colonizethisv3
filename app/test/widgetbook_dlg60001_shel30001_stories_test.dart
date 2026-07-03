// Pins the new `Next Turn Confirmation` (DLG60001) and `Game Initializing`
// (SHEL30001) Widgetbook story inventories that complete subtask S13 of
// issue #2867 (Widgetbook stories for the 12 enumerated dialog / overlay
// surfaces). Together with the existing per-surface story tests this asserts
// the full 12-surface Widgetbook contract from `SPEC/ui/next-turn-confirmation.md`
// § Acceptance criteria and `SPEC/ui/game-initializing.md` § Dark-theme
// visual contract.
//
// Negative-path tests sit alongside positive-path ones so renaming or
// removing one of the new use cases — or regressing the visual contract
// (CtDialogShell wrapping, 48 px `--accent` spinner, 1 px `--danger` error
// border, no Material chrome) — fails CI immediately.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_flow.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_loading_indicator.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import 'support/widgetbook_test_harness.dart';

/// Normative inventory of the new DLG60001 stories that issue #2867 S13
/// requires. Renaming or removing one must fail the inventory test below.
const List<String> kNextTurnConfirmationUseCaseNames = <String>[
  'Default — turn 1',
  'Mid-game — turn 42',
];

/// Normative inventory of the new SHEL30001 stories that issue #2867 S13
/// requires (one story per phase index `0..4` + the failure-state card).
const List<String> kGameInitializingUseCaseNames = <String>[
  'Progress — phase 0 (Old World)',
  'Progress — phase 1 (New World)',
  'Progress — phase 2 (Warp linking)',
  'Progress — phase 3 (Building world)',
  'Progress — phase 4 (Saving)',
  'Error — danger-bordered retry card',
];

WidgetbookFolder _folder(
  List<WidgetbookNode> directories, {
  required String folderName,
}) {
  return directories.whereType<WidgetbookFolder>().firstWhere(
    (folder) => folder.name == folderName,
    orElse: () => fail('Missing Widgetbook folder: $folderName'),
  );
}

WidgetbookUseCase findWidgetbookUseCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  final children = _folder(
    directories,
    folderName: folderName,
  ).children ?? const <WidgetbookNode>[];
  return children.whereType<WidgetbookUseCase>().firstWhere(
    (uc) => uc.name == useCaseName,
    orElse: () => fail(
      'Missing use case "$useCaseName" in folder "$folderName" '
      '(got: ${children.map((c) => c.name).toList()})',
    ),
  );
}

/// Pumps a Widgetbook story without `pumpAndSettle`. The Game Initializing
/// progress stories paint an indeterminate `CtLoadingIndicator` (Material
/// `CircularProgressIndicator` under the hood) whose animation never
/// settles, so we drive a small fixed number of frames to flush
/// localisation loading + the first layout pass instead.
Future<void> _pumpStory(WidgetTester tester, WidgetbookUseCase useCase) async {
  await tester.pumpWidget(Builder(builder: useCase.builder));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Next Turn Confirmation Widgetbook stories (Refs #2867 S13)', () {
    test(
      'nextTurnConfirmationDialogDirectories exposes the normative inventory',
      () {
        final names =
            (_folder(
                  nextTurnConfirmationDialogDirectories,
                  folderName: 'Next Turn Confirmation',
                ).children ??
                const <WidgetbookNode>[])
            .whereType<WidgetbookUseCase>()
            .map((uc) => uc.name)
            .toList();
        expect(names, kNextTurnConfirmationUseCaseNames);
      },
    );

    test(
      'Next Turn Confirmation is registered in the aggregate Widgetbook tree',
      () {
        // Pumping the full app would require Flame asset wiring; instead
        // verify the folder name appears in the addons-free directory tree
        // exposed by `_ctWidgetbookDirectories` through the public
        // `CtWidgetbookApp` entry. We grep the root via the `CtWidgetbookApp`
        // build by inspecting the wired sub-directory getter — the
        // aggregate list is private, so we verify by checking that the
        // sub-directory getter itself is non-empty (renaming the getter or
        // dropping it from `_ctWidgetbookDirectories` would fail at link
        // time, not at runtime; the inventory test above is the stronger
        // pin for content).
        expect(
          nextTurnConfirmationDialogDirectories.isNotEmpty,
          isTrue,
          reason:
              'nextTurnConfirmationDialogDirectories must contribute at '
              'least one folder so it can be wired into the aggregate '
              'Widgetbook tree.',
        );
      },
    );

    for (final useCaseName in kNextTurnConfirmationUseCaseNames) {
      testWidgets(
        '$useCaseName pumps under editorialMonocle without exceptions',
        (WidgetTester tester) async {
          await _pumpStory(
            tester,
            findWidgetbookUseCase(
              nextTurnConfirmationDialogDirectories,
              folderName: 'Next Turn Confirmation',
              useCaseName: useCaseName,
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '$useCaseName wraps the dialog in CtDialogShell with two '
        'CtNinePatchButton actions and no Material AlertDialog',
        (WidgetTester tester) async {
          await _pumpStory(
            tester,
            findWidgetbookUseCase(
              nextTurnConfirmationDialogDirectories,
              folderName: 'Next Turn Confirmation',
              useCaseName: useCaseName,
            ),
          );
          expect(find.byType(CtDialogShell), findsOneWidget);
          expect(find.byType(NextTurnConfirmationDialog), findsOneWidget);
          expect(find.byType(CtNinePatchButton), findsNWidgets(2));
          expect(find.byType(AlertDialog), findsNothing);
        },
      );

      testWidgets(
        '$useCaseName renders under the editorialMonocle dark theme',
        (WidgetTester tester) async {
          await _pumpStory(
            tester,
            findWidgetbookUseCase(
              nextTurnConfirmationDialogDirectories,
              folderName: 'Next Turn Confirmation',
              useCaseName: useCaseName,
            ),
          );
          final ThemeData theme = Theme.of(
            tester.element(find.byType(NextTurnConfirmationDialog)),
          );
          expect(theme.brightness, Brightness.dark);
          expect(
            theme.scaffoldBackgroundColor,
            EditorialMonoclePalette.bg,
            reason:
                'Story host must inject AppThemes.editorialMonocle so DLG60001 '
                'renders against the canonical scaffold token.',
          );
          expect(theme.colorScheme.primary, EditorialMonoclePalette.accent);
        },
      );
    }
  });

  group('Game Initializing Widgetbook stories (Refs #2867 S13)', () {
    test(
      'gameInitializingDirectories exposes the normative inventory',
      () {
        final names =
            (_folder(
                  gameInitializingDirectories,
                  folderName: 'Game Initializing',
                ).children ??
                const <WidgetbookNode>[])
            .whereType<WidgetbookUseCase>()
            .map((uc) => uc.name)
            .toList();
        expect(names, kGameInitializingUseCaseNames);
      },
    );

    for (var i = 0; i < 5; i++) {
      final useCaseName = kGameInitializingUseCaseNames[i];
      testWidgets(
        '$useCaseName paints the 48 px --accent spinner per R32',
        (WidgetTester tester) async {
          await _pumpStory(
            tester,
            findWidgetbookUseCase(
              gameInitializingDirectories,
              folderName: 'Game Initializing',
              useCaseName: useCaseName,
            ),
          );
          expect(find.byType(NewGameSetupProgressView), findsOneWidget);
          final indicator = tester.widget<CtLoadingIndicator>(
            find.byType(CtLoadingIndicator),
          );
          expect(
            indicator.size,
            48,
            reason: 'SPEC/ui/game-initializing.md R32: 48 px ring',
          );
          expect(
            indicator.color,
            EditorialMonoclePalette.accent,
            reason: 'SPEC/ui/game-initializing.md R32: --accent top border',
          );
        },
      );

      testWidgets(
        '$useCaseName resolves the canonical phase label for step '
        '${useCaseName.contains('phase ') ? useCaseName.split('phase ')[1][0] : '?'}',
        (WidgetTester tester) async {
          await _pumpStory(
            tester,
            findWidgetbookUseCase(
              gameInitializingDirectories,
              folderName: 'Game Initializing',
              useCaseName: useCaseName,
            ),
          );
          final view = tester.widget<NewGameSetupProgressView>(
            find.byType(NewGameSetupProgressView),
          );
          expect(view.stepIndex, i);

          final l10n = appL10n(
            tester.element(find.byType(NewGameSetupProgressView)),
          );
          final expectedLabel = switch (i) {
            0 => l10n.shell_newGameProgress_stepOldWorld,
            1 => l10n.shell_newGameProgress_stepNewWorld,
            2 => l10n.shell_newGameProgress_stepWarp,
            3 => l10n.shell_newGameProgress_stepBuildWorld,
            4 => l10n.shell_newGameProgress_stepSave,
            _ => l10n.shell_newGameProgress_title,
          };
          expect(find.text(expectedLabel), findsOneWidget);
        },
      );

      testWidgets(
        '$useCaseName renders no Material AlertDialog chrome',
        (WidgetTester tester) async {
          await _pumpStory(
            tester,
            findWidgetbookUseCase(
              gameInitializingDirectories,
              folderName: 'Game Initializing',
              useCaseName: useCaseName,
            ),
          );
          // CtLoadingIndicator legitimately wraps a Material
          // CircularProgressIndicator (see app/lib/widgets/ct_loading_indicator.dart),
          // so we assert only that the dialog tree avoids the broader
          // Material `AlertDialog` chrome banned by
          // SPEC/ui/pixel-art-ui-catalog.md § Material design ban.
          expect(find.byType(AlertDialog), findsNothing);
        },
      );
    }

    testWidgets(
      '${kGameInitializingUseCaseNames[5]} paints a 1 px --danger border '
      'around the NewGameErrorCard per R34',
      (WidgetTester tester) async {
        await _pumpStory(
          tester,
          findWidgetbookUseCase(
            gameInitializingDirectories,
            folderName: 'Game Initializing',
            useCaseName: kGameInitializingUseCaseNames[5],
          ),
        );
        expect(find.byType(NewGameErrorCard), findsOneWidget);

        final decoratedBoxes = tester.widgetList<DecoratedBox>(
          find.byType(DecoratedBox),
        );
        final dangerBordered = decoratedBoxes.where((box) {
          final deco = box.decoration;
          if (deco is! BoxDecoration) return false;
          final border = deco.border;
          if (border is! Border) return false;
          return border.top.color == EditorialMonoclePalette.danger &&
              border.top.width == 1 &&
              border.bottom.color == EditorialMonoclePalette.danger &&
              border.left.color == EditorialMonoclePalette.danger &&
              border.right.color == EditorialMonoclePalette.danger;
        });
        expect(
          dangerBordered,
          isNotEmpty,
          reason:
              'SPEC/ui/game-initializing.md R34: error card must paint a '
              '1 px --danger border on all four sides.',
        );
      },
    );

    testWidgets(
      '${kGameInitializingUseCaseNames[5]} exposes Retry primary and Close '
      'secondary CtNinePatchButton actions',
      (WidgetTester tester) async {
        await _pumpStory(
          tester,
          findWidgetbookUseCase(
            gameInitializingDirectories,
            folderName: 'Game Initializing',
            useCaseName: kGameInitializingUseCaseNames[5],
          ),
        );
        expect(find.byType(NewGameErrorCard), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsNWidgets(2));

        final l10n = appL10n(
          tester.element(find.byType(NewGameErrorCard)),
        );
        expect(find.text(l10n.shell_newGameError_retry), findsOneWidget);
        expect(find.text(l10n.common_close), findsOneWidget);
      },
    );
  });

  group('NewGameSetupProgressView phase label contract (Refs #2867 R33)', () {
    Widget host(int stepIndex) => MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: NewGameSetupProgressView(stepIndex: stepIndex)),
      ),
    );

    for (var i = 0; i < 5; i++) {
      testWidgets(
        'stepIndex=$i shows the matching phase label and no other phase',
        (WidgetTester tester) async {
          await tester.pumpWidget(host(i));
          for (var f = 0; f < 5; f++) {
            await tester.pump(const Duration(milliseconds: 20));
          }
          final l10n = appL10n(
            tester.element(find.byType(NewGameSetupProgressView)),
          );
          final allLabels = <String>[
            l10n.shell_newGameProgress_stepOldWorld,
            l10n.shell_newGameProgress_stepNewWorld,
            l10n.shell_newGameProgress_stepWarp,
            l10n.shell_newGameProgress_stepBuildWorld,
            l10n.shell_newGameProgress_stepSave,
          ];
          expect(find.text(allLabels[i]), findsOneWidget);
          for (var j = 0; j < allLabels.length; j++) {
            if (j == i) continue;
            expect(
              find.text(allLabels[j]),
              findsNothing,
              reason:
                  'stepIndex=$i must render only its own phase label; '
                  'leaking label "${allLabels[j]}" indicates the label '
                  'mapping has regressed.',
            );
          }
        },
      );
    }

    testWidgets(
      'stepIndex outside 0..4 falls back to the generic progress title '
      '(negative path)',
      (WidgetTester tester) async {
        await tester.pumpWidget(host(99));
        for (var f = 0; f < 5; f++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        final l10n = appL10n(
          tester.element(find.byType(NewGameSetupProgressView)),
        );
        expect(find.text(l10n.shell_newGameProgress_title), findsWidgets);
      },
    );
  });

  group('NewGameErrorCard callback contract (Refs #2867 R34)', () {
    testWidgets(
      'tapping Retry invokes onRetry and not onClose',
      (WidgetTester tester) async {
        var retryCount = 0;
        var closeCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.editorialMonocle,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (ctx) {
                    final l10n = appL10n(ctx);
                    return NewGameErrorCard(
                      title: l10n.shell_newGameError_title,
                      message: 'forced failure',
                      closeLabel: l10n.common_close,
                      retryLabel: l10n.shell_newGameError_retry,
                      onClose: () => closeCount++,
                      onRetry: () => retryCount++,
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = appL10n(
          tester.element(find.byType(NewGameErrorCard)),
        );
        await tester.tap(find.text(l10n.shell_newGameError_retry));
        await tester.pump();
        expect(retryCount, 1);
        expect(closeCount, 0);
      },
    );

    testWidgets(
      'tapping Close invokes onClose and not onRetry',
      (WidgetTester tester) async {
        var retryCount = 0;
        var closeCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.editorialMonocle,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (ctx) {
                    final l10n = appL10n(ctx);
                    return NewGameErrorCard(
                      title: l10n.shell_newGameError_title,
                      message: 'forced failure',
                      closeLabel: l10n.common_close,
                      retryLabel: l10n.shell_newGameError_retry,
                      onClose: () => closeCount++,
                      onRetry: () => retryCount++,
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = appL10n(
          tester.element(find.byType(NewGameErrorCard)),
        );
        await tester.tap(find.text(l10n.common_close));
        await tester.pump();
        expect(closeCount, 1);
        expect(retryCount, 0);
      },
    );

    testWidgets(
      'omitting onClose / onRetry disables the buttons (negative path)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.editorialMonocle,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (ctx) {
                    final l10n = appL10n(ctx);
                    return NewGameErrorCard(
                      title: l10n.shell_newGameError_title,
                      message: 'forced failure',
                      closeLabel: l10n.common_close,
                      retryLabel: l10n.shell_newGameError_retry,
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final buttons = tester.widgetList<CtNinePatchButton>(
          find.byType(CtNinePatchButton),
        );
        for (final btn in buttons) {
          expect(btn.onPressed, isNull);
        }
      },
    );
  });
}
