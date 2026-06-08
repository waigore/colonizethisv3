import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Regression bundle for GitHub #2082 / `selectFullAiCivilianWorkOrders`.
/// Split from monolith for #2288; see sibling files for scenario matrix SC-01-SC-09.
void main() {
  const playerId = 'gp1';
  const ow = 'oldWorld';

  group('Full AI civilian work #2082 regression bundle', () {
    test('three Explorers with non-empty C(e) → three WorkOrders', () {
      const p = '$ow|p1';
      const tk = '$ow|p1|0|0';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: p, regionId: ow, ownerId: playerId)],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              p: [tk],
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
      );
      Unit ex(String id) => Unit(
        id: id,
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: p,
        tileKey: tk,
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {'e1': ex('e1'), 'e2': ex('e2'), 'e3': ex('e3')},
        provincesById: const {},
        visibilityByTile: const {tk: VisibilityLevel.fullyVisible},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e3',
            target: kWorkTargetExplore,
            targetTileKey: tk,
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: tk,
          ),
          WorkOrder(
            unitId: 'e2',
            target: kWorkTargetExplore,
            targetTileKey: tk,
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders, hasLength(3));
      expect(r.workOrders.map((w) => w.unitId).toSet(), {'e1', 'e2', 'e3'});
      expect(r.idleEvents, isEmpty);
    });

    test('deterministic: identical inputs twice → identical picks', () {
      const p = '$ow|p1';
      const tk = '$ow|p1|0|0';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: p, regionId: ow, ownerId: playerId)],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              p: [tk],
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'e1': Unit(
            id: 'e1',
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: p,
            tileKey: tk,
          ),
        },
        provincesById: const {},
        visibilityByTile: const {tk: VisibilityLevel.fullyVisible},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      const suggestions = [
        WorkOrder(unitId: 'e1', target: kWorkTargetExplore, targetTileKey: tk),
        WorkOrder(unitId: 'e1', target: kWorkTargetProspect, targetTileKey: tk),
      ];
      final a = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: view,
        game: game,
      );
      final b = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: view,
        game: game,
      );
      expect(a.workOrders, b.workOrders);
      expect(a.idleEvents, b.idleEvents);
    });

    test('E_unknown caps at 24 when U is large (min(24, 3×U))', () {
      const p = '$ow|pBig';
      final tiles = List.generate(12, (i) => '$ow|pBig|$i|0');
      final vis = <String, VisibilityLevel>{
        for (final t in tiles) t: VisibilityLevel.unknown,
      };
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: p, regionId: ow, ownerId: 'tribe1')],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {p: tiles},
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'e1': Unit(
            id: 'e1',
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: p,
            tileKey: tiles[0],
          ),
        },
        provincesById: const {},
        visibilityByTile: vis,
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      const tkWeak = '$ow|pWeak|0|0';
      final game2 = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: p, regionId: ow, ownerId: 'tribe1'),
              Province(id: '$ow|pWeak', regionId: ow, ownerId: playerId),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              p: tiles,
              '$ow|pWeak': [tkWeak],
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
      );
      final view2 = PlayerView(
        playerId: playerId,
        player: game2.players.single,
        ownUnitsById: {
          'e1': Unit(
            id: 'e1',
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: p,
            tileKey: tiles[0],
          ),
        },
        provincesById: const {},
        visibilityByTile: {...vis, tkWeak: VisibilityLevel.fullyVisible},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      // Big explore E=124; weak prospect on owned plains = 57 → explore wins.
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: tiles[0],
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: tkWeak,
          ),
        ],
        view: view2,
        game: game2,
      );
      expect(r.workOrders.single.target, kWorkTargetExplore);
    });

    test('non-Explorer idle with empty W(u) → no_suggestions', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'b1': Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: playerId,
            locationProvinceId: '$ow|p1',
          ),
        },
        provincesById: const {},
        visibilityByTile: const {},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: const [],
        view: view,
        game: game,
      );
      expect(r.workOrders, isEmpty);
      expect(r.idleEvents.single.unitId, 'b1');
      expect(r.idleEvents.single.reason, 'no_suggestions');
    });
  });
}
