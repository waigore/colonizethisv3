import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_lookup_helpers.dart';

/// Visits each minor nation and tribe that has a capital and non-empty
/// connectivity, invoking [onFaction] with the resolved capital ids and
/// [ConnectivityResult]. Shared by `computeNonGreatPowerExtraction` and
/// `computeNonGreatPowerAutoOffers` so the faction loop is not duplicated.
void forEachNonGpFaction({
  required Game game,
  required Map<String, ConnectivityResult> connectivityByFactionId,
  required void Function({
    required String factionId,
    required String capitalProvinceId,
    required String capitalRegionId,
    required ConnectivityResult connectivity,
  })
  onFaction,
}) {
  void visit({
    required String factionId,
    required String? capitalProvinceId,
    required String? capitalRegionId,
  }) {
    if (capitalProvinceId == null || capitalRegionId == null) return;
    final cr = connectivityByFactionId[factionId];
    if (cr == null || cr.connected.isEmpty) return;
    onFaction(
      factionId: factionId,
      capitalProvinceId: capitalProvinceId,
      capitalRegionId: capitalRegionId,
      connectivity: cr,
    );
  }

  for (final minor in game.minorNations) {
    visit(
      factionId: minor.id,
      capitalProvinceId: capitalProvinceIdForFaction(game, minor.id),
      capitalRegionId: capitalRegionIdForFaction(game, minor.id),
    );
  }
  for (final tribe in game.tribes) {
    visit(
      factionId: tribe.id,
      capitalProvinceId: capitalProvinceIdForFaction(game, tribe.id),
      capitalRegionId: capitalRegionIdForFaction(game, tribe.id),
    );
  }
}
