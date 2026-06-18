// Widget test pin for the `New Game Leader Selection Dialog` →
// `Default (mobile)` Widgetbook use case under `app/lib/widgetbook/catalog.dart`.
//
// Pins two SPEC contracts (Refs #2870 R22 / S9):
//
//  1. The use case is wired into `newGameLeaderSelectionDialogDirectories`.
//  2. The builder pumps without exceptions inside the shared `mobileViewport`
//     (360 × 640 dp) frame per `SPEC/ui/mobile-adaptation.md` § 6 and
//     `SPEC/ui/new-game-leader-selection-dialog.md`.
//
// At 360 dp (< `kLeaderSelectionNarrowBreakpoint` = 540 dp) the slot rows
// stack vertically per the dialog spec § Narrow-viewport slot pickers stacking.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';

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

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'New Game Leader Selection Dialog Widgetbook mobile story (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'Default (mobile) is wired into newGameLeaderSelectionDialogDirectories',
        (WidgetTester tester) async {
          final useCase = _useCase(
            newGameLeaderSelectionDialogDirectories,
            folderName: 'New Game Leader Selection Dialog',
            useCaseName: 'Default (mobile)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Default (mobile) builder pumps at 360 × 640 dp without exceptions',
        (WidgetTester tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(360, 640));

          final useCase = _useCase(
            newGameLeaderSelectionDialogDirectories,
            folderName: 'New Game Leader Selection Dialog',
            useCaseName: 'Default (mobile)',
          );

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(size: Size(360, 640)),
              child: MaterialApp(
                home: Builder(
                  builder: (BuildContext ctx) => useCase.builder(ctx),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));

          expect(
            tester.takeException(),
            isNull,
            reason:
                'Mobile-viewport story must pump without exceptions per '
                'SPEC/ui/mobile-adaptation.md § 6 and '
                'SPEC/ui/new-game-leader-selection-dialog.md.',
          );
          expect(find.byType(NewGameLeaderSelectionDialog), findsOneWidget);
        },
      );
    },
  );
}
