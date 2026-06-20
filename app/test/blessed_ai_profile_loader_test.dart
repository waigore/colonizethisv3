// Tests for BlessedAiProfileLoader asset-bundle loading. Refs #3444.

import 'dart:convert';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/core/services/blessed_ai_profile_loader.dart';

ByteData _utf8Bytes(String value) {
  final bytes = utf8.encode(value);
  return ByteData.view(Uint8List.fromList(bytes).buffer);
}

void _mockAssets(Map<String, String> contents) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final key = const StringCodec().decodeMessage(message);
        final value = contents[key];
        if (value == null) {
          return null;
        }
        return _utf8Bytes(value);
      });
}

void main() {
  suppressLogsForTests();

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(rootBundle.clear);

  tearDown(() {
    rootBundle.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  String manifestFor(List<String> names) => jsonEncode({
    'profiles': [
      for (final name in names)
        {
          'name': name,
          'source_run_id': 'ga-run-test',
          'source_profile_id': 'profile-001',
          'source_fitness': 1.0,
          'blessed_at': '2026-01-01T00:00:00Z',
        },
    ],
  });

  group('loadBlessedProfileNames', () {
    test('returns manifest names sorted', () async {
      _mockAssets({
        kBlessedAiProfilesManifestAsset: manifestFor(['zeta', 'alpha', 'mid']),
      });

      final names = await BlessedAiProfileLoader.loadBlessedProfileNames();

      expect(names, ['alpha', 'mid', 'zeta']);
    });

    test('skips empty and non-string names', () async {
      _mockAssets({
        kBlessedAiProfilesManifestAsset: jsonEncode({
          'profiles': [
            {'name': 'good'},
            {'name': ''},
            {'name': 42},
            {'notname': 'ignored'},
          ],
        }),
      });

      final names = await BlessedAiProfileLoader.loadBlessedProfileNames();

      expect(names, ['good']);
    });

    test('returns empty when manifest root is not a map', () async {
      _mockAssets({kBlessedAiProfilesManifestAsset: jsonEncode([1, 2, 3])});

      expect(await BlessedAiProfileLoader.loadBlessedProfileNames(), isEmpty);
    });

    test('returns empty when profiles entry is not a list', () async {
      _mockAssets({
        kBlessedAiProfilesManifestAsset: jsonEncode({'profiles': 'nope'}),
      });

      expect(await BlessedAiProfileLoader.loadBlessedProfileNames(), isEmpty);
    });
  });

  group('loadCatalog', () {
    test('loads blessed profiles keyed by manifest name', () async {
      final victoria = seedAiProfilesById['victoria']!;
      final napoleon = seedAiProfilesById['napoleon']!;
      _mockAssets({
        kBlessedAiProfilesManifestAsset: manifestFor(['aggressive', 'defensive']),
        blessedAiProfileAssetPath('aggressive'): jsonEncode(victoria.toJson()),
        blessedAiProfileAssetPath('defensive'): jsonEncode(napoleon.toJson()),
      });

      final catalog = await BlessedAiProfileLoader.loadCatalog();

      expect(catalog.keys, containsAll(['aggressive', 'defensive']));
      expect(catalog['aggressive']!.profileId, victoria.profileId);
      expect(catalog['defensive']!.profileId, napoleon.profileId);
    });

    test('returns empty when manifest lists no profiles', () async {
      _mockAssets({kBlessedAiProfilesManifestAsset: manifestFor([])});

      expect(await BlessedAiProfileLoader.loadCatalog(), isEmpty);
    });

    test('skips a profile whose asset fails to load', () async {
      final victoria = seedAiProfilesById['victoria']!;
      _mockAssets({
        kBlessedAiProfilesManifestAsset: manifestFor(['present', 'missing']),
        blessedAiProfileAssetPath('present'): jsonEncode(victoria.toJson()),
      });

      final catalog = await BlessedAiProfileLoader.loadCatalog();

      expect(catalog.keys, ['present']);
    });

    test('returns empty when a blessed profile JSON is invalid', () async {
      _mockAssets({
        kBlessedAiProfilesManifestAsset: manifestFor(['broken']),
        blessedAiProfileAssetPath('broken'): 'not-json',
      });

      expect(await BlessedAiProfileLoader.loadCatalog(), isEmpty);
    });
  });
}
