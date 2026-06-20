import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_test/test.dart';

import 'package:run_observer_game/observer_profiles.dart';

String _profileJson(String profileId, Map<String, num> parameters) {
  return jsonEncode(<String, dynamic>{
    'schema_version': 1,
    'profile_id': profileId,
    'display_name': profileId,
    'parameters': parameters,
  });
}

void main() {
  group('loadObserverProfiles', () {
    test('loads matched <playerId>.json files keyed by playerId', () {
      final dir = Directory.systemTemp.createTempSync('obs_profiles_ok_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/england.json').writeAsStringSync(
        _profileJson('eng', const {'personalityDomainWeights.economy': 5}),
      );
      File('${dir.path}/france.json').writeAsStringSync(
        _profileJson('fra', const {'personalityDomainWeights.military': 95}),
      );

      final loaded = loadObserverProfiles(
        dir: dir.path,
        playerIds: const ['england', 'france', 'spain'],
      );

      expect(loaded.keys.toSet(), {'england', 'france'});
      expect(loaded['england']!.profileId, 'eng');
      expect(loaded['france']!.profileId, 'fra');
    });

    test('Great Power without a matching file is omitted (uses default)', () {
      final dir = Directory.systemTemp.createTempSync('obs_profiles_missing_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/england.json').writeAsStringSync(
        _profileJson('eng', const {'personalityDomainWeights.economy': 5}),
      );

      final loaded = loadObserverProfiles(
        dir: dir.path,
        playerIds: const ['england', 'france'],
      );

      expect(loaded.containsKey('england'), isTrue);
      expect(
        loaded.containsKey('france'),
        isFalse,
        reason: 'no france.json -> france keeps default personality',
      );
    });

    test('unmatched .json file is ignored (not loaded)', () {
      final dir = Directory.systemTemp.createTempSync('obs_profiles_extra_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/england.json').writeAsStringSync(
        _profileJson('eng', const {'personalityDomainWeights.economy': 5}),
      );
      File('${dir.path}/atlantis.json').writeAsStringSync(
        _profileJson('atl', const {'personalityDomainWeights.economy': 5}),
      );

      final loaded = loadObserverProfiles(
        dir: dir.path,
        playerIds: const ['england', 'france'],
      );

      expect(loaded.keys.toSet(), {'england'});
    });

    test('missing directory throws ObserverProfileLoadException', () {
      final dir = Directory.systemTemp.createTempSync('obs_profiles_nodir_');
      final missing = '${dir.path}/does-not-exist';
      dir.deleteSync(recursive: true);

      expect(
        () => loadObserverProfiles(
          dir: missing,
          playerIds: const ['england'],
        ),
        throwsA(isA<ObserverProfileLoadException>()),
      );
    });

    test('unparseable matched file throws ObserverProfileLoadException', () {
      final dir = Directory.systemTemp.createTempSync('obs_profiles_bad_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/england.json').writeAsStringSync('{ not valid json');

      expect(
        () => loadObserverProfiles(
          dir: dir.path,
          playerIds: const ['england'],
        ),
        throwsA(isA<ObserverProfileLoadException>()),
      );
    });

    test('invalid schema_version matched file throws', () {
      final dir = Directory.systemTemp.createTempSync('obs_profiles_schema_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/england.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'schema_version': 99,
          'profile_id': 'eng',
          'display_name': 'eng',
          'parameters': <String, num>{},
        }),
      );

      expect(
        () => loadObserverProfiles(
          dir: dir.path,
          playerIds: const ['england'],
        ),
        throwsA(isA<ObserverProfileLoadException>()),
      );
    });
  });
}
