import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
  group('improvementTechCapForCell', () {
    test('returns terrain-clamped tech cap for owned land with resource', () {
      expect(
        improvementTechCapForCell(
          isSea: false,
          ownerFactionId: 'gp1',
          viewingFactionId: 'gp1',
          techUnlocked: const {},
          resourceId: Resource.grain.name,
          terrainType: TerrainType.plains,
        ),
        defaultExtractionCap,
      );
    });

    test('returns null for foreign owner and global observe', () {
      expect(
        improvementTechCapForCell(
          isSea: false,
          ownerFactionId: 'gp2',
          viewingFactionId: 'gp1',
          techUnlocked: const {},
          resourceId: Resource.grain.name,
          terrainType: TerrainType.plains,
        ),
        isNull,
      );
      expect(
        improvementTechCapForCell(
          isSea: false,
          ownerFactionId: 'gp1',
          viewingFactionId: null,
          techUnlocked: const {},
          resourceId: Resource.grain.name,
          terrainType: TerrainType.plains,
        ),
        isNull,
      );
    });
  });

  group('resolveImprovementCornerMark', () {
    test('paints muted 1 of 1 at cap and non-muted 1 of 2 with headroom', () {
      expect(
        resolveImprovementCornerMark(
          improvementLevel: 1,
          improvementTechCap: 1,
          resourceVisible: true,
          unrevealed: false,
          showImprovements: true,
        ),
        isA<ImprovementCornerMark>()
            .having((m) => m.text, 'text', '1 of 1')
            .having((m) => m.muted, 'muted', isTrue)
            .having((m) => m.hasCapDenominator, 'cap', isTrue),
      );
      expect(
        resolveImprovementCornerMark(
          improvementLevel: 1,
          improvementTechCap: 2,
          resourceVisible: true,
          unrevealed: false,
          showImprovements: true,
        ),
        isA<ImprovementCornerMark>()
            .having((m) => m.text, 'text', '1 of 2')
            .having((m) => m.muted, 'muted', isFalse),
      );
    });

    test(
      'paints level-only for foreign, hidden resource, and compact fallback',
      () {
        expect(
          resolveImprovementCornerMark(
            improvementLevel: 2,
            improvementTechCap: null,
            resourceVisible: true,
            unrevealed: false,
            showImprovements: true,
          )?.text,
          '2',
        );
        expect(
          resolveImprovementCornerMark(
            improvementLevel: 2,
            improvementTechCap: 3,
            resourceVisible: false,
            unrevealed: false,
            showImprovements: true,
          )?.text,
          '2',
        );
        expect(
          resolveImprovementCornerMark(
            improvementLevel: 1,
            improvementTechCap: 1,
            resourceVisible: true,
            unrevealed: false,
            showImprovements: true,
            compact: true,
          )?.text,
          '1/1',
        );
      },
    );

    test('paints nothing for level 0, unrevealed, or improvements off', () {
      expect(
        resolveImprovementCornerMark(
          improvementLevel: 0,
          improvementTechCap: 1,
          resourceVisible: true,
          unrevealed: false,
          showImprovements: true,
        ),
        isNull,
      );
      expect(
        resolveImprovementCornerMark(
          improvementLevel: 1,
          improvementTechCap: 1,
          resourceVisible: true,
          unrevealed: true,
          showImprovements: true,
        ),
        isNull,
      );
      expect(
        resolveImprovementCornerMark(
          improvementLevel: 1,
          improvementTechCap: 1,
          resourceVisible: true,
          unrevealed: false,
          showImprovements: false,
        ),
        isNull,
      );
    });
  });

  group('buildInitGameMapViewData improvementTechCap', () {
    test('sets cap on owned grain and omits it for foreign and observe', () {
      final owned = _grainFarmView(
        viewingFactionId: 'gp1',
        techUnlocked: const {},
      );
      expect(owned.oldWorld.cells.first.improvementTechCap, 1);

      final raised = _grainFarmView(
        viewingFactionId: 'gp1',
        techUnlocked: const {kTechIdLandEnclosure: true},
      );
      expect(raised.oldWorld.cells.first.improvementTechCap, 2);

      final foreignOwner = _grainFarmView(
        viewingFactionId: 'gp1',
        techUnlocked: const {},
        ownerId: 'gp2',
      );
      expect(foreignOwner.oldWorld.cells.first.improvementTechCap, isNull);

      final observe = _grainFarmView(
        viewingFactionId: null,
        techUnlocked: null,
      );
      expect(observe.oldWorld.cells.first.improvementTechCap, isNull);
    });
  });
}

InitGameMapViewData _grainFarmView({
  required String? viewingFactionId,
  required Map<String, bool>? techUnlocked,
  String ownerId = 'gp1',
}) {
  const tileKey = 'oldWorld|p1|0|0';
  final scenario = dualRegionScenario(
    game: minimalGame(
      oldWorldProvinces: [
        Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: ownerId),
      ],
      newWorldProvinces: const [
        Province(id: 'newWorld|p1', regionId: 'newWorld'),
      ],
      players: [
        Player(
          id: 'gp1',
          displayName: 'GP',
          isHuman: true,
          techUnlocked: techUnlocked,
        ),
      ],
      tileState: const TileMapState(improvementByTile: {tileKey: 1}),
    ),
    oldWorldGrid: const [
      ['p1'],
    ],
    oldWorldTopology: regionTopology(
      regionId: 'oldWorld',
      provinceIds: const ['p1'],
    ),
    oldWorldTerrainGrid: const [
      [TerrainType.plains],
    ],
    oldWorldResourceGrid: const [
      [Resource.grain],
    ],
  );
  return buildViewDataForScenario(
    scenario,
    viewingFactionId: viewingFactionId,
    viewingTechUnlocked: techUnlocked,
  );
}
