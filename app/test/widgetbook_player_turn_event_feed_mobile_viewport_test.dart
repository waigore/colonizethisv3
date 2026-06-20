// Widget test pin for the `Player Turn Event Feed Card` → `Mobile viewport`
// Widgetbook use case under `app/lib/widgetbook/catalog_part7.dart`.
//
// Pins two SPEC contracts (Refs #2870 R22 / S9):
//
//  1. The use case is wired into the public
//     `playerTurnEventFeedCardDirectories` getter under the canonical folder
//     + name (so renaming or removing it surfaces here in CI before reviewers
//     lose the mobile-viewport story for the in-game news feed card).
//  2. The builder pumps without exceptions inside the shared `mobileViewport`
//     (360 × 640 dp `MediaQuery.size`) frame and mounts the narrow
//     `PlayerTurnEventFeedCard` surface per
//     `SPEC/ui/player-turn-event-feed.md` § Card chrome — narrow layout and
//     `SPEC/ui/mobile-adaptation.md` § 6.

import 'package:colonizethis_app/features/game/widgets/player_turn_event_feed.dart';
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

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Player Turn Event Feed Card Widgetbook mobile-viewport story '
    '(Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'Mobile viewport is wired into playerTurnEventFeedCardDirectories',
        (WidgetTester tester) async {
          final useCase = _useCase(
            playerTurnEventFeedCardDirectories,
            folderName: 'Player Turn Event Feed Card',
            useCaseName: 'Mobile viewport',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Mobile viewport builder pumps at 360 × 640 dp without exceptions '
        'and mounts narrow card surface',
        (WidgetTester tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(360, 640));

          final useCase = _useCase(
            playerTurnEventFeedCardDirectories,
            folderName: 'Player Turn Event Feed Card',
            useCaseName: 'Mobile viewport',
          );

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(size: Size(360, 640)),
              child: Builder(
                builder: (BuildContext ctx) => useCase.builder(ctx),
              ),
            ),
          );
          await tester.pumpAndSettle(const Duration(milliseconds: 200));

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 6: the Player Turn Event '
                'Feed Card mobile Widgetbook story must pump inside the '
                '360 × 640 dp frame without overflow.',
          );
          expect(find.byKey(PlayerTurnEventFeedCard.surfaceKey), findsOneWidget);
          expect(find.textContaining('Castile completed Castle'), findsOneWidget);
        },
      );
    },
  );
}
