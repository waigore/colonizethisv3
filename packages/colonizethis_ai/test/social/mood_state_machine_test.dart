import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';

void main() {
  group('computeNextNegotiationMood', () {
    test('returns only valid mood values', () {
      for (final current in kPortraitMoodValues) {
        for (final delta in [-1.0, 0.0, 1.0]) {
          final next = computeNextNegotiationMood(
            current,
            delta.toDouble(),
            0,
            0,
          );
          expect(kPortraitMoodValues, contains(next));
        }
      }
    });

    test('high stall count yields impatient or skeptical', () {
      final a = computeNextNegotiationMood('considering', 0.0, 4, 0);
      final b = computeNextNegotiationMood('considering', 0.0, 4, 1);
      expect({'impatient', 'skeptical'}, contains(a));
      expect({'impatient', 'skeptical'}, contains(b));
    });

    test('positive offerQualityDelta yields pleased or gracious', () {
      final next = computeNextNegotiationMood('considering', 0.6, 0, 0);
      expect({'pleased', 'gracious'}, contains(next));
    });

    test('negative offerQualityDelta yields irritated or dismissive', () {
      final next = computeNextNegotiationMood('considering', -0.6, 0, 0);
      expect({'irritated', 'dismissive'}, contains(next));
    });

    test('deterministic for same inputs', () {
      const seed = 42;
      expect(
        computeNextNegotiationMood('considering', 0.3, 1, seed),
        computeNextNegotiationMood('considering', 0.3, 1, seed),
      );
    });
  });

  group('kPortraitMoodValues', () {
    test('contains spec moods', () {
      expect(kPortraitMoodValues, contains('considering'));
      expect(kPortraitMoodValues, contains('pleased'));
      expect(kPortraitMoodValues, contains('gracious'));
      expect(kPortraitMoodValues, contains('calculating'));
      expect(kPortraitMoodValues, contains('skeptical'));
      expect(kPortraitMoodValues, contains('impatient'));
      expect(kPortraitMoodValues, contains('irritated'));
      expect(kPortraitMoodValues, contains('dismissive'));
    });
  });

  group('buildNegotiationMoodTransitionEvent', () {
    test('emits PortraitMoodEvent when mood changes', () {
      final event = buildNegotiationMoodTransitionEvent(
        leaderId: 'gp1',
        currentMood: 'considering',
        offerQualityDelta: -0.8,
        stallCounter: 0,
        seed: 0,
      );
      expect(event, isNotNull);
      expect(event!.leaderId, 'gp1');
      expect(event.fromMood, 'considering');
      expect(event.toMood, anyOf('irritated', 'dismissive'));
      expect(event.durationMs, kNegotiationMoodTransitionDurationMs);
    });

    test('returns null when mood does not change', () {
      final event = buildNegotiationMoodTransitionEvent(
        leaderId: 'gp1',
        currentMood: 'calculating',
        offerQualityDelta: 0.0,
        stallCounter: 2,
        seed: 42,
      );
      expect(event, isNull);
    });
  });
}
