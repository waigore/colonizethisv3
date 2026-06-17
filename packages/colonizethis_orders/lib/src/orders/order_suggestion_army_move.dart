part of 'order_suggestion_move_army.dart';

const int _kMaxArmyMoveSuggestionsPerArmy = 12;
const int _kMaxArmyMoveProbeAttemptsPerArmy = 80;

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
  final ownedProvinceIds =
      playerOwnedFullProvinceIds ??
      (effectiveResolution != null
          ? ownedProvinceIdsFromView(effectiveResolution.view, playerId)
          : <String>{
              for (final p in ProvinceOwnerCache.of(
                game.worldState,
              ).provincesOwnedBy(playerId))
                toFullProvinceId(p.regionId, p.id),
            });
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

/// Suggests candidate [ArmyMoveOrder]s for non-home armies owned by [view.playerId].
///
/// Throughput hook: callers that enumerate multiple suggestion families against
/// the same `(game, view.playerId, currentOrders)` may supply
/// [sharedCandidateValidator] to amortize `PlayerView` / units-by-id
/// construction across families (Refs #2394). The shared instance must be
/// built with the same inputs; observable suggestions must match the default
/// path.
List<ArmyMoveOrder> suggestArmyMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  final pass = SuggestionPassContext.forPlayerView(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    familyLabel: 'suggestArmyMoveOrders',
    sharedCandidateValidator: sharedCandidateValidator,
    useBuildIncrementalWrapper: false,
  );
  final playerId = pass.playerId;
  final suggestions = <ArmyMoveOrder>[];
  final candidateValidator = pass.candidateValidator;
  final existingArmyMoves = indexExistingTargetsByEntityId(
    currentOrders.armyMoveOrdersByPlayerId[playerId],
    (m) => m.armyId,
    (m) => m.destinationProvinceId,
  );

  final playerOwnedFullProvinceIds = ownedProvinceIdsFromView(view, playerId);

  for (final army in game.worldState.armies) {
    if (army.ownerId != playerId) continue;
    if (army.isHomeArmy) continue;

    final fromProvinceId = army.stationedProvinceId;
    final unitRegion = ProvinceId.regionIdFrom(fromProvinceId);

    if (!moveSourceVisibilityOk(view, unitRegion, fromProvinceId)) continue;

    final destIds = armyMoveCandidateDestinationProvinceIds(
      game: game,
      topology: topology,
      playerId: playerId,
      army: army,
      playerOwnedFullProvinceIds: playerOwnedFullProvinceIds,
    );

    runCappedSuggestionProbeLoop<String>(
      candidates: destIds,
      shouldSkip: (destinationProvinceId) {
        final already = existingArmyMoves[army.id];
        return already != null && already.contains(destinationProvinceId);
      },
      probe: (destinationProvinceId) {
        final candidate = ArmyMoveOrder(
          armyId: army.id,
          destinationProvinceId: destinationProvinceId,
        );
        return candidateValidator.isArmyMoveAccepted(candidate);
      },
      onAccepted: (destinationProvinceId) {
        suggestions.add(
          ArmyMoveOrder(
            armyId: army.id,
            destinationProvinceId: destinationProvinceId,
          ),
        );
      },
      maxAccepted: _kMaxArmyMoveSuggestionsPerArmy,
      maxProbes: _kMaxArmyMoveProbeAttemptsPerArmy,
    );
  }

  suggestions.sort((a, b) {
    final idCmp = a.armyId.compareTo(b.armyId);
    if (idCmp != 0) return idCmp;
    return a.destinationProvinceId.compareTo(b.destinationProvinceId);
  });
  return suggestions;
}
