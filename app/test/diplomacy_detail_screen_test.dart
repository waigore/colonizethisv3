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
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'widget_test_assets.dart';

const _humanId = 'gp1';
const _otherId = 'gp2';

Game _minimalGame({
  DiplomaticEventType eventType = DiplomaticEventType.peace,
  bool includeHistory = false,
  bool includeDossier = false,
  bool atWar = false,
  int score = 70,
  bool formalAlliance = false,
}) {
  final relation = DiplomacyRelation(
    factionId1: _humanId,
    factionId2: _otherId,
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
    players: [
      Player(id: _humanId, displayName: 'Human GP', isHuman: true, treasury: 0),
      Player(
        id: _otherId,
        displayName: 'Other GP',
        isHuman: false,
        treasury: 0,
      ),
    ],
    diplomacyRelations: [relation],
    diplomaticHistoryEvents: includeHistory
        ? [
            DiplomaticEvent(
              turn: 2,
              intraTurnIndex: 0,
              type: eventType,
              participants: {_humanId, _otherId},
              fromFactionId: _humanId,
              toFactionId: _otherId,
            ),
          ]
        : const [],
    dossierEvidenceEntries: includeDossier
        ? [
            DossierEvidenceEntry(
              observerId: _humanId,
              subjectId: _otherId,
              agendaType: 'test_agenda',
              turnNumber: 3,
              description: 'evidence-1',
            ),
          ]
        : const [],
  );
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required Game game,
  required String factionId,
  required String factionDisplayName,
  required FactionKind kind,
  DiplomacyRelation? relation,
  List<Override> overrides = const <Override>[],
}) {
  return pumpAppShell(
    tester,
    overrides: overrides,
    child: DiplomacyDetailScreen(
      game: game,
      humanPlayerId: _humanId,
      factionId: factionId,
      factionDisplayName: factionDisplayName,
      kind: kind,
      relation: relation,
    ),
    settle: true,
  );
}

Future<void> _pumpOtherGp(
  WidgetTester tester, {
  required Game game,
  DiplomacyRelation? relation,
  FactionKind kind = FactionKind.greatPower,
  List<Override> overrides = const <Override>[],
}) {
  return _pumpDetail(
    tester,
    game: game,
    factionId: _otherId,
    factionDisplayName: 'Other GP',
    kind: kind,
    relation: relation,
    overrides: overrides,
  );
}

