import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/src/turn/end_of_turn_resolver.dart';
import 'package:colonizethis_turn/src/turn/naval_resolution.dart';

/// Shared New World coastal/inland + seaOrigin/seaDest ids for ship-reveal tests.
abstract final class NwShipRevealCoastalIds {
  static const regionId = kRegionNewWorld;
  static const fullProvinceId = '$regionId|provA';
  static const localProvinceBucket = 'provA';
  static const localSeaDest = 'seaDest';
  static const localSeaOrigin = 'seaOrigin';
  static const prefixedDest = '$regionId|$localSeaDest';
  static const prefixedOrigin = '$regionId|$localSeaOrigin';
  static const seaFar = '$regionId|seaFar';
  static const coastalLand = '$regionId|provA|1|0';
  static const inlandLand = '$regionId|provA|0|0';
  static const extraLandA = '$regionId|provA|0|1';
  static const extraLandB = '$regionId|provA|1|1';
  static const seaDestWater = '$regionId|$localSeaDest|2|0';
  static const seaDestWaterB = '$regionId|$localSeaDest|2|1';
  static const seaOriginWater = '$regionId|$localSeaOrigin|0|2';
}

/// NW province ↔ seaDest ↔ seaOrigin topology; optional unreachable [seaFar] node.
MapTopology nwShipRevealCoastalTopology({bool includeSeaFar = false}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: NwShipRevealCoastalIds.fullProvinceId,
        regionId: NwShipRevealCoastalIds.regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: NwShipRevealCoastalIds.prefixedDest,
        regionId: NwShipRevealCoastalIds.regionId,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: NwShipRevealCoastalIds.prefixedOrigin,
        regionId: NwShipRevealCoastalIds.regionId,
        type: TopologyNodeType.seaZone,
      ),
      if (includeSeaFar)
        TopologyNode(
          id: NwShipRevealCoastalIds.seaFar,
          regionId: NwShipRevealCoastalIds.regionId,
          type: TopologyNodeType.seaZone,
        ),
    ],
    edges: const [
      TopologyEdge(
        id1: NwShipRevealCoastalIds.fullProvinceId,
        id2: NwShipRevealCoastalIds.prefixedDest,
      ),
      TopologyEdge(
        id1: NwShipRevealCoastalIds.prefixedOrigin,
        id2: NwShipRevealCoastalIds.prefixedDest,
      ),
    ],
  );
}

Map<String, String> nwShipRevealUnknownVisibilityStart() {
  return {
    for (final k in [
      NwShipRevealCoastalIds.coastalLand,
      NwShipRevealCoastalIds.inlandLand,
      NwShipRevealCoastalIds.seaDestWater,
      NwShipRevealCoastalIds.seaDestWaterB,
      NwShipRevealCoastalIds.seaOriginWater,
    ])
      k: VisibilityLevel.unknown.name,
  };
}

/// Fleet at [NwShipRevealCoastalIds.prefixedOrigin] with coastal/inland tile keys.
Game nwShipRevealCoastalGame({
  required String id,
  required String landProvinceBucketKey,
  List<String>? landTiles,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: 'fNw',
          ownerId: 'gp1',
          seaZoneId: NwShipRevealCoastalIds.prefixedOrigin,
          regionId: NwShipRevealCoastalIds.regionId,
          shipTypeIds: const ['carrack'],
        ),
      ],
      tileKeysByRegionAndProvince: {
        NwShipRevealCoastalIds.regionId: {
          landProvinceBucketKey:
              landTiles ??
              const [
                NwShipRevealCoastalIds.coastalLand,
                NwShipRevealCoastalIds.inlandLand,
                NwShipRevealCoastalIds.extraLandA,
              ],
          NwShipRevealCoastalIds.prefixedDest: const [
            NwShipRevealCoastalIds.seaDestWater,
            NwShipRevealCoastalIds.seaDestWaterB,
          ],
          NwShipRevealCoastalIds.prefixedOrigin: const [
            NwShipRevealCoastalIds.seaOriginWater,
          ],
        },
      },
      playerVisibilityByTile: {'gp1': nwShipRevealUnknownVisibilityStart()},
    ),
    players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
  );
}

/// Prefixed + local-id twin topologies for a province–sea edge (or sea–sea chain).
({MapTopology combined, MapTopology local})
shipRevealPrefixedLocalTopologyPair({
  required String regionId,
  required List<(String localId, TopologyNodeType type)> nodes,
  required List<(String localId1, String localId2)> edges,
}) {
  MapTopology build({required bool prefixed}) {
    String idFor(String localId) => prefixed ? '$regionId|$localId' : localId;
    return MapTopology(
      nodes: [
        for (final (localId, type) in nodes)
          TopologyNode(id: idFor(localId), regionId: regionId, type: type),
      ],
      edges: [
        for (final (a, b) in edges) TopologyEdge(id1: idFor(a), id2: idFor(b)),
      ],
    );
  }

  return (combined: build(prefixed: true), local: build(prefixed: false));
}

/// Apply naval move+reveal, then end-of-turn, then build [PlayerView].
({Game ended, PlayerView view}) applyShipRevealThenEndOfTurnView({
  required Game game,
  required MapTopology moveTopology,
  required MapTopology endOfTurnTopology,
  required String regionId,
  required Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId,
  required int turnNumber,
  String playerId = 'gp1',
}) {
  final moved = applyNavalMovesAndShipReveal(
    game,
    moveTopology,
    navalMoveOrdersByPlayerId,
  );
  final ended = runEndOfTurnPhase(
    moved.copyWith(
      worldState: moved.worldState.copyWith(
        turnState: TurnState(
          phase: TurnPhase.endOfTurn,
          turnNumber: turnNumber,
        ),
      ),
    ),
    topology: endOfTurnTopology,
    topologyByRegion: {regionId: endOfTurnTopology},
  );
  final view = buildPlayerView(ended, endOfTurnTopology, playerId);
  return (ended: ended, view: view);
}
