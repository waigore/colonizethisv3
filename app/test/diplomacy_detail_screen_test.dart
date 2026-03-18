import 'package:colonizethis_app/features/game/widgets/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Game _minimalGame({
    required String humanPlayerId,
    required String otherFactionId,
    required DiplomaticEventType eventType,
    required bool includeHistory,
    required bool includeDossier,
    required bool atWar,
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
      score: 70,
      state: atWar ? RelationState.atWar : RelationState.atPeace,
    );

    return Game(
      id: 'test',
      worldState: WorldState(
        turnState: TurnState(
          phase: TurnPhase.orders,
          turnNumber: 1,
        ),
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

  testWidgets('DiplomacyDetailScreen shows dossier header for great powers',
      (WidgetTester tester) async {
    final game = getDebugInitGameResult().game;
    final humanPlayerId = game.players.first.id;

    final otherPlayer = game.players.where((p) => p.id != humanPlayerId).firstOrNull ??
        game.players.first;
    final factionId = otherPlayer.id;
    final relation = getRelation(game, humanPlayerId, factionId);

    await tester.pumpWidget(
      MaterialApp(
        home: DiplomacyDetailScreen(
          game: game,
          humanPlayerId: humanPlayerId,
          factionId: factionId,
          factionDisplayName: otherPlayer.displayName,
          kind: FactionKind.greatPower,
          relation: relation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Diplomatic history'), findsOneWidget);
    expect(find.text('Dossier'), findsOneWidget);
    expect(find.textContaining('No dossier evidence yet.'), findsOneWidget);
  });

  testWidgets('DiplomacyDetailScreen renders either empty or non-empty history',
      (WidgetTester tester) async {
    final game = getDebugInitGameResult().game;
    final humanPlayerId = game.players.first.id;

    final allFactionIds = <String>[
      ...game.players.map((p) => p.id),
      ...game.minorNations.map((m) => m.id),
      ...game.tribes.map((t) => t.id),
    ].where((id) => id != humanPlayerId).toList();

    DiplomacyRelation? bestNonNullRelation;
    String? nonEmptyHistoryFactionId;
    for (final id in allFactionIds) {
      final history = diplomaticHistoryForPair(game, humanPlayerId, id);
      if (history.isNotEmpty) {
        nonEmptyHistoryFactionId = id;
        bestNonNullRelation = getRelation(game, humanPlayerId, id);
        break;
      }
    }

    final chosenFactionId = nonEmptyHistoryFactionId ?? allFactionIds.first;
    final history = diplomaticHistoryForPair(game, humanPlayerId, chosenFactionId);
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
      MaterialApp(
        home: DiplomacyDetailScreen(
          game: game,
          humanPlayerId: humanPlayerId,
          factionId: chosenFactionId,
          factionDisplayName: displayNameFor(chosenFactionId),
          kind: kindFor(chosenFactionId),
          relation: relation,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Diplomatic history'), findsOneWidget);
    if (history.isEmpty) {
      expect(find.text('No recorded events with this faction.'), findsOneWidget);
    } else {
      // History is rendered as a list of Cards.
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    }
  });

  testWidgets(
      'DiplomacyDetailScreen hides Dossier when kind != greatPower and relation is null (empty history)',
      (WidgetTester tester) async {
    final game = getDebugInitGameResult().game;
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
      MaterialApp(
        home: DiplomacyDetailScreen(
          game: game,
          humanPlayerId: humanPlayerId,
          factionId: factionId,
          factionDisplayName: displayNameFor(factionId),
          kind: FactionKind.minor,
          relation: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Diplomatic history'), findsOneWidget);
    expect(find.text('Dossier'), findsNothing);
    expect(find.text('No recorded events with this faction.'), findsOneWidget);
  });

  testWidgets('DiplomacyDetailScreen renders non-empty history and dossier entries',
      (WidgetTester tester) async {
    const humanPlayerId = 'gp1';
    const otherFactionId = 'gp2';

    final game = _minimalGame(
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
      MaterialApp(
        home: DiplomacyDetailScreen(
          game: game,
          humanPlayerId: humanPlayerId,
          factionId: otherFactionId,
          factionDisplayName: 'Other GP',
          kind: FactionKind.greatPower,
          relation: relation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Diplomatic history'), findsOneWidget);
    expect(find.text('Dossier'), findsOneWidget);
    expect(find.textContaining('Turn 3:'), findsOneWidget);
    expect(find.textContaining('evidence-1'), findsOneWidget);
    expect(find.textContaining('declared war'), findsOneWidget);
    expect(find.textContaining('War'), findsOneWidget);
  });

  testWidgets('DiplomacyDetailScreen renders empty history (minimal game)',
      (WidgetTester tester) async {
    const humanPlayerId = 'gp1';
    const otherFactionId = 'gp2';

    final game = _minimalGame(
      humanPlayerId: humanPlayerId,
      otherFactionId: otherFactionId,
      eventType: DiplomaticEventType.peace,
      includeHistory: false,
      includeDossier: false,
      atWar: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DiplomacyDetailScreen(
          game: game,
          humanPlayerId: humanPlayerId,
          factionId: otherFactionId,
          factionDisplayName: 'Other GP',
          kind: FactionKind.minor,
          relation: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Diplomatic history'), findsOneWidget);
    expect(find.text('Dossier'), findsNothing);
    expect(find.text('No recorded events with this faction.'), findsOneWidget);
  });
}

