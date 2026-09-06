import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'province_naval_combine_action_state.dart'
    show humanFleetsInOverlayNavalLocality;

/// Visibility for MAP20001 Naval Sail / Move (Refs #4735).
///
/// Visibility and enablement share one cheap occupancy predicate: ≥1 human
/// sea-going non-Home fleet in the overlay locality. Never calls the
/// order-suggestion engine or `navalMoveTopologyPicksForFleet` on paint.
class ProvinceOverlaySailMoveActionState {
  const ProvinceOverlaySailMoveActionState({
    required this.show,
    required this.enabled,
    required this.fleetIds,
  });

  static const hidden = ProvinceOverlaySailMoveActionState(
    show: false,
    enabled: false,
    fleetIds: <String>[],
  );

  final bool show;
  final bool enabled;
  final List<String> fleetIds;
}

/// Occupying human sea-going non-Home fleets for overlay Sail / Move.
///
/// Sea-zone: at-sea fleets in the viewed sea. Province: in-port fleets at an
/// **owned** harbor. Home Fleet is excluded; empty-ship fleets are excluded.
List<Fleet> occupyingSeaGoingNonHomeFleetsForOverlaySailMove({
  required Game game,
  required String humanPlayerId,
  required String displayId,
  required bool isSeaZoneContext,
}) {
  if (!isSeaZoneContext) {
    final province = game.worldState.tryGetProvince(displayId);
    if (province == null || province.ownerId != humanPlayerId) {
      return const [];
    }
  }
  final homeId = homeFleetIdFor(humanPlayerId);
  final local = humanFleetsInOverlayNavalLocality(
    game: game,
    humanPlayerId: humanPlayerId,
    displayId: displayId,
    isSeaZoneContext: isSeaZoneContext,
  );
  final out = <Fleet>[
    for (final f in local)
      if (f.id != homeId && f.ships.isNotEmpty) f,
  ];
  out.sort((a, b) => a.id.compareTo(b.id));
  return out;
}

/// Computes Sail / Move action state for MAP20001 Naval (Refs #4735).
ProvinceOverlaySailMoveActionState computeProvinceOverlaySailMoveActionState({
  required Game game,
  required String humanPlayerId,
  required String displayId,
  required bool showsFullNavalIntel,
  required bool isSeaZoneContext,
  required bool canMutateViaUi,
}) {
  if (!canMutateViaUi || !showsFullNavalIntel) {
    return ProvinceOverlaySailMoveActionState.hidden;
  }
  final fleets = occupyingSeaGoingNonHomeFleetsForOverlaySailMove(
    game: game,
    humanPlayerId: humanPlayerId,
    displayId: displayId,
    isSeaZoneContext: isSeaZoneContext,
  );
  if (fleets.isEmpty) {
    return ProvinceOverlaySailMoveActionState.hidden;
  }
  final ids = [for (final f in fleets) f.id];
  return ProvinceOverlaySailMoveActionState(
    show: true,
    enabled: true,
    fleetIds: ids,
  );
}
