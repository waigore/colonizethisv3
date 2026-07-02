import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/src/setup/faction_setup_helpers.dart';
import 'package:colonizethis_test/test.dart';

/// Shared faction ownership/markdown helpers (Refs #3449): collapse the
/// duplicated `.where(owner).map(id).toList()..sort()` collection sites and the
/// repeated "Faction Setup" row construction while preserving byte-identical
/// observable output.
void main() {
  Province prov(String id, String? ownerId) =>
      Province(id: id, regionId: 'oldWorld', ownerId: ownerId);

  group('ownedProvinceIdsForFaction', () {
    test('positive: returns sorted ids owned by the faction by default', () {
      final provinces = [
        prov('ow|p3', 'gp1'),
        prov('ow|p1', 'gp1'),
        prov('ow|p2', 'gp2'),
        prov('ow|p0', 'gp1'),
      ];
      expect(ownedProvinceIdsForFaction(provinces, 'gp1'), [
        'ow|p0',
        'ow|p1',
        'ow|p3',
      ]);
    });

    test('positive: sorted=false preserves source iteration order', () {
      final provinces = [
        prov('ow|p3', 'gp1'),
        prov('ow|p1', 'gp1'),
        prov('ow|p0', 'gp1'),
      ];
      expect(ownedProvinceIdsForFaction(provinces, 'gp1', sorted: false), [
        'ow|p3',
        'ow|p1',
        'ow|p0',
      ]);
    });

    test('negative: faction owning nothing yields an empty list', () {
      final provinces = [prov('ow|p1', 'gp1'), prov('ow|p2', null)];
      expect(ownedProvinceIdsForFaction(provinces, 'gp9'), isEmpty);
    });

    test('matches the previous inline where/map/sort expression exactly', () {
      final provinces = [
        prov('ow|b', 'gp1'),
        prov('ow|a', 'gp1'),
        prov('ow|c', 'gp2'),
      ];
      final legacy =
          provinces
              .where((pr) => pr.ownerId == 'gp1')
              .map((pr) => pr.id)
              .toList()
            ..sort();
      expect(ownedProvinceIdsForFaction(provinces, 'gp1'), legacy);
    });
  });

  group('ownedProvincesForFaction', () {
    test('positive: returns provinces sorted by id by default', () {
      final provinces = [
        prov('ow|p3', 'gp1'),
        prov('ow|p1', 'gp1'),
        prov('ow|p2', 'gp2'),
        prov('ow|p0', 'gp1'),
      ];
      expect(
        ownedProvincesForFaction(provinces, 'gp1').map((p) => p.id).toList(),
        ['ow|p0', 'ow|p1', 'ow|p3'],
      );
    });

    test('positive: sorted=false preserves source iteration order', () {
      final provinces = [
        prov('ow|p3', 'gp1'),
        prov('ow|p1', 'gp1'),
        prov('ow|p0', 'gp1'),
      ];
      expect(
        ownedProvincesForFaction(
          provinces,
          'gp1',
          sorted: false,
        ).map((p) => p.id).toList(),
        ['ow|p3', 'ow|p1', 'ow|p0'],
      );
    });

    test('negative: faction owning nothing yields an empty list', () {
      final provinces = [prov('ow|p1', 'gp1'), prov('ow|p2', null)];
      expect(ownedProvincesForFaction(provinces, 'gp9'), isEmpty);
    });

    test(
      'matches the previous inline where/toList/sort expression exactly',
      () {
        final provinces = [
          prov('ow|b', 'gp1'),
          prov('ow|a', 'gp1'),
          prov('ow|c', 'gp2'),
        ];
        final legacy = provinces.where((pr) => pr.ownerId == 'gp1').toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        expect(ownedProvincesForFaction(provinces, 'gp1'), legacy);
      },
    );
  });

  group('factionSetupTableRow', () {
    test('positive: byte-identical to the legacy Great Power row format', () {
      const id = 'gp1';
      const displayName = 'England';
      const capital = 'ow|cap1';
      final owned = ['ow|p1', 'ow|p2'];
      final legacy =
          '| $displayName ($id) | Great Power | $capital | ${owned.join(", ")} |';
      expect(
        factionSetupTableRow(
          displayLabel: displayName,
          factionId: id,
          typeLabel: 'Great Power',
          capitalProvinceId: capital,
          ownedProvinceIds: owned,
        ),
        legacy,
      );
    });

    test('negative: null capital renders as an em dash', () {
      final row = factionSetupTableRow(
        displayLabel: 'tribe1',
        factionId: 'tribe1',
        typeLabel: 'Tribe',
        capitalProvinceId: null,
        ownedProvinceIds: const [],
      );
      expect(row, '| tribe1 (tribe1) | Tribe | — |  |');
    });
  });

  group('collectCapitalMapsByOwner', () {
    test('positive: collects capitals for players, minors, and tribes', () {
      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: true,
            capitalProvinceId: 'ow|p1',
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'ow|p1',
              x: 1,
              y: 2,
            ),
          ),
        ],
        minorNations: [
          MinorNation(
            id: 'minor1',
            capitalProvinceId: 'ow|m1',
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'ow|m1',
              x: 0,
              y: 0,
            ),
          ),
        ],
        tribes: [
          Tribe(
            id: 'tribe1',
            capitalProvinceId: 'nw|t1',
            capitalTile: const CapitalTile(
              regionId: 'newWorld',
              provinceId: 'nw|t1',
              x: 3,
              y: 4,
            ),
          ),
        ],
      );

      final maps = collectCapitalMapsByOwner(game);
      expect(maps.capitalProvinceIdByOwner, {
        'gp1': 'ow|p1',
        'minor1': 'ow|m1',
        'tribe1': 'nw|t1',
      });
      expect(maps.capitalTileKeyByOwner['gp1'], contains('oldWorld'));
      expect(maps.capitalTileKeyByOwner['minor1'], isNotNull);
      expect(maps.capitalTileKeyByOwner['tribe1'], isNotNull);
    });

    test('negative: factions without both capital fields are omitted', () {
      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: true,
            capitalProvinceId: 'ow|p1',
          ),
        ],
      );

      expect(collectCapitalMapsByOwner(game).capitalProvinceIdByOwner, isEmpty);
    });
  });

  group('forEachSetupFaction', () {
    test('positive: visits players, minors, then tribes in slot order', () {
      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(id: 'gp1', displayName: 'A', isHuman: true),
          const Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        minorNations: [const MinorNation(id: 'minor1')],
        tribes: [const Tribe(id: 'tribe1')],
      );

      final visited = <String>[];
      forEachSetupFaction(
        game,
        onPlayer: (p) => visited.add('p:${p.id}'),
        onMinorNation: (m) => visited.add('m:${m.id}'),
        onTribe: (t) => visited.add('t:${t.id}'),
      );

      expect(visited, ['p:gp1', 'p:gp2', 'm:minor1', 't:tribe1']);
    });
  });
}
