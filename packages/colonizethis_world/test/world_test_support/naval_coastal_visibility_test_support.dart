import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'topology_builders.dart';

/// Minimal game with tile buckets / fleets for naval coastal visibility pins
/// (Refs #4330 Slice C).
Game navalCoastalVisibilityGame({
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  List<Fleet> fleets = const [],
  List<Province> oldWorldProvinces = const [],
  String playerId = 'a',
}) {
  return Game(
    id: 'test_game',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: const RegionData(),
      fleets: fleets,
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ?? const {},
    ),
    players: [Player(id: playerId, displayName: 'A', isHuman: true)],
  );
}

/// Shared OW coastal province ↔ sea topology for naval visibility pins.
MapTopology navalCoastalProvinceSeaTopology({
  String regionId = kWorldTestOw,
  String provinceLocalId = 'p1',
  String seaZoneId = 'sea1',
}) => provinceSeaZoneTopology(
  regionId: regionId,
  provinceLocalId: provinceLocalId,
  seaZoneId: seaZoneId,
);

/// Default OW land+sea tile buckets used by several naval visibility pins.
Map<String, Map<String, List<String>>> navalCoastalDefaultBuckets({
  String regionId = kWorldTestOw,
  String fullProvinceId = 'oldWorld|p1',
  String seaZoneId = 'oldWorld|sea1',
}) => {
  regionId: {
    fullProvinceId: ['$fullProvinceId|0|0', '$fullProvinceId|2|2'],
    seaZoneId: ['$seaZoneId|1|0'],
  },
};
