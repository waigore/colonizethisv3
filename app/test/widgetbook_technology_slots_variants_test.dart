// Widgetbook story regression test for the three Slots-tab variants added
// to the `Tech Tree` folder by #2864 S5. Each variant mirrors the
// `SPEC/ui/mockups/GAME40001-technology-panel.html` mockup branches:
//
//   * "Slots — default (3 slots, 4th locked)" — three active slot cards plus
//     a dimmed `Slot 4 (University)` locked placeholder.
//   * "Slots — all 4 slots active" — four active slot cards.
//   * "Slots — no researchable techs" — every tech already unlocked so the
//     Choose-tech list collapses to the muted empty-state line.
//
// The test pumps the same `(Player, Game)` fixtures the Widgetbook story
// builders use (seeded here from the lightweight `buildTechnologyPanelTestGame`
// fixture (Refs #3656), `techCatalog`, and `Player.copyWith` APIs so the story
// file does not need to expose private helpers). Each variant must:
//
//   * render under `AppThemes.editorialMonocle`,
//   * not throw during pump + settle,
//   * surface the expected slot-card counts per SPEC § Slot behaviour.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/technology_screen.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Game baseGame;
  late Player basePlayer;
  late List<String> allTechIds;

  setUpAll(() {
    baseGame = buildTechnologyPanelTestGame();
    basePlayer = baseGame.players.first;
    allTechIds = techCatalog.keys.toList()..sort();
  });

  /// Returns the fixture seeded by `_TechnologySlotsStoryVariant
  /// .threeActiveFourthLocked`: half the tech catalog unlocked, one tech in
  /// progress, `researchSlots = 3`.
  (Player, Game) threeActiveFourthLockedFixture() {
    final half = (allTechIds.length / 2).floor();
    final unlocked = Map<String, bool>.fromEntries(
      allTechIds.take(half).map((id) => MapEntry(id, true)),
    );
    final inProgressId = allTechIds.length > half ? allTechIds[half] : null;
    final progress = inProgressId != null
        ? <String, int>{inProgressId: 60}
        : <String, int>{};
    final player = basePlayer.copyWith(
      techUnlocked: unlocked,
      researchProgressByTechId: progress,
      researchSlots: 3,
    );
    final game = baseGame.copyWith(
      players: [player, ...baseGame.players.skip(1)],
    );
    return (player, game);
  }

  /// Returns the fixture seeded by `_TechnologySlotsStoryVariant.allFourActive`:
  /// same mid-game unlock + progress, but `researchSlots = 4`.
  (Player, Game) allFourActiveFixture() {
    final half = (allTechIds.length / 2).floor();
    final unlocked = Map<String, bool>.fromEntries(
      allTechIds.take(half).map((id) => MapEntry(id, true)),
    );
    final inProgressId = allTechIds.length > half ? allTechIds[half] : null;
    final progress = inProgressId != null
        ? <String, int>{inProgressId: 60}
        : <String, int>{};
    final player = basePlayer.copyWith(
      techUnlocked: unlocked,
      researchProgressByTechId: progress,
      researchSlots: 4,
    );
    final game = baseGame.copyWith(
      players: [player, ...baseGame.players.skip(1)],
    );
    return (player, game);
  }

  /// Returns the fixture seeded by `_TechnologySlotsStoryVariant
  /// .noResearchableTechs`: every tech in `techUnlocked`, `researchSlots = 3`.
  (Player, Game) noResearchableTechsFixture() {
    final unlocked = Map<String, bool>.fromEntries(
      allTechIds.map((id) => MapEntry(id, true)),
    );
    final player = basePlayer.copyWith(
      techUnlocked: unlocked,
      researchSlots: 3,
    );
    final game = baseGame.copyWith(
      players: [player, ...baseGame.players.skip(1)],
    );
    return (player, game);
  }

  Widget host({
    required Game game,
    required Player player,
    double width = 900,
    double height = 700,
  }) {
    return ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(
          () => CurrentGameNotifier(game),
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
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.editorialMonocle,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: TechnologyScreen(game: game, player: player),
        ),
      ),
    );
  }

  group(
    'Tech Tree Widgetbook story variants (Refs #2864 S5)',
    () {
      testWidgets(
        'Slots — default (3 slots, 4th locked) renders 3 active + 1 locked card',
        (tester) async {
          final (player, game) = threeActiveFourthLockedFixture();
          await tester.pumpWidget(host(game: game, player: player));
          await pumpSettleCapped(tester);

          expect(tester.takeException(), isNull);
          expect(find.byType(ResearchSlotCard), findsNWidgets(3));
          expect(find.byType(LockedResearchSlotCard), findsOneWidget);
          expect(find.text('Slot 4 (University)'), findsOneWidget);
          // SPEC § Slot behaviour: locked card carries the muted footnote.
          expect(find.text('Requires University tech'), findsOneWidget);

          final BuildContext ctx = tester.element(find.byType(Scaffold).first);
          expect(Theme.of(ctx).brightness, Brightness.dark);
        },
      );

      testWidgets(
        'Slots — all 4 active renders 4 active cards (no locked placeholder)',
        (tester) async {
          final (player, game) = allFourActiveFixture();
          await tester.pumpWidget(host(game: game, player: player));
          await pumpSettleCapped(tester);

          expect(tester.takeException(), isNull);
          expect(find.byType(ResearchSlotCard), findsNWidgets(4));
          expect(find.byType(LockedResearchSlotCard), findsNothing);
          // SPEC § Slot behaviour: active slot label is "Slot 4" (no
          // University footnote) once researchSlots >= 4.
          expect(find.text('Slot 4'), findsOneWidget);
          expect(find.text('Slot 4 (University)'), findsNothing);
          expect(find.text('Requires University tech'), findsNothing);

          final BuildContext ctx = tester.element(find.byType(Scaffold).first);
          expect(Theme.of(ctx).brightness, Brightness.dark);
        },
      );

      testWidgets(
        'Slots — no researchable techs renders 3 active cards with no choosable techs',
        (tester) async {
          final (player, game) = noResearchableTechsFixture();
          await tester.pumpWidget(host(game: game, player: player));
          await pumpSettleCapped(tester);

          expect(tester.takeException(), isNull);
          // SPEC § Slot behaviour: structure is unchanged — 3 active + 1
          // locked even when no techs are researchable.
          expect(find.byType(ResearchSlotCard), findsNWidgets(3));
          expect(find.byType(LockedResearchSlotCard), findsOneWidget);

          // SPEC § Choose-tech dialog: `researchableTechIds` is empty when
          // every tech is in `techUnlocked`, so no slot has an assigned
          // tech and the Choose-tech dialog (not opened here) would show
          // the muted empty-state line. Cross-check the underlying logic.
          final researchable = researchableTechIds(
            player.techUnlocked,
            hasDiscoveredResource: (r) =>
                hasRevealedResourceForPlayer(game, player.id, r),
          );
          expect(researchable, isEmpty);

          final BuildContext ctx = tester.element(find.byType(Scaffold).first);
          expect(Theme.of(ctx).brightness, Brightness.dark);
        },
      );
    },
  );
}
