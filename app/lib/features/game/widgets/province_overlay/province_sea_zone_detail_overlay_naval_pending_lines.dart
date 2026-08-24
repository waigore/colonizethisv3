import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'province_panel_pending_orders.dart';

List<String> pendingNavalLines({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders draftOrders,
  required String? pendingNavalPortProvinceId,
  required String? pendingNavalSeaZoneId,
}) {
  if (pendingNavalPortProvinceId != null) {
    return provincePanelPendingNavalLines(
      game: game,
      orders: draftOrders,
      provinceId: pendingNavalPortProvinceId,
      humanPlayerId: humanPlayerId,
      l10n: l10n,
    );
  }
  if (pendingNavalSeaZoneId == null) return const [];
  final localSea = prefixedIdLocalSegment(pendingNavalSeaZoneId);
  final regionId = prefixedIdRegionSegment(pendingNavalSeaZoneId);
  final fleetIds = <String>{
    for (final fleet in game.worldState.fleets)
      if (fleet.ownerId == humanPlayerId &&
          fleet.isAtSea &&
          fleet.seaZoneId == localSea &&
          (regionId == null || fleet.regionId == regionId))
        fleet.id,
  };
  if (fleetIds.isEmpty) return const [];
  return pendingNavalLinesForFleets(
    game: game,
    orders: draftOrders,
    fleetIds: fleetIds,
    humanPlayerId: humanPlayerId,
    l10n: l10n,
  );
}
