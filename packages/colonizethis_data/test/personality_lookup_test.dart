import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('personalityLookupKeyForAi', () {
    test('uses known personalityId override over leader key', () {
      expect(
        personalityLookupKeyForAi(
          leaderKeyOrId: 'england_leader',
          personalityId: 'napoleon',
        ),
        'napoleon',
      );
    });

    test('falls back to canonical leader when personalityId unknown', () {
      expect(
        personalityLookupKeyForAi(
          leaderKeyOrId: 'england_leader',
          personalityId: 'unknown_archetype',
        ),
        'victoria',
      );
    });
  });
}
