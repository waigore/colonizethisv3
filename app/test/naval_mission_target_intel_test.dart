// Pins DLG31002 harbor intel helpers (Refs #4340).

import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_intel.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_intel_labels.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_mission_target_intel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('computeNavalMissionHarborIntelSummary', () {
    test('unknown when playerView is null', () {
      final game = buildNavalMissionIntelGame(visibilityByTile: const {});
      final summary = computeNavalMissionHarborIntelSummary(
        game: game,
        playerView: null,
        humanPlayerId: navalIntelHumanId,
        targetProvinceId: navalIntelPortProvince,
      );
      expect(summary.intelLevel, NavalMissionHarborIntelLevel.unknown);
    });

    test('unknown when target tiles are fogged', () {
      final game = buildNavalMissionIntelGame(
        visibilityByTile: {
          'oldWorld|p_port|0|0': 'fogged',
        },
        portsByProvinceSeaboard: const {
          'oldWorld|p_port|sea1': 'oldWorld|p_port|0|0',
        },
      );
      final view = buildPlayerView(game, const MapTopology(), navalIntelHumanId);
      final summary = computeNavalMissionHarborIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: navalIntelHumanId,
        targetProvinceId: navalIntelPortProvince,
      );
      expect(summary.intelLevel, NavalMissionHarborIntelLevel.unknown);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        navalMissionHarborIntelSummaryLines(l10n, summary),
        ['Harbor status unknown'],
      );
    });

    test('full intel empty harbor when port present and no hostile fleets', () {
      final game = buildNavalMissionIntelGame(
        visibilityByTile: {
          'oldWorld|p_port|0|0': 'fullyVisible',
        },
        portsByProvinceSeaboard: const {
          'oldWorld|p_port|sea1': 'oldWorld|p_port|0|0',
        },
      );
      final view = buildPlayerView(game, const MapTopology(), navalIntelHumanId);
      final summary = computeNavalMissionHarborIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: navalIntelHumanId,
        targetProvinceId: navalIntelPortProvince,
      );
      expect(summary.intelLevel, NavalMissionHarborIntelLevel.full);
      expect(summary.portPresent, isTrue);
      expect(summary.emptyHarbor, isTrue);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        navalMissionHarborIntelSummaryLines(l10n, summary),
        ['Empty harbor'],
      );
    });

    test('full intel summarizes two hostile fleets in port', () {
      final game = buildNavalMissionIntelGame(
        visibilityByTile: {
          'oldWorld|p_port|0|0': 'fullyVisible',
        },
        portsByProvinceSeaboard: const {
          'oldWorld|p_port|sea1': 'oldWorld|p_port|0|0',
        },
        fleets: [
          Fleet(
            id: 'enemy_a',
            ownerId: navalIntelRivalId,
            regionId: 'oldWorld',
            inPortAtProvinceId: navalIntelPortProvince,
            ships: const [ShipInstance(id: 'ea', typeId: 'carrack')],
          ),
          Fleet(
            id: 'enemy_b',
            ownerId: navalIntelRivalId,
            regionId: 'oldWorld',
            inPortAtProvinceId: navalIntelPortProvince,
            ships: const [ShipInstance(id: 'eb', typeId: 'galleon')],
          ),
        ],
      );
      final view = buildPlayerView(game, const MapTopology(), navalIntelHumanId);
      final summary = computeNavalMissionHarborIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: navalIntelHumanId,
        targetProvinceId: navalIntelPortProvince,
      );
      expect(summary.hostileFleetsInPortCount, 2);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        navalMissionHarborIntelSummaryLines(l10n, summary),
        ['2 fleets in port'],
      );
    });

    test('full intel reports no port when seaboard registry is empty', () {
      final game = buildNavalMissionIntelGame(
        visibilityByTile: {
          'oldWorld|p_coast|0|0': 'fullyVisible',
        },
      );
      final view = buildPlayerView(game, const MapTopology(), navalIntelHumanId);
      final summary = computeNavalMissionHarborIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: navalIntelHumanId,
        targetProvinceId: navalIntelNoPortProvince,
      );
      expect(summary.portPresent, isFalse);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        navalMissionHarborIntelSummaryLines(l10n, summary),
        ['No port'],
      );
    });
  });
}
