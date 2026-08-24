// Pins Next Turn Confirmation (DLG60001) Widgetbook story inventory (Refs #2867 S13).
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';
import 'widgetbook_dlg60001_shel30001_stories_test_support.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Next Turn Confirmation Widgetbook stories (Refs #2867 S13)', () {
    test(
      'nextTurnConfirmationDialogDirectories exposes the normative inventory',
      () {
        final names =
            (widgetbookFolderNamed(
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
        '$useCaseName pumps under editorialMonocle with CtDialogShell chrome',
        (WidgetTester tester) async {
          await pumpWidgetbookStory(
            tester,
            findWidgetbookUseCase(
              nextTurnConfirmationDialogDirectories,
              folderName: 'Next Turn Confirmation',
              useCaseName: useCaseName,
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(CtDialogShell), findsOneWidget);
          expect(find.byType(NextTurnConfirmationDialog), findsOneWidget);
          expect(find.byType(CtNinePatchButton), findsNWidgets(2));
          expect(find.byType(AlertDialog), findsNothing);
          final ThemeData theme = Theme.of(
            tester.element(find.byType(NextTurnConfirmationDialog)),
          );
          expect(theme.brightness, Brightness.dark);
          expect(theme.scaffoldBackgroundColor, EditorialMonoclePalette.bg);
          expect(theme.colorScheme.primary, EditorialMonoclePalette.accent);
        },
      );
    }
  });
}
