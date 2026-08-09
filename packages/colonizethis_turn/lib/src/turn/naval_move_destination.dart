import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Reachability gate for naval-move destination resolution (Refs #4168 wave-5).
bool navalMoveDestinationIsReachable({
  required MapTopology topology,
  required Fleet fleet,
  required String destZoneId,
}) {
  if (fleet.isAtSea) {
    final cur = fleet.seaZoneId;
    if (cur == null) return false;
    if (cur == destZoneId) return true;
    return isAdjacentSeaSeaZone(topology, cur, destZoneId);
  }
  final inPortProvinceId = fleet.inPortAtProvinceId;
  if (inPortProvinceId == null) return false;
  final rl = regionAndLocalProvinceForFleetInPort(
    inPortProvinceId,
    fleet.regionId,
  );
  final provinceNodeId = provinceTopologyNodeId(
    topology,
    rl.localId,
    rl.regionId,
  );
  if (provinceNodeId == null) return false;
  return seaZonesAdjacentToProvince(
    topology,
    provinceNodeId,
  ).contains(destZoneId);
}
