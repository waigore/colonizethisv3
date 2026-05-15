import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';
import '../world/movement.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/unit_lookup.dart';
import '../world/civilian_tile_occupancy.dart';
import 'draft_orders_mutations.dart';
import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';
import 'order_visibility.dart';

const int _kMaxMoveSuggestionsPerUnit = 24;
const int _kMaxArmyMoveSuggestionsPerArmy = 12;
const int _kMaxMoveProbeAttemptsPerUnit = 160;
const int _kMaxArmyMoveProbeAttemptsPerArmy = 80;

/// Suggests candidate move orders that are information-legal (per [PlayerView])
/// and rules-legal (per [OrderEngine]) for [view.playerId].
///
/// Throughput hook: callers that enumerate multiple suggestion families against
/// the same `(game, view.playerId, currentOrders)` may supply
/// [sharedCandidateValidator] to amortize `PlayerView` / units-by-id
/// construction across families (Refs #2394,
/// `SPEC/program/order-suggestions.md` § Throughput bounds). When omitted,
/// this function constructs its own validator. The shared instance must be
/// built with the same inputs as this call; observable suggestions must match
/// the default path.
List<MoveOrder> suggestMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  orderSuggestionLog.d('suggestMoveOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <MoveOrder>[];

  // Build a convenience index of current move orders for this player to avoid
  // suggesting duplicate moves for the same unit + destination.
  final existingMoves = <String, Set<String>>{};
  final existingForPlayer =
      currentOrders.moveOrdersByPlayerId[playerId] ?? const [];
  for (final m in existingForPlayer) {
    existingMoves
        .putIfAbsent(m.unitId, () => <String>{})
        .add(m.destinationTileKey);
  }

  final landTiles = sortedLandTileKeys(game.worldState);
  final visibleLandTiles = <String>[];
  for (final tileKey in landTiles) {
    if (moveDestinationTileVisibilityOk(view, tileKey)) {
      visibleLandTiles.add(tileKey);
    }
  }

  // Build the incremental candidate validator once per suggestion pass: the
  // per-player [PlayerView]/units-by-id work is amortized across every
  // candidate probe in the loop, instead of being rebuilt per probe via the
  // old [OrderEngine] full-pass path. SPEC/program/order-suggestions.md
  // § Incremental candidate validation. Refs #2237.
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match view.playerId',
  );
  final candidateValidator =
      sharedCandidateValidator ??
      IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: currentOrders,
        factionMembership: DiplomacyFactionMembership.from(game),
        view: view,
        unitsById: unitsByIdFromWorld(game.worldState),
      );

  for (final unit in view.ownUnits) {
    if (isMilitaryUnit(unit.type)) {
      // Land regiments move via [ArmyMoveOrder]; see [suggestArmyMoveOrders].
      continue;
    }
    final unitRegion = regionIdForUnit(view, unit);
    final fromProvinceId = unit.locationProvinceId;

    // Source province cannot be unknown; by definition the unit is in a known province.
    if (!moveSourceVisibilityOk(view, unitRegion, fromProvinceId)) {
      throw StateError(
        'Source province must be visible; unit ${unit.id} has source province $fromProvinceId with unknown visibility',
      );
    }

    var acceptedForUnit = 0;
    var probeAttemptsForUnit = 0;
    for (final destinationTileKey in visibleLandTiles) {
      final already = existingMoves[unit.id];
      if (already != null && already.contains(destinationTileKey)) continue;
      probeAttemptsForUnit++;

      final candidate = MoveOrder(
        unitId: unit.id,
        destinationTileKey: destinationTileKey,
      );

      if (candidateValidator.isMoveAccepted(candidate)) {
        suggestions.add(candidate);
        acceptedForUnit++;
        if (acceptedForUnit >= _kMaxMoveSuggestionsPerUnit) {
          break;
        }
      }
      if (probeAttemptsForUnit >= _kMaxMoveProbeAttemptsPerUnit) {
        break;
      }
    }
  }

  suggestions.sort((a, b) {
    final unitCmp = a.unitId.compareTo(b.unitId);
    if (unitCmp != 0) return unitCmp;
    return a.destinationTileKey.compareTo(b.destinationTileKey);
  });

  orderSuggestionLog.d(
    'suggestMoveOrders player=$playerId candidates=${suggestions.length}',
  );
  if (suggestions.isEmpty) {
    orderSuggestionLog.w('suggestMoveOrders no candidates player=$playerId');
  }
  return suggestions;
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
    for (final p in allProvinces(game.worldState)) {
      if (p.ownerId == playerId) {
        out.add(toFullProvinceId(p.regionId, p.id));
      }
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
/// skips the fallback owned-province [allProvinces] scan and reuses the
/// provided set (Refs #2394).
///
/// When [playerView] / [unitsById] are provided (same contract as
/// [IncrementalCandidateValidator.forPlayer]), each internal validator reuses
/// them instead of embedding `buildPlayerView` / `unitsByIdFromWorld` scans.
/// Callers such as the Flutter shell may supply these when they already hold a
/// [PlayerView] for [playerId]; when omitted, behavior matches the historical
/// path.
List<ArmyMovePickerDestination> armyMovePickerDestinations({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Army army,
  required Orders currentOrders,
  Set<String>? playerOwnedFullProvinceIds,
  PlayerView? playerView,
  Map<String, Unit>? unitsById,
  /// When callers already built membership for this [game], pass it to skip a
  /// second [DiplomacyFactionMembership.from] scan (Refs #2394).
  DiplomacyFactionMembership? factionMembership,
}) {
  final diplo =
      currentOrders.diplomaticOrdersByPlayerId[playerId] ??
      const <DiplomaticOrder>[];
  final effectiveFactionMembership =
      factionMembership ?? DiplomacyFactionMembership.from(game);
  final ownedProvinceIds =
      playerOwnedFullProvinceIds ??
      (playerView != null
          ? <String>{
              for (final e in playerView.provincesById.entries)
                if (e.value.ownerId == playerId) e.key,
            }
          : <String>{
              for (final p in allProvinces(game.worldState))
                if (p.ownerId == playerId) toFullProvinceId(p.regionId, p.id),
            });
  final raw = armyMoveCandidateDestinationProvinceIds(
    game: game,
    topology: topology,
    playerId: playerId,
    army: army,
    playerOwnedFullProvinceIds: ownedProvinceIds,
  );
  final baseValidator = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: currentOrders,
    factionMembership: effectiveFactionMembership,
    view: playerView,
    unitsById: unitsById,
  );
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
      final trialValidator =
          declareWarTrialValidatorsByTargetFaction.putIfAbsent(ownerId, () {
        final trialOrders = ordersWithAppendedDiplomaticOrder(
          currentOrders,
          playerId,
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: ownerId,
          ),
        );
        return IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: playerId,
          basePrefix: trialOrders,
          factionMembership: effectiveFactionMembership,
          view: playerView,
          unitsById: unitsById,
        );
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
  final playerId = view.playerId;
  final suggestions = <ArmyMoveOrder>[];
  final existingArmyMoves = <String, Set<String>>{};
  final existingForPlayer =
      currentOrders.armyMoveOrdersByPlayerId[playerId] ?? const [];
  for (final m in existingForPlayer) {
    existingArmyMoves
        .putIfAbsent(m.armyId, () => <String>{})
        .add(m.destinationProvinceId);
  }

  // Single per-player validator: amortizes the per-player [PlayerView] /
  // units-by-id setup across every candidate probe. SPEC/program/order-
  // suggestions.md § Incremental candidate validation. Refs #2237.
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match view.playerId',
  );
  final candidateValidator =
      sharedCandidateValidator ??
      IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: currentOrders,
        factionMembership: DiplomacyFactionMembership.from(game),
        view: view,
        unitsById: unitsByIdFromWorld(game.worldState),
      );

  final playerOwnedFullProvinceIds = <String>{
    for (final e in view.provincesById.entries)
      if (e.value.ownerId == playerId) e.key,
  };

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

    var acceptedForArmy = 0;
    var probeAttemptsForArmy = 0;
    for (final destinationProvinceId in destIds) {
      final already = existingArmyMoves[army.id];
      if (already != null && already.contains(destinationProvinceId)) continue;
      probeAttemptsForArmy++;

      final candidate = ArmyMoveOrder(
        armyId: army.id,
        destinationProvinceId: destinationProvinceId,
      );

      if (candidateValidator.isArmyMoveAccepted(candidate)) {
        suggestions.add(candidate);
        acceptedForArmy++;
        if (acceptedForArmy >= _kMaxArmyMoveSuggestionsPerArmy) {
          break;
        }
      }
      if (probeAttemptsForArmy >= _kMaxArmyMoveProbeAttemptsPerArmy) {
        break;
      }
    }
  }

  suggestions.sort((a, b) {
    final idCmp = a.armyId.compareTo(b.armyId);
    if (idCmp != 0) return idCmp;
    return a.destinationProvinceId.compareTo(b.destinationProvinceId);
  });
  return suggestions;
}
