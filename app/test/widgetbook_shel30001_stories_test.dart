// Pins Game Initializing (SHEL30001) Widgetbook stories and setup chrome (Refs #2867 S13).
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_flow.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_loading_indicator.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';
import 'app_shell_harness.dart';
import 'widgetbook_dlg60001_shel30001_stories_test_support.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Game Initializing Widgetbook stories (Refs #2867 S13)', () {
    test('gameInitializingDirectories exposes the normative inventory', () {
      final names =
          (widgetbookFolderNamed(
                    gameInitializingDirectories,
                    folderName: 'Game Initializing',
                  ).children ??
                  const <WidgetbookNode>[])
              .whereType<WidgetbookUseCase>()
              .map((uc) => uc.name)
              .toList();
      expect(names, kGameInitializingUseCaseNames);
    });

    for (var i = 0; i < 5; i++) {
      final useCaseName = kGameInitializingUseCaseNames[i];
      testWidgets(
        '$useCaseName paints 48 px accent spinner, phase label, no AlertDialog',
        (WidgetTester tester) async {
          await pumpWidgetbookStory(
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
          expect(indicator.size, 48);
          expect(indicator.color, EditorialMonoclePalette.accent);
          expect(
            tester
                .widget<NewGameSetupProgressView>(
                  find.byType(NewGameSetupProgressView),
                )
                .stepIndex,
            i,
          );
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
          expect(find.byType(AlertDialog), findsNothing);
        },
      );
    }

    testWidgets(
      '${kGameInitializingUseCaseNames[5]} paints 1 px danger border with '
      'Retry/Close CtNinePatchButtons (R34)',
      (WidgetTester tester) async {
        await pumpWidgetbookStory(
          tester,
          findWidgetbookUseCase(
            gameInitializingDirectories,
            folderName: 'Game Initializing',
            useCaseName: kGameInitializingUseCaseNames[5],
          ),
        );
        expect(find.byType(NewGameErrorCard), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsNWidgets(2));
        final l10n = appL10n(tester.element(find.byType(NewGameErrorCard)));
        expect(find.text(l10n.shell_newGameError_retry), findsOneWidget);
        expect(find.text(l10n.common_close), findsOneWidget);

        final dangerBordered = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where((box) {
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
        expect(dangerBordered, isNotEmpty);
      },
    );
  });

  group('NewGameSetupProgressView phase label contract (Refs #2867 R33)', () {
    Widget host(int stepIndex) => buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      child: Scaffold(
        body: Center(child: NewGameSetupProgressView(stepIndex: stepIndex)),
      ),
    );

    Future<void> pumpProgress(WidgetTester tester, int stepIndex) async {
      await tester.pumpWidget(host(stepIndex));
      for (var f = 0; f < 5; f++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    testWidgets('stepIndex 0..4 shows only its matching phase label', (
      WidgetTester tester,
    ) async {
      for (var i = 0; i < 5; i++) {
        await pumpProgress(tester, i);
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
          expect(find.text(allLabels[j]), findsNothing);
        }
      }
    });

    testWidgets(
      'stepIndex outside 0..4 falls back to the generic progress title '
      '(negative path)',
      (WidgetTester tester) async {
        await pumpProgress(tester, 99);
        final l10n = appL10n(
          tester.element(find.byType(NewGameSetupProgressView)),
        );
        expect(find.text(l10n.shell_newGameProgress_title), findsWidgets);
      },
    );
  });

  group('NewGameErrorCard callback contract (Refs #2867 R34)', () {
    Future<void> pumpErrorCard(
      WidgetTester tester, {
      VoidCallback? onClose,
      VoidCallback? onRetry,
    }) async {
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (ctx) {
                  final l10n = appL10n(ctx);
                  return NewGameErrorCard(
                    title: l10n.shell_newGameError_title,
                    message: 'forced failure',
                    closeLabel: l10n.common_close,
                    retryLabel: l10n.shell_newGameError_retry,
                    onClose: onClose,
                    onRetry: onRetry,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Retry/Close callbacks are exclusive; omitted handlers disable buttons',
      (WidgetTester tester) async {
        var retryCount = 0;
        var closeCount = 0;
        await pumpErrorCard(
          tester,
          onClose: () => closeCount++,
          onRetry: () => retryCount++,
        );
        final l10n = appL10n(tester.element(find.byType(NewGameErrorCard)));
        await tester.tap(find.text(l10n.shell_newGameError_retry));
        await tester.pump();
        expect(retryCount, 1);
        expect(closeCount, 0);

        retryCount = 0;
        closeCount = 0;
        await pumpErrorCard(
          tester,
          onClose: () => closeCount++,
          onRetry: () => retryCount++,
        );
        await tester.tap(find.text(l10n.common_close));
        await tester.pump();
        expect(closeCount, 1);
        expect(retryCount, 0);

        await pumpErrorCard(tester);
        for (final btn in tester.widgetList<CtNinePatchButton>(
          find.byType(CtNinePatchButton),
        )) {
          expect(btn.onPressed, isNull);
        }
      },
    );
  });
}
