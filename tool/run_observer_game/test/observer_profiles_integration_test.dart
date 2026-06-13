import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:run_observer_game/observer_profiles.dart';
import 'package:run_observer_game/observer_session_runner.dart';

/// Small deterministic 2-player setup matching the existing observer smoke
/// tests, so a single turn resolves quickly.
GameSetupConfig _smokeSetup() => GameSetupConfig(
  selectedGreatPowerIds: const ['england', 'france'],
  continentCount: 4,
  minorNationCount: 2,
  tribeCount: 2,
  numProvincesOldWorld: 14,
  numProvincesNewWorld: 6,
  minProvincesPerMinor: 2,
  seed: 11,
  // Force a fully-AI game (matches the observer CLI) so every GP plans via
  // Full AI and emits a turn-trace AI section.
  humanGreatPowerSlotIndices: const <int>{},
);

/// Reads the single merged turn-trace JSON under [outputRoot] and returns the
/// AI section for [factionId].
Map<String, Object?> _aiSectionForFaction(String outputRoot, String factionId) {
  final gameDir = Directory('$outputRoot/observer-traces')
      .listSync()
      .whereType<Directory>()
      .single;
  final mergedTrace = gameDir
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .firstWhere(
        (n) =>
            n.endsWith('.json') &&
            !n.endsWith('.snapshot.json') &&
            n != 'run-summary.json',
      );
  final doc =
      jsonDecode(File('${gameDir.path}/$mergedTrace').readAsStringSync())
          as Map<String, dynamic>;
  final ai = (doc['ai'] as List<dynamic>).cast<Map<String, dynamic>>();
  return ai.firstWhere((s) => s['factionId'] == factionId);
}

Map<String, Object?> _domainWeights(Map<String, Object?> aiSection) {
  final thresholds = aiSection['thresholds'] as Map<String, dynamic>;
  final derived = thresholds['derived'] as Map<String, dynamic>;
  return derived['domainWeights'] as Map<String, dynamic>;
}

void main() {
  group('observer --profiles overrides AI behavior (Refs #3437)', () {
    test(
      'profile changes domain weights and records profileId in trace',
      () async {
        // Baseline run: no profiles.
        final baseDir = Directory.systemTemp.createTempSync('obs_prof_base_');
        addTearDown(() => baseDir.deleteSync(recursive: true));
        final baseCode = await runObserverSession(
          outputRoot: baseDir.path,
          setupConfig: _smokeSetup(),
          maxTurnsCap: 1,
        );
        expect(baseCode, 0);

        final baseGp1 = _aiSectionForFaction(baseDir.path, 'gp1');
        final baseState = baseGp1['state'] as Map<String, dynamic>;
        final baseContext =
            baseState['decisionContext'] as Map<String, dynamic>;
        expect(
          baseContext['profileId'],
          isNull,
          reason: 'no --profiles => profileId is null',
        );
        final baseWeights = _domainWeights(baseGp1);

        // Profiled run: gp1.json with non-default domain weights.
        final profilesDir = Directory.systemTemp.createTempSync('obs_prof_in_');
        addTearDown(() => profilesDir.deleteSync(recursive: true));
        File('${profilesDir.path}/gp1.json').writeAsStringSync(
          jsonEncode(<String, dynamic>{
            'schema_version': 1,
            'profile_id': 'gp1_test',
            'display_name': 'GP1 (test)',
            'parameters': <String, num>{
              'personalityDomainWeights.economy': 5,
              'personalityDomainWeights.military': 95,
            },
          }),
        );

        final outDir = Directory.systemTemp.createTempSync('obs_prof_out_');
        addTearDown(() => outDir.deleteSync(recursive: true));
        final code = await runObserverSession(
          outputRoot: outDir.path,
          setupConfig: _smokeSetup(),
          maxTurnsCap: 1,
          profilesDir: profilesDir.path,
        );
        expect(code, 0);

        final gp1 = _aiSectionForFaction(outDir.path, 'gp1');
        final state = gp1['state'] as Map<String, dynamic>;
        final context = state['decisionContext'] as Map<String, dynamic>;
        expect(context['profileId'], 'gp1_test');

        final weights = _domainWeights(gp1);
        expect(weights['economy'], 5);
        expect(weights['military'], 95);
        expect(
          weights,
          isNot(baseWeights),
          reason: 'profile overrides must change the trace domain weights',
        );
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'invalid profile aborts the run with kExitProfileLoadFailed',
      () async {
        final profilesDir = Directory.systemTemp.createTempSync('obs_prof_bad_');
        addTearDown(() => profilesDir.deleteSync(recursive: true));
        File('${profilesDir.path}/gp1.json')
            .writeAsStringSync('{ not valid json');

        final outDir = Directory.systemTemp.createTempSync('obs_prof_baderr_');
        addTearDown(() => outDir.deleteSync(recursive: true));
        final code = await runObserverSession(
          outputRoot: outDir.path,
          setupConfig: _smokeSetup(),
          maxTurnsCap: 1,
          profilesDir: profilesDir.path,
        );

        expect(code, kExitProfileLoadFailed);
        // No turns resolved => no merged trace directory contents.
        final traceRoot = Directory('${outDir.path}/observer-traces');
        final games = traceRoot.existsSync()
            ? traceRoot.listSync().whereType<Directory>().toList()
            : <Directory>[];
        expect(games, isEmpty);
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  });
}
