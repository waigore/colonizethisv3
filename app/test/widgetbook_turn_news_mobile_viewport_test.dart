// Widget test pin for the `Turn news` → `Mobile viewport` Widgetbook
// use case under `app/lib/widgetbook/catalog_part2.dart`.
//
// Pins two SPEC contracts (Refs #2870 R22 / S9):
//
//  1. The use case is wired into the public `turnNewsDialogDirectories`
//     getter under the canonical folder + name (so renaming or removing
//     it surfaces here in CI before reviewers lose the mobile-viewport
//     story for `TurnNewsDialog`).
//  2. The builder pumps without exceptions inside the shared
//     `mobileViewport` (360 × 640 dp `MediaQuery.size`) frame, per
//     `SPEC/ui/mobile-adaptation.md` § 6 and the Widgetbook contract in
//     `SPEC/ui/turn-news-dialog.md`.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/widgetbook/catalog.dart';

WidgetbookUseCase _useCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  final folder = directories
      .whereType<WidgetbookFolder>()
      .firstWhere(
        (folder) => folder.name == folderName,
        orElse: () =>
            fail('Missing Widgetbook folder: $folderName (got: $directories)'),
      );
  final children = folder.children ?? const <WidgetbookNode>[];
  final useCase = children
      .whereType<WidgetbookUseCase>()
      .firstWhere(
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
    'Turn news Widgetbook mobile-viewport story (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'Mobile viewport is wired into turnNewsDialogDirectories under the '
        'canonical folder + name',
        (WidgetTester tester) async {
          final useCase = _useCase(
            turnNewsDialogDirectories,
            folderName: 'Turn news',
            useCaseName: 'Mobile viewport',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Mobile viewport builder pumps at 360 × 640 dp without exceptions',
        (WidgetTester tester) async {
          // Match the surface bound by the production `mobileViewport`
          // helper (`SizedBox(width: 360, height: 640)`) so the explicit
          // MediaQuery the helper overlays maps to the surface bounds.
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(360, 640));

          final useCase = _useCase(
            turnNewsDialogDirectories,
            folderName: 'Turn news',
            useCaseName: 'Mobile viewport',
          );

          // The story builds its own MaterialApp (with localizations
          // delegates) inside `mobileViewport`, so we wrap only the
          // outer MediaQuery here to avoid a double app shell.
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(size: Size(360, 640)),
              child: Builder(
                builder: (BuildContext ctx) => useCase.builder(ctx),
              ),
            ),
          );
          // Localization delegates load asynchronously; give them a few
          // frames to settle before sampling exceptions.
          await tester.pumpAndSettle(const Duration(milliseconds: 200));

          expect(
            tester.takeException(),
            isNull,
            reason:
                'Mobile-viewport story must pump without exceptions per '
                'SPEC/ui/mobile-adaptation.md § 6 and the Widgetbook AC in '
                'SPEC/ui/turn-news-dialog.md.',
          );
        },
      );
    },
  );
}
