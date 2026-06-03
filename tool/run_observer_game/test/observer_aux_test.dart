import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:run_observer_game/observer_snapshot_v1.dart';
import 'package:run_observer_game/setup_config_parser.dart';

void main() {
  group('gameSetupFromObserverCli', () {
    // Refs #3176: the observer always forces a fully-AI game via
    // humanGreatPowerSlotIndices = {} (no post-init aiControlByGpId override).
    test('default (no file, no seed) keeps defaults but forces fully-AI', () {
      final c = gameSetupFromObserverCli();
      expect(c.humanGreatPowerSlotIndices, isEmpty);
      expect(c.seed, GameSetupConfig.defaultConfig.seed);
      expect(
        c.selectedGreatPowerIds,
        GameSetupConfig.defaultConfig.selectedGreatPowerIds,
      );
    });

    test('seed override replaces config seed and preserves fully-AI', () {
      final c = gameSetupFromObserverCli(seedOverride: 42);
      expect(c.seed, 42);
      expect(c.humanGreatPowerSlotIndices, isEmpty);
      expect(c.selectedGreatPowerIds, GameSetupConfig.defaultConfig.selectedGreatPowerIds);
    });

    test('config JSON requesting a human slot is overridden to fully-AI', () {
      final tmp = Directory.systemTemp.createTempSync('observer_cfg_human_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final path = '${tmp.path}/cfg.json';
      // Even if a config JSON tried to keep a human, the observer forces all-AI.
      File(path).writeAsStringSync(
        '{"selectedGreatPowerIds":["england","france","spain"],"seed":11}',
      );

      final c = gameSetupFromObserverCli(configJsonPath: path);
      expect(c.humanGreatPowerSlotIndices, isEmpty);
      // Preserved across a subsequent seed override too.
      final c2 = gameSetupFromObserverCli(
        configJsonPath: path,
        seedOverride: 99,
      );
      expect(c2.humanGreatPowerSlotIndices, isEmpty);
      expect(c2.seed, 99);
    });

    test('loads JSON file with selectedGreatPowerIds and leaderVariantByGpId', () {
      final tmp = Directory.systemTemp.createTempSync('observer_cfg_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final path = '${tmp.path}/cfg.json';
      File(path).writeAsStringSync(
        '{"selectedGreatPowerIds":["england","france"],"leaderVariantByGpId":'
        '{"england":"a"},"continentCount":3,"seed":7}',
      );

      final c = gameSetupFromObserverCli(configJsonPath: path);
      expect(c.selectedGreatPowerIds, ['england', 'france']);
      expect(c.leaderVariantByGpId['england'], 'a');
      expect(c.continentCount, 3);
      expect(c.seed, 7);
      expect(c.humanGreatPowerSlotIndices, isEmpty);
    });

    test('missing config file throws FileSystemException', () {
      expect(
        () => gameSetupFromObserverCli(configJsonPath: '/nonexistent/path.json'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('invalid JSON in config file throws FormatException', () {
      final tmp = Directory.systemTemp.createTempSync('observer_cfg_badjson_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final path = '${tmp.path}/bad.json';
      File(path).writeAsStringSync('{');

      expect(
        () => gameSetupFromObserverCli(configJsonPath: path),
        throwsA(isA<FormatException>()),
      );
    });

    test('loads initTownRoadWiringRegionIds from JSON file', () {
      final tmp = Directory.systemTemp.createTempSync('observer_cfg_wiring_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final path = '${tmp.path}/cfg.json';
      File(path).writeAsStringSync(
        '{"selectedGreatPowerIds":["england"],"initTownRoadWiringRegionIds":'
        '["oldWorld","newWorld"],"seed":3}',
      );

      final c = gameSetupFromObserverCli(configJsonPath: path);
      expect(c.initTownRoadWiringRegionIds, {'oldWorld', 'newWorld'});
      expect(c.seed, 3);
    });
  });

  group('observer snapshot helpers', () {
    test('buildObserverSnapshotJson uses year 1 when postResolutionTurnNumber below 1', () {
      final game = Game(
        id: 'g-min',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'england', displayName: 'England', isHuman: false),
        ],
      );
      final json = buildObserverSnapshotJson(game, postResolutionTurnNumber: 0);
      expect(json['calendarYearAtTurnStart'], TurnTimeMapping.gdd01.yearAtTurn(1));
      expect(json['turnNumber'], 0);
    });

    test(
      'fully-AI game => every player rollup reports isHuman:false (Refs #3176)',
      () {
        final game = Game(
          id: 'g-all-ai',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: [
            Player(id: 'gp1', displayName: 'Power 1', isHuman: false),
            Player(id: 'gp2', displayName: 'Power 2', isHuman: false),
            Player(id: 'gp3', displayName: 'Power 3', isHuman: false),
          ],
          aiControlByGpId: const {'gp1': true, 'gp2': true, 'gp3': true},
        );
        final json = buildObserverSnapshotJson(
          game,
          postResolutionTurnNumber: 1,
        );
        final players =
            (json['players'] as List<Object?>).cast<Map<String, Object?>>();
        expect(players, hasLength(3));
        for (final row in players) {
          expect(row['isHuman'], isFalse, reason: '${row['playerId']}');
        }
      },
    );

    test('encodeObserverSnapshotJson ends with newline', () {
      final encoded = encodeObserverSnapshotJson({
        'observerSnapshotSchemaVersion': 1,
        'gameId': 'x',
      });
      expect(encoded.endsWith('\n'), isTrue);
      expect(
        () => jsonDecode(encoded) as Map<String, dynamic>,
        returnsNormally,
      );
    });

    test('renderObserverSnapshotHtml escapes angle brackets', () {
      final html = renderObserverSnapshotHtml('{"x":"<script>"}\n');
      expect(html, contains('&lt;script&gt;'));
      expect(html, isNot(contains('<script>')));
    });
  });
}
