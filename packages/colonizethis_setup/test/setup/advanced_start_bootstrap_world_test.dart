import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_setup/src/setup/advanced_start_nw_topology.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'advanced_start_test_support.dart';

void main() {
  group('applyAdvancedStartWorldKnowledge', () {
    test('turns50 reveals contiguous NW provinces without prospecting', () {
      final result = applyAdvancedStartWorldKnowledge(
        game: advancedStartWorldKnowledgeFixture(),
        startType: AdvancedStartType.turns50,
        topologyOldWorld: advancedStartOwCapitalTopology(),
        topologyNewWorld: advancedStartWorldKnowledgeNwTopology(),
        warpLinks: advancedStartDefaultWarpLinks,
      );

      final visibility =
          result.game.worldState.playerVisibilityByTile['gp1'] ?? const {};
      expect(visibility['newWorld|p1|0|0'], VisibilityLevel.fullyVisible.name);
      expect(visibility['newWorld|p2|0|0'], VisibilityLevel.fullyVisible.name);
      expect(result.encounteredTribeIds, contains('tribe1'));
      expect(result.encounteredTribeIds, isNot(contains('tribe2')));

      expect(visibility['newWorld|s1|0|0'], VisibilityLevel.fogged.name);
      expect(visibility['newWorld|s2|0|0'], VisibilityLevel.fogged.name);
      expect(visibility['newWorld|s3|0|0'], VisibilityLevel.unknown.name);

      final prospected =
          result.game.worldState.playerProspectedTiles['gp1'] ?? const {};
      expect(prospected, isEmpty);
    });

    test('turns100 reveals all NW provinces', () {
      final result = applyAdvancedStartWorldKnowledge(
        game: advancedStartWorldKnowledgeFixture(),
        startType: AdvancedStartType.turns100,
        topologyOldWorld: advancedStartOwCapitalTopology(),
        topologyNewWorld: advancedStartWorldKnowledgeNwTopology(),
        warpLinks: advancedStartDefaultWarpLinks,
      );

      final visibility =
          result.game.worldState.playerVisibilityByTile['gp1'] ?? const {};
      expect(visibility['newWorld|p3|0|0'], VisibilityLevel.fullyVisible.name);
      expect(result.encounteredTribeIds, containsAll(['tribe1', 'tribe2']));

      expect(visibility['newWorld|s1|0|0'], VisibilityLevel.fogged.name);
      expect(visibility['newWorld|s2|0|0'], VisibilityLevel.fogged.name);
      expect(visibility['newWorld|s3|0|0'], VisibilityLevel.fogged.name);
    });
  });

  group('advancedStartFoggedNwSeaZoneLocalIds', () {
    test('returns shortest S-S path from entry to adjacent seas only', () {
      final seas = advancedStartFoggedNwSeaZoneLocalIds(
        topologyNewWorld: advancedStartWorldKnowledgeNwTopology(),
        entrySeaZoneLocalIds: const ['s1'],
        revealedProvinceLocalIds: const {'p1', 'p2'},
      );
      expect(seas, ['s1', 's2']);
    });

    test('returns empty when no entry seas', () {
      expect(
        advancedStartFoggedNwSeaZoneLocalIds(
          topologyNewWorld: advancedStartWorldKnowledgeNwTopology(),
          entrySeaZoneLocalIds: const [],
          revealedProvinceLocalIds: const {'p1'},
        ),
        isEmpty,
      );
    });
  });

  group('applyAdvancedStartCoastalSeaVisibility', () {
    test('promotes owned-coast NW seas to fullyVisible', () {
      final game = advancedStartWorldGame(
        oldWorldProvinces: const [],
        newWorldProvinces: [
          Province(
            id: 'newWorld|p1',
            regionId: kRegionNewWorld,
            ownerId: 'gp1',
          ),
          Province(
            id: 'newWorld|p2',
            regionId: kRegionNewWorld,
            ownerId: 'tribe1',
          ),
        ],
        owTiles: null,
        nwTiles: {
          'newWorld|s1': ['newWorld|s1|0|0'],
          'newWorld|s2': ['newWorld|s2|0|0'],
        },
        resourceByTileKey: const {},
        playerVisibilityByTile: {
          'gp1': {
            'newWorld|s1|0|0': VisibilityLevel.fogged.name,
            'newWorld|s2|0|0': VisibilityLevel.fogged.name,
          },
        },
        player: advancedStartDefaultPlayer,
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        turnNumber: 100,
      );

      final updated = applyAdvancedStartCoastalSeaVisibility(
        game: game,
        topologyByRegion: {
          kRegionNewWorld: advancedStartWorldKnowledgeNwTopology(),
        },
      );

      final visibility =
          updated.worldState.playerVisibilityByTile['gp1'] ?? const {};
      expect(visibility['newWorld|s1|0|0'], VisibilityLevel.fullyVisible.name);
      expect(visibility['newWorld|s2|0|0'], VisibilityLevel.fogged.name);
    });
  });

  group('applyAdvancedStartDiplomacy', () {
    test('turns50 adds consulates for minors and encountered tribes', () {
      final game = applyAdvancedStartDiplomacy(
        game: advancedStartWorldKnowledgeFixture(),
        startType: AdvancedStartType.turns50,
        encounteredTribeIds: const {'tribe1'},
      );

      expect(
        getOverture(game, 'gp1', 'minor1')!.stage,
        OvertureStage.tradeConsulate,
      );
      expect(
        getOverture(game, 'gp1', 'tribe1')!.stage,
        OvertureStage.tradeConsulate,
      );
      expect(getOverture(game, 'gp1', 'tribe2'), isNull);
    });

    test('turns100 adds embassies for minors and encountered tribes', () {
      final game = applyAdvancedStartDiplomacy(
        game: advancedStartWorldKnowledgeFixture(),
        startType: AdvancedStartType.turns100,
        encounteredTribeIds: const {'tribe1', 'tribe2'},
      );

      expect(getOverture(game, 'gp1', 'minor1')!.stage, OvertureStage.embassy);
      expect(getOverture(game, 'gp1', 'tribe2')!.hasEmbassy, isTrue);
    });
  });
}
