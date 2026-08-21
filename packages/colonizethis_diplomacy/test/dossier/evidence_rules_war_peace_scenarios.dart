// Declare-war / offer-peace / isolationist evidence scenarios (Refs #4574).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import '../diplomacy/call_to_arms_fixtures.dart';
import 'evidence_rules_scenario_helpers.dart';

List<EvidenceRulesScenario> evidenceRulesDeclareWarScenarios() => [
  erDeclareWarRow(
    label: 'AI declaring war on weaker allied GP adds backstabber and warmonger evidence',
    aiMil: 5,
    targetMil: 2,
    targetId: 'ally',
    relations: [erAllied('ai', 'ally')],
    expectEntries: (entries) {
      expect(entries.length, 2);
      erExpectEntry(erOnlyAgenda(entries, 'backstabber'), agenda: 'backstabber', observer: 'human', subject: 'ai', delta: 3, desc: contains('ally'));
      erExpectEntry(erOnlyAgenda(entries, 'warmonger'), agenda: 'warmonger', observer: 'human', subject: 'ai', delta: 2, desc: contains('weaker'));
    },
  ),
  erDeclareWarRow(
    label: 'AI declaring war on weaker non-allied GP only adds warmonger evidence',
    aiMil: 5,
    targetMil: 2,
    targetId: 'target',
    expectEntries: (entries) {
      expect(entries.length, 1);
      erExpectEntry(entries.first, agenda: 'warmonger', observer: 'human', subject: 'ai', delta: 2, desc: contains('weaker'));
    },
  ),
  erDeclareWarRow(
    label: 'AI declaring war on allied non-weaker GP only adds backstabber evidence',
    aiMil: 2,
    targetMil: 5,
    targetId: 'ally',
    relations: [erAllied('ai', 'ally')],
    expectEntries: (entries) {
      expect(entries.length, 1);
      erExpectEntry(entries.first, agenda: 'backstabber', observer: 'human', subject: 'ai', delta: 3, desc: contains('ally'));
    },
  ),
  erEmptyBattle(label: 'human actor returns no evidence', players: erHumanAi, fn: (g) => evidenceForDeclareWar(g, 'human', 'ai', 2)),
  erEmptyBattle(label: 'declare war: no human observer returns no evidence', players: [erPlayer('ai', 'AI'), erPlayer('other', 'Other')], fn: (g) => evidenceForDeclareWar(g, 'ai', 'other', 2)),
];

List<EvidenceRulesScenario> evidenceRulesOfferPeaceScenarios() => [
  erRow('AI offering peace adds peacemaker evidence for human observer', () {
    final entries = evidenceForOfferPeace(diplomacyGame(turnNumber: 2, players: erHumanAi), 'ai', 'human', 2);
    expect(entries.length, 1);
    erExpectEntry(entries.first, agenda: 'peacemaker', observer: 'human', subject: 'ai', delta: 1, desc: contains('peace'));
  }),
  erEmptyBattle(label: 'human offering peace returns no evidence', players: erHumanAi, fn: (g) => evidenceForOfferPeace(g, 'human', 'ai', 2)),
  erEmptyBattle(label: 'offer peace: no human observer returns no evidence', players: [erPlayer('ai', 'AI'), erPlayer('other', 'Other')], fn: (g) => evidenceForOfferPeace(g, 'ai', 'other', 2)),
];

List<EvidenceRulesScenario> evidenceRulesTreatyBreakWindowScenarios() => [
  erRow('adds backstabber when war follows callToArmsRefused within 3 turns', () {
    final e = evidenceForDeclareWar(
      diplomacyGame(
        turnNumber: 6,
        players: [erPlayer('human', 'Human', human: true, mil: 5), erPlayer('ai', 'AI', mil: 5), erPlayer('target', 'Target', mil: 5)],
        diplomacyRelations: [peaceRelation('ai', 'target', 50, level: RelationLevel.friendly)],
        diplomaticHistoryEvents: const [
          DiplomaticEvent(
            turn: 5,
            intraTurnIndex: 0,
            type: DiplomaticEventType.callToArmsRefused,
            participants: {'ai', 'target'},
            fromFactionId: 'ai',
            toFactionId: 'target',
          ),
        ],
      ),
      'ai',
      'target',
      6,
    ).single;
    expect(e.agendaType, 'backstabber');
    expect(e.scoreDelta, 3);
  }),
];

List<EvidenceRulesScenario> evidenceRulesIsolationistScenarios() => [
  erRow('AI refusing call to arms while at peace with defender adds isolationist +2', () {
    final e = evidenceForIsolationistCallToArmsRefuse(
      ctaRefuseEvidenceGame(allyIsAi: true, atPeaceWithDefender: true),
      'ally',
      'defender',
      3,
    ).single;
    expect(e.turnNumber, 3);
    erExpectEntry(e, agenda: 'isolationist', observer: 'observer', subject: 'ally', delta: 2, desc: contains('declined call to arms'));
  }),
  erEmptyIsolationist(label: 'empty when ally and defender are at war', game: ctaRefuseEvidenceGame(allyIsAi: true, atPeaceWithDefender: false)),
  erEmptyIsolationist(label: 'human ally returns no evidence', game: ctaRefuseEvidenceGame(allyIsAi: false, atPeaceWithDefender: true)),
  erEmptyIsolationist(
    label: 'isolationist call to arms: no human observer returns no evidence',
    game: diplomacyGame(
      turnNumber: 3,
      players: [erPlayer('ai1', 'AI1'), erPlayer('ai2', 'AI2'), erPlayer('defender', 'Defender')],
      diplomacyRelations: [peaceRelation('ai1', 'defender', 50)],
    ),
    ally: 'ai1',
  ),
  erEmptyIsolationist(
    label: 'empty when no relation exists between ally and defender',
    game: diplomacyGame(
      turnNumber: 3,
      players: [
        const Player(id: 'observer', displayName: 'Human', isHuman: true),
        erPlayer('ally', 'Ally'),
        erPlayer('defender', 'Defender'),
      ],
    ),
  ),
];
