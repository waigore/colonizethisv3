part of 'capital_and_gp_fall.dart';

/// Terminal fall for **Minor Nations** and **Tribes** after combat resolution
/// and capital reassignment. Parallel to [applyGreatPowerFall] but the
/// eligibility check is **no owned provinces in the original capital region**
/// (matches the `evaluateCapitalReassignmentEligibility`
/// `no_owned_provinces_in_region` branch). When the trigger fires, all
/// provinces previously owned by the falling faction are transferred to the
/// faction that currently owns its lost capital province, the faction is
/// removed from `Game.minorNations` / `Game.tribes`, and any remaining units
/// and fleets owned by the falling faction are removed from world state.
/// SPEC/game/capital-and-connectivity § Minor Nation and Tribe terminal fall.
Game applyFactionTerminalFall(
  Game state, {
  required Map<String, String?> previousCapitalByMinor,
  required Map<String, String?> previousCapitalByTribe,
}) {
  var game = state;

  for (final minorId in previousCapitalByMinor.keys.toList()..sort()) {
    final prevCapitalId = previousCapitalByMinor[minorId];
    if (prevCapitalId == null || prevCapitalId.isEmpty) continue;
    if (!game.minorNations.any((m) => m.id == minorId)) continue;
    final result = _applyTerminalFallForFaction(
      game: game,
      factionId: minorId,
      previousCapitalId: prevCapitalId,
      factionLabel: 'minor',
      removeFaction: (g) => g.copyWith(
        minorNations: g.minorNations.where((m) => m.id != minorId).toList(),
      ),
    );
    game = result;
  }

  for (final tribeId in previousCapitalByTribe.keys.toList()..sort()) {
    final prevCapitalId = previousCapitalByTribe[tribeId];
    if (prevCapitalId == null || prevCapitalId.isEmpty) continue;
    if (!game.tribes.any((t) => t.id == tribeId)) continue;
    final result = _applyTerminalFallForFaction(
      game: game,
      factionId: tribeId,
      previousCapitalId: prevCapitalId,
      factionLabel: 'tribe',
      removeFaction: (g) =>
          g.copyWith(tribes: g.tribes.where((t) => t.id != tribeId).toList()),
    );
    game = result;
  }

  return game;
}

Game _applyTerminalFallForFaction({
  required Game game,
  required String factionId,
  required String previousCapitalId,
  required String factionLabel,
  required Game Function(Game) removeFaction,
}) {
  final prevCapital = game.worldState.tryGetProvince(previousCapitalId);
  if (prevCapital == null) return game;
  final conquerorId = prevCapital.ownerId;
  if (conquerorId == null || conquerorId.isEmpty || conquerorId == factionId) {
    return game;
  }
  final originalRegionId = ProvinceId.regionIdFrom(previousCapitalId);
  final originalRegion = regionDataForId(game.worldState, originalRegionId);
  if (originalRegion == null) return game;
  final hasProvinceInOriginalRegion = originalRegion.provinces.any(
    (p) => p.ownerId == factionId,
  );
  if (hasProvinceInOriginalRegion) return game;

  RegionData transferRegion(RegionData region) {
    final updatedProvinces = region.provinces
        .map(
          (p) => p.ownerId == factionId ? p.copyWith(ownerId: conquerorId) : p,
        )
        .toList();
    final remainingUnits = region.units
        .where((u) => u.ownerId != factionId)
        .toList();
    return RegionData(provinces: updatedProvinces, units: remainingUnits);
  }

  final updatedWorldState = game.worldState.mapBothRegions(
    (_, region) => transferRegion(region),
  );
  final remainingFleets = game.worldState.fleets
      .where((f) => f.ownerId != factionId)
      .toList();
  final nextWorldState = updatedWorldState.copyWith(fleets: remainingFleets);
  var next = game.withWorldState(nextWorldState);
  next = removeFaction(next);
  worldLog.i(
    '$factionLabel $factionId fell after capital loss; '
    'provinces and assets transferred to $conquerorId',
  );
  return next;
}

Game applyGreatPowerFall(
  Game state,
  Map<String, String?> previousCapitalByPlayer,
) {
  var game = state;

  final provinceOwnerById = <String, String?>{
    for (final p in allProvinces(game.worldState)) p.id: p.ownerId,
  };

  final portsByProvince = <String, List<String>>{};
  game.worldState.portsByProvinceSeaboard.forEach((key, _) {
    final decoded = decodePortSeaboardRegistryKey(key);
    if (decoded == null || !decoded.isPrefixedKey) return;
    portsByProvince.putIfAbsent(decoded.fullProvinceId, () => []).add(key);
  });

  for (final player in game.players) {
    final playerId = player.id;
    final prevCapitalId = previousCapitalByPlayer[playerId];
    if (prevCapitalId == null || prevCapitalId.isEmpty) continue;

    final prevCapitalOwner = provinceOwnerById[prevCapitalId];
    if (prevCapitalOwner == null || prevCapitalOwner == playerId) {
      continue;
    }

    var hasPortProvince = false;
    provinceOwnerById.forEach((provId, ownerId) {
      if (ownerId == playerId && portsByProvince.containsKey(provId)) {
        hasPortProvince = true;
      }
    });
    if (hasPortProvince) continue;

    final conquerorId = prevCapitalOwner;

    RegionData transferRegion(RegionData region) {
      final updatedProvinces = region.provinces
          .map(
            (p) => p.ownerId == playerId ? p.copyWith(ownerId: conquerorId) : p,
          )
          .toList();
      final remainingUnits = region.units
          .where((u) => u.ownerId != playerId)
          .toList();
      return RegionData(provinces: updatedProvinces, units: remainingUnits);
    }

    final updatedWorldState = game.worldState.mapBothRegions(
      (_, region) => transferRegion(region),
    );

    final remainingFleets = game.worldState.fleets
        .where((f) => f.ownerId != playerId)
        .toList();

    final nextWorldState = updatedWorldState.copyWith(fleets: remainingFleets);
    game = game
        .withWorldState(nextWorldState)
        .mapPlayers(
          (p) => p.id == playerId
              ? p.copyWith(capitalProvinceId: null, capitalTile: null)
              : p,
        );
  }

  return game;
}
