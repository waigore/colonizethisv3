// Tests for dialogue key catalog. SPEC/ai/dialogue-and-mood.md.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('dialogueKeyForEvent', () {
    test('builds key without mood', () {
      expect(
        dialogueKeyForEvent(
          category: 'event',
          situation: 'era_change',
          era: 'earlyModern',
        ),
        equals('dialogue.event.era_change.earlyModern'),
      );
      expect(
        dialogueKeyForEvent(
          category: 'diplomatic',
          situation: 'declare_war',
          era: 'imperial',
        ),
        equals('dialogue.diplomatic.declare_war.imperial'),
      );
    });

    test('builds key with mood for negotiation', () {
      expect(
        dialogueKeyForEvent(
          category: 'negotiation',
          situation: 'counter_offer',
          era: 'earlyModern',
          mood: 'skeptical',
        ),
        equals('dialogue.negotiation.counter_offer.earlyModern.skeptical'),
      );
    });

    test('omits mood when null', () {
      expect(
        dialogueKeyForEvent(
          category: 'agenda',
          situation: 'comment',
          era: 'discovery',
          mood: null,
        ),
        equals('dialogue.agenda.comment.discovery'),
      );
    });

    test('omits mood when empty string', () {
      expect(
        dialogueKeyForEvent(
          category: 'event',
          situation: 'battle_won',
          era: 'industrial',
          mood: '',
        ),
        equals('dialogue.event.battle_won.industrial'),
      );
    });
  });

  group('constants', () {
    test('kDialogueCategories contains spec categories', () {
      expect(kDialogueCategories, contains('diplomatic'));
      expect(kDialogueCategories, contains('reactive'));
      expect(kDialogueCategories, contains('event'));
      expect(kDialogueCategories, contains('agenda'));
      expect(kDialogueCategories, contains('negotiation'));
      expect(kDialogueCategories, hasLength(5));
    });

    test('kDialogueEras contains spec eras', () {
      expect(kDialogueEras, containsAll(['discovery', 'earlyModern', 'imperial', 'industrial']));
      expect(kDialogueEras, hasLength(4));
    });

    test('kPortraitMoodValues contains spec moods', () {
      expect(kPortraitMoodValues, contains('considering'));
      expect(kPortraitMoodValues, contains('dismissive'));
      expect(kPortraitMoodValues, hasLength(8));
    });
  });
}
