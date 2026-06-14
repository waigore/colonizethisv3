// Widget test pins for the shell-screen mobile-viewport Widgetbook use cases
// under `app/lib/widgetbook/catalog.dart`:
//
//  * `Main Menu` → `Default (mobile)` and `Pixel art (mobile)`
//  * `New Game Leader Selection Dialog` → `Default (mobile)`
//
// Pins two SPEC contracts per mobile story (Refs #2870 R22 / S9):
//
//  1. Each mobile use case is wired into its public directory getter
//     (`mainMenuDirectories` / `newGameLeaderSelectionDialogDirectories`).
//  2. The builder pumps without exceptions inside the shared `mobileViewport`
//     (360 × 640 dp) frame.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 6 (Widgetbook verification) and
// § 4 (narrow breakpoints). Complements the 320 dp minimum-viewport pins in
// `mobile_320dp_min_viewport_test.dart`.

import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase _useCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  final folder = directories.whereType<WidgetbookFolder>().firstWhere(
    (folder) => folder.name == folderName,
    orElse: () =>
        fail('Missing Widgetbook folder: $folderName (got: $directories)'),
  );
  final children = folder.children ?? const <WidgetbookNode>[];
  final useCase = children.whereType<WidgetbookUseCase>().firstWhere(
    (uc) => uc.name == useCaseName,
    orElse: () => fail(
      'Missing use case "$useCaseName" in folder "$folderName" '
      '(got: ${children.map((c) => c.name).toList()})',
    ),
  );
  return useCase;
}

Future<void> _pumpMobileViewport(
  WidgetTester tester,
  WidgetbookUseCase useCase,
) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(360, 640));

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(360, 640)),
      child: MaterialApp(
        home: Builder(builder: (BuildContext ctx) => useCase.builder(ctx)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  suppressLogsForTests();

  group(
    'Main Menu Widgetbook mobile-viewport stories (Refs #2870 R22 / S9)',
    () {
      for (final useCaseName in const <String>[
        'Default (mobile)',
        'Pixel art (mobile)',
      ]) {
        testWidgets('"$useCaseName" is wired into mainMenuDirectories', (
          WidgetTester tester,
        ) async {
          final useCase = _useCase(
            mainMenuDirectories,
            folderName: 'Main Menu',
            useCaseName: useCaseName,
          );
          expect(useCase.builder, isNotNull);
        });

        testWidgets(
          '"$useCaseName" pumps without exception and resolves the narrow '
          '(≤ 430 dp) main-menu padding',
          (WidgetTester tester) async {
            final useCase = _useCase(
              mainMenuDirectories,
              folderName: 'Main Menu',
              useCaseName: useCaseName,
            );

            await _pumpMobileViewport(tester, useCase);

            expect(
              tester.takeException(),
              isNull,
              reason:
                  'SPEC/ui/mobile-adaptation.md § 6: the Main Menu mobile '
                  'Widgetbook story must pump inside the 360 × 640 dp frame '
                  'without overflow.',
            );
            expect(find.byType(CtMainMenu), findsOneWidget);

            final Padding bodyPadding = tester.widget<Padding>(
              find.byKey(const Key(kMainMenuBodyPaddingKey)),
            );
            expect(
              bodyPadding.padding,
              kMainMenuBodyPaddingNarrow,
              reason:
                  'SPEC/ui/mobile-adaptation.md § 4 Main Menu: at the 360 dp '
                  'mobile frame (≤ kMainMenuNarrowBreakpoint = 430) the body '
                  'must resolve the compact narrow padding.',
            );
          },
        );
      }
    },
  );

  group(
    'New Game Leader Selection Dialog Widgetbook mobile story (Refs #2870 R22 / S9)',
    () {
      const useCaseName = 'Default (mobile)';

      testWidgets(
        '"$useCaseName" is wired into newGameLeaderSelectionDialogDirectories',
        (WidgetTester tester) async {
          final useCase = _useCase(
            newGameLeaderSelectionDialogDirectories,
            folderName: 'New Game Leader Selection Dialog',
            useCaseName: useCaseName,
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        '"$useCaseName" pumps without exception and mounts '
        'NewGameLeaderSelectionDialog',
        (WidgetTester tester) async {
          final useCase = _useCase(
            newGameLeaderSelectionDialogDirectories,
            folderName: 'New Game Leader Selection Dialog',
            useCaseName: useCaseName,
          );

          await _pumpMobileViewport(tester, useCase);

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 6: the leader-selection '
                'mobile Widgetbook story must pump inside the 360 × 640 dp '
                'frame without overflow (< 500 dp stacked-slot layout).',
          );
          expect(find.byType(NewGameLeaderSelectionDialog), findsOneWidget);
        },
      );
    },
  );
}
