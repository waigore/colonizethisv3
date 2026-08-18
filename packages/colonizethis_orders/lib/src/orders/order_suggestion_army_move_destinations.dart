import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_suggestion_pass_context.dart';

/// Owned full province ids for army-move candidate enumeration.
///
/// Prefers an explicit [playerOwnedFullProvinceIds] when the caller already
/// scanned the world or view once per pass; falls back to [view] when supplied
/// (picker with [OrderResolutionContext]); otherwise uses [ProvinceOwnerCache].
Set<String> armyMovePlayerOwnedProvinceIds({
  required Game game,
  required String playerId,
  Set<String>? playerOwnedFullProvinceIds,
  PlayerView? view,
}) {
  if (playerOwnedFullProvinceIds != null) {
    return playerOwnedFullProvinceIds;
  }
  if (view != null) {
    return ownedProvinceIdsFromView(view, playerId);
  }
  return {
    for (final p in ProvinceOwnerCache.of(
      game.worldState,
    ).provincesOwnedBy(playerId))
      toFullProvinceId(p.regionId, p.id),
  };
}

/// Destination province ids for army moves (Military Units picker parity): adjacent
/// land provinces in the army's region plus every province owned by [playerId]
/// in any region; excludes the army's current province.
///
/// When [playerOwnedFullProvinceIds] is supplied (typically built once per
/// [suggestArmyMoveOrders] pass from [PlayerView.provincesById] or a single
/// [allProvinces] scan), owned-province ids are taken from that set instead of
/// rescanning the world per army (Refs #2394, SPEC/program/order-suggestions.md,
/// SPEC/program/logic-dual-region-province-access.md).
List<String> armyMoveCandidateDestinationProvinceIds({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Army army,
  Set<String>? playerOwnedFullProvinceIds,
}) {
  final fromFull = army.stationedProvinceId;
  final regionId = ProvinceId.regionIdFrom(fromFull);
  final fromLocal = ProvinceId.localIdFrom(fromFull);
  final out = <String>{};

  for (final n in neighborProvinceIdsInRegion(topology, regionId, fromLocal)) {
    out.add(ProvinceId.full(regionId, n));
  }
  if (playerOwnedFullProvinceIds != null) {
    out.addAll(playerOwnedFullProvinceIds);
  } else {
    for (final p in ProvinceOwnerCache.of(
      game.worldState,
    ).provincesOwnedBy(playerId)) {
      out.add(toFullProvinceId(p.regionId, p.id));
    }
  }
  out.remove(fromFull);
  final sorted = out.toList()..sort();
  return sorted;
}

/// One destination row for the Move Army picker (Military Units).
/// Only entries produced by [armyMovePickerDestinations] are selectable; each
/// corresponds to a draft that passes [OrderEngine] validation.
class ArmyMovePickerDestination {
  const ArmyMovePickerDestination({
    required this.fullProvinceId,
    required this.provinceLabel,
    required this.regionId,
    required this.ownerFactionId,
    required this.isPlayerOwned,
    required this.requiresDeclareWarOnConfirm,
  });

  final String fullProvinceId;
  final String provinceLabel;
  final String regionId;

  /// Province owner (same as [playerId] when [isPlayerOwned]).
  final String ownerFactionId;
  final bool isPlayerOwned;

  /// When true, confirm must run invasion flow and the shell should set
  /// [ArmyMoveRequestedEvent.declareWarTargetFactionId] to [ownerFactionId].
  final bool requiresDeclareWarOnConfirm;
}
