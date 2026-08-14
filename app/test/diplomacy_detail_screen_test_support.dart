// Shared Game/pump helpers for DiplomacyDetailScreen tests (Refs #4352).
// SPEC: SPEC/ui/diplomacy-detail-screen.md.

import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const diplomacyDetailHumanId = 'gp1';
const diplomacyDetailOtherId = 'gp2';

Game diplomacyDetailMinimalGame({
  DiplomaticEventType eventType = DiplomaticEventType.peace,
  bool includeHistory = false,
  bool includeDossier = false,
  bool atWar = false,
  int score = 70,
  bool formalAlliance = false,
}) {
  final relation = DiplomacyRelation(
    factionId1: diplomacyDetailHumanId,
    factionId2: diplomacyDetailOtherId,
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
      Player(
        id: diplomacyDetailHumanId,
        displayName: 'Human GP',
        isHuman: true,
        treasury: 0,
      ),
      Player(
        id: diplomacyDetailOtherId,
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
              participants: {diplomacyDetailHumanId, diplomacyDetailOtherId},
              fromFactionId: diplomacyDetailHumanId,
              toFactionId: diplomacyDetailOtherId,
            ),
          ]
        : const [],
    dossierEvidenceEntries: includeDossier
        ? [
            DossierEvidenceEntry(
              observerId: diplomacyDetailHumanId,
              subjectId: diplomacyDetailOtherId,
              agendaType: 'test_agenda',
              turnNumber: 3,
              description: 'evidence-1',
            ),
          ]
        : const [],
  );
}

Future<void> pumpDiplomacyDetail(
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
      humanPlayerId: diplomacyDetailHumanId,
      factionId: factionId,
      factionDisplayName: factionDisplayName,
      kind: kind,
      relation: relation,
    ),
    settle: true,
  );
}

Future<void> pumpDiplomacyDetailOtherGp(
  WidgetTester tester, {
  required Game game,
  DiplomacyRelation? relation,
  FactionKind kind = FactionKind.greatPower,
  List<Override> overrides = const <Override>[],
}) {
  return pumpDiplomacyDetail(
    tester,
    game: game,
    factionId: diplomacyDetailOtherId,
    factionDisplayName: 'Other GP',
    kind: kind,
    relation: relation,
    overrides: overrides,
  );
}

String diplomacyDetailDisplayNameFor(Game game, String id) {
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

FactionKind diplomacyDetailKindFor(Game game, String id) {
  if (game.players.any((p) => p.id == id)) return FactionKind.greatPower;
  if (game.minorNations.any((m) => m.id == id)) return FactionKind.minor;
  return FactionKind.tribe;
}

List<String> diplomacyDetailOtherFactionIds(Game game) => <String>[
  ...game.players.map((p) => p.id),
  ...game.minorNations.map((m) => m.id),
  ...game.tribes.map((t) => t.id),
].where((id) => id != diplomacyDetailHumanId).toList();

const diplomacyDetailUnknownFactionId = 'minorX';

Game diplomacyDetailUnknownFactionGame() {
  return Game(
    id: 'test-unknown',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(
        id: diplomacyDetailHumanId,
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
        participants: {diplomacyDetailHumanId, diplomacyDetailUnknownFactionId},
        fromFactionId: diplomacyDetailHumanId,
        toFactionId: diplomacyDetailUnknownFactionId,
      ),
    ],
    dossierEvidenceEntries: const [],
  );
}

typedef DiplomacyDetailPin = (Finder finder, Matcher matcher);
