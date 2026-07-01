// Tests for declare-war / offer-peace / treaty-break dossier evidence rules.
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'evidence_rules_test_support.dart';

void main() {
  group('evidenceForDeclareWar', () {
    test(
      'AI declaring war on weaker allied GP adds backstabber and warmonger evidence',
      () {
        final game = evidenceGame(
          players: const [
            Player(
              id: 'human',
              displayName: 'Human',
              isHuman: true,
              militaryLevel: 3,
            ),
            Player(
              id: 'ai',
              displayName: 'AI',
              isHuman: false,
              militaryLevel: 5,
            ),
            Player(
              id: 'ally',
              displayName: 'Ally',
              isHuman: false,
              militaryLevel: 2,
            ),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'ai',
              factionId2: 'ally',
              level: RelationLevel.allied,
            ),
          ],
        );

        final entries = evidenceForDeclareWar(game, 'ai', 'ally', 2);

        expect(entries.length, 2);
        final backstabberEntries = entries
            .where((e) => e.agendaType == 'backstabber')
            .toList();
        final warmongerEntries = entries
            .where((e) => e.agendaType == 'warmonger')
            .toList();

        expect(backstabberEntries.length, 1);
        expect(backstabberEntries.first.observerId, 'human');
        expect(backstabberEntries.first.subjectId, 'ai');
        expect(backstabberEntries.first.scoreDelta, 3);
        expect(backstabberEntries.first.description, contains('ally'));

        expect(warmongerEntries.length, 1);
        expect(warmongerEntries.first.observerId, 'human');
        expect(warmongerEntries.first.subjectId, 'ai');
        expect(warmongerEntries.first.scoreDelta, 2);
        expect(warmongerEntries.first.description, contains('weaker'));
      },
    );

    test(
      'AI declaring war on weaker non-allied GP only adds warmonger evidence',
      () {
        final game = evidenceGame(
          players: const [
            Player(
              id: 'human',
              displayName: 'Human',
              isHuman: true,
              militaryLevel: 3,
            ),
            Player(
              id: 'ai',
              displayName: 'AI',
              isHuman: false,
              militaryLevel: 5,
            ),
            Player(
              id: 'target',
              displayName: 'Target',
              isHuman: false,
              militaryLevel: 2,
            ),
          ],
        );

        final entries = evidenceForDeclareWar(game, 'ai', 'target', 2);

        expect(entries.length, 1);
        expect(entries.first.agendaType, 'warmonger');
        expect(entries.first.observerId, 'human');
        expect(entries.first.subjectId, 'ai');
        expect(entries.first.scoreDelta, 2);
        expect(entries.first.description, contains('weaker'));
      },
    );

    test(
      'AI declaring war on allied non-weaker GP only adds backstabber evidence',
      () {
        final game = evidenceGame(
          players: const [
            Player(
              id: 'human',
              displayName: 'Human',
              isHuman: true,
              militaryLevel: 3,
            ),
            Player(
              id: 'ai',
              displayName: 'AI',
              isHuman: false,
              militaryLevel: 2,
            ),
            Player(
              id: 'ally',
              displayName: 'Ally',
              isHuman: false,
              militaryLevel: 5,
            ),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'ai',
              factionId2: 'ally',
              level: RelationLevel.allied,
            ),
          ],
        );

        final entries = evidenceForDeclareWar(game, 'ai', 'ally', 2);

        expect(entries.length, 1);
        expect(entries.first.agendaType, 'backstabber');
        expect(entries.first.observerId, 'human');
        expect(entries.first.subjectId, 'ai');
        expect(entries.first.scoreDelta, 3);
        expect(entries.first.description, contains('ally'));
      },
    );

    test('human actor returns no evidence', () {
      final game = evidenceGame(
        players: const [
          Player(id: 'human', displayName: 'Human', isHuman: true),
          Player(id: 'ai', displayName: 'AI', isHuman: false),
        ],
      );

      final entries = evidenceForDeclareWar(game, 'human', 'ai', 2);

      expect(entries, isEmpty);
    });

    test('declare war: no human observer returns no evidence', () {
      final game = evidenceGame(
        players: const [
          Player(id: 'ai', displayName: 'AI', isHuman: false),
          Player(id: 'other', displayName: 'Other', isHuman: false),
        ],
      );

      final entries = evidenceForDeclareWar(game, 'ai', 'other', 2);

      expect(entries, isEmpty);
    });
  });

  group('evidenceForOfferPeace', () {
    test('AI offering peace adds peacemaker evidence for human observer', () {
      final game = evidenceGame(
        players: const [
          Player(id: 'human', displayName: 'Human', isHuman: true),
          Player(id: 'ai', displayName: 'AI', isHuman: false),
        ],
      );

      final entries = evidenceForOfferPeace(game, 'ai', 'human', 2);

      expect(entries.length, 1);
      final entry = entries.first;
      expect(entry.agendaType, 'peacemaker');
      expect(entry.observerId, 'human');
      expect(entry.subjectId, 'ai');
      expect(entry.scoreDelta, 1);
      expect(entry.description, contains('peace'));
    });

    test('human offering peace returns no evidence', () {
      final game = evidenceGame(
        players: const [
          Player(id: 'human', displayName: 'Human', isHuman: true),
          Player(id: 'ai', displayName: 'AI', isHuman: false),
        ],
      );

      final entries = evidenceForOfferPeace(game, 'human', 'ai', 2);

      expect(entries, isEmpty);
    });

    test('offer peace: no human observer returns no evidence', () {
      final game = evidenceGame(
        players: const [
          Player(id: 'ai', displayName: 'AI', isHuman: false),
          Player(id: 'other', displayName: 'Other', isHuman: false),
        ],
      );

      final entries = evidenceForOfferPeace(game, 'ai', 'other', 2);

      expect(entries, isEmpty);
    });
  });

  group('evidenceForDeclareWar treaty-break window', () {
    test(
      'adds backstabber when war follows callToArmsRefused within 3 turns',
      () {
        final game = evidenceGame(
          turnNumber: 6,
          players: const [
            Player(
              id: 'human',
              displayName: 'Human',
              isHuman: true,
              militaryLevel: 5,
            ),
            Player(
              id: 'ai',
              displayName: 'AI',
              isHuman: false,
              militaryLevel: 5,
            ),
            Player(
              id: 'target',
              displayName: 'Target',
              isHuman: false,
              militaryLevel: 5,
            ),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'ai',
              factionId2: 'target',
              level: RelationLevel.friendly,
              state: RelationState.atPeace,
            ),
          ],
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
        );

        final entries = evidenceForDeclareWar(game, 'ai', 'target', 6);

        expect(entries.length, 1);
        expect(entries.single.agendaType, 'backstabber');
        expect(entries.single.scoreDelta, 3);
      },
    );
  });
}
