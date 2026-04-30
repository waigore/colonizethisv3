import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('tech effect summary', () {
    test('every authored tech exists in the catalog', () {
      for (final techId in techEffectSummaryAuthoredTechIds) {
        expect(techCatalog.containsKey(techId), isTrue, reason: techId);
      }
    });

    test('line ids resolve to non-placeholder English', () {
      final ids = techEffectSummaryLineIdsFor(kTechIdUniversity);
      expect(ids.length, greaterThanOrEqualTo(2));
      for (final id in ids) {
        final en = techEffectSummaryMessageEn(id);
        expect(en.isNotEmpty, isTrue, reason: id);
        expect(en, isNot(equals(id)), reason: id);
      }
    });

    test('university first line matches historical copy', () {
      expect(
        techEffectSummaryMessageEn('techEffectSummary_university_0'),
        'Enables: Fourth active research slot (3 -> 4)',
      );
    });
  });
}
