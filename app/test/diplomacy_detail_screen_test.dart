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
