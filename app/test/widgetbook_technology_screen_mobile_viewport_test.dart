// Widget test pin for the `Tech Tree` → `Mid-game slots (mobile)` Widgetbook
// use case under `app/lib/widgetbook/catalog_part2.dart`.
//
// Pins three SPEC contracts (Refs #2870 R22 / S9):
//
//  1. The use case is wired into the public `techTreeDirectories` getter
//     under the canonical folder + name.
//  2. The builder pumps without exceptions inside the shared `mobileViewport`
//     (360 × 640 dp `MediaQuery.size`) frame, per `SPEC/ui/mobile-adaptation.md`
//     § 6 and `SPEC/ui/technology-panel.md` § Widgetbook.
//  3. The Slots-tab scroll host and four slot cards render at 360 dp so the
//     narrow vertical-scroll contract from `SPEC/ui/mobile-adaptation.md` § 7
//     remains reviewable in Widgetbook without window resizing.

import 'package:colonizethis_app/features/game/screens/technology_screen.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/widgetbook/catalog.dart';

import 'support/panel_test_fixtures.dart';

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

  late Game baseGame;

  setUpAll(() {
    // Refs #3656: lightweight hand-built fixture replaces the ~11s procedural
    // map generation of getDebugInitGameResult(). The Technology screen reads
    // only game.players + the static techCatalog, so the Slots tab renders its
    // three active slot cards plus the locked University slot without any
    // generated map/topology data.
    //
    // The game id and human player id match the Widgetbook mid-game story
    // (kWidgetbookTechnologyStoryGameId / kPanelTestHumanPlayerId): because
    // CtGameFeatureScreenShell renders the live currentGameProvider game when
    // its id matches the screen's game.id, this fixture's fresh player (no
    // researched techs) is the one rendered — mirroring the previous debug-init
    // first-player render and keeping the Slots tab free of the wide
    // researched-tech chips that overflow a 360 dp viewport.
    baseGame = buildPanelTestGame(
      id: kWidgetbookTechnologyStoryGameId,
      players: [panelTestHumanPlayer()],
    );
    expect(baseGame.players, isNotEmpty);
  });

  group(
    'Technology screen Widgetbook mobile-viewport story (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'Mid-game slots (mobile) is wired into techTreeDirectories under the '
        'canonical folder + name',
        (WidgetTester tester) async {
          final useCase = _useCase(
            techTreeDirectories,
            folderName: 'Tech Tree',
            useCaseName: 'Mid-game slots (mobile)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Mid-game slots (mobile) builder pumps at 360 × 640 dp without '
        'exceptions and mounts the Slots scroll host',
        (WidgetTester tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(360, 640));

          final useCase = _useCase(
            techTreeDirectories,
            folderName: 'Tech Tree',
            useCaseName: 'Mid-game slots (mobile)',
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                currentGameProvider.overrideWith(
                  () => CurrentGameNotifier(baseGame),
                ),
                currentOrdersProvider.overrideWith(
                  () => CurrentOrdersNotifier(const Orders()),
                ),
                appEventBusProvider.overrideWith((ref) {
                  final bus = AppEventBus.create();
                  ref.onDispose(bus.dispose);
                  return bus;
                }),
              ],
              child: MediaQuery(
                data: const MediaQueryData(size: Size(360, 640)),
                child: Builder(
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
                'Mobile-viewport Technology screen story must pump without '
                'exceptions per SPEC/ui/mobile-adaptation.md § 6.',
          );
          expect(find.byType(TechnologyScreen), findsOneWidget);
          expect(find.byType(SingleChildScrollView), findsOneWidget);
          // Lightweight fixture player (researchSlots null -> default 3):
          // three active slots + locked slot 4 (University).
          expect(find.byType(ResearchSlotCard), findsNWidgets(3));
          expect(find.byType(LockedResearchSlotCard), findsOneWidget);
        },
      );
    },
  );
}
