import 'dart:convert';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('loadAiProfilesFromJsonDocuments', () {
    test('loads valid profiles keyed by logical name', () {
      final victoria = seedAiProfilesById['victoria']!;
      final napoleon = seedAiProfilesById['napoleon']!;
      final loaded = loadAiProfilesFromJsonDocuments(<String, String>{
        'alpha': jsonEncode(victoria.toJson()),
        'beta': jsonEncode(napoleon.toJson()),
      });
      expect(loaded.length, 2);
      expect(loaded['alpha']!.profileId, victoria.profileId);
      expect(loaded['beta']!.profileId, napoleon.profileId);
    });

    test('throws AiProfileBatchLoadException for invalid JSON', () {
      expect(
        () => loadAiProfilesFromJsonDocuments(<String, String>{
          'bad': 'not-json',
        }),
        throwsA(isA<AiProfileBatchLoadException>()),
      );
    });

    test('throws AiProfileBatchLoadException for schema-invalid profile', () {
      expect(
        () => loadAiProfilesFromJsonDocuments(<String, String>{
          'bad': '{"schema_version": 99}',
        }),
        throwsA(isA<AiProfileBatchLoadException>()),
      );
    });
  });
}
