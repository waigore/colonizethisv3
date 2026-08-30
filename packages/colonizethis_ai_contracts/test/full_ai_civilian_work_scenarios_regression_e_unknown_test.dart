import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// E_unknown cap regression for GitHub #2082 / `selectFullAiCivilianWorkOrders`.
/// Split from [full_ai_civilian_work_scenarios_regression_test.dart] for #4683.
void main() {
  const playerId = 'gp1';
  const ow = 'oldWorld';

  group('Full AI civilian work #2082 regression bundle', () {
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
  });
}