String _displayNameFor(Game game, String id) {
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

FactionKind _kindFor(Game game, String id) {
  if (game.players.any((p) => p.id == id)) return FactionKind.greatPower;
  if (game.minorNations.any((m) => m.id == id)) return FactionKind.minor;
  return FactionKind.tribe;
}

List<String> _otherFactionIds(Game game) => <String>[
  ...game.players.map((p) => p.id),
  ...game.minorNations.map((m) => m.id),
  ...game.tribes.map((t) => t.id),
].where((id) => id != _humanId).toList();

typedef _Pin = (Finder finder, Matcher matcher);

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await preloadNinePatchImage();
  });

  testWidgets(
    'DiplomacyDetailScreen renders either empty or non-empty history',
    (WidgetTester tester) async {
      final game = _minimalGame();
      final allFactionIds = _otherFactionIds(game);
      String? nonEmptyHistoryFactionId;
      for (final id in allFactionIds) {
        if (diplomaticHistoryForPair(game, _humanId, id).isNotEmpty) {
          nonEmptyHistoryFactionId = id;
          break;
        }
      }
      final chosenFactionId = nonEmptyHistoryFactionId ?? allFactionIds.first;
      final history = diplomaticHistoryForPair(game, _humanId, chosenFactionId);
      await _pumpDetail(
        tester,
        game: game,
        factionId: chosenFactionId,
        factionDisplayName: _displayNameFor(game, chosenFactionId),
        kind: _kindFor(game, chosenFactionId),
        relation: getRelation(game, _humanId, chosenFactionId),
      );
      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      if (history.isEmpty) {
        expect(
          find.text('No recorded events with this faction.'),
          findsOneWidget,
        );
      } else {
        expect(
          find.text(formatDiplomaticEvent(history.first, game, _humanId)),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'DiplomacyDetailScreen hides Dossier when kind != greatPower and relation is null (empty history)',
    (WidgetTester tester) async {
      final game = _minimalGame();
      final allFactionIds = _otherFactionIds(game);
      var factionId = allFactionIds.first;
      for (final id in allFactionIds) {
        if (diplomaticHistoryForPair(game, _humanId, id).isEmpty) {
          factionId = id;
          break;
        }
      }
      await _pumpDetail(
        tester,
        game: game,
        factionId: factionId,
        factionDisplayName: _displayNameFor(game, factionId),
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
    for (final c in <({
      String name,
      Game Function() game,
      FactionKind kind,
      bool useRelation,
      List<_Pin> pins,
    })>[
      (
        name: 'GP shows dossier header and empty evidence',
        game: _minimalGame,
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
        game: _minimalGame,
        kind: FactionKind.greatPower,
        useRelation: false,
        pins: [
          (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
          (find.text('DOSSIER'), findsOneWidget),
          (find.text('No dossier evidence yet.'), findsOneWidget),
          (find.text('No recorded events with this faction.'), findsOneWidget),
        ],
      ),
      (
        name: 'non-GP with relation shows Peace and hides Dossier',
        game: _minimalGame,
        kind: FactionKind.minor,
        useRelation: true,
        pins: [
          (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
          (find.text('DOSSIER'), findsNothing),
          (find.text('No recorded events with this faction.'), findsOneWidget),
          (find.textContaining('Peace'), findsOneWidget),
        ],
      ),
      (
        name: 'GP empty-state dossier when no evidence exists',
        game: () => _minimalGame(eventType: DiplomaticEventType.declareWar),
        kind: FactionKind.greatPower,
        useRelation: true,
        pins: [
          (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
          (find.text('DOSSIER'), findsOneWidget),
          (find.text('No recorded events with this faction.'), findsOneWidget),
          (find.text('No dossier evidence yet.'), findsOneWidget),
          (find.textContaining('Peace'), findsOneWidget),
        ],
      ),
      (
        name: 'GP non-empty history + dossier at war',
        game: () => _minimalGame(
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
        game: () => _minimalGame(
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
        final relation =
            c.useRelation ? getRelation(game, _humanId, _otherId) : null;
        await _pumpOtherGp(
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
            id: _humanId,
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
            participants: {_humanId, unknownFactionId},
            fromFactionId: _humanId,
            toFactionId: unknownFactionId,
          ),
        ],
        dossierEvidenceEntries: const [],
      );
      await _pumpDetail(
        tester,
        game: game,
        factionId: unknownFactionId,
        factionDisplayName: 'Unknown Faction',
        kind: FactionKind.minor,
        relation: null,
      );
      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.textContaining('Unknown faction'), findsOneWidget);
      expect(find.textContaining('declared war'), findsOneWidget);
    },
  );

  testWidgets(
    'DiplomacyDetailScreen renders dark editorial-monocle chrome '
    '(CtTopBar + scaffold bg) per Refs #2863 S5',
    (WidgetTester tester) async {
      final game = _minimalGame();
      await _pumpOtherGp(
        tester,
        game: game,
        relation: getRelation(game, _humanId, _otherId),
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
    },
  );

  testWidgets(
    'DiplomacyDetailScreen emits exactly one PopNavigationEvent when the '
    'CtTopBar back button is tapped per Refs #2863 S5',
    (WidgetTester tester) async {
      final game = _minimalGame();
      final AppEventBus bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final List<PopNavigationEvent> popEvents = <PopNavigationEvent>[];
      final sub = bus.on<PopNavigationEvent>().listen(popEvents.add);
      addTearDown(sub.cancel);
      await _pumpOtherGp(
        tester,
        overrides: [appEventBusProvider.overrideWith((ref) => bus)],
        game: game,
        relation: getRelation(game, _humanId, _otherId),
      );
      expect(popEvents, isEmpty);
      await tester.tap(find.byType(CtBackButton));
      await tester.pump();
      expect(popEvents, hasLength(1));
    },
  );

  group('current relation card chrome', () {
    for (final c in <({
      String name,
      Game Function() game,
      void Function(WidgetTester tester) assertUi,
    })>[
      (
        name: 'War label in --danger colour',
        game: () => _minimalGame(
          eventType: DiplomaticEventType.declareWar,
          atWar: true,
        ),
        assertUi: (tester) {
          expect(find.text('CURRENT RELATION'), findsOneWidget);
          final Text war = tester.widget(find.text('War'));
          expect(war.style?.color, EditorialMonoclePalette.danger);
        },
      ),
      (
        name: 'Peace label in --success colour',
        game: _minimalGame,
        assertUi: (tester) {
          expect(find.text('CURRENT RELATION'), findsOneWidget);
          final Text peace = tester.widget(find.text('Peace'));
          expect(peace.style?.color, EditorialMonoclePalette.success);
        },
      ),
      (
        name: 'ALLIANCE badge in --accent for formal alliance (Refs #3625 AC4)',
        game: () => _minimalGame(
          eventType: DiplomaticEventType.allianceFormed,
          score: 90,
          formalAlliance: true,
        ),
        assertUi: (tester) {
          expect(find.text('CURRENT RELATION'), findsOneWidget);
          final Finder badge = find.text(kDiplomacyAllianceBadgeLabel);
          expect(badge, findsOneWidget);
          final Text badgeText = tester.widget<Text>(badge);
          expect(badgeText.style?.color, EditorialMonoclePalette.accent);
          expect(kDiplomacyAllianceBadgeLabel, isNot('Friendly'));
        },
      ),
      (
        name:
            'omits ALLIANCE badge for informal Allied band (Refs #3625 AC4 negative)',
        game: () => _minimalGame(score: 90),
        assertUi: (tester) {
          expect(find.text('CURRENT RELATION'), findsOneWidget);
          expect(find.text(kDiplomacyAllianceBadgeLabel), findsNothing);
          expect(find.textContaining('Devoted'), findsOneWidget);
        },
      ),
    ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        final game = c.game();
        final relation = getRelation(game, _humanId, _otherId);
        expect(relation, isNotNull);
        await _pumpOtherGp(tester, game: game, relation: relation);
        c.assertUi(tester);
      });
    }
  });
}
