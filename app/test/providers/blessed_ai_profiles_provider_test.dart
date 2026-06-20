// Tests for blessed AI profile Riverpod catalog providers. Refs #3444.

import 'dart:convert';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/providers/blessed_ai_profiles_provider.dart';

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

  test('blessedAiProfileNamesProvider exposes sorted manifest names', () async {
    _mockAssets({
      kBlessedAiProfilesManifestAsset: manifestFor(['zeta', 'alpha']),
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final names = await container.read(blessedAiProfileNamesProvider.future);

    expect(names, ['alpha', 'zeta']);
  });

  test('blessedAiProfileCatalogProvider exposes loaded profiles', () async {
    final victoria = seedAiProfilesById['victoria']!;
    _mockAssets({
      kBlessedAiProfilesManifestAsset: manifestFor(['aggressive']),
      blessedAiProfileAssetPath('aggressive'): jsonEncode(victoria.toJson()),
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final catalog = await container.read(
      blessedAiProfileCatalogProvider.future,
    );

    expect(catalog.keys, ['aggressive']);
    expect(catalog['aggressive']!.profileId, victoria.profileId);
  });

  test('catalog provider yields empty map when no profiles blessed', () async {
    _mockAssets({kBlessedAiProfilesManifestAsset: manifestFor([])});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final catalog = await container.read(
      blessedAiProfileCatalogProvider.future,
    );

    expect(catalog, isEmpty);
  });
}
