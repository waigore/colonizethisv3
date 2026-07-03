// Widget test pin for the `Map Widget` → `Debug mode (mobile)` Widgetbook
// use case under `app/lib/widgetbook/catalog.dart`.
//
// Pins two SPEC contracts (Refs #2870 R22 / S9):
//
//  1. The use case is wired into the public `mapWidgetDirectories`
//     getter under the canonical folder + name (so renaming or removing
//     it surfaces here in CI before reviewers lose the mobile-viewport
//     story for the debug map surface).
//  2. The builder pumps without exceptions inside the shared
//     `mobileViewport` (360 × 640 dp `MediaQuery.size`) frame, per
//     `SPEC/ui/mobile-adaptation.md` § 6 and the Widgetbook contract in
//     `SPEC/ui/map-widget.md`.

import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'support/widgetbook_test_harness.dart';

WidgetbookUseCase findWidgetbookUseCase(
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
    'Map Widget Widgetbook mobile-viewport story (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'Debug mode (mobile) is wired into mapWidgetDirectories under the '
        'canonical folder + name',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            mapWidgetDirectories,
            folderName: 'Map Widget',
            useCaseName: 'Debug mode (mobile)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Debug mode (mobile) builder pumps at 360 × 640 dp without exceptions',
        (WidgetTester tester) async {
          // Match the surface bound by the production `mobileViewport`
          // helper (`SizedBox(width: 360, height: 640)`) so the explicit
          // MediaQuery the helper overlays maps to the surface bounds.
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(360, 640));

          final useCase = findWidgetbookUseCase(
            mapWidgetDirectories,
            folderName: 'Map Widget',
            useCaseName: 'Debug mode (mobile)',
          );

          // The story's `DebugMapVisibilityStory` reads `appL10n(context)`,
          // so we host it inside a localized `MaterialApp`. Widgetbook
          // itself wires localizations at runtime via the addon chain.
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(size: Size(360, 640)),
              child: MaterialApp(
                localizationsDelegates:
                    AppLocalizationsBinding.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Builder(
                    builder: (BuildContext ctx) => useCase.builder(ctx),
                  ),
                ),
              ),
            ),
          );
          // The map view loads tile assets / debug-init game data
          // asynchronously; let async work settle before sampling.
          await tester.pumpAndSettle(const Duration(milliseconds: 200));

          expect(
            tester.takeException(),
            isNull,
            reason:
                'Mobile-viewport story must pump without exceptions per '
                'SPEC/ui/mobile-adaptation.md § 6 and the Widgetbook AC in '
                'SPEC/ui/map-widget.md.',
          );
        },
      );
    },
  );
}
