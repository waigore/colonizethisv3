import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'draft_orders_mutations.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_army_move_destinations.dart';

export 'order_suggestion_army_move_destinations.dart';

bool _armyMoveNeedsDeclareWarTrial(
  Game game,
  String playerId,
  String? destOwnerId,
  List<DiplomaticOrder> diplo,
  DiplomacyFactionMembership factionMembership,
) {
  if (destOwnerId == null || destOwnerId.isEmpty || destOwnerId == playerId) {
    return false;
  }
  if (!isGreatPower(game, destOwnerId, factionMembership: factionMembership) &&
      !isMinorOrTribe(
        game,
        destOwnerId,
        factionMembership: factionMembership,
      )) {
    return false;
  }
  return !canAttackWithWarOrDeclaring(game, playerId, destOwnerId, diplo);
}

/// Valid, sorted destinations for the Move Army dialog: player-owned and
/// invasion targets only if the merged draft (with optional same-turn declare
/// war) passes [OrderEngine] validation. SPEC/ui/military-units-panel.md.
///
/// When [playerOwnedFullProvinceIds] is provided by the caller, the picker
/// skips the fallback owned-province [ProvinceOwnerCache] lookup and reuses the
/// provided set (Refs #2394).
///
/// When [resolution] is provided (same contract as
/// [IncrementalCandidateValidator.forPlayer]), each internal validator reuses
/// the pass snapshot instead of embedding `buildPlayerView` / unit-map scans.
/// When [sharedCandidateValidator] is provided for the same suggestion pass,
/// it is reused (rebound via [IncrementalCandidateValidator.forBasePrefix] when
/// [currentOrders] differs from the validator's embedded prefix). Callers such
/// as the Flutter shell may supply these when they already hold a [PlayerView]
/// for [playerId]; when omitted, behavior matches the historical path.
List<ArmyMovePickerDestination> armyMovePickerDestinations({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Army army,
  required Orders currentOrders,
  Set<String>? playerOwnedFullProvinceIds,
  OrderResolutionContext? resolution,

  /// When callers already built membership for this [game], pass it to skip a
  /// second [DiplomacyFactionMembership.from] scan (Refs #2394).
  DiplomacyFactionMembership? factionMembership,

  /// When non-null, must match [playerId] and be built from the same
  /// `(game, topology, …)` tuple; amortizes validator setup across picker calls
  /// in the same pass (Refs #2394).
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match armyMovePickerDestinations playerId',
  );
  final diplo =
      currentOrders.diplomaticOrdersByPlayerId[playerId] ??
      const <DiplomaticOrder>[];
  final effectiveFactionMembership =
      factionMembership ??
      sharedCandidateValidator?.factionMembershipSnapshot ??
      DiplomacyFactionMembership.from(game);
  final effectiveResolution =
      resolution ??
      (sharedCandidateValidator != null
          ? (
              view: sharedCandidateValidator.view,
              unitsById: sharedCandidateValidator.unitsById,
              provinceById: sharedCandidateValidator.view.provincesById,
            )
          : null);
  final ownedProvinceIds = armyMovePlayerOwnedProvinceIds(
    game: game,
    playerId: playerId,
    playerOwnedFullProvinceIds: playerOwnedFullProvinceIds,
    view: effectiveResolution?.view,
  );
  final raw = armyMoveCandidateDestinationProvinceIds(
    game: game,
    topology: topology,
    playerId: playerId,
    army: army,
    playerOwnedFullProvinceIds: ownedProvinceIds,
  );
  final baseValidator = switch (sharedCandidateValidator) {
    final shared? when shared.basePrefix == currentOrders => shared,
    final shared? => shared.forBasePrefix(currentOrders),
    null => IncrementalCandidateValidator.forPlayer(
      game: game,
      topology: topology,
      playerId: playerId,
      basePrefix: currentOrders,
      factionMembership: effectiveFactionMembership,
      resolution:
          effectiveResolution ??
          buildOrderResolutionContext(
            game: game,
            topology: topology,
            playerId: playerId,
          ),
    ),
  };
  final declareWarTrialValidatorsByTargetFaction =
      <String, IncrementalCandidateValidator>{};
  final out = <ArmyMovePickerDestination>[];
  for (final fullId in raw) {
    final province = game.worldState.tryGetProvince(fullId);
    final ownerId = province?.ownerId ?? '';
    final move = ArmyMoveOrder(armyId: army.id, destinationProvinceId: fullId);
    final acceptedBase = baseValidator.isArmyMoveAccepted(move);
    var requiresDeclare = false;
    if (acceptedBase) {
      requiresDeclare = false;
    } else {
      if (!_armyMoveNeedsDeclareWarTrial(
        game,
        playerId,
        ownerId,
        diplo,
        effectiveFactionMembership,
      )) {
        continue;
      }
      // Trial diplomatic context differs from [currentOrders] (extra declare
      // war on [ownerId]). Reuse one validator per target faction so multiple
      // provinces with the same owner do not each pay a full PlayerView build
      // (Refs #2394, SPEC/program/order-suggestions.md § Throughput bounds).
      final trialValidator = declareWarTrialValidatorsByTargetFaction
          .putIfAbsent(ownerId, () {
            final trialOrders = ordersWithAppendedDiplomaticOrder(
              currentOrders,
              playerId,
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: ownerId,
              ),
            );
            return baseValidator.forBasePrefix(trialOrders);
          });
      if (!trialValidator.isArmyMoveAccepted(move)) {
        continue;
      }
      requiresDeclare = true;
    }
    final label = province?.displayName ?? ProvinceId.localIdFrom(fullId);
    final isOwn = ownerId == playerId;
    final ownerKey = ownerId.isEmpty ? '__unowned__' : ownerId;
    out.add(
      ArmyMovePickerDestination(
        fullProvinceId: fullId,
        provinceLabel: label,
        regionId: ProvinceId.regionIdFrom(fullId),
        ownerFactionId: ownerKey,
        isPlayerOwned: isOwn,
        requiresDeclareWarOnConfirm: requiresDeclare,
      ),
    );
  }
  out.sort((a, b) {
    if (a.isPlayerOwned != b.isPlayerOwned) {
      return a.isPlayerOwned ? -1 : 1;
    }
    final o = a.ownerFactionId.compareTo(b.ownerFactionId);
    if (o != 0) return o;
    final r = a.regionId.compareTo(b.regionId);
    if (r != 0) return r;
    final l = a.provinceLabel.compareTo(b.provinceLabel);
    if (l != 0) return l;
    return a.fullProvinceId.compareTo(b.fullProvinceId);
  });
  return out;
}
