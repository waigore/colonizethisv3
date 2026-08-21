// Table-driven dossier evidence rule scenarios (Refs #3837 / #4028 / #4037 / #4130).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

import '../diplomacy/call_to_arms_fixtures.dart';

class EvidenceRulesScenario {
  const EvidenceRulesScenario({required this.label, required this.run});
  final String label;
  final void Function() run;
}

void runEvidenceRulesScenario(EvidenceRulesScenario scenario) => scenario.run();

const erHuman = Player(id: 'gp1', displayName: 'Human', isHuman: true);
const erAi = Player(id: 'gp2', displayName: 'AI', isHuman: false);
const erOther = Player(id: 'gp3', displayName: 'Other', isHuman: false);
const erAi1 = Player(id: 'gp1', displayName: 'AI1', isHuman: false);
const erAi2 = Player(id: 'gp2', displayName: 'AI2', isHuman: false);
const erHumanNamed = Player(id: 'human', displayName: 'Human', isHuman: true);
const erAiNamed = Player(id: 'ai', displayName: 'AI', isHuman: false);
const erHumanAi = [erHumanNamed, erAiNamed];

Player erPlayer(String id, String name, {bool human = false, int? mil}) =>
    Player(id: id, displayName: name, isHuman: human, militaryLevel: mil);

DiplomacyRelation erAllied(String a, String b) =>
    peaceRelation(a, b, 80, level: RelationLevel.allied, formalAlliance: true);

EvidenceRulesScenario erRow(String label, void Function() run) =>
    EvidenceRulesScenario(label: label, run: run);

EvidenceRulesScenario erEmptyBattle({
  required String label,
  required List<Player> players,
  required List<DossierEvidenceEntry> Function(Game) fn,
}) => erRow(label, () => expect(fn(diplomacyGame(turnNumber: 2, players: players)), isEmpty));

void erExpectEntry(
  DossierEvidenceEntry e, {
  required String agenda,
  required String observer,
  required String subject,
  required int delta,
  required Matcher desc,
}) {
  expect(e.agendaType, agenda);
  expect(e.observerId, observer);
  expect(e.subjectId, subject);
  expect(e.scoreDelta, delta);
  expect(e.description, desc);
}

DossierEvidenceEntry erOnlyAgenda(List<DossierEvidenceEntry> entries, String agenda) {
  final matched = entries.where((e) => e.agendaType == agenda).toList();
  expect(matched.length, 1);
  return matched.single;
}

Game erMirrorGame({required int refTurn, required int currentTurn}) => diplomacyGame(
      turnNumber: currentTurn,
      players: erHumanAi,
      aiControlByGpId: const {'ai': true},
      lastHumanCompletedResearchCategory: 'gathering',
      lastHumanResearchCategoryCompletionTurn: refTurn,
    );

EvidenceRulesScenario erEmptyMirror({
  required String label,
  required int refTurn,
  required int currentTurn,
  required String category,
  List<DossierEvidenceEntry> pending = const [],
}) => erRow(
      label,
      () => expect(
        evidenceForEnvyResearchMirror(erMirrorGame(refTurn: refTurn, currentTurn: currentTurn), 'ai', category, currentTurn, pending),
        isEmpty,
      ),
    );

Game erLandPlayers(int aiMil, int otherMil) => diplomacyGame(
      turnNumber: 2,
      players: [erHuman, erPlayer('gp2', 'AI', mil: aiMil), erPlayer('gp3', 'Other', mil: otherMil)],
    );

EvidenceRulesScenario erEmptyIsolationist({
  required String label,
  required Game game,
  String ally = 'ally',
  String defender = 'defender',
}) => erRow(label, () => expect(evidenceForIsolationistCallToArmsRefuse(game, ally, defender, 3), isEmpty));

EvidenceRulesScenario erDeclareWarRow({
  required String label,
  required int aiMil,
  required int targetMil,
  required String targetId,
  List<DiplomacyRelation> relations = const [],
  required void Function(List<DossierEvidenceEntry> entries) expectEntries,
}) => erRow(label, () {
      expectEntries(evidenceForDeclareWar(
        diplomacyGame(
          turnNumber: 2,
          players: [
            erPlayer('human', 'Human', human: true, mil: 3),
            erPlayer('ai', 'AI', mil: aiMil),
            erPlayer(targetId, targetId == 'ally' ? 'Ally' : 'Target', mil: targetMil),
          ],
          diplomacyRelations: relations,
        ),
        'ai',
        targetId,
        2,
      ));
    });

