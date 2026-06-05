import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'full_ai_civilian_work_supplier_feedstock_extraction_fixtures.dart';

// Refs #2847 § H8-extraction Old World mineral feedstock prospect localization
// (incremental-validator acceptance gate slice).
//
// `ownsIdleExplorerColocatedWithValidatorAcceptedMineralEligibleUnprospectedOldWorldFeedstockTile`
// narrows the residual past the mineral-eligibility predicate: an idle Explorer
// can be co-located with a mineral-eligible unprospected Old World feedstock
// tile yet still generate no `prospect` candidate when the incremental validator
// rejects the order (visibility, occupancy, duplicate pending, etc.).

const _supplierIronTile = 'oldWorld|s0|2|0';
const _supplierTimberTile = 'oldWorld|s0|1|0';
const _supplierProvinceId = 'oldWorld|s0';

MapTopology _supplierTopology() => MapTopology(
  nodes: const [
    TopologyNode(
      id: 's0',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Map<String, TileMapResult> _tileMapWithIronTerrain(TerrainType ironTerrain) => {
  kRegionOldWorld: TileMapResult(
    width: 3,
    height: 1,
    grid: const [
      ['oldWorld|s0', 'oldWorld|s0', 'oldWorld|s0'],
    ],
    terrainGrid: [
      [TerrainType.hills, TerrainType.hills, ironTerrain],
    ],
  ),
};

Game _prospectValidatorGame({
  required Map<String, String> visibilityByTile,
  List<Unit> extraUnits = const [],
  Orders? pendingOrders,
}) {
  final game = twoPlayerSupplierFeedstockGame(
    resourceByTileKey: const {
      _supplierTimberTile: 'timber',
      _supplierIronTile: 'iron',
      sellerWoolTile: 'wool',
    },
    extraUnits: extraUnits,
  );
  return Game(
    id: game.id,
    worldState: WorldState(
      turnState: game.worldState.turnState,
      oldWorld: game.worldState.oldWorld,
      newWorld: game.worldState.newWorld,
      resourceByTileKey: game.worldState.resourceByTileKey,
      tileState: game.worldState.tileState,
      playerVisibilityByTile: {supplierFeedstockId: visibilityByTile},
      tileKeysByRegionAndProvince: {
        kRegionOldWorld: {
          _supplierProvinceId: const [
            'oldWorld|s0|0|0',
            _supplierTimberTile,
            _supplierIronTile,
          ],
        },
      },
    ),
    players: game.players,
  );
}

Unit _explorer(String id, {CurrentWork? currentWork}) => Unit(
  id: id,
  type: kUnitTypeExplorer,
  ownerId: supplierFeedstockId,
  locationProvinceId: _supplierProvinceId,
  tileKey: _supplierIronTile,
  currentWork: currentWork,
);

void main() {
  group(
    'ownsIdleExplorerColocatedWithValidatorAcceptedMineralEligibleUnprospectedOldWorldFeedstockTile '
    '(Refs #2847 H8-extraction validator acceptance gate)',
    () {
      test('true when the co-located iron tile is validator-accepted for '
          'prospect', () {
        final game = _prospectValidatorGame(
          visibilityByTile: const {_supplierIronTile: 'fogged'},
          extraUnits: [_explorer('e1')],
        );
        final tileMap = _tileMapWithIronTerrain(TerrainType.hills);
        expect(
          ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
            tileMap,
          ),
          isTrue,
        );
        expect(
          ownsIdleExplorerColocatedWithValidatorAcceptedMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            _supplierTopology(),
            supplierFeedstockId,
            {'iron'},
            tileMap,
          ),
          isTrue,
        );
      });

      test('false when the iron tile lacks fogged visibility while the '
          'mineral-eligibility predicate stays true (teeth test)', () {
        final game = _prospectValidatorGame(
          visibilityByTile: const {},
          extraUnits: [_explorer('e1')],
        );
        final tileMap = _tileMapWithIronTerrain(TerrainType.hills);
        expect(
          ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
            tileMap,
          ),
          isTrue,
        );
        expect(
          ownsIdleExplorerColocatedWithValidatorAcceptedMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            _supplierTopology(),
            supplierFeedstockId,
            {'iron'},
            tileMap,
          ),
          isFalse,
        );
      });

      test('false when the co-located Explorer has a pending prospect order '
          '(duplicate pending negative control)', () {
        final game = _prospectValidatorGame(
          visibilityByTile: const {_supplierIronTile: 'fogged'},
          extraUnits: [_explorer('e1')],
        );
        final tileMap = _tileMapWithIronTerrain(TerrainType.hills);
        final pending = Orders(
          workOrdersByPlayerId: {
            supplierFeedstockId: [
              WorkOrder(
                unitId: 'e1',
                target: kWorkTargetProspect,
                targetTileKey: _supplierIronTile,
              ),
            ],
          },
        );
        expect(
          ownsIdleExplorerColocatedWithValidatorAcceptedMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            _supplierTopology(),
            supplierFeedstockId,
            {'iron'},
            tileMap,
            currentOrders: pending,
          ),
          isFalse,
        );
      });

      test('false when the Explorer is in a different province', () {
        final game = _prospectValidatorGame(
          visibilityByTile: const {_supplierIronTile: 'fogged'},
          extraUnits: [
            Unit(
              id: 'e1',
              type: kUnitTypeExplorer,
              ownerId: supplierFeedstockId,
              locationProvinceId: 'oldWorld|s1',
            ),
          ],
        );
        expect(
          ownsIdleExplorerColocatedWithValidatorAcceptedMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            _supplierTopology(),
            supplierFeedstockId,
            {'iron'},
            _tileMapWithIronTerrain(TerrainType.hills),
          ),
          isFalse,
        );
      });

      test('false when the co-located Explorer is busy', () {
        final game = _prospectValidatorGame(
          visibilityByTile: const {_supplierIronTile: 'fogged'},
          extraUnits: [
            _explorer(
              'e1',
              currentWork: const CurrentWork(
                workTarget: kWorkTargetExplore,
                tileKey: _supplierIronTile,
                totalTurns: 5,
                remainingTurns: 3,
              ),
            ),
          ],
        );
        expect(
          ownsIdleExplorerColocatedWithValidatorAcceptedMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            _supplierTopology(),
            supplierFeedstockId,
            {'iron'},
            _tileMapWithIronTerrain(TerrainType.hills),
          ),
          isFalse,
        );
      });

      test('false when the iron tile is already prospected', () {
        final game = _prospectValidatorGame(
          visibilityByTile: const {_supplierIronTile: 'fogged'},
          extraUnits: [_explorer('e1')],
        ).copyWithSupplierProspected({_supplierIronTile});
        expect(
          ownsIdleExplorerColocatedWithValidatorAcceptedMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            _supplierTopology(),
            supplierFeedstockId,
            {'iron'},
            _tileMapWithIronTerrain(TerrainType.hills),
          ),
          isFalse,
        );
      });

      test('false for an empty feedstockIds set (negative control)', () {
        final game = _prospectValidatorGame(
          visibilityByTile: const {_supplierIronTile: 'fogged'},
          extraUnits: [_explorer('e1')],
        );
        expect(
          ownsIdleExplorerColocatedWithValidatorAcceptedMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            _supplierTopology(),
            supplierFeedstockId,
            {},
            _tileMapWithIronTerrain(TerrainType.hills),
          ),
          isFalse,
        );
      });
    },
  );
}
