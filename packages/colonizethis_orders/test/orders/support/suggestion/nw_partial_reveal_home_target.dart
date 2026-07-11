// NW home + adjacent target with partial visibility (Refs #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'valid_work_tiles_test_support.dart';

/// NW home + adjacent target province with partial visibility (home full, t0
/// unknown, t1 fogged). Used by suggest explore/prospect scenario bodies.
class NwPartialRevealHomeTarget {
  NwPartialRevealHomeTarget({
    required this.homeLocalId,
    required this.targetLocalId,
    this.homeOwnerId = ValidWorkTilesTestSupport.playerId,
    required this.targetOwnerId,
    this.unitId = 'ex1',
    this.resourceByTileKey = const {},
    this.playerProspectedTiles = const {},
  }) : provHome = ValidWorkTilesTestSupport.provinceId(
         homeLocalId,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       provTarget = ValidWorkTilesTestSupport.provinceId(
         targetLocalId,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       tileHome = ValidWorkTilesTestSupport.tileKey(
         homeLocalId,
         0,
         0,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       t0 = ValidWorkTilesTestSupport.tileKey(
         targetLocalId,
         0,
         0,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       t1 = ValidWorkTilesTestSupport.tileKey(
         targetLocalId,
         1,
         0,
         regionId: ValidWorkTilesTestSupport.nw,
       );

  final String homeLocalId;
  final String targetLocalId;
  final String homeOwnerId;
  final String targetOwnerId;
  final String unitId;
  final Map<String, String> resourceByTileKey;
  final Map<String, Set<String>> playerProspectedTiles;
  final String provHome;
  final String provTarget;
  final String tileHome;
  final String t0;
  final String t1;

  WorldState world({Unit? unit}) {
    final actor =
        unit ??
        ValidWorkTilesTestSupport.explorerUnit(
          id: unitId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
    return WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(
            id: provHome,
            regionId: ValidWorkTilesTestSupport.nw,
            ownerId: homeOwnerId,
          ),
          Province(
            id: provTarget,
            regionId: ValidWorkTilesTestSupport.nw,
            ownerId: targetOwnerId,
          ),
        ],
        units: [actor],
      ),
      tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
        {
          provHome: [tileHome],
          provTarget: [t0, t1],
        },
        regionId: ValidWorkTilesTestSupport.nw,
      ),
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: playerProspectedTiles,
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: {
          tileHome: 'fullyVisible',
          t0: 'unknown',
          t1: 'fogged',
        },
      },
    );
  }

  MapTopology topology() => MapTopology(
    nodes: [
      TopologyNode(
        id: homeLocalId,
        regionId: ValidWorkTilesTestSupport.nw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: targetLocalId,
        regionId: ValidWorkTilesTestSupport.nw,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: homeLocalId, id2: targetLocalId)],
  );

  Game game({
    required String id,
    List<Player>? players,
    List<Tribe>? tribes,
    List<MinorNation>? minorNations,
    List<OvertureState>? overtureStates,
    Unit? unit,
  }) => Game(
    id: id,
    worldState: world(unit: unit),
    players: players ?? const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: tribes ?? const [],
    minorNations: minorNations ?? const [],
    overtureStates: overtureStates ?? const [],
  );

  static NwPartialRevealHomeTarget tribeGrainIron({
    bool prospectedIron = false,
  }) {
    final t0 = ValidWorkTilesTestSupport.tileKey(
      'tribe1',
      0,
      0,
      regionId: ValidWorkTilesTestSupport.nw,
    );
    final t1 = ValidWorkTilesTestSupport.tileKey(
      'tribe1',
      1,
      0,
      regionId: ValidWorkTilesTestSupport.nw,
    );
    return NwPartialRevealHomeTarget(
      homeLocalId: 'home',
      targetLocalId: 'tribe1',
      targetOwnerId: 'tribe1',
      resourceByTileKey: {t0: 'grain', t1: 'iron'},
      playerProspectedTiles: prospectedIron
          ? {
              ValidWorkTilesTestSupport.playerId: {t1},
            }
          : const {},
    );
  }

  static NwPartialRevealHomeTarget minorPurchase({
    Map<String, String> resourceByTileKey = const {},
  }) {
    final t1 = ValidWorkTilesTestSupport.tileKey(
      'm1',
      1,
      0,
      regionId: ValidWorkTilesTestSupport.nw,
    );
    return NwPartialRevealHomeTarget(
      homeLocalId: 'own',
      targetLocalId: 'm1',
      targetOwnerId: 'minor1',
      resourceByTileKey: resourceByTileKey.isEmpty
          ? {t1: 'grain'}
          : resourceByTileKey,
    );
  }

  Game tribeConsulateGame(String id) => game(
    id: id,
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );

  Game minorPurchaseGame(String id, {List<OvertureState>? overtureStates}) =>
      game(
        id: id,
        players: [ValidWorkTilesTestSupport.playerWithTreasury()],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        overtureStates: overtureStates,
        unit: Unit(
          id: 'u1',
          type: kUnitTypeMerchant,
          ownerId: ValidWorkTilesTestSupport.playerId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        ),
      );
}
