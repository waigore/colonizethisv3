import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('WorkerTier', () {
    test('canonical ids match WorkerPool plural field names', () {
      expect(WorkerTier.peasant.id, 'peasants');
      expect(WorkerTier.apprentice.id, 'apprentices');
      expect(WorkerTier.journeyman.id, 'journeymen');
      expect(WorkerTier.master.id, 'masters');
    });

    test('isTrained is true only for non-peasant tiers', () {
      expect(WorkerTier.peasant.isTrained, isFalse);
      expect(WorkerTier.apprentice.isTrained, isTrue);
      expect(WorkerTier.journeyman.isTrained, isTrue);
      expect(WorkerTier.master.isTrained, isTrue);
    });

    test('fromId round-trips every canonical id', () {
      for (final tier in WorkerTier.values) {
        expect(WorkerTier.fromId(tier.id), tier);
      }
    });

    test('fromId throws ArgumentError for unknown id', () {
      expect(() => WorkerTier.fromId('peasant'), throwsA(isA<ArgumentError>()));
      expect(() => WorkerTier.fromId(''), throwsA(isA<ArgumentError>()));
      expect(
        () => WorkerTier.fromId('engineer'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('tryFromId returns null for unknown id', () {
      expect(WorkerTier.tryFromId('engineer'), isNull);
      expect(WorkerTier.tryFromId(''), isNull);
      expect(WorkerTier.tryFromId('peasants'), WorkerTier.peasant);
    });
  });
}
