import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../../widgets/province_overlay/province_sea_zone_detail_overlay_designation.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_sections_political.dart';

/// Read-only blockade status for MAP20001 Naval on human-owned ports (Refs #4516).
enum ProvinceBlockadeStatus { none, portBlockaded, capitalBlockaded }

ProvinceBlockadeStatus resolveHumanOwnedBlockadeStatus({
  required Game game,
  required String humanPlayerId,
  required String provinceId,
  required MapTopology topology,
  required bool isSeaZone,
}) {
  if (isSeaZone) return ProvinceBlockadeStatus.none;
  final province = findProvinceForSeaZoneOverlay(game, provinceId);
  if (province == null || province.ownerId != humanPlayerId) {
    return ProvinceBlockadeStatus.none;
  }
  final blockadedByPlayer = computeBlockadedPortProvincesByPlayer(
    game,
    topology,
  );
  final blockaded = blockadedByPlayer[humanPlayerId] ?? const <String>{};
  if (!blockaded.contains(provinceId)) {
    return ProvinceBlockadeStatus.none;
  }
  return provinceOverlayIsCapital(game, provinceId)
      ? ProvinceBlockadeStatus.capitalBlockaded
      : ProvinceBlockadeStatus.portBlockaded;
}
