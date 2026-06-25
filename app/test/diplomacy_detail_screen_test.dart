import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_game_feature_screen_shell.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await preloadNinePatchImage();
  });

  Game minimalGame({
    required String humanPlayerId,
    required String otherFactionId,
    required DiplomaticEventType eventType,
    required bool includeHistory,
    required bool includeDossier,
    required bool atWar,
    int score = 70,
    bool formalAlliance = false,
  }) {
    final otherPlayer = Player(
      id: otherFactionId,
      displayName: 'Other GP',
      isHuman: false,
      treasury: 0,
    );

    final humanPlayer = Player(
      id: humanPlayerId,
      displayName: 'Human GP',
      isHuman: true,
      treasury: 0,
    );

    final relation = DiplomacyRelation(
      factionId1: humanPlayerId,
      factionId2: otherFactionId,
      score: score,
      state: atWar ? RelationState.atWar : RelationState.atPeace,
      formalAlliance: formalAlliance,
    );

    return Game(
      id: 'test',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      turnTimeMapping: TurnTimeMapping.gdd01,
      players: [humanPlayer, otherPlayer],
      diplomacyRelations: [relation],
      diplomaticHistoryEvents: includeHistory
          ? [
              DiplomaticEvent(
                turn: 2,
                intraTurnIndex: 0,
                type: eventType,
                participants: {humanPlayerId, otherFactionId},
                fromFactionId: humanPlayerId,
                toFactionId: otherFactionId,
              ),
            ]
          : const [],
      dossierEvidenceEntries: includeDossier
          ? [
              DossierEvidenceEntry(
                observerId: humanPlayerId,
                subjectId: otherFactionId,
                agendaType: 'test_agenda',
                turnNumber: 3,
                description: 'evidence-1',
              ),
            ]
          : const [],
    );
  }

  testWidgets('DiplomacyDetailScreen shows dossier header for great powers', (
    WidgetTester tester,
  ) async {
    // Refs #3656: lightweight gp1/gp2 fixture replaces the ~7-11s
    // getDebugInitGameResult(); the detail screen only reads players, relations,
    // history, and dossier entries — no generated map/topology data.
    final game = minimalGame(
      humanPlayerId: 'gp1',
      otherFactionId: 'gp2',
      eventType: DiplomaticEventType.peace,
      includeHistory: false,
      includeDossier: false,
      atWar: false,
    );
    final humanPlayerId = game.players.first.id;

    final otherPlayer =
        game.players.where((p) => p.id != humanPlayerId).firstOrNull ??
        game.players.first;
    final factionId = otherPlayer.id;
    final relation = getRelation(game, humanPlayerId, factionId);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: DiplomacyDetailScreen(
            game: game,
            humanPlayerId: humanPlayerId,
            factionId: factionId,
            factionDisplayName: otherPlayer.displayName,
            kind: FactionKind.greatPower,
            relation: relation,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
    expect(find.text('DOSSIER'), findsOneWidget);
    expect(find.textContaining('No dossier evidence yet.'), findsOneWidget);
  });

  testWidgets(
    'DiplomacyDetailScreen renders either empty or non-empty history',
    (WidgetTester tester) async {
      final game = minimalGame(
        humanPlayerId: 'gp1',
        otherFactionId: 'gp2',
        eventType: DiplomaticEventType.peace,
        includeHistory: false,
        includeDossier: false,
        atWar: false,
      );
      final humanPlayerId = game.players.first.id;

      final allFactionIds = <String>[
        ...game.players.map((p) => p.id),
        ...game.minorNations.map((m) => m.id),
        ...game.tribes.map((t) => t.id),
      ].where((id) => id != humanPlayerId).toList();

      String? nonEmptyHistoryFactionId;
      for (final id in allFactionIds) {
        final history = diplomaticHistoryForPair(game, humanPlayerId, id);
        if (history.isNotEmpty) {
          nonEmptyHistoryFactionId = id;
          break;
        }
      }

      final chosenFactionId = nonEmptyHistoryFactionId ?? allFactionIds.first;
      final history = diplomaticHistoryForPair(
        game,
        humanPlayerId,
        chosenFactionId,
      );
      final relation = getRelation(game, humanPlayerId, chosenFactionId);

      String displayNameFor(String id) {
        final p = game.playerById(id);
        if (p != null) return p.displayName;
        for (final m in game.minorNations) {
          if (m.id == id) return m.displayName ?? m.id;
        }
        for (final t in game.tribes) {
          if (t.id == id) return t.displayName ?? t.id;
        }
        return id;
      }

      FactionKind kindFor(String id) {
        if (game.players.any((p) => p.id == id)) return FactionKind.greatPower;
        if (game.minorNations.any((m) => m.id == id)) return FactionKind.minor;
        return FactionKind.tribe;
      }

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: chosenFactionId,
              factionDisplayName: displayNameFor(chosenFactionId),
              kind: kindFor(chosenFactionId),
              relation: relation,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      if (history.isEmpty) {
        expect(
          find.text('No recorded events with this faction.'),
          findsOneWidget,
        );
      } else {
        // History rows are no longer Material Card widgets — they are the
        // mockup `.event` chrome (left-bordered tiles) introduced by
        // Refs #2863 S5. Verify at least one formatted event sentence
        // renders instead so the assertion stays meaningful without
        // coupling to the private tile widget type.
        final formatted = formatDiplomaticEvent(
          history.first,
          game,
          humanPlayerId,
        );
        expect(find.text(formatted), findsOneWidget);
      }
    },
  );

  testWidgets(
    'DiplomacyDetailScreen hides Dossier when kind != greatPower and relation is null (empty history)',
    (WidgetTester tester) async {
      final game = minimalGame(
        humanPlayerId: 'gp1',
        otherFactionId: 'gp2',
        eventType: DiplomaticEventType.peace,
        includeHistory: false,
        includeDossier: false,
        atWar: false,
      );
      final humanPlayerId = game.players.first.id;

      final allFactionIds = <String>[
        ...game.players.map((p) => p.id),
        ...game.minorNations.map((m) => m.id),
        ...game.tribes.map((t) => t.id),
      ].where((id) => id != humanPlayerId).toList();

      String factionId = allFactionIds.first;
      for (final id in allFactionIds) {
        final history = diplomaticHistoryForPair(game, humanPlayerId, id);
        if (history.isEmpty) {
          factionId = id;
          break;
        }
      }

      String displayNameFor(String id) {
        final p = game.playerById(id);
        if (p != null) return p.displayName;
        for (final m in game.minorNations) {
          if (m.id == id) return m.displayName ?? m.id;
        }
        for (final t in game.tribes) {
          if (t.id == id) return t.displayName ?? t.id;
        }
        return id;
      }

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: factionId,
              factionDisplayName: displayNameFor(factionId),
              kind: FactionKind.minor,
              relation: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text('DOSSIER'), findsNothing);
      expect(
        find.text('No recorded events with this faction.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'DiplomacyDetailScreen renders non-empty history and dossier entries',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const otherFactionId = 'gp2';

      final game = minimalGame(
        humanPlayerId: humanPlayerId,
        otherFactionId: otherFactionId,
        eventType: DiplomaticEventType.declareWar,
        includeHistory: true,
        includeDossier: true,
        atWar: true,
      );

      final relation = getRelation(game, humanPlayerId, otherFactionId);
      expect(relation, isNotNull);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: otherFactionId,
              factionDisplayName: 'Other GP',
              kind: FactionKind.greatPower,
              relation: relation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text('DOSSIER'), findsOneWidget);
      expect(find.textContaining('Turn 3:'), findsOneWidget);
      expect(find.textContaining('evidence-1'), findsOneWidget);
      expect(find.textContaining('declared war'), findsOneWidget);
      expect(find.textContaining('War'), findsOneWidget);
    },
  );

  testWidgets('DiplomacyDetailScreen renders empty history (minimal game)', (
    WidgetTester tester,
  ) async {
    const humanPlayerId = 'gp1';
    const otherFactionId = 'gp2';

    final game = minimalGame(
      humanPlayerId: humanPlayerId,
      otherFactionId: otherFactionId,
      eventType: DiplomaticEventType.peace,
      includeHistory: false,
      includeDossier: false,
      atWar: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: DiplomacyDetailScreen(
            game: game,
            humanPlayerId: humanPlayerId,
            factionId: otherFactionId,
            factionDisplayName: 'Other GP',
            kind: FactionKind.greatPower,
            relation: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
    expect(find.text('DOSSIER'), findsOneWidget);
    expect(find.text('No dossier evidence yet.'), findsOneWidget);
    expect(find.text('No recorded events with this faction.'), findsOneWidget);
  });

  testWidgets(
    'DiplomacyDetailScreen shows Peace (relation present) and hides Dossier for non-GP kind',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const otherFactionId = 'gp2';

      final game = minimalGame(
        humanPlayerId: humanPlayerId,
        otherFactionId: otherFactionId,
        eventType: DiplomaticEventType.peace,
        includeHistory: false,
        includeDossier: false,
        atWar: false,
      );

      final relation = getRelation(game, humanPlayerId, otherFactionId);
      expect(relation, isNotNull);
      expect(relation!.atWar, isFalse);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: otherFactionId,
              factionDisplayName: 'Other GP',
              kind: FactionKind.minor,
              relation: relation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text('DOSSIER'), findsNothing);
      expect(
        find.text('No recorded events with this faction.'),
        findsOneWidget,
      );
      expect(find.textContaining('Peace'), findsOneWidget);
    },
  );

  testWidgets(
    'DiplomacyDetailScreen shows Great Power Dossier empty-state when no evidence exists',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const otherFactionId = 'gp2';

      final game = minimalGame(
        humanPlayerId: humanPlayerId,
        otherFactionId: otherFactionId,
        eventType: DiplomaticEventType.declareWar,
        includeHistory: false,
        includeDossier: false,
        atWar: false,
      );

      final relation = getRelation(game, humanPlayerId, otherFactionId);
      expect(relation, isNotNull);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: otherFactionId,
              factionDisplayName: 'Other GP',
              kind: FactionKind.greatPower,
              relation: relation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text('DOSSIER'), findsOneWidget);
      expect(
        find.text('No recorded events with this faction.'),
        findsOneWidget,
      );
      expect(find.text('No dossier evidence yet.'), findsOneWidget);
      expect(find.textContaining('Peace'), findsOneWidget);
    },
  );

  testWidgets(
    'DiplomacyDetailScreen renders non-empty history with empty Dossier (great power)',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const otherFactionId = 'gp2';

      final game = minimalGame(
        humanPlayerId: humanPlayerId,
        otherFactionId: otherFactionId,
        eventType: DiplomaticEventType.declareWar,
        includeHistory: true,
        includeDossier: false,
        atWar: true,
      );

      final relation = getRelation(game, humanPlayerId, otherFactionId);
      expect(relation, isNotNull);
      expect(relation!.atWar, isTrue);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: otherFactionId,
              factionDisplayName: 'Other GP',
              kind: FactionKind.greatPower,
              relation: relation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text('DOSSIER'), findsOneWidget);
      expect(find.textContaining('declared war'), findsOneWidget);
      expect(find.textContaining('War'), findsOneWidget);
      expect(find.text('No dossier evidence yet.'), findsOneWidget);
    },
  );

  testWidgets(
    'DiplomacyDetailScreen falls back to "Unknown faction" for events with unknown relation pairs',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const unknownFactionId = 'minorX';

      final game = Game(
        id: 'test-unknown',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        turnTimeMapping: TurnTimeMapping.gdd01,
        players: [
          Player(
            id: humanPlayerId,
            displayName: 'Human GP',
            isHuman: true,
            treasury: 0,
          ),
        ],
        diplomacyRelations: const [],
        diplomaticHistoryEvents: [
          DiplomaticEvent(
            turn: 2,
            intraTurnIndex: 0,
            type: DiplomaticEventType.declareWar,
            participants: {humanPlayerId, unknownFactionId},
            fromFactionId: humanPlayerId,
            toFactionId: unknownFactionId,
          ),
        ],
        dossierEvidenceEntries: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: unknownFactionId,
              factionDisplayName: 'Unknown Faction',
              kind: FactionKind.minor,
              relation: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.textContaining('Unknown faction'), findsOneWidget);
      expect(find.textContaining('declared war'), findsOneWidget);
    },
  );

  // ----- Refs #2863 S5: GAME30002 dark-theme chrome assertions -----

  testWidgets(
    'DiplomacyDetailScreen renders dark editorial-monocle chrome '
    '(CtTopBar + scaffold bg) per Refs #2863 S5',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const otherFactionId = 'gp2';
      final game = minimalGame(
        humanPlayerId: humanPlayerId,
        otherFactionId: otherFactionId,
        eventType: DiplomaticEventType.peace,
        includeHistory: false,
        includeDossier: false,
        atWar: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: otherFactionId,
              factionDisplayName: 'Other GP',
              kind: FactionKind.greatPower,
              relation: getRelation(game, humanPlayerId, otherFactionId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
    },
  );

  testWidgets(
    'DiplomacyDetailScreen emits exactly one PopNavigationEvent when the '
    'CtTopBar back button is tapped per Refs #2863 S5',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const otherFactionId = 'gp2';
      final game = minimalGame(
        humanPlayerId: humanPlayerId,
        otherFactionId: otherFactionId,
        eventType: DiplomaticEventType.peace,
        includeHistory: false,
        includeDossier: false,
        atWar: false,
      );

      final AppEventBus bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final List<PopNavigationEvent> popEvents = <PopNavigationEvent>[];
      final sub = bus.on<PopNavigationEvent>().listen(popEvents.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appEventBusProvider.overrideWith((ref) => bus)],
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: otherFactionId,
              factionDisplayName: 'Other GP',
              kind: FactionKind.greatPower,
              relation: getRelation(game, humanPlayerId, otherFactionId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(popEvents, isEmpty);
      await tester.tap(find.byType(CtBackButton));
      await tester.pump();
      expect(popEvents, hasLength(1));
    },
  );

  testWidgets(
    'DiplomacyDetailScreen Current relation card shows War label '
    'in --danger colour per mockup GAME30002 .relation-row .war',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const otherFactionId = 'gp2';
      final game = minimalGame(
        humanPlayerId: humanPlayerId,
        otherFactionId: otherFactionId,
        eventType: DiplomaticEventType.declareWar,
        includeHistory: false,
        includeDossier: false,
        atWar: true,
      );
      final relation = getRelation(game, humanPlayerId, otherFactionId);
      expect(relation, isNotNull);
      expect(relation!.atWar, isTrue);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: otherFactionId,
              factionDisplayName: 'Other GP',
              kind: FactionKind.greatPower,
              relation: relation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      final Text war = tester.widget(find.text('War'));
      expect(war.style?.color, EditorialMonoclePalette.danger);
    },
  );

  testWidgets(
    'DiplomacyDetailScreen Current relation card shows Peace label '
    'in --success colour per mockup GAME30002 .relation-row .state',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const otherFactionId = 'gp2';
      final game = minimalGame(
        humanPlayerId: humanPlayerId,
        otherFactionId: otherFactionId,
        eventType: DiplomaticEventType.peace,
        includeHistory: false,
        includeDossier: false,
        atWar: false,
      );
      final relation = getRelation(game, humanPlayerId, otherFactionId);
      expect(relation, isNotNull);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: otherFactionId,
              factionDisplayName: 'Other GP',
              kind: FactionKind.greatPower,
              relation: relation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      final Text peace = tester.widget(find.text('Peace'));
      expect(peace.style?.color, EditorialMonoclePalette.success);
    },
  );

  // ----- Refs #3625 AC4: formal-alliance treaty indicator on GAME30002 -----

  testWidgets(
    'DiplomacyDetailScreen Current relation card shows the ALLIANCE badge '
    'in --accent for a formal alliance (Refs #3625 AC4)',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const otherFactionId = 'gp2';
      final game = minimalGame(
        humanPlayerId: humanPlayerId,
        otherFactionId: otherFactionId,
        eventType: DiplomaticEventType.allianceFormed,
        includeHistory: false,
        includeDossier: false,
        atWar: false,
        score: 90,
        formalAlliance: true,
      );
      final relation = getRelation(game, humanPlayerId, otherFactionId);
      expect(relation, isNotNull);
      expect(relation!.formalAlliance, isTrue);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: otherFactionId,
              factionDisplayName: 'Other GP',
              kind: FactionKind.greatPower,
              relation: relation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      final Finder badge = find.text(kDiplomacyAllianceBadgeLabel);
      expect(badge, findsOneWidget);
      final Text badgeText = tester.widget<Text>(badge);
      expect(badgeText.style?.color, EditorialMonoclePalette.accent);
      // The treaty marker is distinct from the one-word relation label.
      expect(kDiplomacyAllianceBadgeLabel, isNot('Friendly'));
    },
  );

  testWidgets(
    'DiplomacyDetailScreen Current relation card omits the ALLIANCE badge '
    'for the informal Allied band without a treaty (Refs #3625 AC4 negative)',
    (WidgetTester tester) async {
      const humanPlayerId = 'gp1';
      const otherFactionId = 'gp2';
      final game = minimalGame(
        humanPlayerId: humanPlayerId,
        otherFactionId: otherFactionId,
        eventType: DiplomaticEventType.peace,
        includeHistory: false,
        includeDossier: false,
        atWar: false,
        score: 90,
        formalAlliance: false,
      );
      final relation = getRelation(game, humanPlayerId, otherFactionId);
      expect(relation, isNotNull);
      expect(relation!.formalAlliance, isFalse);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiplomacyDetailScreen(
              game: game,
              humanPlayerId: humanPlayerId,
              factionId: otherFactionId,
              factionDisplayName: 'Other GP',
              kind: FactionKind.greatPower,
              relation: relation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.text(kDiplomacyAllianceBadgeLabel), findsNothing);
      // The informal high-relation row still shows the one-word label.
      expect(find.textContaining('Friendly'), findsOneWidget);
    },
  );
}
