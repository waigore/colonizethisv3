// Pins DLG30001 sea-zone destination hostile-fleet intel (Refs #4573).

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_destination_intel.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_destination_intel_labels.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'move_fleet_destination_intel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('computeMoveFleetDestinationIntelSummary', () {
    test('unknown when playerView is null', () {
      final game = buildMoveFleetDestinationIntelGame(visibilityByTile: const {});
      final summary = computeMoveFleetDestinationIntelSummary(
        game: game,
        playerView: null,
        humanPlayerId: moveFleetDestIntelHumanId,
        regionId: 'oldWorld',
        destinationSeaZoneId: moveFleetDestIntelSea,
      );
      expect(summary.intelLevel, MoveFleetDestinationIntelLevel.unknown);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        moveFleetDestinationIntelSummaryLines(l10n, summary),
        ['Fleets unknown'],
      );
    });

    test('unknown when every water tile is unrevealed', () {
      final game = buildMoveFleetDestinationIntelGame(
        visibilityByTile: const {},
        fleets: [
          buildHostileAtSeaFleet(id: 'enemy_p', mission: FleetMission.patrol),
        ],
      );
      final view = buildPlayerView(
        game,
        const MapTopology(),
        moveFleetDestIntelHumanId,
      );
      final summary = computeMoveFleetDestinationIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: moveFleetDestIntelHumanId,
        regionId: 'oldWorld',
        destinationSeaZoneId: moveFleetDestIntelSea,
      );
      expect(summary.intelLevel, MoveFleetDestinationIntelLevel.unknown);
      expect(summary.hostileAtSeaCount, isNull);
    });

    test('hostile patrol gist when at-war patrol is visible', () {
      final game = buildMoveFleetDestinationIntelGame(
        visibilityByTile: const {
          moveFleetDestIntelSeaTile: 'fullyVisible',
        },
        fleets: [
          buildHostileAtSeaFleet(id: 'enemy_p', mission: FleetMission.patrol),
        ],
      );
      final view = buildPlayerView(
        game,
        const MapTopology(),
        moveFleetDestIntelHumanId,
      );
      final summary = computeMoveFleetDestinationIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: moveFleetDestIntelHumanId,
        regionId: 'oldWorld',
        destinationSeaZoneId: moveFleetDestIntelSea,
      );
      expect(summary.intelLevel, MoveFleetDestinationIntelLevel.full);
      expect(summary.hostileAtSeaCount, 1);
      expect(summary.anyHostilePatrol, isTrue);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        moveFleetDestinationIntelSummaryLines(l10n, summary),
        ['Hostile patrol'],
      );
    });

    test('hostile blockade gist when at-war blockade is visible', () {
      final game = buildMoveFleetDestinationIntelGame(
        visibilityByTile: const {
          moveFleetDestIntelSeaTile: 'fogged',
        },
        fleets: [
          buildHostileAtSeaFleet(
            id: 'enemy_b',
            mission: FleetMission.blockade,
          ),
        ],
      );
      final view = buildPlayerView(
        game,
        const MapTopology(),
        moveFleetDestIntelHumanId,
      );
      final summary = computeMoveFleetDestinationIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: moveFleetDestIntelHumanId,
        regionId: 'oldWorld',
        destinationSeaZoneId: moveFleetDestIntelSea,
      );
      expect(summary.anyHostileBlockade, isTrue);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        moveFleetDestinationIntelSummaryLines(l10n, summary),
        ['Hostile blockade'],
      );
    });

    test('hostile count when missions are not patrol or blockade', () {
      final game = buildMoveFleetDestinationIntelGame(
        visibilityByTile: const {
          moveFleetDestIntelSeaTile: 'fullyVisible',
        },
        fleets: [
          buildHostileAtSeaFleet(id: 'enemy_d', mission: FleetMission.defend),
          buildHostileAtSeaFleet(id: 'enemy_n', mission: FleetMission.none),
        ],
      );
      final view = buildPlayerView(
        game,
        const MapTopology(),
        moveFleetDestIntelHumanId,
      );
      final summary = computeMoveFleetDestinationIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: moveFleetDestIntelHumanId,
        regionId: 'oldWorld',
        destinationSeaZoneId: moveFleetDestIntelSea,
      );
      expect(summary.hostileAtSeaCount, 2);
      expect(summary.anyHostilePatrol, isFalse);
      expect(summary.anyHostileBlockade, isFalse);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        moveFleetDestinationIntelSummaryLines(l10n, summary),
        ['Hostile fleets: 2'],
      );
    });

    test('no gist line when destination has no at-war hostile fleets', () {
      final game = buildMoveFleetDestinationIntelGame(
        visibilityByTile: const {
          moveFleetDestIntelSeaTile: 'fullyVisible',
        },
      );
      final view = buildPlayerView(
        game,
        const MapTopology(),
        moveFleetDestIntelHumanId,
      );
      final summary = computeMoveFleetDestinationIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: moveFleetDestIntelHumanId,
        regionId: 'oldWorld',
        destinationSeaZoneId: moveFleetDestIntelSea,
      );
      expect(summary.hasHostilePresence, isFalse);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(moveFleetDestinationIntelSummaryLines(l10n, summary), isEmpty);
    });

    test('ignores hostile fleets that are in port', () {
      final game = buildMoveFleetDestinationIntelGame(
        visibilityByTile: const {
          moveFleetDestIntelSeaTile: 'fullyVisible',
        },
        fleets: [
          Fleet(
            id: 'enemy_port',
            ownerId: moveFleetDestIntelRivalId,
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|p_home',
            ships: const [ShipInstance(id: 'ep1', typeId: 'carrack')],
            mission: FleetMission.patrol,
          ),
        ],
      );
      final view = buildPlayerView(
        game,
        const MapTopology(),
        moveFleetDestIntelHumanId,
      );
      final summary = computeMoveFleetDestinationIntelSummary(
        game: game,
        playerView: view,
        humanPlayerId: moveFleetDestIntelHumanId,
        regionId: 'oldWorld',
        destinationSeaZoneId: moveFleetDestIntelSea,
      );
      expect(summary.hostileAtSeaCount, 0);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(moveFleetDestinationIntelSummaryLines(l10n, summary), isEmpty);
    });
  });
}
