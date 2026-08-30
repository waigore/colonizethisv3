// Diplomacy detail (GAME30002) widget coverage. Shared local pump +
// minimalGame helpers densify near-cap fixtures (Refs #4021).
//
// SPEC: SPEC/ui/diplomacy-detail-screen.md (history/dossier/relation chrome).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_game_feature_screen_shell.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_assets.dart';
import 'diplomacy_detail_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await preloadNinePatchImage();
  });

  testWidgets(
    'DiplomacyDetailScreen renders either empty or non-empty history',
    (WidgetTester tester) async {
      final game = diplomacyDetailMinimalGame();
      final allFactionIds = diplomacyDetailOtherFactionIds(game);
      String? nonEmptyHistoryFactionId;
      for (final id in allFactionIds) {
        if (diplomaticHistoryForPair(
          game,
          diplomacyDetailHumanId,
          id,
        ).isNotEmpty) {
          nonEmptyHistoryFactionId = id;
          break;
        }
      }
      final chosenFactionId = nonEmptyHistoryFactionId ?? allFactionIds.first;
      final history = diplomaticHistoryForPair(
        game,
        diplomacyDetailHumanId,
        chosenFactionId,
      );
      await pumpDiplomacyDetail(
        tester,
        game: game,
        factionId: chosenFactionId,
        factionDisplayName: diplomacyDetailDisplayNameFor(
          game,
          chosenFactionId,
        ),
        kind: diplomacyDetailKindFor(game, chosenFactionId),
        relation: getRelation(game, diplomacyDetailHumanId, chosenFactionId),
      );
      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      if (history.isEmpty) {
        expect(
          find.text('No recorded events with this faction.'),
          findsOneWidget,
        );
      } else {
        expect(
          find.text(
            formatDiplomaticEvent(history.first, game, diplomacyDetailHumanId),
          ),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'DiplomacyDetailScreen hides Dossier when kind != greatPower and relation is null (empty history)',
    (WidgetTester tester) async {
      final game = diplomacyDetailMinimalGame();
      final allFactionIds = diplomacyDetailOtherFactionIds(game);
      var factionId = allFactionIds.first;
      for (final id in allFactionIds) {
        if (diplomaticHistoryForPair(
          game,
          diplomacyDetailHumanId,
          id,
        ).isEmpty) {
          factionId = id;
          break;
        }
      }
      await pumpDiplomacyDetail(
        tester,
        game: game,
        factionId: factionId,
        factionDisplayName: diplomacyDetailDisplayNameFor(game, factionId),
        kind: FactionKind.minor,
        relation: null,
      );
      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text('DOSSIER'), findsNothing);
      expect(
        find.text('No recorded events with this faction.'),
        findsOneWidget,
      );
    },
  );

  group('history / dossier matrix (GAME30002)', () {
    for (final c
        in <
          ({
            String name,
            Game Function() game,
            FactionKind kind,
            bool useRelation,
            List<DiplomacyDetailPin> pins,
          })
        >[
          (
            name: 'GP shows dossier header and empty evidence',
            game: diplomacyDetailMinimalGame,
            kind: FactionKind.greatPower,
            useRelation: true,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsOneWidget),
              (find.textContaining('No dossier evidence yet.'), findsOneWidget),
            ],
          ),
          (
            name: 'GP empty history when relation is null',
            game: diplomacyDetailMinimalGame,
            kind: FactionKind.greatPower,
            useRelation: false,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsOneWidget),
              (find.text('No dossier evidence yet.'), findsOneWidget),
              (
                find.text('No recorded events with this faction.'),
                findsOneWidget,
              ),
            ],
          ),
          (
            name: 'non-GP with relation shows Peace and hides Dossier',
            game: diplomacyDetailMinimalGame,
            kind: FactionKind.minor,
            useRelation: true,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsNothing),
              (
                find.text('No recorded events with this faction.'),
                findsOneWidget,
              ),
              (find.textContaining('Peace'), findsOneWidget),
            ],
          ),
          (
            name: 'GP empty-state dossier when no evidence exists',
            game: () => diplomacyDetailMinimalGame(
              eventType: DiplomaticEventType.declareWar,
            ),
            kind: FactionKind.greatPower,
            useRelation: true,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsOneWidget),
              (
                find.text('No recorded events with this faction.'),
                findsOneWidget,
              ),
              (find.text('No dossier evidence yet.'), findsOneWidget),
              (find.textContaining('Peace'), findsOneWidget),
            ],
          ),
          (
            name: 'GP non-empty history + dossier at war',
            game: () => diplomacyDetailMinimalGame(
              eventType: DiplomaticEventType.declareWar,
              includeHistory: true,
              includeDossier: true,
              atWar: true,
            ),
            kind: FactionKind.greatPower,
            useRelation: true,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsOneWidget),
              (find.textContaining('Turn 3:'), findsOneWidget),
              (find.textContaining('evidence-1'), findsOneWidget),
              (find.textContaining('declared war'), findsOneWidget),
              (find.textContaining('War'), findsOneWidget),
            ],
          ),
          (
            name: 'GP non-empty history with empty Dossier at war',
            game: () => diplomacyDetailMinimalGame(
              eventType: DiplomaticEventType.declareWar,
              includeHistory: true,
              atWar: true,
            ),
            kind: FactionKind.greatPower,
            useRelation: true,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsOneWidget),
              (find.textContaining('declared war'), findsOneWidget),
              (find.textContaining('War'), findsOneWidget),
              (find.text('No dossier evidence yet.'), findsOneWidget),
            ],
          ),
        ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        final game = c.game();
        final relation = c.useRelation
            ? getRelation(game, diplomacyDetailHumanId, diplomacyDetailOtherId)
            : null;
        await pumpDiplomacyDetailOtherGp(
          tester,
          game: game,
          kind: c.kind,
          relation: relation,
        );
        for (final (finder, matcher) in c.pins) {
          expect(finder, matcher);
        }
      });
    }
  });

  testWidgets(
    'DiplomacyDetailScreen falls back to "Unknown faction" for events with unknown relation pairs',
    (WidgetTester tester) async {
      await pumpDiplomacyDetail(
        tester,
        game: diplomacyDetailUnknownFactionGame(),
        factionId: diplomacyDetailUnknownFactionId,
        factionDisplayName: 'Unknown Faction',
        kind: FactionKind.minor,
        relation: null,
      );
      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.textContaining('Unknown faction'), findsOneWidget);
      expect(find.textContaining('declared war'), findsOneWidget);
    },
  );

  testWidgets('DiplomacyDetailScreen renders dark editorial-monocle chrome '
      '(CtTopBar + scaffold bg) per Refs #2863 S5', (
    WidgetTester tester,
  ) async {
    final game = diplomacyDetailMinimalGame();
    await pumpDiplomacyDetailOtherGp(
      tester,
      game: game,
      relation: getRelation(
        game,
        diplomacyDetailHumanId,
        diplomacyDetailOtherId,
      ),
    );
    expect(find.byType(CtTopBar), findsOneWidget);
    expect(find.byType(CtBackButton), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(CtGameFeatureScreenShell), findsOneWidget);
    final CtGameFeatureScreenShell shell = tester.widget(
      find.byType(CtGameFeatureScreenShell),
    );
    expect(shell.backgroundColor, EditorialMonoclePalette.bg);
    expect(shell.attachGameToUiListener, isFalse);
    final Scaffold scaffold = tester.widget(find.byType(Scaffold));
    expect(scaffold.backgroundColor, EditorialMonoclePalette.bg);
  });

  testWidgets(
    'DiplomacyDetailScreen emits exactly one PopNavigationEvent when the '
    'CtTopBar back button is tapped per Refs #2863 S5',
    (WidgetTester tester) async {
      final game = diplomacyDetailMinimalGame();
      final AppEventBus bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final List<PopNavigationEvent> popEvents = <PopNavigationEvent>[];
      final sub = bus.on<PopNavigationEvent>().listen(popEvents.add);
      addTearDown(sub.cancel);
      await pumpDiplomacyDetailOtherGp(
        tester,
        overrides: [appEventBusProvider.overrideWith((ref) => bus)],
        game: game,
        relation: getRelation(
          game,
          diplomacyDetailHumanId,
          diplomacyDetailOtherId,
        ),
      );
      expect(popEvents, isEmpty);
      await tester.tap(find.byType(CtBackButton));
      await tester.pump();
      expect(popEvents, hasLength(1));
    },
  );
}
