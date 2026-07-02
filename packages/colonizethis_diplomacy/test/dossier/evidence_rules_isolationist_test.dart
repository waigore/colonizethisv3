// Tests for isolationist call-to-arms refusal evidence rule.
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('evidenceForIsolationistCallToArmsRefuse', () {
    Game ctaRefuseGame({
      required bool allyIsAi,
      required bool atPeaceWithDefender,
    }) {
      return evidenceGame(
        turnNumber: 3,
        players: [
          const Player(id: 'observer', displayName: 'Human', isHuman: true),
          Player(id: 'ally', displayName: 'Ally', isHuman: !allyIsAi),
          const Player(id: 'defender', displayName: 'Defender', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'ally',
            factionId2: 'defender',
            score: 50,
            level: RelationLevel.friendly,
            state: atPeaceWithDefender
                ? RelationState.atPeace
                : RelationState.atWar,
          ),
        ],
      );
    }

    test(
      'AI refusing call to arms while at peace with defender adds isolationist +2',
      () {
        final game = ctaRefuseGame(
          allyIsAi: true,
          atPeaceWithDefender: true,
        );
        final entries = evidenceForIsolationistCallToArmsRefuse(
          game,
          'ally',
          'defender',
          3,
        );
        expect(entries.length, 1);
        expect(entries.single.observerId, 'observer');
        expect(entries.single.subjectId, 'ally');
        expect(entries.single.agendaType, 'isolationist');
        expect(entries.single.scoreDelta, 2);
        expect(entries.single.turnNumber, 3);
        expect(entries.single.description, contains('declined call to arms'));
      },
    );

    test('empty when ally and defender are at war', () {
      final game = ctaRefuseGame(
        allyIsAi: true,
        atPeaceWithDefender: false,
      );
      final entries = evidenceForIsolationistCallToArmsRefuse(
        game,
        'ally',
        'defender',
        3,
      );
      expect(entries, isEmpty);
    });

    test('human ally returns no evidence', () {
      final game = ctaRefuseGame(
        allyIsAi: false,
        atPeaceWithDefender: true,
      );
      final entries = evidenceForIsolationistCallToArmsRefuse(
        game,
        'ally',
        'defender',
        3,
      );
      expect(entries, isEmpty);
    });

    test('isolationist call to arms: no human observer returns no evidence', () {
      final game = evidenceGame(
        turnNumber: 3,
        players: const [
          Player(id: 'ai1', displayName: 'AI1', isHuman: false),
          Player(id: 'ai2', displayName: 'AI2', isHuman: false),
          Player(id: 'defender', displayName: 'Defender', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'ai1',
            factionId2: 'defender',
            score: 50,
            level: RelationLevel.friendly,
            state: RelationState.atPeace,
          ),
        ],
      );
      final entries = evidenceForIsolationistCallToArmsRefuse(
        game,
        'ai1',
        'defender',
        3,
      );
      expect(entries, isEmpty);
    });

    test('empty when no relation exists between ally and defender', () {
      final game = evidenceGame(
        turnNumber: 3,
        players: const [
          Player(id: 'observer', displayName: 'Human', isHuman: true),
          Player(id: 'ally', displayName: 'Ally', isHuman: false),
          Player(id: 'defender', displayName: 'Defender', isHuman: false),
        ],
      );
      final entries = evidenceForIsolationistCallToArmsRefuse(
        game,
        'ally',
        'defender',
        3,
      );
      expect(entries, isEmpty);
    });
  });
}
